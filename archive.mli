open Cohttp
open Har_j

type t_get_har = Request.t -> Response.t -> int -> int -> int * int * int -> har

module type Sig_make = sig val get_har : t_get_har end
module type Sig_arg = sig val key : bytes end

module Make : functor (X : Sig_arg) -> Sig_make
