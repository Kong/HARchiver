open Core.Std
open Lwt

module type Sig_arg = sig
  val host : string
  val port : string
end
module type Sig_make = sig
  val send : string -> (string, string) Result.t Lwt.t
end

module Make (Arg : Sig_arg) : Sig_make = struct
  let zmq_host = Arg.host
  let zmq_port = Arg.port
  let remote = Printf.sprintf "tcp://%s:%s" zmq_host zmq_port
  let har_buffer = ref []
  let socket_cache = Cache.create ()
  let add_to_buffer har = har_buffer := har :: !har_buffer

  let get_ZMQ_sock () =
    Cache.get socket_cache ~key:remote ~exp:Settings.zmq_socket_ttl ~thunk:(fun () ->
      try_lwt (
        let ctx = ZMQ.Context.create () in
        let raw_sock = ZMQ.Socket.create ctx ZMQ.Socket.push in
        ignore (Lwt_io.printlf "Connecting to %s..." remote);
        ZMQ.Socket.connect raw_sock remote;
        let sock = Lwt_zmq.Socket.of_socket raw_sock in
        ignore (Lwt_io.printl "Connected.");
        return (Ok sock)
      ) with e ->
        ignore (Lwt_io.printlf "ZMQ ERROR\n%s\n%s" (Exn.to_string e) (Exn.backtrace ()));
        return (Error e)
    ) >|= function
    | Ok sock -> sock
    | Error e -> raise e

  let send har =
    get_ZMQ_sock ()
    >>= fun sock ->
      Lwt.pick [
        (Lwt_zmq.Socket.send sock har >|= fun () -> Ok har);
        (Lwt_unix.sleep Settings.zmq_flush_timeout
        >|= fun () ->
          add_to_buffer har;
          Error "Could not flush"
        );
      ]

  let flush_buffer () =
    Cache.invalidate socket_cache remote;
    get_ZMQ_sock ()
    >>= fun sock ->
      let buffer = !har_buffer in
      har_buffer := [];
      Lwt_list.map_p send buffer
    >>= fun _ ->
      return_unit

  (* Background task *)
  let rec timer_check_buffer () =
    Lwt_unix.sleep 5.
    >>= fun () ->
      if List.length !har_buffer > 0 then flush_buffer ()
      else return_unit
    >>= fun () ->
      timer_check_buffer ()

  let () = ignore (timer_check_buffer ())

end
