open Cohttp
open Har_j

type t_input = {
	req: Request.t;
	res: Response.t;
	req_length: int;
	res_length: int;
	client_ip: string;
	server_ip: string;
	timings: int * int * int;
	startedDateTime: string;
}

type t_get_message =  t_input -> message

module type Sig_make = sig val get_message : t_get_message end
module type Sig_arg = sig val key : bytes end

module Make : functor (X : Sig_arg) -> Sig_make

val get_timestamp_ms : unit -> int
val get_utc_time_string : unit -> string
