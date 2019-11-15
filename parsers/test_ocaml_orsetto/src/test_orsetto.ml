let load_octets () =
  match Sys.argv |> Array.to_list with
  | [_; filename] ->
    let ch = open_in filename in
    let s = really_input_string ch (in_channel_length ch) in
    close_in ch;
    s
  | _ ->
    really_input_string stdin (in_channel_length stdin)

let load_text () =
    let s = load_octets () in
    match Ucs_text.of_string s with
    | exception Invalid_argument _ ->
        print_endline "invalid UTF-8";
        exit 1
    | text ->
        text

let parse_text () = ()
  |> load_text
  |> Json_scan.(of_text value)
  |> Json_scan.Annot.dn

let () =
    match parse_text () with
    | exception Json_scan.Bad_syntax xl ->
        Json_scan.Annot.dn xl |> print_endline;
        exit 1
    | exception Not_found ->
        print_endline "Not_found";
        exit 1
    | opaque ->
        opaque
            |> Json_emit.to_text
            |> (fun (Ucs_text.Octets s) -> s)
            |> print_endline
