open Core.Std
open Lwt
open Cohttp_lwt
open Cohttp_lwt_unix
open Cohttp_lwt_unix_io
open Har_j

module Body = Cohttp_lwt_body

let get_ZMQ_sock remote =
	let ctx = ZMQ.Context.create () in
	let raw_sock = ZMQ.Socket.create ctx ZMQ.Socket.push in
	ZMQ.Socket.connect raw_sock remote;
	print_endline ("Attempting to connect to "^remote);
	Lwt_zmq.Socket.of_socket raw_sock

let get_timestamp () = Time.now () |> Time.to_float |> Int.of_float

let stream_length stream = Lwt_stream.fold (fun a b -> (String.length a)+b) stream 0

let make_server port key () =
	let sock = get_ZMQ_sock "tcp://127.0.0.1:5000" in
	let global_archive = Option.map key (fun k -> (module Archive.Make (struct let key = k end) : Archive.Sig_make)) in
	let send_har archive req res t_client_length t_provider_length timings =
		t_client_length
		>>= fun client_length -> t_provider_length
		>>= fun provider_length ->
			let module KeyArchive = (val archive : Archive.Sig_make) in

			Lwt_zmq.Socket.send sock (KeyArchive.get_har req res client_length provider_length timings |> string_of_har ~len:1024)
	in
	let callback (_,_) req client_body =
		let har_init = get_timestamp () in
		let client_uri = Request.uri req in
		let client_headers = Cohttp.Header.replace (Request.headers req) "Host" (Uri.host client_uri |> Option.value ~default:"") in
		let t_client_length = Body.to_stream client_body |> Lwt_stream.clone |> stream_length in
		let har_send = (get_timestamp ()) - har_init in
		let local_archive = Option.map (Cohttp.Header.get client_headers "Service-Token") ~f:(fun k ->
			(module Archive.Make (struct let key = k end) : Archive.Sig_make)) in

		try_lwt (
			match Option.first_some local_archive global_archive with
			| None -> raise (Failure "Service-Token missing")
			| Some archive ->
				Client.call ~headers:client_headers ~body:client_body (Request.meth req) client_uri
				>>= fun (res, provider_body) ->
					let har_wait = (get_timestamp ()) - har_init in
					let provider_headers = Cohttp.Header.remove (Response.headers res) "content-length" in (* Because we're using Transfer-Encoding: Chunked *)
					let t_provider_length = Body.to_stream provider_body |> Lwt_stream.clone |> stream_length in
					let har_receive = (get_timestamp ()) - har_init in
					let _ = send_har archive req res t_client_length t_provider_length (har_send, har_wait, har_receive) in
					Server.respond ~flush:true ~headers:provider_headers ~status:(Response.status res) ~body:provider_body ()
		) with ex ->
			let har_wait = (get_timestamp ()) - har_init in
			let t_res = Server.respond_error ~status:(Cohttp.Code.status_of_code 503) ~body:(Exn.to_string ex) () in
			let _ = t_res >>= fun (res, body) ->
				let t_provider_length = Body.to_stream body |> Lwt_stream.clone |> stream_length in
				match Option.first_some local_archive global_archive with
				| None -> return ()
				| Some archive -> send_har archive req res t_client_length t_provider_length (har_wait, har_send, 0)
			in t_res
	in
	let conn_closed (_,_) () = () in
	let config = {Server.callback; conn_closed} in
	let ctx = Cohttp_lwt_unix_net.init () in
	let mode = `TCP (`Port port) in
	let _ = Lwt_io.printf "Server listening on port %n\n" port in
	Server.create ~ctx ~mode config

let start port key () = Lwt_unix.run (make_server port key ())

let command =
	Command.basic
		~summary:"Transparent analytics layer for apianalytics.com"
		~readme:(fun () -> "Portable, fast and transparent proxy. It lets HTTP traffic through and streams datapoints to apianalytics.com.")
		Command.Spec.(
			empty
			+> anon ("port" %: int)
			+> anon (maybe ("key" %: string))
		)
		start

(* let () = start 15000 (Some "DEFAULT") () *)
let () = Command.run ~version:"0.1" ~build_info:"github.com/SGrondin/analytics-harchiver" command
