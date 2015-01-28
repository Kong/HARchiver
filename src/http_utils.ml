open Core.Std
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

let set_x_forwarded_for h client_ip =
	match Cohttp.Header.get h "X-Forwarded-For" with
	| None -> Cohttp.Header.add h "X-Forwarded-For" client_ip
	| Some x -> Cohttp.Header.replace h "X-Forwarded-For" (x^", "^client_ip)

(* Body *)
let body_length body =
	let clone = body |> Body.to_stream |> Lwt_stream.clone in
	Lwt_stream.fold (fun a b -> (String.length a)+b) clone 0
