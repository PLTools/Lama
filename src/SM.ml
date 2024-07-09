open GT
open Language

(* The type for patters *)
type patt = StrCmp | String | Array | Sexp | Boxed | UnBoxed | Closure
[@@deriving gt ~options:{ show; enum }]

(* The type for local scopes tree *)
type scope = {
  blab : string;
  elab : string;
  names : (string * int) list;
  subs : scope list;
}
[@@deriving gt ~options:{ show }]

let normal_label = "L"
let builtin_label = "B"
let global_label = "global_"
let labeled s = normal_label ^ s
let labeled_builtin s = builtin_label ^ s
let labeled_global s = global_label ^ s
let labeled_scoped i s = labeled s ^ "_" ^ string_of_int i
let show_scope = show scope

(* The type for the stack machine instructions *)
type insn =
  (* binary operator                           *)
  | BINOP of string
  (* put a constant on the stack               *)
  | CONST of int
  (* put a string on the stack                 *)
  | STRING of string
  (* create an S-expression                    *)
  | SEXP of string * int
  (* load a variable to the stack              *)
  | LD of Value.designation
  (* load a variable address to the stack      *)
  | LDA of Value.designation
  (* store a value into a variable             *)
  | ST of Value.designation
  (* store a value into a reference            *)
  | STI
  (* store a value into array/sexp/string      *)
  | STA
  (* takes an element of array/string/sexp     *)
  | ELEM
  (* a label                                   *)
  | LABEL of string
  (* a forwarded label                         *)
  | FLABEL of string
  (* a scope label                             *)
  | SLABEL of string
  (* unconditional jump                        *)
  | JMP of string
  (* conditional jump                          *)
  | CJMP of string * string
  (* begins procedure definition               *)
  | BEGIN of
      string * int * int * Value.designation list * string list * scope list
  (* end procedure definition                  *)
  | END
  (* create a closure                          *)
  | CLOSURE of string * Value.designation list
  (* proto closure                             *)
  | PROTO of string * string
  (* proto closure to a possible constant      *)
  | PPROTO of string * string
  (* proto call                                *)
  | PCALLC of int * bool
  (* calls a closure                           *)
  | CALLC of int * bool
  (* calls a function/procedure                *)
  | CALL of string * int * bool
  (* returns from a function                   *)
  | RET
  (* drops the top element off                 *)
  | DROP
  (* duplicates the top element                *)
  | DUP
  (* swaps two top elements                    *)
  | SWAP
  (* checks the tag and arity of S-expression  *)
  | TAG of string * int
  (* checks the tag and size of array          *)
  | ARRAY of int
  (* checks various patterns                   *)
  | PATT of patt
  (* match failure (location, leave a value    *)
  | FAIL of Loc.t * bool
  (* external definition                       *)
  | EXTERN of string
  (* public   definition                       *)
  | PUBLIC of string
  (* import clause                             *)
  | IMPORT of string
  (* line info                                 *)
  | LINE of int
[@@deriving gt ~options:{ show }]

(* The type for the stack machine program *)
type prg = insn list [@@deriving gt ~options:{ show }]

module ByteCode = struct
  module M = Map.Make (String)
  module S = Set.Make (String)

  module StringTab = struct
    type t = { mutable smap : int M.t; buffer : Buffer.t; mutable index : int }

    let create () = { smap = M.empty; buffer = Buffer.create 255; index = 0 }

    let add st s =
      try
        let i = M.find s st.smap in
        i
      with Not_found ->
        let i = st.index in
        Buffer.add_string st.buffer s;
        Buffer.add_char st.buffer (Char.chr 0);
        st.smap <- M.add s i st.smap;
        st.index <- st.index + String.length s + 1;
        i
  end

  exception Found of int

  let opnum =
    let optab =
      [ "+"; "-"; "*"; "/"; "%"; "<"; "<="; ">"; ">="; "=="; "!="; "&&"; "!!" ]
    in
    fun s ->
      try
        ignore
        @@ List.fold_left
             (fun i op -> if s = op then raise (Found i) else i + 1)
             1 optab;
        failwith (Printf.sprintf "ERROR: undefined binary operator '%s'" s)
      with Found i -> i

  (* Below are the the numbers of occurrencies of SM instructions for the stdlib+lama compiler itself

     7328 SLABEL
     5351 CALL
     5321 DROP
     4437 LABEL
     4331 LD
     4213 DUP
     3979 EXTERN
     3525 CONST
     2503 LINE
     2281 JMP
     1400 ST
     1122 CJMP
      922 END
      922 BEGIN
      790 SEXP
      770 CLOSURE
      519 TAG
      493 STRING
      354 FAIL
      349 CALLC
      339 BINOP
      289 ARRAY
      270 PUBLIC
       87 PATT
       39 STA
       16 FLABEL
  *)

  let compile cmd insns =
    let code = Buffer.create 256 in
    let st = StringTab.create () in
    let lmap = Stdlib.ref M.empty in
    let pubs = Stdlib.ref S.empty in
    let imports = Stdlib.ref S.empty in
    let globals = Stdlib.ref M.empty in
    let glob_count = Stdlib.ref 0 in
    let fixups = Stdlib.ref [] in
    let add_lab l = lmap := M.add l (Buffer.length code) !lmap in
    let add_public l = pubs := S.add l !pubs in
    let add_import l = imports := S.add l !imports in
    let add_fixup l = fixups := (Buffer.length code, l) :: !fixups in
    let add_bytes = List.iter (fun x -> Buffer.add_char code @@ Char.chr x) in
    let add_ints =
      List.iter (fun x -> Buffer.add_int32_ne code @@ Int32.of_int x)
    in
    let add_strings =
      List.iter (fun x ->
          Buffer.add_int32_ne code @@ Int32.of_int @@ StringTab.add st x)
    in
    let add_designations n =
      let b x = match n with None -> x | Some b -> (b * 16) + x in
      List.iter (function
        | Value.Global s ->
            let i =
              try M.find s !globals
              with Not_found ->
                let i = !glob_count in
                incr glob_count;
                globals := M.add s i !globals;
                i
            in
            add_bytes [ b 0 ];
            add_ints [ i ]
        | Value.Local n ->
            add_bytes [ b 1 ];
            add_ints [ n ]
        | Value.Arg n ->
            add_bytes [ b 2 ];
            add_ints [ n ]
        | Value.Access n ->
            add_bytes [ b 3 ];
            add_ints [ n ]
        | _ ->
            failwith
              (Printf.sprintf "Unexpected pattern: %s: %d" __FILE__ __LINE__))
    in
    let insn_code = function
      (* 0x0s                 *)
      | BINOP s -> add_bytes [ opnum s ]
      (* 0x10 n:32            *)
      | CONST n ->
          add_bytes [ (1 * 16) + 0 ];
          add_ints [ n ]
      (* 0x11 s:32            *)
      | STRING s ->
          add_bytes [ (1 * 16) + 1 ];
          add_strings [ s ]
      (* 0x12 s:32 n:32       *)
      | SEXP (s, n) ->
          add_bytes [ (1 * 16) + 2 ];
          add_strings [ s ];
          add_ints [ n ]
      (* 0x13                 *)
      | STI -> add_bytes [ (1 * 16) + 3 ]
      (* 0x14                 *)
      | STA -> add_bytes [ (1 * 16) + 4 ]
      | LABEL s | FLABEL s | SLABEL s -> add_lab s
      (* 0x15 l:32            *)
      | JMP s ->
          add_bytes [ (1 * 16) + 5 ];
          add_fixup s;
          add_ints [ 0 ]
      (* 0x16                 *)
      | END -> add_bytes [ (1 * 16) + 6 ]
      (* 0x17                 *)
      | RET -> add_bytes [ (1 * 16) + 7 ]
      (* 0x18                 *)
      | DROP -> add_bytes [ (1 * 16) + 8 ]
      (* 0x19                 *)
      | DUP -> add_bytes [ (1 * 16) + 9 ]
      (* 0x1a                 *)
      | SWAP -> add_bytes [ (1 * 16) + 10 ]
      (* 0x1b                 *)
      | ELEM -> add_bytes [ (1 * 16) + 11 ]
      (* 0x2d n:32            *)
      | LD d -> add_designations (Some 2) [ d ]
      (* 0x3d n:32            *)
      | LDA d -> add_designations (Some 3) [ d ]
      (* 0x4d n:32            *)
      | ST d -> add_designations (Some 4) [ d ]
      (* 0x50 l:32            *)
      | CJMP ("z", s) ->
          add_bytes [ (5 * 16) + 0 ];
          add_fixup s;
          add_ints [ 0 ]
      (* 0x51 l:32            *)
      | CJMP ("nz", s) ->
          add_bytes [ (5 * 16) + 1 ];
          add_fixup s;
          add_ints [ 0 ]
      (* 0x70                 *)
      | CALL (f, _, _) when f = labeled "read" -> add_bytes [ (7 * 16) + 0 ]
      (* 0x71                 *)
      | CALL (f, _, _) when f = labeled "write" -> add_bytes [ (7 * 16) + 1 ]
      (* 0x72                 *)
      | CALL (f, _, _) when f = labeled "length" -> add_bytes [ (7 * 16) + 2 ]
      (* 0x73                 *)
      | CALL (f, _, _) when f = labeled "string" -> add_bytes [ (7 * 16) + 3 ]
      (* 0x74                 *)
      | CALL (".array", n, _) ->
          add_bytes [ (7 * 16) + 4 ];
          add_ints [ n ]
      (* 0x52 n:32 n:32       *)
      | BEGIN (_, a, l, [], _, _) ->
          add_bytes [ (5 * 16) + 2 ];
          add_ints [ a; l ] (* with no closure *)
      (* 0x53 n:32 n:32       *)
      | BEGIN (_, a, l, _, _, _) ->
          add_bytes [ (5 * 16) + 3 ];
          add_ints [ a; l ] (* with a closure  *)
      (* 0x54 l:32 n:32 d*:32 *)
      | CLOSURE (s, ds) ->
          add_bytes [ (5 * 16) + 4 ];
          add_fixup s;
          add_ints [ 0; List.length ds ];
          add_designations None ds
      (* 0x55 n:32            *)
      | CALLC (n, _) ->
          add_bytes [ (5 * 16) + 5 ];
          add_ints [ n ]
      (* 0x56 l:32 n:32       *)
      | CALL (fn, n, _) ->
          add_bytes [ (5 * 16) + 6 ];
          add_fixup fn;
          add_ints [ 0; n ]
      (* 0x57 s:32 n:32       *)
      | TAG (s, n) ->
          add_bytes [ (5 * 16) + 7 ];
          add_strings [ s ];
          add_ints [ n ]
      (* 0x58 n:32            *)
      | ARRAY n ->
          add_bytes [ (5 * 16) + 8 ];
          add_ints [ n ]
      (* 0x59 n:32 n:32       *)
      | FAIL ((l, c), _) ->
          add_bytes [ (5 * 16) + 9 ];
          add_ints [ l; c ]
      (* 0x5a n:32            *)
      | LINE n ->
          add_bytes [ (5 * 16) + 10 ];
          add_ints [ n ]
      (* 0x6p                 *)
      | PATT p -> add_bytes [ (6 * 16) + enum patt p ]
      | EXTERN _ -> ()
      | PUBLIC s -> add_public s
      | IMPORT s -> add_import s
      | _ ->
          failwith
            (Printf.sprintf "Unexpected pattern: %s: %d" __FILE__ __LINE__)
    in
    List.iter insn_code insns;
    add_bytes [ 255 ];
    let code = Buffer.to_bytes code in
    List.iter
      (fun (ofs, l) ->
        Bytes.set_int32_ne code ofs
          (Int32.of_int
          @@
          try M.find l !lmap
          with Not_found ->
            failwith (Printf.sprintf "ERROR: undefined label '%s'" l)))
      !fixups;
    let pubs =
      List.map (fun l ->
          ( Int32.of_int @@ StringTab.add st l,
            Int32.of_int
            @@
            try M.find l !lmap
            with Not_found ->
              failwith (Printf.sprintf "ERROR: undefined label '%s'" l) ))
      @@ S.elements !pubs
    in
    let st = Buffer.to_bytes st.StringTab.buffer in
    let file = Buffer.create 1024 in
    Buffer.add_int32_ne file (Int32.of_int @@ Bytes.length st);
    Buffer.add_int32_ne file (Int32.of_int @@ !glob_count);
    Buffer.add_int32_ne file (Int32.of_int @@ List.length pubs);
    List.iter
      (fun (n, o) ->
        Buffer.add_int32_ne file n;
        Buffer.add_int32_ne file o)
      pubs;
    Buffer.add_bytes file st;
    Buffer.add_bytes file code;
    let f = open_out_bin (Printf.sprintf "%s.bc" cmd#basename) in
    Buffer.output_buffer f file;
    close_out f
end

let show_prg p =
  let b = Buffer.create 512 in
  List.iter
    (fun i ->
      Buffer.add_string b (show insn i);
      Buffer.add_string b "\n")
    p;
  Buffer.contents b

(* Values *)
type value = (string, value array) Value.t [@@deriving gt ~options:{ show }]

(* Local state of the SM *)
type local = { args : value array; locals : value array; closure : value array }
[@@deriving gt ~options:{ show }]

(* Global state of the SM *)
type global = (string, value) arrow [@@deriving gt]

(* Control stack *)
type control = (prg * local) list [@@deriving gt ~options:{ show }]

(* Data stack *)
type stack = value list [@@deriving gt ~options:{ show }]

(* The type for the stack machine configuration: control stack, stack, global and local states,
   input and output streams
*)
type config = control * stack * global * local * int list * int list

(* Stack machine interpreter

     val eval : env -> config -> prg -> config

   Takes an environment, a configuration and a program, and returns a configuration as a result. The
   environment is used to locate a label to jump to (via method env#labeled <label_name>)
*)
let split n l =
  let rec unzip (taken, rest) = function
    | 0 -> (List.rev taken, rest)
    | n ->
        let[@ocaml.warning "-8"] (h :: tl) = rest in
        unzip (h :: taken, tl) (n - 1)
  in
  unzip ([], l) n

let update glob loc z = function
  | Value.Global x -> State.bind x z glob
  | Value.Local i ->
      loc.locals.(i) <- z;
      glob
  | Value.Arg i ->
      loc.args.(i) <- z;
      glob
  | Value.Access i ->
      loc.closure.(i) <- z;
      glob
  | _ ->
      failwith (Printf.sprintf "Unexpected pattern: %s: %d" __FILE__ __LINE__)

let print_stack _ s =
  Printf.eprintf "Memo %!";
  List.iter (fun v -> Printf.eprintf "%s " @@ show value v) s;
  Printf.eprintf "\n%!"

let show_insn = show insn

let[@ocaml.warning "-8-20"] rec eval env
    ((cstack, stack, glob, loc, i, o) as conf : config) = function
  | [] -> conf
  | insn :: prg' -> (
      (*
   Printf.eprintf "eval\n";
   Printf.eprintf "   insn=%s\n" (show_insn insn);
   Printf.eprintf "   stack=%s\n" (show(list) (show(value)) stack);
   Printf.eprintf "end\n";
    *)
      match insn with
      | IMPORT _ | PUBLIC _ | EXTERN _ | LINE _ -> eval env conf prg'
      | BINOP "==" ->
          let (y :: x :: stack') = stack in
          let z =
            match (x, y) with
            | Value.Int _, Value.Int _ ->
                Value.of_int
                @@ Expr.to_func "==" (Value.to_int x) (Value.to_int y)
            | Value.Int _, _ | _, Value.Int _ -> Value.of_int 0
            | _ ->
                failwith "unexpected operands in comparison: %s vs. %s\n"
                  (show Value.t
                     (fun _ -> "<not supported>")
                     (fun _ -> "<not supported>")
                     x)
                  (show Value.t
                     (fun _ -> "<not supported>")
                     (fun _ -> "<not supported>")
                     y)
          in
          eval env (cstack, z :: stack', glob, loc, i, o) prg'
      | BINOP op ->
          let (y :: x :: stack') = stack in
          eval env
            ( cstack,
              (Value.of_int @@ Expr.to_func op (Value.to_int x) (Value.to_int y))
              :: stack',
              glob,
              loc,
              i,
              o )
            prg'
      | CONST n ->
          eval env (cstack, Value.of_int n :: stack, glob, loc, i, o) prg'
      | STRING s ->
          eval env
            ( cstack,
              (Value.of_string @@ Bytes.of_string s) :: stack,
              glob,
              loc,
              i,
              o )
            prg'
      | SEXP (s, n) ->
          let vs, stack' = split n stack in
          eval env
            (cstack, (Value.sexp s @@ List.rev vs) :: stack', glob, loc, i, o)
            prg'
      | ELEM ->
          let (a :: b :: stack') = stack in
          eval env
            (env#builtin ".elem" [ a; b ] (cstack, stack', glob, loc, i, o))
            prg'
      | LD x ->
          eval env
            ( cstack,
              (match x with
              | Value.Global x -> glob x
              | Value.Local i -> loc.locals.(i)
              | Value.Arg i -> loc.args.(i)
              | Value.Access i -> loc.closure.(i))
              :: stack,
              glob,
              loc,
              i,
              o )
            prg'
      | LDA x -> eval env (cstack, Value.Var x :: stack, glob, loc, i, o) prg'
      | ST x ->
          let (z :: stack') = stack in
          eval env (cstack, z :: stack', update glob loc z x, loc, i, o) prg'
      | STI ->
          let (z :: Value.Var r :: stack') = stack in
          eval env (cstack, z :: stack', update glob loc z r, loc, i, o) prg'
      | STA -> (
          let (z :: j :: stack') = stack in
          match j with
          | Value.Var r ->
              eval env
                (cstack, z :: stack', update glob loc z r, loc, i, o)
                prg'
          | Value.Int _ ->
              let (x :: stack') = stack' in
              Value.update_elem x (Value.to_int j) z;
              eval env (cstack, z :: stack', glob, loc, i, o) prg')
      | SLABEL _ | LABEL _ | FLABEL _ -> eval env conf prg'
      | JMP l -> eval env conf (env#labeled l)
      | CJMP (c, l) ->
          let (x :: stack') = stack in
          eval env
            (cstack, stack', glob, loc, i, o)
            (if
               (c = "z" && Value.to_int x = 0)
               || (c = "nz" && Value.to_int x <> 0)
             then env#labeled l
             else prg')
      | CLOSURE (name, dgs) ->
          let closure =
            Array.of_list
            @@ List.map
                 (function
                   | Value.Arg i -> loc.args.(i)
                   | Value.Local i -> loc.locals.(i)
                   | Value.Access i -> loc.closure.(i)
                   | _ -> invalid_arg "wrong value in CLOSURE")
                 dgs
          in
          eval env
            (cstack, Value.Closure ([], name, closure) :: stack, glob, loc, i, o)
            prg'
      | CALL (f, n, _) ->
          let args, stack' = split n stack in
          if env#is_label f then
            eval env
              ( (prg', loc) :: cstack,
                stack',
                glob,
                {
                  args = Array.of_list (List.rev args);
                  locals = [||];
                  closure = [||];
                },
                i,
                o )
              (env#labeled f)
          else
            eval env
              (env#builtin f args ((cstack, stack', glob, loc, i, o) : config))
              prg'
      | CALLC (n, _) -> (
          let vs, stack' = split (n + 1) stack in
          let (f :: args) = List.rev vs in
          match f with
          | Value.Builtin f ->
              eval env
                (env#builtin f (List.rev args)
                   ((cstack, stack', glob, loc, i, o) : config))
                prg'
          | Value.Closure (_, f, closure) ->
              eval env
                ( (prg', loc) :: cstack,
                  stack',
                  glob,
                  { args = Array.of_list args; locals = [||]; closure },
                  i,
                  o )
                (env#labeled f)
          | _ ->
              invalid_arg "not a closure (or a builtin) in CALL: %s\n"
              @@ show value f)
      | BEGIN (_, _, locals, _, _, _) ->
          eval env
            ( cstack,
              stack,
              glob,
              { loc with locals = Array.init locals (fun _ -> Value.Empty) },
              i,
              o )
            prg'
      | END -> (
          match cstack with
          | (prg', loc') :: cstack' ->
              eval env
                (cstack', (*Value.Empty ::*) stack, glob, loc', i, o)
                prg'
          | [] -> conf)
      | RET -> (
          match cstack with
          | (prg', loc') :: cstack' ->
              eval env (cstack', stack, glob, loc', i, o) prg'
          | [] -> conf)
      | DROP -> eval env (cstack, List.tl stack, glob, loc, i, o) prg'
      | DUP -> eval env (cstack, List.hd stack :: stack, glob, loc, i, o) prg'
      | SWAP ->
          let (x :: y :: stack') = stack in
          eval env (cstack, y :: x :: stack', glob, loc, i, o) prg'
      | TAG (t, n) ->
          let (x :: stack') = stack in
          eval env
            ( cstack,
              (Value.of_int
              @@
              match x with
              | Value.Sexp (t', a) when t' = t && Array.length a = n -> 1
              | _ -> 0)
              :: stack',
              glob,
              loc,
              i,
              o )
            prg'
      | ARRAY n ->
          let (x :: stack') = stack in
          eval env
            ( cstack,
              (Value.of_int
              @@
              match x with Value.Array a when Array.length a = n -> 1 | _ -> 0)
              :: stack',
              glob,
              loc,
              i,
              o )
            prg'
      | PATT StrCmp ->
          let (x :: y :: stack') = stack in
          eval env
            ( cstack,
              (Value.of_int
              @@
              match (x, y) with
              | Value.String xs, Value.String ys when xs = ys -> 1
              | _ -> 0)
              :: stack',
              glob,
              loc,
              i,
              o )
            prg'
      | PATT Array ->
          let (x :: stack') = stack in
          eval env
            ( cstack,
              (Value.of_int @@ match x with Value.Array _ -> 1 | _ -> 0)
              :: stack',
              glob,
              loc,
              i,
              o )
            prg'
      | PATT String ->
          let (x :: stack') = stack in
          eval env
            ( cstack,
              (Value.of_int @@ match x with Value.String _ -> 1 | _ -> 0)
              :: stack',
              glob,
              loc,
              i,
              o )
            prg'
      | PATT Sexp ->
          let (x :: stack') = stack in
          eval env
            ( cstack,
              (Value.of_int @@ match x with Value.Sexp _ -> 1 | _ -> 0)
              :: stack',
              glob,
              loc,
              i,
              o )
            prg'
      | PATT Boxed ->
          let (x :: stack') = stack in
          eval env
            ( cstack,
              (Value.of_int @@ match x with Value.Int _ -> 0 | _ -> 1)
              :: stack',
              glob,
              loc,
              i,
              o )
            prg'
      | PATT UnBoxed ->
          let (x :: stack') = stack in
          eval env
            ( cstack,
              (Value.of_int @@ match x with Value.Int _ -> 1 | _ -> 0)
              :: stack',
              glob,
              loc,
              i,
              o )
            prg'
      | PATT Closure ->
          let (x :: stack') = stack in
          eval env
            ( cstack,
              (Value.of_int @@ match x with Value.Closure _ -> 1 | _ -> 0)
              :: stack',
              glob,
              loc,
              i,
              o )
            prg'
      | FAIL (l, _) ->
          let (x :: _) = stack in
          raise
            (Failure
               (Printf.sprintf "matching value %s failure at %s" (show value x)
                  (show Loc.t l))))

(* Top-level evaluation

     val run : prg -> int list -> int list

   Takes a program, an input stream, and returns an output stream this program calculates
*)

module M = Map.Make (String)

class indexer prg =
  let rec make_env m = function
    | [] -> m
    | LABEL l :: tl | FLABEL l :: tl -> make_env (M.add l tl m) tl
    | _ :: tl -> make_env m tl
  in
  let m = make_env M.empty prg in
  object
    method is_label l = M.mem l m
    method labeled l = M.find l m
  end

let run p i =
  let module M = Map.Make (String) in
  let glob = State.undefined in
  let _, _, _, _, _, o =
    eval
      (object
         inherit indexer p

         method builtin f args ((cstack, stack, glob, loc, i, o) : config) =
           let f =
             match f.[0] with
             | 'L' -> String.sub f 1 (String.length f - 1)
             | _ -> f
           in
           let _, i, o, r =
             Language.Builtin.eval (State.I, i, o, [])
               (List.map Obj.magic @@ List.rev args)
               f
           in
           ( cstack,
             (match r with
             | [ r ] -> Obj.magic r :: stack
             | _ -> Value.Empty :: stack),
             glob,
             loc,
             i,
             o )
         [@@ocaml.warning "-8"]
      end)
      ( [],
        [],
        List.fold_left
          (fun s (name, value) -> State.bind name value s)
          glob (Builtin.bindings ()),
        { locals = [||]; args = [||]; closure = [||] },
        i,
        [] )
      p
  in
  o

(* Stack machine compiler

     val compile : Language.t -> prg

   Takes a program in the source language and returns an equivalent program for the
   stack machine
*)

let check_name_and_add names name mut =
  if List.exists (fun (n, _) -> n = name) names then
    report_error ~loc:(Loc.get name)
      (Printf.sprintf "name \"%s\" is already defined in the scope"
         (Subst.subst name))
  else (name, mut) :: names

type funscope = {
  st : Value.designation State.t;
  arg_index : int;
  local_index : int;
  acc_index : int;
  nlocals : int;
  closure : Value.designation list;
  scopes : scope list;
}
[@@deriving gt ~options:{ show }]

type fundef = {
  name : string;
  args : string list;
  body : Expr.t;
  scope : funscope;
}
[@@deriving gt ~options:{ show }]

type context = Top of fundef list | Item of fundef * fundef list * context
[@@deriving gt ~options:{ show }]

let init_scope st =
  {
    st;
    arg_index = 0;
    acc_index = 0;
    local_index = 0;
    nlocals = 0;
    closure = [];
    scopes = [];
  }

let to_fundef name args body st = { name; args; body; scope = init_scope st }
let from_fundef fd = (fd.name, fd.args, fd.body, fd.scope.st)

let open_scope c fd =
  match c with
  | Top _ -> Item (fd, [], c)
  | Item (p, fds, up) ->
      Item (fd, [], Item ({ p with scope = fd.scope }, fds, up))

let[@ocaml.warning "-8"] close_scope (Item (_, [], c)) = c

let add_fun c fd =
  match c with
  | Top fds -> Top (fd :: fds)
  | Item (parent, fds, up) -> Item (parent, fd :: fds, up)

let[@ocaml.warning "-39"] rec pick = function
  | Item (parent, fd :: fds, up) -> (Item (parent, fds, up), Some fd)
  | Top (fd :: fds) -> (Top fds, Some fd)
  | c -> (c, None)

let top = function Item (p, _, _) -> Some p | _ -> None

let[@ocaml.warning "-8"] rec propagate_acc (Item (p, fds, up) as item) name =
  match State.eval p.scope.st name with
  | Value.Access n when n = ~-1 ->
      let index = p.scope.acc_index in
      let up', loc = propagate_acc up name in
      ( Item
          ( {
              p with
              scope =
                {
                  p.scope with
                  st = State.update name (Value.Access index) p.scope.st;
                  acc_index = p.scope.acc_index + 1;
                  closure = loc :: p.scope.closure;
                };
            },
            fds,
            up' ),
        Value.Access index )
  | other -> (item, other)

module FC = Map.Make (struct
  type t = string * string

  let compare = Stdlib.compare
end)

class funinfo =
  object (self : 'self)
    val funtree : string M.t ref = Stdlib.ref M.empty
    val closures : Value.designation list M.t ref = Stdlib.ref M.empty
    val functx : Value.designation list FC.t ref = Stdlib.ref FC.empty

    method show_funinfo =
      Printf.sprintf "funtree: %s\nclosures: %s\ncontexts: %s\n"
        (show list (fun (x, y) -> x ^ ": " ^ y) @@ M.bindings !funtree)
        (show list (fun (x, y) ->
             x ^ ": " ^ show list (show Value.designation) y)
        @@ M.bindings !closures)
        (show list (fun ((x, y), v) ->
             "(" ^ x ^ ", " ^ y ^ ")" ^ show list (show Value.designation) v)
        @@ FC.bindings !functx)

    method lookup_closure p = FC.find p !functx

    method register_call f c =
      functx := FC.add (f, c) [] !functx;
      self

    method register_fun f p =
      funtree := M.add f p !funtree;
      self

    method register_closure f c =
      closures := M.add f c !closures;
      self

    method private get_parent f = M.find f !funtree
    method get_closure f = M.find f !closures

    method private propagate_for_call (f, c) =
      try
        let fp = self#get_parent f in
        let rec find_path current =
          if fp = current then []
          else find_path (self#get_parent current) @ [ current ]
        in
        let path = find_path c in
        let changed = Stdlib.ref false in
        let rec propagate_downwards current_closure = function
          | [] -> current_closure
          | f :: tl ->
              let fclosure = self#get_closure f in
              let delta = Stdlib.ref fclosure in
              let index = Stdlib.ref (List.length fclosure) in
              let added = Stdlib.ref false in
              let add_to_closure loc =
                added := true;
                delta := !delta @ [ loc ];
                let loc' = Value.Access !index in
                incr index;
                loc'
              in
              let next_closure =
                List.map
                  (fun loc ->
                    let rec find_index i = function
                      | [] -> raise Not_found
                      | loc' :: tl ->
                          if loc' = loc then Value.Access i
                          else find_index (i + 1) tl
                    in
                    try find_index 0 fclosure
                    with Not_found -> add_to_closure loc)
                  current_closure
              in
              if !added then (
                changed := true;
                closures := M.add f !delta !closures);
              propagate_downwards next_closure tl
        in
        let closure = propagate_downwards (self#get_closure f) path in
        functx := FC.add (f, c) closure !functx;
        !changed
      with Not_found -> false

    method propagate_closures =
      while
        List.fold_left
          (fun flag (call, _) -> flag || self#propagate_for_call call)
          false
        @@ FC.bindings !functx
      do
        ()
      done;
      self
  end

class env cmd imports =
  object (self : 'self)
    val label_index = 0
    val scope_index = 0
    val lam_index = 0
    val scope = init_scope State.I
    val fundefs = Top []
    val decls = []
    val funinfo = new funinfo
    val line = None
    val end_label = ""
    method show_funinfo = funinfo#show_funinfo
    method get_closure p = try funinfo#lookup_closure p with Not_found -> []
    method get_fun_closure f = funinfo#get_closure f
    method propagate_closures = {<funinfo = funinfo#propagate_closures>}

    method register_call f =
      {<funinfo = funinfo#register_call f self#current_function>}

    method register_fun f =
      {<funinfo = funinfo#register_fun f self#current_function>}

    method register_closure f =
      {<funinfo = funinfo#register_closure f self#closure>}

    method current_function =
      match fundefs with Top _ -> "main" | Item (fd, _, _) -> fd.name

    method private import_imports =
      let paths = cmd#get_include_paths in
      let env =
        List.fold_left
          (fun env import ->
            let _, intfs = Interface.find import paths in
            List.fold_left
              (fun env -> function
                | `Variable name -> env#add_name name `Extern Mut
                | `Fun name -> env#add_fun_name name `Extern
                | _ -> env)
              env intfs)
          self imports
      in
      env

    method global_scope = scope_index = 0

    method get_label =
      (labeled @@ string_of_int label_index, {<label_index = label_index + 1>})

    method get_end_label =
      let lab = labeled @@ string_of_int label_index in
      (lab, {<end_label = lab; label_index = label_index + 1>})

    method end_label = end_label
    method nargs = scope.arg_index
    method nlocals = scope.nlocals

    method get_decls =
      let opt_label = function
        | true -> labeled
        | _ -> labeled_global
      in
      List.flatten
      @@ List.map (function
           | name, `Extern, f -> [ EXTERN (opt_label f name) ]
           | name, `Public, f -> [ PUBLIC (opt_label f name) ]
           | name, `PublicExtern, f ->
               [ PUBLIC (opt_label f name); EXTERN (opt_label f name) ]
           | _ -> invalid_arg "must not happen")
      @@ List.filter (function _, `Local, _ -> false | _ -> true) decls

    method push_scope (blab : string) (elab : string) =
      (*Printf.printf "push: Scope local index = %d\n" scope.local_index;*)
      match scope.st with
      | State.I ->
          {<scope_index = scope_index + 1
           ; scope = { scope with st = State.G ([], State.undefined) }>}
            #import_imports
      | _ ->
          {<scope_index = scope_index + 1
           ; scope = {
                       scope with
                       st = State.L ([], State.undefined, scope.st);
                       scopes =
                         { blab; elab; names = []; subs = [] } :: scope.scopes;
                     }>}

    method pop_scope =
      match scope.st with
      | State.I -> {<scope = { scope with st = State.I }>}
      | State.G _ -> {<scope = { scope with st = State.I }>}
      | State.L (xs, _, x) ->
          {<scope = {
                      scope with
                      st = x;
                      local_index =
                        (*Printf.printf "pop: Scope local index = %d\n" (scope.local_index - List.length xs);*)
                        scope.local_index
                        - List.length (List.filter (fun (_, x) -> x <> FVal) xs)
                        (*xs*);
                      scopes =
                        (match scope.scopes with
                        | [ _ ] -> scope.scopes
                        | hs :: ps :: tl ->
                            { ps with subs = hs :: ps.subs } :: tl
                        | _ ->
                            failwith
                              (Printf.sprintf "Unexpected pattern: %s: %d"
                                 __FILE__ __LINE__));
                    }>}

    method open_fun_scope blab elab (name, args, body, st') =
      {<fundefs = open_scope fundefs
                    { name; args; body; scope = { scope with st = st' } }
       ; scope = init_scope
                   (let rec readdress_to_closure = function
                      | State.L (xs, st, tl) ->
                          State.L
                            ( xs,
                              (fun name ->
                                match st name with
                                | Value.Fun _ as x -> x
                                | _ -> Value.Access ~-1),
                              readdress_to_closure tl )
                      | st -> st
                    in
                    readdress_to_closure st')>}
        #push_scope
        blab elab

    method close_fun_scope =
      (*Printf.printf "Scopes: %s\n" @@ show(GT.list) show_scope scope.scopes;*)
      let scopes = scope.scopes in
      let fundefs' = close_scope fundefs in
      match top fundefs' with
      | Some fd -> ({<fundefs = fundefs'; scope = fd.scope>}#pop_scope, scopes)
      | None -> ({<fundefs = fundefs'>}#pop_scope, scopes)

    method add_arg (name : string) =
      {<scope = {
                  scope with
                  st =
                    (match scope.st with
                    | State.I | State.G _ ->
                        invalid_arg "wrong scope in add_arg"
                    | State.L (names, s, p) ->
                        State.L
                          ( check_name_and_add names name Mut,
                            State.bind name (Value.Arg scope.arg_index) s,
                            p ));
                  arg_index = scope.arg_index + 1;
                }>}

    method check_scope m name =
      match m with
      | `Local -> ()
      | _ ->
          report_error
            (Printf.sprintf
               "external/public definitions (\"%s\") not allowed in local \
                scopes"
               (Subst.subst name))

    method add_name (name : string)
        (m : [ `Local | `Extern | `Public | `PublicExtern ]) (mut : Language.k)
        =
      {<decls = (name, m, false) :: decls
       ; scope = {
                   scope with
                   st =
                     (match scope.st with
                     | State.I -> invalid_arg "uninitialized scope"
                     | State.G (names, s) ->
                         State.G
                           ( (match m with
                             | `Extern | `PublicExtern -> names
                             | _ -> check_name_and_add names name mut),
                             State.bind name (Value.Global name) s )
                     | State.L (names, s, p) ->
                         self#check_scope m name;
                         State.L
                           ( check_name_and_add names name mut,
                             State.bind name
                               (Value.Local
                                  (*Printf.printf "Var: %s -> %d\n" name scope.local_index;*)
                                  scope.local_index)
                               s,
                             p )
                         (* !! *));
                   local_index =
                     (match scope.st with
                     | State.L _ -> scope.local_index + 1
                     | _ -> scope.local_index);
                   nlocals =
                     (match scope.st with
                     | State.L _ -> max (scope.local_index + 1) scope.nlocals
                     | _ -> scope.nlocals);
                   scopes =
                     (match scope.scopes with
                     | ts :: tl ->
                         {
                           ts with
                           names = (name, scope.local_index) :: ts.names;
                         }
                         :: tl
                     | _ -> scope.scopes);
                 }>}

    method fun_internal_name (name : string) =
      (match scope.st with
      | State.G _ -> labeled
      | _ -> labeled_scoped scope_index)
        name

    method add_fun_name (name : string)
        (m : [ `Local | `Extern | `Public | `PublicExtern ]) =
      let name' = self#fun_internal_name name in
      let st' =
        match scope.st with
        | State.I -> invalid_arg "uninitialized scope"
        | State.G (names, s) ->
            State.G
              ( (match m with
                | `Extern | `PublicExtern -> names
                | _ -> check_name_and_add names name FVal),
                State.bind name (Value.Fun name') s )
        | State.L (names, s, p) ->
            self#check_scope m name;
            State.L
              ( check_name_and_add names name FVal,
                State.bind name (Value.Fun name') s,
                p )
      in
      {<decls = (name, m, true) :: decls; scope = { scope with st = st' }>}

    method add_lambda (args : string list) (body : Expr.t) =
      let name' =
        self#fun_internal_name (Printf.sprintf "lambda_%d" lam_index)
      in
      ( {<fundefs = add_fun fundefs (to_fundef name' args body scope.st)
         ; lam_index = lam_index + 1>}
          #register_fun name',
        name' )

    method add_fun (name : string) (args : string list)
        (m : [ `Local | `Extern | `Public | `PublicExtern ]) (body : Expr.t) =
      let name' = self#fun_internal_name name in
      match m with
      | `Extern -> self
      | _ ->
          {<fundefs = add_fun fundefs (to_fundef name' args body scope.st)>}
            #register_fun name'

    method lookup name =
      match State.eval scope.st name with
      | Value.Access n when n = ~-1 ->
          let index = scope.acc_index in
          let fundefs', loc = propagate_acc fundefs name in
          ( {<fundefs = fundefs'
             ; scope = {
                         scope with
                         st = State.update name (Value.Access index) scope.st;
                         acc_index = scope.acc_index + 1;
                         closure = loc :: scope.closure;
                       }>},
            Value.Access index )
      | other -> (self, other)

    method next_definition =
      match pick fundefs with
      | _, None -> None
      | fds, Some fd -> Some ({<fundefs = fds>}, from_fundef fd)

    method closure = List.rev scope.closure

    method gen_line name =
      match Loc.get name with
      | None -> (self, [])
      | Some (l, _) -> (
          match line with
          | None -> ({<line = Some l>}, [ LINE l ])
          | Some l' when l' <> l -> ({<line = Some l>}, [ LINE l ])
          | _ -> (self, []))
  end [@@ocaml.warning "-15"]

let compile cmd ((imports, _), p) =
  let rec pattern env lfalse = function
    | Pattern.Wildcard -> (env, false, [ DROP ])
    | Pattern.Named (_, p) -> pattern env lfalse p
    | Pattern.Const c -> (env, true, [ CONST c; BINOP "=="; CJMP ("z", lfalse) ])
    | Pattern.String s ->
        (env, true, [ STRING s; PATT StrCmp; CJMP ("z", lfalse) ])
    | Pattern.ArrayTag -> (env, true, [ PATT Array; CJMP ("z", lfalse) ])
    | Pattern.StringTag -> (env, true, [ PATT String; CJMP ("z", lfalse) ])
    | Pattern.SexpTag -> (env, true, [ PATT Sexp; CJMP ("z", lfalse) ])
    | Pattern.UnBoxed -> (env, true, [ PATT UnBoxed; CJMP ("z", lfalse) ])
    | Pattern.Boxed -> (env, true, [ PATT Boxed; CJMP ("z", lfalse) ])
    | Pattern.ClosureTag -> (env, true, [ PATT Closure; CJMP ("z", lfalse) ])
    | Pattern.Array ps ->
        let lhead, env = env#get_label in
        let ldrop, env = env#get_label in
        let tag =
          [
            DUP;
            ARRAY (List.length ps);
            CJMP ("nz", lhead);
            LABEL ldrop;
            DROP;
            JMP lfalse;
            LABEL lhead;
          ]
        in
        let code, env = pattern_list lhead ldrop env ps in
        (env, true, tag @ code @ [ DROP ])
    | Pattern.Sexp (t, ps) ->
        let lhead, env = env#get_label in
        let ldrop, env = env#get_label in
        let tag =
          [
            DUP;
            TAG (t, List.length ps);
            CJMP ("nz", lhead);
            LABEL ldrop;
            DROP;
            JMP lfalse;
            LABEL lhead;
          ]
        in
        let code, env = pattern_list lhead ldrop env ps in
        (env, true, tag @ code @ [ DROP ])
  and pattern_list _ ldrop env ps =
    let _, env, code =
      List.fold_left
        (fun (i, env, code) p ->
          let env, _, pcode = pattern env ldrop p in
          ( i + 1,
            env,
            ([ DUP; CONST i; ELEM (*CALL (".elem", 2, false)*) ] @ pcode)
            :: code ))
        (0, env, []) ps
    in
    (List.flatten (List.rev code), env)
  and bindings env p =
    let bindings =
      transform Pattern.t
        (fun fself ->
          object
            inherit [int list, _, (string * int list) list] Pattern.t_t
            method c_Wildcard _ _ = []
            method c_Named path _ s p = [ (s, path) ] @ fself path p

            method c_Sexp path _ _ ps =
              List.concat @@ List.mapi (fun i p -> fself (path @ [ i ]) p) ps

            method c_UnBoxed _ _ = []
            method c_StringTag _ _ = []
            method c_String _ _ _ = []
            method c_SexpTag _ _ = []
            method c_Const _ _ _ = []
            method c_Boxed _ _ = []
            method c_ArrayTag _ _ = []
            method c_ClosureTag _ _ = []

            method c_Array path _ ps =
              List.concat @@ List.mapi (fun i p -> fself (path @ [ i ]) p) ps
          end)
        [] p
    in
    let env, code =
      List.fold_left
        (fun (env, acc) (name, path) ->
          (*Printf.printf "Bindings..\n";*)
          let env = env#add_name name `Local Mut in
          let env, dsg = env#lookup name in
          (*Printf.printf "End Bindings..\n";*)
          ( env,
            ([ DUP ]
            @ List.concat
                (List.map
                   (fun i -> [ CONST i; ELEM (* CALL (".elem", 2, false)*) ])
                   path)
            @ [ ST dsg; DROP ])
            :: acc ))
        (env, []) (List.rev bindings)
    in
    (env, List.flatten code @ [ DROP ])
  and add_code (env, flag, s) l f s' =
    (env, f, s @ (if flag then [ LABEL l ] else []) @ s')
  and compile_list tail l env = function
    | [] -> (env, false, [])
    | [ e ] -> compile_expr tail l env e
    | e :: es ->
        let les, env = env#get_label in
        let env, flag1, s1 = compile_expr false les env e in
        let env, flag2, s2 = compile_list tail l env es in
        add_code (env, flag1, s1) les flag2 s2
  and[@ocaml.warning "-8"] compile_expr tail l env = function
    | Expr.Lambda (args, b) ->
        let env, lines =
          List.fold_left
            (fun (env, acc) name ->
              let env, ln = env#gen_line name in
              (env, acc @ ln))
            (env, []) args
        in
        let env, name = env#add_lambda args b in
        ( env#register_call name,
          false,
          lines @ [ PROTO (name, env#current_function) ] )
    | Expr.Scope (ds, e) ->
        let blab, env = env#get_label in
        let elab, env = env#get_label in
        let env = env#push_scope blab elab in
        let env, e, funs =
          List.fold_left
            (fun (env, e, funs) -> function
              | name, (m, `Fun (args, b)) ->
                  (env#add_fun_name name m, e, (name, args, m, b) :: funs)
              | name, (m, `Variable None) -> (env#add_name name m Mut, e, funs)
              | name, (m, `Variable (Some v)) ->
                  ( env#add_name name m Mut,
                    Expr.Seq (Expr.Ignore (Expr.Assign (Expr.Ref name, v)), e),
                    funs ))
            (env, e, []) (List.rev ds)
        in
        let env =
          List.fold_left
            (fun env (name, args, m, b) -> env#add_fun name args m b)
            env funs
        in
        let env, flag, code = compile_expr tail l env e in
        (env#pop_scope, flag, [ SLABEL blab ] @ code @ [ SLABEL elab ])
    | Expr.Unit -> (env, false, [ CONST 0 ])
    | Expr.Ignore s ->
        let ls, env = env#get_label in
        add_code (compile_expr tail ls env s) ls false [ DROP ]
    | Expr.ElemRef (x, i) -> compile_list tail l env [ x; i ]
    | Expr.Var x -> (
        let env, line = env#gen_line x in
        let env, acc = env#lookup x in
        (*Printf.printf "Looking up %s -> %s\n" x (show(Value.designation) acc);*)
        match acc with
        | Value.Fun name ->
            ( env#register_call name,
              false,
              line @ [ PROTO (name, env#current_function) ] )
        | _ -> (env, false, line @ [ LD acc ]))
    | Expr.Ref x ->
        let env, line = env#gen_line x in
        let env, acc = env#lookup x in
        (env, false, line @ [ LDA acc ])
    | Expr.Const n -> (env, false, [ CONST n ])
    | Expr.String s -> (env, false, [ STRING s ])
    | Expr.Binop (op, x, y) ->
        let lop, env = env#get_label in
        add_code (compile_list false lop env [ x; y ]) lop false [ BINOP op ]
    | Expr.Call (f, args) -> (
        let lcall, env = env#get_label in
        match f with
        | Expr.Var name -> (
            let env, line = env#gen_line name in
            let env, acc = env#lookup name in
            match acc with
            | Value.Fun name ->
                let env = env#register_call name in
                let env, f, code =
                  add_code
                    (compile_list false lcall env args)
                    lcall false
                    [ PCALLC (List.length args, tail) ]
                in
                (env, f, line @ (PPROTO (name, env#current_function) :: code))
            | _ ->
                add_code
                  (compile_list false lcall env (f :: args))
                  lcall false
                  [ CALLC (List.length args, tail) ])
        | _ ->
            add_code
              (compile_list false lcall env (f :: args))
              lcall false
              [ CALLC (List.length args, tail) ])
    | Expr.Array xs ->
        let lar, env = env#get_label in
        add_code
          (compile_list false lar env xs)
          lar false
          [ CALL (".array", List.length xs, tail) ]
    | Expr.Sexp (t, xs) ->
        let lsexp, env = env#get_label in
        add_code
          (compile_list false lsexp env xs)
          lsexp false
          [ SEXP (t, List.length xs) ]
    | Expr.Elem (a, i) ->
        let lelem, env = env#get_label in
        add_code
          (compile_list false lelem env [ a; i ])
          lelem false
          [ ELEM (* CALL (".elem", 2, tail) *) ]
    | Expr.Assign (Expr.Ref x, e) ->
        let lassn, env = env#get_label in
        let env, line = env#gen_line x in
        let env, acc = env#lookup x in
        add_code (compile_expr false lassn env e) lassn false (line @ [ ST acc ])
    | Expr.Assign (x, e) ->
        let lassn, env = env#get_label in
        add_code
          (compile_list false lassn env [ x; e ])
          lassn false
          [ (match x with Expr.Ref _ -> STI | _ -> STA) ]
        (*Expr.ElemRef _ -> STA | _ -> STI]*)
    | Expr.Skip -> (env, false, [])
    | Expr.Seq (s1, s2) -> compile_list tail l env [ s1; s2 ]
    | Expr.If (c, s1, s2) ->
        let le, env = env#get_label in
        let l2, env = env#get_label in
        let env, fe, se = compile_expr false le env c in
        let env, flag1, s1 = compile_expr tail l env s1 in
        let env, flag2, s2 = compile_expr tail l env s2 in
        ( env,
          true,
          se
          @ (if fe then [ LABEL le ] else [])
          @ [ CJMP ("z", l2) ]
          @ s1
          @ (if flag1 then [] else [ JMP l ])
          @ [ LABEL l2 ] @ s2
          @ if flag2 then [] else [ JMP l ] )
    | Expr.While (c, s) ->
        let lexp, env = env#get_label in
        let loop, env = env#get_label in
        let cond, env = env#get_label in
        let env, fe, se = compile_expr false lexp env c in
        let env, _, s = compile_expr false cond env s in
        ( env,
          false,
          [ JMP cond; FLABEL loop ] @ s @ [ LABEL cond ] @ se
          @ (if fe then [ LABEL lexp ] else [])
          @ [ CJMP ("nz", loop) ] )
    | Expr.DoWhile (s, c) ->
        let lexp, env = env#get_label in
        let loop, env = env#get_label in
        let check, env = env#get_label in
        let env, fe, se = compile_expr false lexp env c in
        let env, flag, body = compile_expr false check env s in
        ( env,
          false,
          [ LABEL loop ] @ body
          @ (if flag then [ LABEL check ] else [])
          @ se
          @ (if fe then [ LABEL lexp ] else [])
          @ [ CJMP ("nz", loop) ] )
    | Expr.Leave -> (env, false, [])
    | Expr.Case (e, brs, loc, atr) ->
        let n = List.length brs - 1 in
        let lfail, env = env#get_label in
        let lexp, env = env#get_label in
        let env, fe, se = compile_expr false lexp env e in
        let env, _, _, code, fail =
          List.fold_left
            (fun ((env, lab, i, code, continue) as acc) (p, s) ->
              if continue then
                let (lfalse, env), jmp =
                  if i = n then ((lfail, env), [])
                  else (env#get_label, [ JMP l ])
                in
                let env, lfalse', pcode = pattern env lfalse p in
                let blab, env = env#get_label in
                let elab, env = env#get_label in
                let env = env#push_scope blab elab in
                let env, bindcode = bindings env p in
                let env, _, scode = compile_expr tail l env s in
                let env = env#pop_scope in
                ( env,
                  Some lfalse,
                  i + 1,
                  ((match lab with
                   | None -> [ SLABEL blab ]
                   | Some l -> [ SLABEL blab; LABEL l; DUP ])
                  @ pcode @ bindcode @ scode @ jmp @ [ SLABEL elab ])
                  :: code,
                  lfalse' )
              else acc)
            (env, None, 0, [], true) brs
        in
        ( env,
          true,
          se
          @ (if fe then [ LABEL lexp ] else [])
          @ [ DUP ]
          @ (List.flatten @@ List.rev code)
          @ [ JMP l ]
          @
          if fail then [ LABEL lfail; FAIL (loc, atr != Expr.Void); JMP l ]
          else [] )
  in
  let rec compile_fundef env ((name, args, stmt, _) as fd) =
    (* Printf.eprintf "Compile fundef: %s, state=%s\n" name (show(State.t) (show(Value.designation)) st);                *)
    (* Printf.eprintf "st (inner) = %s\n" (try show(Value.designation) @@ State.eval st "inner" with _ -> " not found"); *)
    let blab, env = env#get_label in
    let elab, env = env#get_label in
    let env = env#open_fun_scope blab elab fd in
    (*Printf.eprintf "Lookup: %s\n%!" (try show(Value.designation) @@ snd (env#lookup "inner") with _ -> "no inner..."); *)
    let env = List.fold_left (fun env arg -> env#add_arg arg) env args in
    let lend, env = env#get_end_label in
    let env, _, code = compile_expr true lend env stmt in
    let env, funcode = compile_fundefs [] env in
    (*Printf.eprintf "Function: %s, closure: %s\n%!" name (show(list) (show(Value.designation)) env#closure);*)
    let env = env#register_closure name in
    let nargs, nlocals, closure = (env#nargs, env#nlocals, env#closure) in
    let env, scopes = env#close_fun_scope in
    let code =
      ([
         LABEL name;
         BEGIN (name, nargs, nlocals, closure, args, scopes);
         SLABEL blab;
       ]
      @ code
      @ [ LABEL lend; SLABEL elab; END ])
      :: funcode
    in
    (env, code)
  and compile_fundefs acc env =
    match env#next_definition with
    | None -> (env, acc)
    | Some (env, def) ->
        let env, code = compile_fundef env def in
        compile_fundefs (acc @ code) env
  in
  let fix_closures env prg =
    let rec inner state = function
      | [] -> []
      | BEGIN (f, na, l, c, a, s) :: tl ->
          BEGIN
            (f, na, l, (try env#get_fun_closure f with Not_found -> c), a, s)
          :: inner state tl
      | PROTO (f, c) :: tl ->
          CLOSURE (f, env#get_closure (f, c)) :: inner state tl
      | PPROTO (f, c) :: tl -> (
          match env#get_closure (f, c) with
          | [] -> inner (Some f :: state) tl
          | closure -> CLOSURE (f, closure) :: inner (None :: state) tl)
      | PCALLC (n, tail) :: tl -> (
          match state with
          | None :: state' -> CALLC (n, tail) :: inner state' tl
          | Some f :: state' -> CALL (f, n, tail) :: inner state' tl
          | _ ->
              failwith
                (Printf.sprintf "Unexpected pattern: %s: %d" __FILE__ __LINE__))
      | insn :: tl -> insn :: inner state tl
    in
    inner [] prg
  in
  let env = new env cmd imports in
  let lend, env = env#get_label in
  let env, flag, code = compile_expr false lend env p in
  let code = if flag then code @ [ LABEL lend ] else code in
  let topname = cmd#topname in
  let env, prg =
    compile_fundefs
      [
        [
          LABEL topname;
          BEGIN
            ( topname,
              (if topname = "main" then 2 else 0),
              env#nlocals,
              [],
              [],
              [] );
        ]
        @ code @ [ END ];
      ]
      env
  in
  let prg =
    List.map (fun i -> IMPORT i) imports
    @ [ PUBLIC topname ] @ env#get_decls @ List.flatten prg
  in
  (*Printf.eprintf "Before propagating closures:\n";
    Printf.eprintf "%s\n%!" env#show_funinfo;
  *)
  let env = env#propagate_closures in
  (*
  Printf.eprintf "After propagating closures:\n";
  Printf.eprintf "%s\n%!" env#show_funinfo;
   *)
  (*Printf.eprintf "Before fix:\n%s\n" (show_prg prg);  *)
  let prg = fix_closures env prg in
  cmd#dump_SM prg;
  prg
