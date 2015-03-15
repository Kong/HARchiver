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
let send_msg = foreign "send_msg" (zmq_sock @-> str_ptr @-> int @-> returning void)

module CLU = Conduit_lwt_unix

let get_zmq_sock zmq_host zmq_port =
	let remote = "tcp://"^zmq_host^":"^zmq_port in
	let ctx = get_context () in
	print_endline ("Connecting to "^remote^" ...");
	let sock = get_sock ctx remote in
	print_endline "Connected.";
	sock

let send_zmq sock thunk =
	let p_str = allocate string (thunk ()) in
	(p_str, (return (send_msg sock p_str (String.length !@p_str))))

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
				| None -> return (Error "No answer")
				| Some answer ->
					match answer.rdata with
					| A ipv4 -> return (Ok (Ipaddr.V4.to_string ipv4))
					| _ -> return (Error "Not ipv4")
		)
	)
