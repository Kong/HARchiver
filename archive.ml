open Core.Std
open Cohttp_lwt
open Cohttp_lwt_unix
open Har_j

let get_timestamp () = Time.now () |> Time.to_float |> Int.of_float
let get_timestamp_ms () = Time.now () |> Time.to_float |> ( *. ) 1000. |> Int.of_float

let name_value_of_query tl =
	List.map ~f:(fun (name, values) ->
		let value = String.concat values in
		{name; value}) tl

let name_value_of_headers tl =
	List.map ~f:(fun (name, value) -> {name; value}) tl

let length_of_headers raw_headers =
	raw_headers |> Cohttp.Header.to_lines |> List.fold_left ~init:0 ~f:(fun acc x -> acc+(Bytes.length x))

let get_unique_header raw_headers desired =
	List.filter_map raw_headers ~f:(fun (x,y) -> if x = desired then Some y else None) |> List.hd

(* ================================================================================================ *)

let get_har_creator = {
	name = "Mashape HARchiver";
	version = "1.0.1";
}

let get_har_request req req_length = {
	meth = Cohttp.Code.string_of_method (Request.meth req);
	url = Uri.to_string (Request.uri req);
	httpVersion = Cohttp.Code.string_of_version (Request.version req);
	queryString = req |> Request.uri |> Uri.query |> name_value_of_query;
	headers = req |> Request.headers |> Cohttp.Header.to_list |> name_value_of_headers;
	headersSize = req |> Request.headers |> length_of_headers;
	bodySize = req_length;
}

let get_har_response_content raw_headers res_length = {
	size = res_length; (* What's this? *)
	mimeType = get_unique_header raw_headers "content-type" |> Option.value ~default:"";
}

let get_har_reponse res res_length =
	let raw_headers = res |> Response.headers |> Cohttp.Header.to_list in
	{
		status = res |> Response.status |> Cohttp.Code.code_of_status;
		statusText = res |> Response.status |> Cohttp.Code.string_of_status;
		httpVersion = res |> Response.version |> Cohttp.Code.string_of_version;
		headers = raw_headers |> name_value_of_headers;
		content = get_har_response_content raw_headers res_length;
		redirectUrl = get_unique_header raw_headers "location" |> Option.value ~default:"";
		headersSize = res |> Response.headers |> length_of_headers;
		bodySize = res_length;
	}

let get_har_cache = {
	x = None;
}

let get_har_timings (send, wait, receive) = {
	send;
	wait;
	receive;
}

let get_entry req res req_length res_length timings = {
	startedDateTime = get_timestamp ();
	request = get_har_request req req_length;
	response = get_har_reponse res res_length;
	cache = get_har_cache;
	timings = get_har_timings timings;
}

(* ================================================================================================ *)

type t_get_har =  Request.t -> Response.t -> int -> int -> int * int * int -> har

module type Sig_make = sig val get_har : t_get_har end
module type Sig_arg = sig val key : bytes end

module Make (X : Sig_arg) : Sig_make = struct
	let get_har req res req_length res_length timings = {
		version = "1.2";
		serviceToken = X.key;
		creator = get_har_creator;
		entries = [get_entry req res req_length res_length timings];
	}
end
