open Core.Std
open Cohttp_lwt_unix
open Lwt
open Har_j

module Body = Cohttp_lwt_body

(* Headers *)
let name_value_of_query tl =
	List.map ~f:(fun (name, values) ->
		let value = String.concat values in
		{name; value}
	) tl

let name_value_of_headers tl =
	List.map ~f:(fun (name, value) -> {name; value}) tl

let length_of_headers raw_headers =
	raw_headers |> Cohttp.Header.to_lines |> List.fold_left ~init:0 ~f:(fun acc x -> acc+(Bytes.length x))

let maybe_add_header headers k v =
	match Cohttp.Header.get headers k with
	| Some _ -> headers
	| None -> Cohttp.Header.add headers k v

(* Body *)
let body_length body =
	let clone = body |> Body.to_stream |> Lwt_stream.clone in
	Lwt_stream.fold (fun a b -> (String.length a)+b) clone 0
