open Core.Std
open Cohttp_lwt_unix
open Har_j

type t_input = {
  environment: string option;
  req: Request.t;
  req_uri: Uri.t;
  req_headers: Cohttp.Header.t;
  res: Response.t;
  req_length: int;
  res_length: int;
  req_b64: string option;
  res_b64: string option;
  client_ip: string;
  server_ip: string;
  timings: int * int * int;
}

type t_get_alf =  t_input -> alf

let get_timestamp_ms () = Time.now () |> Time.to_float |> ( *. ) 1000. |> Int.of_float
let get_timestamp () = Time.now () |> Time.to_float |> Int.of_float
let get_utc_time_string () =
  Time.now ()
  |> Time.to_string_abs ~zone:Core.Zone.utc
  |> Str.global_replace (Str.regexp_string " ") "T"

(* ================================================================================================ *)

let get_har_creator = {
  name = Settings.name;
  version = Settings.version;
}

let get_har_content headers size b64 =
  if (size > 0) || (Option.is_some b64)  then
    Some {
      size;
      mimeType = Cohttp.Header.get headers "content-type" |> Option.value ~default:"application/octet-stream";
      encoding = Option.map ~f:(fun _ -> "base64") b64;
      text = b64;
    }
  else
    None

let get_har_postData headers size b64 =
  if (size > 0) || (Option.is_some b64)  then
    Some {
      mimeType = Cohttp.Header.get headers "content-type" |> Option.value ~default:"application/octet-stream";
      text = b64;
    }
  else
    None

let get_har_request req req_uri req_headers req_length req_b64 =
  let raw_headers = req_headers |> Cohttp.Header.to_list in
  {
    meth = Cohttp.Code.string_of_method (Request.meth req);
    url = Uri.to_string req_uri;
    httpVersion = Cohttp.Code.string_of_version (Request.version req);
    queryString = req |> Request.uri |> Uri.query |> Http_utils.name_value_of_query;
    headers = raw_headers |> Http_utils.name_value_of_headers;
    headersSize = req_headers |> Http_utils.length_of_headers;
    cookies = [];
    bodySize = req_length;
    postData = get_har_postData req_headers req_length req_b64;
  }

let get_har_reponse res res_length res_b64 =
  let headers = res |> Response.headers in
  let raw_headers = headers |> Cohttp.Header.to_list in
  {
    status = res |> Response.status |> Cohttp.Code.code_of_status;
    statusText = res |> Response.status |> Cohttp.Code.string_of_status;
    httpVersion = res |> Response.version |> Cohttp.Code.string_of_version;
    headers = raw_headers |> Http_utils.name_value_of_headers;
    headersSize = res |> Response.headers |> Http_utils.length_of_headers;
    redirectURL = res |> Response.headers |> (fun h -> Cohttp.Header.get h "Location") |> Option.value ~default:"";
    cookies = [];
    bodySize = res_length;
    content = get_har_content headers res_length res_b64;
  }

let get_har_timings (send, wait, receive) = {
  send;
  wait;
  receive;
}

let get_cache = {
  x = None;
}

let get_har_entry {req; req_uri; req_headers; res; req_length; res_length; req_b64; res_b64; server_ip; timings=(t1, t2, t3); _} = {
  serverIPAddress = server_ip;
  startedDateTime = get_utc_time_string ();
  time = (t1 + t2 + t3);
  request = get_har_request req req_uri req_headers req_length req_b64;
  response = get_har_reponse res res_length res_b64;
  timings = get_har_timings (t1, t2, t3);
  cache = get_cache;
}

let get_log input = {
  version = "1.2";
  creator = get_har_creator;
  entries = [get_har_entry input];
}

let get_har input = {
  log = get_log input;
}

(* ================================================================================================ *)

module type Sig_make = sig
  val get_alf : t_get_alf
  val key : string
end
module type Sig_arg = sig val key : string end

module Make (X : Sig_arg) : Sig_make = struct
  let get_alf input = {
    version = "1.0.0";
    serviceToken = X.key;
    environment = input.environment;
    clientIPAddress = input.client_ip;
    har = get_har input;
  }
  let key = X.key
end
