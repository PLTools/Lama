open Benchmark

let () =
  let options = object
    method is_workaround = false
    method get_infile = "stdlib/List.lama"
    method get_include_paths = ["./stdlib"; "runtime"]
  end in
  let ast =
    try match Language.run_parser options with
      | `Ok  r -> r
      | `Fail s ->
          Printf.eprintf "Error: %s\n" s;
          exit 1
    with Language.Semantic_error s ->
      Printf.eprintf "Error: %s\n" s;
      exit 1
  in

  let () =
    let s1 = Format.asprintf "%a" Pprint_gt.pp (snd ast) in
    let s2 = Format.asprintf "%a" Pprint_default.pp (snd ast) in
    if s1<>s2
    then begin
      let wrap name cnt =
        let ch = open_out name in
        output_string ch cnt;
        close_out ch
      in
      wrap "/tmp/gt.ml" s1;
      wrap "/tmp/default.ml" s2;
      failwith "Two printers doesn't behave the same"
    end
  in
  let run_gt () =
    let _:string = Format.asprintf "%a" Pprint_gt.pp (snd ast) in
    ()
  in
  let run_default () =
    let _:string = Format.asprintf "%a" Pprint_default.pp (snd ast) in
    ()
  in

  let res = throughputN ~repeat:1 1
    [ ("GT", run_gt, ())
    ; ("Default", run_default, ())
    ]
  in
  tabulate res
