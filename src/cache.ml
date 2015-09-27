open Core.Std
open Lwt

type ('a, 'b) entry = {
  element: 'a option;
  t_expire: unit Lwt.t;
  mutable waiting: ('a, 'b) Result.t Lwt.u list;
}

type ('a, 'b) t = (string, ('a, 'b) entry) Hashtbl.t


let create () = Hashtbl.create ~hashable:String.hashable ()

(* Creates a thread that expires after `exp` and invalidates the element if no one is waiting for it *)
let make_expire c key exp =
  Lwt_unix.sleep exp
  >|= fun () ->
    match Hashtbl.find c key with
    | None -> ()
    | Some item ->
      match item.waiting with
      | [] -> Hashtbl.remove c key
      | _ -> ()

(* An element was found, this updates the entry *)
let put c key data exp =
  let item = {
    element = Some data;
    t_expire = (make_expire c key exp);
    waiting = [];
  }
  in
  Hashtbl.replace c ~key ~data:item

(* Returns the cached element if it exists.
Otherwise, either goes fetch it itself if no other thread is
currently doing it, or wait for the result of that other thread and return it.
Call `get` inside Lwt.pick with a timeout if there's a chance the thunk might never return. *)
let get c ~key ~exp ~thunk =
  match Hashtbl.find c key with
  | Some found -> begin
    match found.element with
    | Some el ->
      (* There's something *)
      Lwt.return (Ok el)
    | None ->
      (* Currently being fetched *)
      let (thread, wakener) = Lwt.wait () in
      found.waiting <- (wakener::found.waiting);
      thread end
  | None ->
    (* Go get it yourself *)
    let new_cached = {
      element = None;
      t_expire = (make_expire c key exp);
      waiting = [];
    }
    in
    ignore (Hashtbl.add c ~key ~data:new_cached);
    thunk ()
    >|= fun res ->
      (* There's a response, remove the expiration thread, store the response and wake every thread up *)
      Lwt.cancel new_cached.t_expire;
      let () = match res with
      | Ok v ->
        put c key v exp
      | Error _ ->
        Hashtbl.remove c key
      in
      List.iter ~f:(fun w ->
        try Lwt.wakeup w res with ex ->
          ignore_result (Lwt_io.printlf "Race condition: thread is already awake, this shouldn't happen: %s" (Exn.to_string ex));
      ) new_cached.waiting;
      res

let invalidate c key =
  match Hashtbl.find c key with
  | Some found -> begin
    match found.element with
    | Some el -> Hashtbl.remove c key
    | None -> ()
    end
  | None -> ()