open Core.Std
open Re_pcre

let create str = regexp str

let matches rex str =
  let thunk = fun () -> exec ~rex ~pos:0 str |> fun x -> get_substring x 0 in
  Result.try_with thunk |> Result.is_ok
