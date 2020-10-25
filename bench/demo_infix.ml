open Benchmark

let dirname,filename =
  let dirname =
    let path1 = "./stdlib" in
    let path2 = "../stdlib" in
    if Sys.(file_exists path1 && is_directory path1) then path1
    else if Sys.(file_exists path2 && is_directory path2) then path2
    else failwith (Printf.sprintf "Can't find a directory '%s' or '%s'" path1 path2)
  in
  let filename =
    let path1 = "./demo.lama" in
    let path2 = "./bench/demo.lama" in
    if Sys.file_exists path1 then path1
    else if Sys.file_exists path2 then path2
    else failwith (Printf.sprintf "Can't find an input file both in '%s' and '%s'" path1 path2)
  in
  (dirname,filename)

let infix_prefix = "i__Infix_"
let looks_like_infix s =
  Str.first_chars s (String.length infix_prefix) = infix_prefix

let rewrite_infix s =
  if not (looks_like_infix s)
  then s
  else
    let b = Buffer.create 3 in
    let s = String.sub s (String.length infix_prefix) String.(length s - length infix_prefix) in
    let rec loop i =
      if i >= String.length s then ()
      else
        let num c = Char.code c - Char.code '0' in
        let c = Char.chr (num s.[i] * 10 + num s.[i+1]) in
        (* Printf.printf "Got char '%c'\n" c; *)
        Buffer.add_char b c;
        loop (i+2)
    in
    let () = loop 0 in
    Buffer.contents b

class my_pp_e pp_decl fself = object
  inherit Pprint_gt.pp_e pp_decl fself as super
  method! c_Call ppf e f args =
    match f,args with
    | (Var s, [l; r]) when looks_like_infix s ->
        super#c_Call ppf e (Var (rewrite_infix s)) args                (* CHANGE 1 *)
    | _ -> super#c_Call ppf e f args
end

let fix decl0 t0 =
  let open Language in
  let rec decl (name,ppf) subj =
    let inh = (rewrite_infix name, ppf) in                             (* CHANGE 2 *)
    Expr.gcata_decl (decl0 decl expr) inh subj
  and expr inh subj =
    Expr.gcata_t (t0 decl expr) inh subj
  in
  (decl, expr)

let pp fmt s =
  let open Pprint_gt in
  snd (fix (new pp_d) (new my_pp_e)) fmt s

let options = object
  method is_workaround = false
  method get_infile = filename
  method get_include_paths = [dirname; Printf.sprintf "%s/../runtime" dirname]
end

let () =
  let ast =
    Format.printf "Parsing input file `%s'\n%!" options#get_infile;
    try match Language.run_parser options with
      | `Ok  r -> r
      | `Fail s ->
          Printf.eprintf "Error: %s\n" s;
          exit 1
    with Language.Semantic_error s ->
      Printf.eprintf "Error: %s\n" s;
      exit 1
  in

  Format.printf "Default printer:\n%a\n\n%!" Pprint_gt.pp (snd ast);
  Format.printf "Modified printer:\n%a\n\n%!" pp (snd ast);
  ()
