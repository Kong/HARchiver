open Core.Std

(* val get_ZMQ_sock : (([> `Push ] as 'a) Lwt_zmq.Socket.t, unit) Cache.t -> string -> string -> ('a Lwt_zmq.Socket.t, unit) Core.Std.Result.t Lwt.t *)
(* val add_to_buffer : string -> unit *)
(* val invalidate_cache : (([> `Push ] as 'a) Lwt_zmq.Socket.t, unit) Cache.t -> string -> string -> unit *)

module type Sig_arg = sig
  val host : string
  val port : string
end
module type Sig_make = sig
  val send : string -> (string, string) Result.t Lwt.t
end

module Make : functor (Arg : Sig_arg) -> Sig_make
