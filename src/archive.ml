open Core.Std
open Cohttp_lwt
open Cohttp_lwt_unix
open Har_j

type t_input = {
	req: Request.t;
	res: Response.t;
	req_length: int;
	res_length: int;
	client_ip: string;
	server_ip: string;
	timings: int * int * int;
	startedDateTime: string;
}

type t_get_message =  t_input -> message

(* ================================================================================================ *)

let get_timestamp_ms () = Time.now () |> Time.to_float |> ( *. ) 1000. |> Int.of_float
let get_utc_time_string () = Time.now () |> Time.to_string_abs ~zone:Core.Zone.utc

let name_value_of_query tl =
	List.map ~f:(fun (name, values) ->
		let value = String.concat values in
		{name; value}
	) tl

let name_value_of_headers tl =
	List.map ~f:(fun (name, value) -> {name; value}) tl

let length_of_headers raw_headers =
	raw_headers |> Cohttp.Header.to_lines |> List.fold_left ~init:0 ~f:(fun acc x -> acc+(Bytes.length x))

let get_unique_header raw_headers desired =
	List.filter_map raw_headers ~f:(fun (x,y) -> if x = desired then Some y else None) |> List.hd

(* ================================================================================================ *)

let get_har_creator = {
	name = "Mashape HARchiver";
	version = "1.2.0";
}

let get_har_content raw_headers size =
	if size > 0 then
		Some {
			size;
			mimeType = get_unique_header raw_headers "content-type" |> Option.value ~default:"application/octet-stream";
		}
	else
		None

let get_har_request req req_length =
	let raw_headers = req |> Request.headers |> Cohttp.Header.to_list in
	{
		meth = Cohttp.Code.string_of_method (Request.meth req);
		url = Uri.to_string (Request.uri req);
		httpVersion = Cohttp.Code.string_of_version (Request.version req);
		queryString = req |> Request.uri |> Uri.query |> name_value_of_query;
		headers = raw_headers |> name_value_of_headers;
		headersSize = req |> Request.headers |> length_of_headers;
		bodySize = req_length;
		content = get_har_content raw_headers req_length;
	}

let get_har_reponse res res_length =
	let raw_headers = res |> Response.headers |> Cohttp.Header.to_list in
	{
		status = res |> Response.status |> Cohttp.Code.code_of_status;
		statusText = res |> Response.status |> Cohttp.Code.string_of_status;
		httpVersion = res |> Response.version |> Cohttp.Code.string_of_version;
		headers = raw_headers |> name_value_of_headers;
		headersSize = res |> Response.headers |> length_of_headers;
		bodySize = res_length;
		content = get_har_content raw_headers res_length;
	}

let get_har_timings (send, wait, receive) = {
	send;
	wait;
	receive;
}

let get_har_entry {req; res; req_length; res_length; client_ip; server_ip; timings=(t1, t2, t3); startedDateTime;} = {
	serverIPAddress = server_ip;
	clientIPAddress = client_ip;
	startedDateTime;
	time = (t1 + t2 + t3);
	request = get_har_request req req_length;
	response = get_har_reponse res res_length;
	timings = get_har_timings (t1, t2, t3);
}

let get_har input = {
	version = "1.2";
	creator = get_har_creator;
	entries = [get_har_entry input];
}

(* ================================================================================================ *)

module type Sig_make = sig val get_message : t_get_message end
module type Sig_arg = sig val key : bytes end

module Make (X : Sig_arg) : Sig_make = struct
	let get_message input = {
		serviceToken = X.key;
		har = get_har input;
	}
end
