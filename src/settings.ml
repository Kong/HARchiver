open Core.Std

let version = "1.6.2"
let name = "ApiAnalytics HARchiver"

let zmq_flush_timeout = 20.

let http_error_wait = 0.5

let resolver_pool = 10
let resolver_timeout = 10. (* Currently unused *)
let resolver_expire = 30.

let default_concurrent = 500
let default_timeout = 6.

let default_zmq_host = "socket.apianalytics.com"
let default_zmq_port = 5000


type config = {
	port: int;
	https: int option;
	reverse: (string option * int option option) option;
	debug: bool;
	concurrent: int;
	timeout: float;
	replays: bool;
	filter_ua: Re.re option;
	zmq_host: string;
	zmq_port: string;
	key: string option
}

let make_config port https reverse debug concurrent timeout replays filter_ua zmq_host zmq_port key = {
	port;
	https;
	reverse = reverse
	|> Option.map ~f:(fun str ->
		Uri.of_string ("http://"^str)
		|> fun uri ->
			let host = Option.value_exn ~message:"Invalid host name or IP for reverse mode" (Uri.host uri) in
			let port = Uri.port uri in
			((Some host), (Some port))
	);
	debug;
	concurrent = concurrent |> Option.value ~default:default_concurrent;
	timeout = timeout |> Option.value ~default:default_timeout;
	replays;
	filter_ua = Option.map ~f:Regex.create filter_ua;
	zmq_host = zmq_host |> Option.value ~default:default_zmq_host;
	zmq_port = zmq_port |> Option.value ~default:default_zmq_port |> Int.to_string;
	key;
}
