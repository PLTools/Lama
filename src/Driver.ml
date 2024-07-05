open Options

let[@ocaml.warning "-32"] main =
  try
    let cmd = new options Sys.argv in
    cmd#greet;
    match
      try Language.run_parser cmd
      with Language.Semantic_error msg -> `Fail msg
    with
    | `Ok prog -> (
        cmd#dump_AST (snd prog);
        cmd#dump_source (snd prog);
        match cmd#get_mode with
        | `Default | `Compile -> ignore @@ X86_64.build cmd prog
        | `BC -> SM.ByteCode.compile cmd (SM.compile cmd prog)
        | _ ->
            let rec read acc =
              try
                let r = read_int () in
                Printf.printf "> ";
                read (acc @ [ r ])
              with End_of_file -> acc
            in
            let input = read [] in
            let output =
              if cmd#get_mode = `Eval then Language.eval prog input
              else SM.run (SM.compile cmd prog) input
            in
            List.iter (fun i -> Printf.printf "%d\n" i) output)
    | `Fail er ->
        Printf.eprintf "Error: %s\n" er;
        exit 255
  with
  | Language.Semantic_error msg ->
      Printf.printf "Error: %s\n" msg;
      exit 255
  | Commandline_error msg ->
      Printf.printf "%s\n" msg;
      exit 255
