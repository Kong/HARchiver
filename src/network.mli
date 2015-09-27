open Core.Std

module CLU = Conduit_lwt_unix

val get_addr_from_ch : CLU.flow -> string

val dns_lookup : string -> (string, string) Result.t Lwt.t