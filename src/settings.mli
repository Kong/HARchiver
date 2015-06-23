open Core.Std

val version : string
val name : string
val zmq_flush_timeout : float
val http_error_wait : float
val resolver_pool : int
val resolver_timeout : float
val resolver_expire : float
val default_concurrent : int
val default_timeout : float

type config = {
	port : int;
	https : int option;
	reverse : (string option * int option option) option;
	environment: string option;
	debug : bool;
	concurrent : int;
	timeout : float;
	replays : bool;
	filter_ua: Re.re option;
	zmq_host : string;
	zmq_port : string;
	key : string option;
}

val make_config : int -> int option -> string option -> string option -> bool -> int option -> float option -> bool -> string option -> string option -> int option -> string option -> config
