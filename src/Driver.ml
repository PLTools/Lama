open Ostap

let parse cmd =
  let s   = Util.read cmd#get_infile in
  let kws = [
    "skip";
    "if"; "then"; "else"; "elif"; "fi";
    "while"; "do"; "od";
    "repeat"; "until";
    "for";
    "fun"; "local"; "public"; "external"; "return"; "import"; 
    "length";
    "string";
    "case"; "of"; "esac"; "when";
    "boxed"; "unboxed"; "string"; "sexp"; "array";
    "infix"; "infixl"; "infixr"; "at"; "before"; "after";
    "true"; "false"; "lazy"]
  in
  Util.parse
    (object
       inherit Matcher.t s
       inherit Util.Lexers.decimal s
       inherit Util.Lexers.string s
       inherit Util.Lexers.char   s
       inherit Util.Lexers.infix  s
       inherit Util.Lexers.lident kws s
       inherit Util.Lexers.uident kws s
       inherit Util.Lexers.skip [
	 Matcher.Skip.whitespaces " \t\n";
	 Matcher.Skip.lineComment "--";
	 Matcher.Skip.nestedComment "(*" "*)"
       ] s
     end
    )
    (if cmd#is_workaround then ostap (p:!(Language.constparse cmd) -EOF) else ostap (p:!(Language.parse cmd) -EOF))

exception Commandline_error of string
  
class options args =
  let n = Array.length args in
  let rec fix f = f (fix f) in
  let dump_ast  = 1 in
  let dump_sm   = 2 in
  object (self)
    val i      = ref 1
    val infile = ref (None : string option)
    val paths  = ref [X86.get_std_path ()]
    val mode   = ref (`Default : [`Default | `Eval | `SM | `Compile ])
    (* Workaround until Ostap starts to memoize properly *)
    val const  = ref false
    (* end of the workaround *)
    val dump   = ref 0
    val help   = ref false
    initializer
      let rec loop () =
        match self#peek with
        | Some opt ->
           (match opt with
            (* Workaround until Ostap starts to memoize properly *)
            | "-w"  -> self#set_workaround
            (* end of the workaround *)
            | "-c"  -> self#set_mode `Compile
            | "-I"  -> (match self#peek with None -> raise (Commandline_error "path expected after '-I' specifier") | Some path -> self#add_include_path path)
            | "-s"  -> self#set_mode `SM
            | "-i"  -> self#set_mode `Eval
            | "-ds" -> self#set_dump dump_sm
            | "-dp" -> self#set_dump dump_ast
            | "-h"  -> self#set_help
            | _ ->
               if opt.[0] = '-'
               then raise (Commandline_error (Printf.sprintf "invalid command line specifier ('%s')" opt))
               else self#set_infile opt
           );
           loop ()
        | None -> ()
      in loop ()
    (* Workaround until Ostap starts to memoize properly *)
    method is_workaround = !const   
    method private set_workaround =
      const := true
    (* end of the workaround *)
    method private set_dump mask =
      dump := !dump lor mask
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
    method basename = Filename.chop_suffix (Filename.basename self#get_infile) ".expr"
    method topname =
      match !mode with
      | `Compile -> "init" ^ self#basename
      | _ -> "main"
    method dump_file ext contents =
      let name = self#basename in
      let outf = open_out (Printf.sprintf "%s.%s" name ext) in
      Printf.fprintf outf "%s" contents;
      close_out outf
    method dump_AST ast =
      if (!dump land dump_ast) > 0
      then self#dump_file "ast" (GT.show(Language.Expr.t) ast)
      else ()
    method dump_SM sm  =
      if (!dump land dump_sm) > 0
      then self#dump_file "sm" (SM.show_prg sm)
      else ()
  end
  
let main =
  try 
    let cmd = new options Sys.argv in
    match (try parse cmd with Language.Semantic_error msg -> `Fail msg) with
    | `Ok prog ->
       cmd#dump_AST (snd prog);
       (match cmd#get_mode with
        | `Default | `Compile ->
            ignore @@ X86.build cmd prog
        | _ -> 
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
	     else SM.run (SM.compile cmd prog) input
	   in
	   List.iter (fun i -> Printf.printf "%d\n" i) output 
       )
    | `Fail er -> Printf.eprintf "Error: %s\n" er
  with Language.Semantic_error msg -> Printf.printf "Error: %s\n" msg 

