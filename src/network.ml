open Core.Std
open Lwt

module CLU = Conduit_lwt_unix

let get_ZMQ_sock zmq_host zmq_port =
	let remote = "tcp://"^zmq_host^":"^zmq_port in
	let ctx = ZMQ.Context.create () in
	let raw_sock = ZMQ.Socket.create ctx ZMQ.Socket.push in
	print_endline ("Connecting to "^remote^" ...");
	ZMQ.Socket.connect raw_sock remote;
	let sock = Lwt_zmq.Socket.of_socket raw_sock in
	print_endline "Connected.";
	sock

let get_addr_from_ch = function
| CLU.TCP {CLU.fd; _} -> begin (* Also contains ip and port *)
	match Lwt_unix.getpeername fd with
	| Lwt_unix.ADDR_INET (ia, _port) -> Ipaddr.to_string (Ipaddr_unix.of_inet_addr ia)
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
				| None -> return (Ok host) (* If the system resolver has no response we assume it was a valid IP and just try it *)
				| Some answer ->
					match answer.rdata with
					| A ipv4 -> return (Ok (Ipaddr.V4.to_string ipv4))
					| _ -> return (Error "Not ipv4")
		)
	)
