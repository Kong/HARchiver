open Core.Std
open Ctypes
open PosixTypes
open Foreign

type zmq_sock = unit ptr
type str_ptr = string ptr

module CLU = Conduit_lwt_unix

val get_zmq_sock : string -> string -> zmq_sock

val send_zmq : zmq_sock -> (unit -> string) -> (str_ptr * unit Lwt.t)

val get_addr_from_ch : CLU.flow -> string

val dns_lookup : string -> (string, string) Result.t Lwt.t