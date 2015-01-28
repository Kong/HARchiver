module Body = Cohttp_lwt_body

val name_value_of_query : (string * string list) list -> Har_j.name_value list

val name_value_of_headers : (string * string) list -> Har_j.name_value list

val length_of_headers : Cohttp.Header.t -> int

val set_x_forwarded_for : Cohttp.Header.t -> string -> Cohttp.Header.t

val body_length : Body.t -> int Lwt.t