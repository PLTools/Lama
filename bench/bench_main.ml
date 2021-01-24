open Benchmark

(* How many repetitions should be performed *)
let repeat = 2
(* How nuch time we should spent on benchmark *)
let timeout = 2

let dirname,filenames =
  let dirname =
    let path1 = "./stdlib" in
    let path2 = "../stdlib" in
    if Sys.(file_exists path1 && is_directory path1) then path1
    else if Sys.(file_exists path2 && is_directory path2) then path2
    else failwith (Printf.sprintf "Can't find a directory '%s' or '%s'" path1 path2)
  in
  Format.printf "Looking for samples from: '%s'\n%!" dirname;
  let files =
    let fs = Sys.readdir dirname in
    let r = Str.regexp ".*\\.lama$" in
    List.filter (fun s -> (Str.string_match r s 0) && s <> "Ostap.lama") (Array.to_list fs)
  in
  Format.printf "Tests found: %s\n%!" (GT.show GT.list (GT.show GT.string) files);
  (dirname,files)


let bench_file file =
  Format.printf "Benchmarking file `%s`\n%!" file;
  let options = object
    method is_workaround = false
    method get_infile = Printf.sprintf "%s/%s" dirname file
    method get_include_paths = [dirname; Printf.sprintf "%s/../runtime" dirname]
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
  Gc.full_major ();
  let run_gt () =
    let _:string = Format.asprintf "%a" Pprint_gt.pp (snd ast) in
    ()
  in
  let run_default () =
    let _:string = Format.asprintf "%a" Pprint_default.pp (snd ast) in
    ()
  in

  let res = throughputN ~style:Nil ~repeat timeout
    [ ("GT", run_gt, ())
    ; ("Default", run_default, ())
    ]
  in
  tabulate res

let () = List.iter bench_file filenames
