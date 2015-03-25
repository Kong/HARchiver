open Core.Std
open Ctypes

type zmq_sock

type str_ptr = string ptr

module CLU = Conduit_lwt_unix

val get_zmq_sock : string -> string -> zmq_sock

val send_zmq : str_ptr -> char ptr -> unit Lwt.t

val get_addr_from_ch : CLU.flow -> string

val dns_lookup : string -> (string, string) Result.t Lwt.t

val sock : zmq_sock option ref