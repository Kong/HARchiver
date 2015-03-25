open Core.Std
open Lwt
open Ctypes
open PosixTypes
open Foreign

type zmq_ctx = unit ptr
let zmq_ctx : zmq_ctx typ = ptr void

type zmq_sock = unit ptr
let zmq_sock : zmq_sock typ = ptr void

type str_ptr = string ptr
let str_ptr : str_ptr typ = ptr string

let get_context = foreign "get_context" (void @-> returning zmq_ctx)
let get_sock = foreign "get_sock" (zmq_ctx @-> string @-> returning zmq_sock)
let send_msg = foreign "send_msg" (zmq_sock @-> ptr void @-> int @-> ptr void @-> returning int)
let say_hi = foreign "say_hi" (void @-> returning string)

module CLU = Conduit_lwt_unix

let ctx = get_context ()
(* TODO: Change to a functor *)
let sock = ref None
let msg_queue = ref []
let len_queue = ref []
let p_queue = ref []

let rec check_length () =
	Lwt_unix.sleep 2.
	>>= fun () ->
		match !msg_queue with
		| [] -> check_length ()
		| messages ->
			let msg_arr = CArray.of_list str_ptr messages in
			let len_arr = CArray.of_list int !len_queue in
				msg_queue := [];
				len_queue := [];
				let save_p_queue = !p_queue in
				p_queue := [];

			Lwt_preemptive.detach (fun () ->
				send_msg (Option.value_exn !sock) (to_voidp (CArray.start msg_arr)) (List.length messages) (to_voidp (CArray.start len_arr)) |> Int.to_string |> print_endline
			) () >>= fun () ->
				check_length ()

let () = Lwt.async check_length

let get_zmq_sock zmq_host zmq_port =
	let remote = "tcp://"^zmq_host^":"^zmq_port in
	print_endline ("Connecting to "^remote^" ...");
	let sock = get_sock ctx remote in
	print_endline "Connected.";
	sock

let send_zmq p_str p =
	msg_queue := p_str :: !msg_queue;
	len_queue := String.length !@p_str :: !len_queue;
	p_queue := p :: !p_queue;
	return_unit

let get_addr_from_ch = function
| CLU.TCP {CLU.fd; ip; port} -> begin
	match Lwt_unix.getpeername fd with
	| Lwt_unix.ADDR_INET (ia,port) -> Ipaddr.to_string (Ipaddr_unix.of_inet_addr ia)
	| Lwt_unix.ADDR_UNIX path -> sprintf "sock:%s" path end
| _ -> "<error>"

let resolvers = Lwt_pool.create Settings.resolver_pool ~check:(fun _ f -> f false) Dns_resolver_unix.create
let dns_cache = Cache.create ()

let dns_lookup host =
	Cache.get dns_cache ~key:host ~exp:Settings.resolver_expire ~thunk:(fun () ->
		Lwt_pool.use resolvers (fun resolver ->
			let open Dns.Packet in
			Dns_resolver_unix.resolve resolver Q_IN Q_A (Dns.Name.string_to_domain_name host)
			>>= fun response ->
				match List.hd response.answers with
				| None -> return (Ok host) (* If the system resolver doesn't respond, we assume it's a valid IP *)
				| Some answer ->
					match answer.rdata with
					| A ipv4 -> return (Ok (Ipaddr.V4.to_string ipv4))
					| _ -> return (Error "Not ipv4")
		)
	)
