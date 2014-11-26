open Cohttp_async
open Har_j

val get_har : Request.t -> Response.t -> int -> int -> int * int * int -> har
