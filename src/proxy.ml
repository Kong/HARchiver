open Core.Std
open Lwt
open Cohttp_lwt_unix
open Har_j

type protocol = HTTP | HTTPS
exception Too_many_requests
exception Cant_resolve_ip of string
exception Cant_send_har of string

let make_server port https reverse debug concurrent timeout dev key =
	let nb_current = ref 0 in
	let sock = Network.get_ZMQ_sock (if dev then Settings.apianalytics_staging else Settings.apianalytics_prod) in
	let global_archive = Option.map ~f:(fun k -> (module Archive.Make (struct let key = k end) : Archive.Sig_make)) key in

	let send_har archive req res t_client_length t_provider_length client_ip server_ip (t0, har_send, har_wait) startedDateTime =
		try_lwt (
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
					server_ip;
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
	let callback (ch, _) req client_body protcol =
		(* Initiate counters and other bookeeping *)
		let () = nb_current := (!nb_current + 1) in
		let t0 = Archive.get_timestamp_ms () in
		let startedDateTime = Archive.get_utc_time_string () in
		let client_ip = Network.get_addr_from_ch ch in

		(* Prepare the target *)
		let target = (match reverse with
		| None -> Request.uri req
		| Some (reverse_host, reverse_port) ->
			Request.uri req
			|> fun uri -> Uri.with_host uri reverse_host
			|> fun uri ->
				match reverse_port with
				| Some p -> Uri.with_port uri p
				| None -> uri
		) |> fun uri ->
			match protcol with
			| HTTPS -> Uri.with_scheme uri (Some "https")
			| HTTP -> Uri.with_scheme uri (Some "http")
		in

		(* Start fetching the target IP in advance *)
		let t_dns = Network.dns_lookup (target |> Uri.host |> Option.value ~default:"") in

		(* More bookeeping *)
		let client_headers = Request.headers req in
		let t_client_length = Http_utils.body_length client_body in
		let local_archive = Option.map (Cohttp.Header.get client_headers "Service-Token") ~f:(fun k ->
			(module Archive.Make (struct let key = k end) : Archive.Sig_make)) in
		let har_send = (Archive.get_timestamp_ms ()) - t0 in

		(* Main block. Throws lwt exceptions for any invalid request or error *)
		let response = try_lwt (
			(* Throw some exceptions if needed, then set some headers *)
			if !nb_current > concurrent then Lwt.fail Too_many_requests else
			match Option.first_some local_archive global_archive with
			| None -> Lwt.fail (Failure "Service-Token header missing")
			| Some archive ->
				let client_headers_ready = Cohttp.Header.remove client_headers "Service-Token"
				|> fun h -> Cohttp.Header.add h "X-Forwarded-For" client_ip
				in

				(* Do the remote call using the prefetched cached IP. The whole thing has a Lwt.pick timeout *)
				let remote_call = (
					t_dns
					>>= function
						| Error e -> Lwt.fail (Cant_resolve_ip e)
						| Ok server_ip ->
							Client.call ~headers:client_headers_ready ~body:client_body (Request.meth req) (Uri.with_host target (Some server_ip))
					>>= fun (provider_res, provider_body) ->
						let har_wait = (Archive.get_timestamp_ms ()) - t0 - har_send in
						let t_provider_length = Http_utils.body_length provider_body in
						let _ = send_har archive req provider_res t_client_length t_provider_length client_ip server_ip (t0, har_send, har_wait) startedDateTime in
						let provider_headers = Response.headers provider_res in
						(* Keep the same Encoding as the remote server *)
						let encoding = match Cohttp.Header.get provider_headers "content-length" with
						| None -> Cohttp.Transfer.Chunked
						| Some length -> Cohttp.Transfer.Fixed (Int64.of_string length)
						in
						(* Make the response manually to choose the right Encoding *)
						let client_response = Response.make ~version:(Response.version provider_res) ~status:(Response.status provider_res) ~encoding ~headers:provider_headers () in
						return (client_response, provider_body)
				)
				in
				Lwt.pick [remote_call; Lwt_unix.timeout timeout]
		) with ex ->
			let (error_code, error_text) = match ex with
			| Lwt_unix.Timeout ->
				(504, "504: The server timed out trying to establish a connection")
			| Too_many_requests ->
				(503, "503: The server is under heavy load, try again")
			| Cant_resolve_ip ip ->
				(400, "400: Hostname cannot be resolved")
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
				let t_provider_length = Http_utils.body_length body in
				match Option.first_some local_archive global_archive with
				| None -> return ()
				| Some archive ->
					t_dns
					>>= function
						| Error server_ip | Ok server_ip ->
							send_har archive req res t_client_length t_provider_length client_ip server_ip (t0, har_send, har_wait) startedDateTime
			in t_res
		in
		let _ = response >>= fun _ -> return (nb_current := (!nb_current - 1)) in
		response
	in
	let conn_closed (_, _) = () in
	let config_tcp = Server.make ~callback:(fun c r b -> callback c r b HTTP) ~conn_closed () in
	let config_ssl = Server.make ~callback:(fun c r b -> callback c r b HTTPS) ~conn_closed () in
	let ctx = Cohttp_lwt_unix_net.init () in
	let tcp_mode = `TCP (`Port port) in
	let tcp_server = Server.create ~ctx ~mode:tcp_mode config_tcp in
	let _ = Lwt_io.printf "HTTP server listening on port %n\n" port in
	match https with
	| None ->
		tcp_server
	| Some https_port ->
		let ssl_mode = `OpenSSL (`Crt_file_path "cert.pem", `Key_file_path "key.pem", `No_password, `Port https_port) in
		let start_https_thunk () = Server.create ~ctx ~mode:ssl_mode config_ssl in
		match Result.try_with start_https_thunk with
		| Ok ssl_server ->
			let _ = Lwt_io.printf "HTTPS server listening on port %n\n" https_port in
			(tcp_server <&> ssl_server)
		| Error e ->
			let _ = Lwt_io.printf "An HTTPS error occured. Make sure both cert.pem and key.pem are located in the current harchiver directory\n%s\nOnly HTTP mode was started\n\n" (Exn.to_string e) in
			tcp_server
