open Ostap

let parse infile =
  let s   = Util.read infile in
  let kws = [
    "skip";
    "if"; "then"; "else"; "elif"; "fi";
    "while"; "do"; "od";
    "repeat"; "until";
    "for";
    "fun"; "local"; "return";
    "length";
    "string";
    "case"; "of"; "esac"; "when";
    "boxed"; "unboxed"; "string"; "sexp"; "array";
    "infix"; "infixl"; "infixr"; "at"; "before"; "after"]
  in
  Util.parse
    (object
       inherit Matcher.t s
       inherit Util.Lexers.decimal s
       inherit Util.Lexers.string s
       inherit Util.Lexers.char   s
       inherit Util.Lexers.lident kws s
       inherit Util.Lexers.uident kws s
       inherit Util.Lexers.skip [
	 Matcher.Skip.whitespaces " \t\n";
	 Matcher.Skip.lineComment "--";
	 Matcher.Skip.nestedComment "(*" "*)"
       ] s
     end
    )
    (ostap (!(Language.parse Language.Infix.default)  -EOF))

let main =
  try
    let interpret  = Sys.argv.(1) = "-i"  in
    let stack      = Sys.argv.(1) = "-s"  in
    let to_compile = not (interpret || stack) in
    let infile     = Sys.argv.(if not to_compile then 2 else 1) in
    match (try parse infile with Language.Semantic_error msg -> `Fail msg) with
    | `Ok prog ->
       if to_compile
       then
         let basename = Filename.chop_suffix infile ".expr" in
         ignore @@ X86.build prog basename
       else
	 let rec read acc =
	   try
	     let r = read_int () in
	     Printf.printf "> ";
	     read (acc @ [r])
           with End_of_file -> acc
	 in
	 let input = read [] in
	 let output =
	   if interpret
	   then Language.eval prog input
	   else SM.run (SM.compile prog) input
	 in
	 List.iter (fun i -> Printf.printf "%d\n" i) output
    | `Fail er -> Printf.eprintf "Error: %s\n" er
  with Invalid_argument _ ->
    Printf.printf "Usage: rc [-i | -s] <input file.expr>\n"
