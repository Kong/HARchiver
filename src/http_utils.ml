open Core.Std
open Har_j
open Lwt

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
let process_body body replays =
	let clone = body |> Body.to_stream |> Lwt_stream.clone in
	match replays with
	| false ->
		Lwt_stream.fold (fun chunk len ->
			(String.length chunk) + len
		) clone 0
		>>= fun len -> return (len, None)
	| true ->
		(* This base64-encodes the body one chunk at a time and concatenates it efficiently *)
		let buffer = Bigbuffer.create 16 in
		Lwt_stream.fold (fun chunk (len, last4) ->
			let base64 = B64.encode ~pad:true ((B64.decode last4)^chunk) in
			match String.length base64 with
			| 0 -> (len, "")
			| base64_length ->
				let new_last4 = String.slice base64 (base64_length - 4) 0 in
				Bigbuffer.add_substring buffer base64 0 (base64_length - 4);
				(((String.length chunk) + len), new_last4)
		) clone (0, "")
		>>= fun (len, last4) ->
			Bigbuffer.add_string buffer last4;
			let b64 = Bigbuffer.contents buffer in
			return (len, (Some b64))

(* Uri *)
let fix_uri uri =
	let ungarble uri host protocol_len =
		uri
		|> fun uri -> ((Uri.with_host uri (Some (String.slice host 0 (-protocol_len)))), (String.length host - protocol_len))
		|> fun (uri, len) -> Uri.with_path uri (String.slice (Uri.path uri) (len + 2) 0)
	in
	match (uri |> Uri.host |> Option.value ~default:"") with
	| host when String.is_suffix ~suffix:"http" host -> ungarble uri host 4
	| host when String.is_suffix ~suffix:"https" host -> ungarble uri host 5
	| host when (((String.length host) / 2) mod 2 = 0) && ((String.slice host (String.length host / 2) 0) = (String.slice host 0 (String.length host / 2))) ->
			Uri.with_host uri (Some (String.slice host 0 (String.length host / 2)))
	| _ -> uri

