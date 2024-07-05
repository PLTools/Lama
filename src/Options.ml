exception Commandline_error of string

type arch_t = X86_64 | X86
type os_t = Linux | Darwin

class options args =
  let n = Array.length args in
  let dump_ast = 0b1 in
  let dump_sm = 0b010 in
  let dump_source = 0b100 in
  (* Kakadu: binary masks are cool for C code, but for OCaml I don't see any reason to save memory like this *)
  let runtime_path_ =
    match Sys.getenv_opt "LAMA" with Some s -> s | None -> Stdpath.path
  in
  let host_os =
    let uname = Posix_uname.uname () in
    match uname.sysname with
    | "Darwin" -> Darwin
    | "Linux" -> Linux
    | _ -> failwith "Unsupported OS"
  in
  let help_string =
    "Lama compiler. (C) JetBrains Reserach, 2017-2020.\n"
    ^ "Usage: lamac <options> <input file>\n\n"
    ^ "When no options specified, builds the source file into executable.\n"
    ^ "Options:\n" ^ "  -c        --- compile into object file\n"
    ^ "  -o <file> --- write executable into file <file>\n"
    ^ "  -I <path> --- add <path> into unit search path list\n"
    ^ "  -i        --- interpret on a source-level interpreter\n"
    ^ "  -s        --- compile into stack machine code and interpret on the \
       stack machine initerpreter\n"
    ^ "  -m32      --- compile into x86 architecture\n"
    ^ "  -g        --- add more debug info and runtime checks\n"
    ^ "  -dp       --- dump AST (the output will be written into .ast file)\n"
    ^ "  -dsrc     --- dump pretty-printed source code\n"
    ^ "  -ds       --- dump stack machine code (the output will be written \
       into .sm file; has no\n"
    ^ "                effect if -i option is specfied)\n"
    ^ "  -b        --- compile to a stack machine bytecode\n"
    ^ "  -v        --- show version\n" ^ "  -h        --- show this help\n"
  in
  object (self)
    val version = ref false
    val help = ref false
    val i = ref 1
    val infile = ref (None : string option)
    val outfile = ref (None : string option)
    val runtime_path = runtime_path_
    val paths = ref [ runtime_path_ ]
    val mode = ref (`Default : [ `Default | `Eval | `SM | `Compile | `BC ])
    val curdir = Unix.getcwd ()
    val debug = ref false
    val arch = ref X86_64
    val target_os = host_os

    (* Workaround until Ostap starts to memoize properly *)
    val const = ref false

    (* end of the workaround *)
    val dump = ref 0

    initializer
      let set_debug () = debug := true in
      let set_x86 () = arch := X86 in
      let rec loop () =
        match self#peek with
        | Some opt ->
            (match opt with
            (* Workaround until Ostap starts to memoize properly *)
            | "-w" -> self#set_workaround
            (* end of the workaround *)
            | "-c" -> self#set_mode `Compile
            | "-o" -> (
                match self#peek with
                | None ->
                    raise
                      (Commandline_error
                         "File name expected after '-o' specifier")
                | Some fname -> self#set_outfile fname)
            | "-I" -> (
                match self#peek with
                | None ->
                    raise
                      (Commandline_error "Path expected after '-I' specifier")
                | Some path -> self#add_include_path path)
            | "-s" -> self#set_mode `SM
            | "-b" -> self#set_mode `BC
            | "-i" -> self#set_mode `Eval
            | "-ds" -> self#set_dump dump_sm
            | "-dsrc" -> self#set_dump dump_source
            | "-dp" -> self#set_dump dump_ast
            | "-h" -> self#set_help
            | "-v" -> self#set_version
            | "-g" -> set_debug ()
            | "-m32" -> set_x86 ()
            | _ ->
                if opt.[0] = '-' then
                  raise
                    (Commandline_error
                       (Printf.sprintf "Invalid command line specifier ('%s')"
                          opt))
                else self#set_infile opt);
            loop ()
        | None -> ()
      in
      loop ()

    (* Workaround until Ostap starts to memoize properly *)
    method is_workaround = !const
    method private set_workaround = const := true

    (* end of the workaround *)
    method private set_help = help := true
    method private set_version = version := true
    method private set_dump mask = dump := !dump lor mask

    method private set_infile name =
      match !infile with
      | None -> infile := Some name
      | Some name' ->
          raise
            (Commandline_error
               (Printf.sprintf "Input file ('%s') already specified" name'))

    method private set_outfile name =
      match !outfile with
      | None -> outfile := Some name
      | Some name' ->
          raise
            (Commandline_error
               (Printf.sprintf "Output file ('%s') already specified" name'))

    method private add_include_path path = paths := path :: !paths

    method private set_mode s =
      match !mode with
      | `Default -> mode := s
      | _ -> raise (Commandline_error "Extra compilation mode specifier")

    method private peek =
      let j = !i in
      if j < n then (
        incr i;
        Some args.(j))
      else None

    method get_mode = !mode

    method get_output_option =
      match !outfile with
      | None -> Printf.sprintf "-o %s" self#basename
      | Some name -> Printf.sprintf "-o %s" name

    method get_absolute_infile =
      let f = self#get_infile in
      if Filename.is_relative f then Filename.concat curdir f else f

    method get_infile =
      match !infile with
      | None -> raise (Commandline_error "Input file not specified")
      | Some name -> name

    method get_help = !help
    method get_include_paths = !paths
    method get_runtime_path = runtime_path

    method basename =
      Filename.chop_suffix (Filename.basename self#get_infile) ".lama"

    method topname =
      match !mode with `Compile -> "init" ^ self#basename | _ -> "main"

    method dump_file ext contents =
      let name = self#basename in
      let outf = open_out (Printf.sprintf "%s.%s" name ext) in
      Printf.fprintf outf "%s" contents;
      close_out outf

    method dump_AST ast =
      if !dump land dump_ast > 0 then (
        let buf = Buffer.create 1024 in
        Buffer.add_string buf "<html>";
        Buffer.add_string buf
          (Printf.sprintf "<title> %s </title>" self#get_infile);
        Buffer.add_string buf "<body><li>";
        GT.html Language.Expr.t ast buf;
        Buffer.add_string buf "</li></body>";
        Buffer.add_string buf "</html>";
        self#dump_file "html" (Buffer.contents buf))

    method dump_source (ast : Language.Expr.t) =
      if !dump land dump_source > 0 then Pprinter.pp Format.std_formatter ast

    method dump_SM sm =
      if !dump land dump_sm > 0 then self#dump_file "sm" (SM.show_prg sm)
      else ()

    method greet =
      (match !outfile with
      | None -> ()
      | Some _ -> (
          match !mode with
          | `Default -> ()
          | _ -> Printf.printf "Output file option ignored in this mode.\n"));
      if !version then Printf.printf "%s\n" Version.version;
      if !help then Printf.printf "%s" help_string

    method is_debug = !debug
    method arch = !arch
    method target_os = target_os
  end
