open Core.Std
open Lwt

let start port https debug concurrent timeout key () = Lwt_unix.run (Proxy.make_server port https debug concurrent timeout key)

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
			+> flag "debug" no_arg ~doc:" Print generated HARs once they've been flushed to ApiAnalytics.com."
			+> flag "c" (optional int) ~doc:" Set a maximum number of concurrent requests. This is 300 by default. Beyond that, your kernel might start complaining about the number of open network sockets."
			+> flag "t" (optional float) ~doc:" Timeout, in seconds. Close the connection if the remote server doesn't respond before the timeout expires. This is 6 seconds by default."
			+> anon (maybe ("service_token" %: string))
		)
		start

let () = Command.run ~version:"1.2.0" ~build_info:"github.com/Mashape/HARchiver" command
