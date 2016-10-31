let load_json () =
  match Sys.argv |> Array.to_list with
  | [_; filename] -> Yojson.Basic.from_file filename
  | _ -> Yojson.Basic.from_channel stdin

let print_json json =
  json
  |> Yojson.Basic.to_string
  |> print_endline

let () =
  () |> load_json |> print_json
