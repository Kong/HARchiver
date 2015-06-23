open Core.Std
open Lwt
open Settings

(* Force usage of libev *)
let () = Lwt_engine.set ~transfer:true ~destroy:true (new Lwt_engine.libev)

(* Replace the default uncaught exception hook with one that doesn't quit *)
let () = Lwt.async_exception_hook := fun ex -> print_endline (Exn.to_string ex)

let start config = Lwt_unix.run (Proxy.make_server config)

let command =
	Command.basic
		~summary:"Universal lightweight analytics layer for apianalytics.com"
		~readme:(fun () -> "Portable, fast and transparent proxy.\n
			It lets HTTP/HTTPS traffic through and streams datapoints to apianalytics.com\n
			If a Service-Token isn't specified at startup, it needs to be in a header for every request.")
		Command.Spec.(
			empty
			+> anon ("port" %: int)
			+> flag "https" (optional int) ~doc:" Pass the desired HTTPS port. This also means that the files 'cert.pem' and 'key.pem' must be present in the current directory."
			+> flag "reverse" (optional string) ~doc:" Reverse proxy mode. Pass the desired target. All the incoming requests will be redirected to that hostname or IP."
			+> flag "env" (optional string) ~doc:" Set which environment to use"
			+> flag "debug" no_arg ~doc:" Print generated HARs once they've been flushed to ApiAnalytics.com."
			+> flag "c" (optional int) ~doc:(" Set a maximum number of concurrent requests. This is "^(Int.to_string Settings.default_concurrent)^" by default. Beyond that, make sure your ulimit is high enough.")
			+> flag "t" (optional float) ~doc:(" Timeout, in seconds. Close the connection if the remote server doesn't respond before the timeout expires. This is "^(Float.to_string Settings.default_timeout)^" seconds by default.")
			+> flag "replays" no_arg ~doc:" Enable replays by sending the body of the requests in the ALF"
			+> flag "filter-ua" (optional string) ~doc:" Do not send datapoints for the calls containing a User-Agent header that matches this case-insensitive PCRE regular expression."
			+> flag "host" (optional string) ~doc:" (Dev option). Overrides the APIAnalytics host"
			+> flag "port" (optional int) ~doc:" (Dev option). Overrides the APIAnalytics port"
			+> anon (maybe ("service_token" %: string))
		)
		(fun port https reverse environment debug concurrent timeout replays filter_ua zmq_host zmq_port key () ->
			Settings.make_config port https reverse environment debug concurrent timeout replays filter_ua zmq_host zmq_port key |> start)

let () = Command.run ~version:Settings.version ~build_info:"github.com/Mashape/HARchiver" command
