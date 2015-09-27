open Core.Std
open Lwt

let version = "2.2.0"
let name = "mashape-analytics-proxy"
let alf_version = "alf_1.0.0"

let zmq_flush_timeout = 5.
let zmq_socket_ttl = 5. *. 60.

let http_error_wait = 0.5

let resolver_pool = 10
let resolver_expire = 30.

let default_concurrent = 500
let default_timeout = 6.

let default_zmq_host = "socket.analytics.mashape.com"
let default_zmq_port = 5500


type config = {
  port: int;
  https: int option;
  reverse: (string option * int option option) option;
  environment: string option;
  debug: bool;
  concurrent: int;
  timeout: float;
  replays: bool;
  filter_ua: Re.re option;
  zmq_host: string;
  zmq_port: string;
  key: string option
}

let print_config config =
  let opt_string = Option.map ~f:Int.to_string in
  let opt_prepend x = Option.map ~f:((^) x) in
  let on_off x = if x then "On" else "Off" in
  ignore (Lwt_io.printlf
    "\nVersion %s\n\nConfiguration:\nHTTP port: %n\nHTTPS port: %s\nProxy mode: %s\nEnvironment: %s\nDebug: %s\nMax concurrency: %n\nTimeout: %fs\nReplays: %s\nService-Token: %s\n"
    version
    config.port
    (config.https |> opt_string |> Option.value ~default:"Off")
    (config.reverse
      |> Option.map ~f:(fun (h, p) ->
        (Option.value_exn h) ^ (Option.map ~f:(fun x -> x |> opt_string |> opt_prepend ":" |> Option.value ~default:"") p |> Option.value ~default:"")
      )
      |> opt_prepend "Reverse "
      |> Option.value ~default:"Forward")
    (config.environment |> Option.value ~default:"Default")
    (config.debug |> on_off)
    config.concurrent
    config.timeout
    (config.replays |> on_off)
    (config.key |> Option.value ~default:"None"))


let make_config port https reverse environment debug concurrent timeout replays filter_ua zmq_host zmq_port key =
  let config = {
    port;
    https;
    reverse = reverse
    |> Option.map ~f:(fun str ->
      Uri.of_string ("http://"^str)
      |> fun uri ->
        let host = Option.value_exn ~message:"Invalid host name or IP for reverse mode" (Uri.host uri) in
        let port = Uri.port uri in
        ((Some host), (Some port))
    );
    environment;
    debug;
    concurrent = concurrent |> Option.value ~default:default_concurrent;
    timeout = timeout |> Option.value ~default:default_timeout;
    replays;
    filter_ua = Option.map ~f:Regex.create filter_ua;
    zmq_host = zmq_host |> Option.value ~default:default_zmq_host;
    zmq_port = zmq_port |> Option.value ~default:default_zmq_port |> Int.to_string;
    key;
  } in
  print_config config;
  config
