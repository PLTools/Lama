open Ostap

let parse infile =
  let s   = Util.read infile in
  let kws = [
    "skip";
    "if"; "then"; "else"; "elif"; "fi";
    "while"; "do"; "od";
    "repeat"; "until";
    "for";
    "fun"; "local"; "public"; "external"; "return"; 
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

exception Commandline_error of string
  
class options args =
  let n = Array.length args in
  let rec fix f = f (fix f) in
  object (self)
    val i      = ref 1
    val infile = ref (None : string option)
    val paths  = ref ([] : string list)
    val mode   = ref (`Default : [`Default | `Eval | `SM | `Compile ])
    val help   = ref false
    initializer
      let rec loop () =
        match self#peek with
        | Some opt ->
           (match opt with
            | "-c" -> self#set_mode `Compile
            | "-I" -> (match self#peek with None -> raise (Commandline_error "path expected after '-I' specifier") | Some path -> self#add_include_path path)
            | "-s" -> self#set_mode `SM
            | "-i" -> self#set_mode `Eval
            | "-h" -> self#set_help
            | _ ->
               if opt.[0] = '-'
               then raise (Commandline_error (Printf.sprintf "invalid command line specifier ('%s')" opt))
               else self#set_infile opt
           );
           loop ()
        | None -> ()
      in loop ()
    method private set_infile name =
      match !infile with
      | None       -> infile := Some name
      | Some name' -> raise (Commandline_error (Printf.sprintf "input file ('%s') already specified" name'))
    method private add_include_path path =
      paths := path :: !paths
    method private set_mode s =
      match !mode with
      | `Default -> mode := s
      | _ -> raise (Commandline_error "extra compilation mode specifier")
    method private peek =
      let j = !i in
      if j < n
      then (incr i; Some (args.(j)))
      else None
    method private set_help = help := true
    method get_mode = !mode
    method get_infile =
      match !infile with
      | None      -> raise (Commandline_error "input file not specified")
      | Some name -> name
    method get_help = !help
    method get_include_paths = !paths
  end
  
let main =
  (*  try*)
    let cmd = new options Sys.argv in
  
    (*let interpret  = Sys.argv.(1) = "-i"  in
    let stack      = Sys.argv.(1) = "-s"  in
    let to_compile = not (interpret || stack) in
    let infile     = Sys.argv.(if not to_compile then 2 else 1) in
     *)
    match (try parse cmd#get_infile with Language.Semantic_error msg -> `Fail msg) with
    | `Ok prog ->
       (match cmd#get_mode with
        | `Default | `Compile ->
            ignore @@ X86.build cmd prog 
        | _ ->       
           (* Printf.printf "Program:\n%s\n" (GT.show(Language.Expr.t) prog);*)
           (*Format.printf "Program\n%s\n%!" (HTML.toHTML ((GT.html(Language.Expr.t)) prog));*)
	   let rec read acc =
	     try
	       let r = read_int () in
	       Printf.printf "> ";
	       read (acc @ [r])
             with End_of_file -> acc
	   in
	   let input = read [] in
	   let output =
	     if cmd#get_mode = `Eval
	     then Language.eval prog input
	     else SM.run (SM.compile prog) input
	   in
	   List.iter (fun i -> Printf.printf "%d\n" i) output
       )
    | `Fail er -> Printf.eprintf "Error: %s\n" er
(*  with Invalid_argument _ ->
    Printf.printf "Usage: rc [-i | -s] <input file.expr>\n"
 *)
