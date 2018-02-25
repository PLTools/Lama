open Ostap

let parse infile =
  let s = Util.read infile in
  Util.parse
    (object
       inherit Matcher.t s
       inherit Util.Lexers.decimal s
       inherit Util.Lexers.ident ["read"; "write"] s
       inherit Util.Lexers.skip [
	 Matcher.Skip.whitespaces " \t\n";
	 Matcher.Skip.lineComment "--";
	 Matcher.Skip.nestedComment "(*" "*)"
       ] s
     end
    )
    (ostap (!(Language.parse) -EOF))

let main =
  try
    let interpret  = Sys.argv.(1) = "-i"  in
    let infile     = Sys.argv.(2) in
    match parse infile with
    | `Ok prog ->
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
    | `Fail er -> Printf.eprintf "Syntax error: %s\n" er
  with Invalid_argument _ ->
    Printf.printf "Usage: rc [-i] <input file.expr>\n"
