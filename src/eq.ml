let rec read_all_from_stdin () =
  try
    let line = input_line stdin in
    line ^ read_all_from_stdin ()
  with
    End_of_file -> ""

let read_edn_from_stdin () =
  Edn.from_string (read_all_from_stdin ())

let _ =
  let use_colors = ref true in
  let filter = ref Filter.Id in

  let set_filter s =
    filter := Filter.make_filter (Edn.from_string s) in

  let cmd_args_spec =
    [("--no-colors", Arg.Clear use_colors, "Disable syntax highlighting")] in

  let usage_msg =
    "EQ (edn-query) is an edn processor & pretty printer. Inspired by jq (https://stedolan.github.io/jq/)" in

  Arg.parse cmd_args_spec set_filter usage_msg;

  let color_scheme = if !use_colors
                     then Pp.edn_color_scheme
                     else Pp.edn_no_color_scheme in

  let edns = Filter.apply_filter !filter (read_edn_from_stdin ()) in

  List.iter (fun edn -> Easy_format.Pretty.to_stdout (Pp.format color_scheme edn);
                        print_newline ())
            edns
