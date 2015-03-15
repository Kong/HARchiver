open Core.Std
open Ctypes
open PosixTypes
open Foreign

type zmq_sock
type str_ptr = string ptr

module CLU = Conduit_lwt_unix

val send_zmq : str_ptr -> unit Lwt.t

val get_addr_from_ch : CLU.flow -> string

val dns_lookup : string -> (string, string) Result.t Lwt.t
