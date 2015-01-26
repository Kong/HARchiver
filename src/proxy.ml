open Core.Std
open Lwt
open Cohttp_lwt_unix
open Har_j

module Body = Cohttp_lwt_body
module CLU = Conduit_lwt_unix
exception Too_many_requests
exception Cant_send_har of string

let get_ZMQ_sock remote =
	let ctx = ZMQ.Context.create () in
	let raw_sock = ZMQ.Socket.create ctx ZMQ.Socket.push in
	ZMQ.Socket.connect raw_sock remote;
	print_endline ("Attempting to connect to "^remote);
	Lwt_zmq.Socket.of_socket raw_sock

let body_length body =
	let clone = body |> Body.to_stream |> Lwt_stream.clone in
	Lwt_stream.fold (fun a b -> (String.length a)+b) clone 0

let get_addr_from_ch = function
| CLU.TCP {CLU.fd; ip; port} -> begin
	match Lwt_unix.getpeername fd with
	| Lwt_unix.ADDR_INET (ia,port) -> Ipaddr.to_string (Ipaddr_unix.of_inet_addr ia)
	| Lwt_unix.ADDR_UNIX path -> sprintf "sock:%s" path end
| _ -> "<error>"

let resolvers = Lwt_pool.create Settings.resolver_pool ~check:(fun _ f -> f false) Dns_resolver_unix.create
let dns_cache = Cache.create ()

let dns_lookup host =
	Cache.get dns_cache ~key:host ~exp:Settings.resolver_expire ~thunk:(fun () ->
		Lwt_pool.use resolvers (fun resolver ->
			let open Dns.Packet in
			Dns_resolver_unix.resolve resolver Q_IN Q_A (Dns.Name.string_to_domain_name host)
			>>= fun response ->
				match List.hd response.answers with
				| None -> return (Error "No answer")
				| Some answer ->
					match answer.rdata with
					| A ipv4 ->
						return (Ok (Ipaddr.V4.to_string ipv4))
					| _ -> return (Error "Not ipv4")
		)
	)

let make_server port https reverse debug concurrent timeout dev key =
	let nb_current = ref 0 in
	let sock = get_ZMQ_sock (if dev then Settings.apianalytics_staging else Settings.apianalytics_prod) in
	let global_archive = Option.map ~f:(fun k -> (module Archive.Make (struct let key = k end) : Archive.Sig_make)) key in

	let send_har archive t_dns req res t_client_length t_provider_length client_ip (t0, har_send, har_wait) startedDateTime =
		try_lwt (
			Lwt.pick [t_dns; Lwt_unix.sleep Settings.resolver_timeout >>= fun () -> return (Error "Timeout")]
			>>= fun r_server_ip ->
				t_client_length
			>>= fun client_length ->
				t_provider_length
			>>= fun provider_length ->
				let module KeyArchive = (val archive : Archive.Sig_make) in

				let open Archive in
				let archive_input = {
					req;
					res;
					req_length = client_length;
					res_length = provider_length;
					client_ip;
					server_ip = (r_server_ip |> function
					| Error e -> e
					| Ok ip -> ip
					);
					timings = (har_send, har_wait, ((get_timestamp_ms ()) - t0 - har_wait));
					startedDateTime;
				} in

				let har_string = KeyArchive.get_message archive_input |> string_of_message in
				Lwt.pick [
					Lwt_zmq.Socket.send sock har_string;
					Lwt_unix.sleep Settings.zmq_flush_timeout >>= fun () -> Lwt.fail (Cant_send_har har_string);
				]
			>>= fun () ->
				if debug then Lwt_io.printlf "%s\n" har_string else return ()
		) with ex ->
			match ex with
			| Cant_send_har har ->
				Lwt_io.printlf "ERROR: Could not flush this datapoint to the ZMQ driver within %f seconds:\n%s\n" Settings.zmq_flush_timeout har
			| e ->
				Lwt_io.printlf "ERROR:\n%s\n%s" (Exn.to_string e) (Exn.backtrace ())
	in
	let callback (ch, _) req client_body =
		let () = nb_current := (!nb_current + 1) in
		let t0 = Archive.get_timestamp_ms () in
		let startedDateTime = Archive.get_utc_time_string () in
		let client_ip = get_addr_from_ch ch in
		let target = match reverse with
		| None -> Request.uri req
		| Some (reverse_host, reverse_port) ->
			Request.uri req
			|> fun uri -> Uri.with_host uri reverse_host
			|> fun uri ->
				match reverse_port with
				| Some p -> Uri.with_port uri p
				| None -> uri
		in
		let t_dns = dns_lookup (target |> Uri.host |> Option.value ~default:"") in
		let client_headers = Request.headers req in
		let t_client_length = body_length client_body in
		let local_archive = Option.map (Cohttp.Header.get client_headers "Service-Token") ~f:(fun k ->
			(module Archive.Make (struct let key = k end) : Archive.Sig_make)) in
		let har_send = (Archive.get_timestamp_ms ()) - t0 in

		let response = try_lwt (
			if !nb_current > concurrent then Lwt.fail Too_many_requests else
			match Option.first_some local_archive global_archive with
			| None -> Lwt.fail (Failure "Service-Token header missing")
			| Some archive ->
				let client_headers_ready = Cohttp.Header.remove client_headers "Service-Token"
				|> fun h -> Cohttp.Header.remove h "Host" (* Duplicate automatically added by Cohttp *)
				|> fun h -> Cohttp.Header.add h "X-Forwarded-For" client_ip in
				let remote_call = Client.call ~headers:client_headers_ready ~body:client_body (Request.meth req) target
				>>= fun (res, provider_body) ->
					let har_wait = (Archive.get_timestamp_ms ()) - t0 - har_send in
					let provider_headers = Cohttp.Header.remove (Response.headers res) "content-length" in (* Because we're using Transfer-Encoding: Chunked *)
					let t_provider_length = body_length provider_body in
					let _ = send_har archive t_dns req res t_client_length t_provider_length client_ip (t0, har_send, har_wait) startedDateTime in
					Server.respond ~headers:provider_headers ~status:(Response.status res) ~body:provider_body ()
				in
				Lwt.pick [remote_call; Lwt_unix.timeout timeout]
		) with ex ->
			let (error_code, error_text) = match ex with
			| Lwt_unix.Timeout ->
				(504, "504: The server timed out trying to establish a connection")
			| Too_many_requests ->
				(503, "503: The server is under heavy load, try again")
			| _ ->
				(500, ("500: "^(Exn.to_string ex)))
			in
			let har_wait = (Archive.get_timestamp_ms ()) - t0 - har_send in
			let t_res =
				Lwt_unix.sleep Settings.http_error_wait
				>>= fun () ->
					Server.respond_error ~status:(Cohttp.Code.status_of_code error_code) ~body:error_text ()
			in
			let _ = t_res >>= fun (res, body) ->
				let t_provider_length = body_length body in
				match Option.first_some local_archive global_archive with
				| None -> return ()
				| Some archive -> send_har archive t_dns req res t_client_length t_provider_length client_ip (t0, har_send, har_wait) startedDateTime
			in t_res
		in
		let _ = response >>= fun _ -> return (nb_current := (!nb_current - 1)) in
		response
	in
	let conn_closed (_, _) = () in
	let config = Server.make ~callback ~conn_closed () in
	let ctx = Cohttp_lwt_unix_net.init () in
	let tcp_mode = `TCP (`Port port) in
	let tcp_server = Server.create ~ctx ~mode:tcp_mode config in
	let _ = Lwt_io.printf "HTTP server listening on port %n\n" port in
	match https with
	| None ->
		tcp_server
	| Some https_port ->
		let ssl_mode = `OpenSSL (`Crt_file_path "cert.pem", `Key_file_path "key.pem", `No_password, `Port (https_port)) in
		let start_https_thunk () = Server.create ~ctx ~mode:ssl_mode config in
		match Result.try_with start_https_thunk with
		| Ok ssl_server ->
			let _ = Lwt_io.printf "HTTPS server listening on port %n\n" https_port in
			(tcp_server <&> ssl_server)
		| Error e ->
			let _ = Lwt_io.printf "An HTTPS error occured. Make sure both cert.pem and key.pem are located in the current harchiver directory\n%s\nOnly HTTP mode was started\n\n" (Exn.to_string e) in
			tcp_server
