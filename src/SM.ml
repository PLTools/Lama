open GT       
open Language

(* The type for patters *)
@type patt = StrCmp | String | Array | Sexp | Boxed | UnBoxed with show
                                                                          
(* The type for the stack machine instructions *)
@type insn =
(* binary operator                           *) | BINOP   of string
(* put a constant on the stack               *) | CONST   of int
(* put a string on the stack                 *) | STRING  of string
(* create an S-expression                    *) | SEXP    of string * int
(* load a variable to the stack              *) | LD      of string
(* store a variable from the stack           *) | ST      of string
(* store in an array                         *) | STA     of string * int
(* a label                                   *) | LABEL   of string
(* unconditional jump                        *) | JMP     of string
(* conditional jump                          *) | CJMP    of string * string
(* begins procedure definition               *) | BEGIN   of string * string list * string list
(* end procedure definition                  *) | END
(* calls a function/procedure                *) | CALL    of string * int * bool
(* returns from a function                   *) | RET     of bool
(* drops the top element off                 *) | DROP
(* duplicates the top element                *) | DUP
(* swaps two top elements                    *) | SWAP
(* checks the tag and arity of S-expression  *) | TAG     of string * int
(* checks the tag and size of array          *) | ARRAY   of int
(* checks various patterns                   *) | PATT    of patt
(* enters a scope                            *) | ENTER   of string list
(* leaves a scope                            *) | LEAVE
with show
                                                   
(* The type for the stack machine program *)
type prg = insn list

let print_prg p = List.iter (fun i -> Printf.printf "%s\n\!" (show(insn) i)) p
                            
(* The type for the stack machine configuration: control stack, stack and configuration from statement
   interpreter
*)
type config = (prg * State.t) list * Value.t list * Expr.config

(* Stack machine interpreter

     val eval : env -> config -> prg -> config

   Takes an environment, a configuration and a program, and returns a configuration as a result. The
   environment is used to locate a label to jump to (via method env#labeled <label_name>)
*)                                                  
let split n l =
  let rec unzip (taken, rest) = function
  | 0 -> (List.rev taken, rest)
  | n -> let h::tl = rest in unzip (h::taken, tl) (n-1)
  in
  unzip ([], l) n
          
let rec eval env ((cstack, stack, ((st, i, o) as c)) as conf) = function
| [] -> conf
| insn :: prg' ->
   (match insn with
    | BINOP  op               -> let y::x::stack' = stack in eval env (cstack, (Value.of_int @@ Expr.to_func op (Value.to_int x) (Value.to_int y)) :: stack', c) prg'
    | CONST i                 -> eval env (cstack, (Value.of_int i)::stack, c) prg'
    | STRING s                -> eval env (cstack, (Value.of_string s)::stack, c) prg'
    | SEXP (s, n)             -> let vs, stack' = split n stack in                                 
                                 eval env (cstack, (Value.sexp s @@ List.rev vs)::stack', c) prg'
    | LD x                    -> eval env (cstack, State.eval st x :: stack, c) prg'
    | ST x                    -> let z::stack' = stack in eval env (cstack, stack', (State.update x z st, i, o)) prg'
    | STA (x, n)              -> let v::is, stack' = split (n+1) stack in
                                 eval env (cstack, stack', (Language.Stmt.update st x v (List.rev is), i, o)) prg'
    | LABEL  _                -> eval env conf prg'
    | JMP    l                -> eval env conf (env#labeled l)
    | CJMP  (c, l)            -> let x::stack' = stack in eval env (cstack, stack', (st, i, o)) (if (c = "z" && Value.to_int x = 0) || (c = "nz" && Value.to_int x <> 0) then env#labeled l else prg')
    | CALL  (f, n, p)         -> if env#is_label f
                                 then eval env ((prg', st)::cstack, stack, c) (env#labeled f)
                                 else eval env (env#builtin conf f n p) prg'
    | BEGIN (_, args, locals) -> let vs, stack' = split (List.length args) stack in
                                 let state      = List.combine args @@ List.rev vs in
                                 eval env (cstack, stack', (List.fold_left (fun s (x, v) -> State.update x v s) (State.enter st (args @ locals)) state, i, o)) prg'
    | END | RET _             -> (match cstack with
                                  | (prg', st')::cstack' -> eval env (cstack', stack, (State.leave st st', i, o)) prg'
                                  | []                   -> conf
                                 )
    | DROP                    -> eval env (cstack, List.tl stack, c) prg'
    | DUP                     -> eval env (cstack, List.hd stack :: stack, c) prg'
    | SWAP                    -> let x::y::stack' = stack in
                                 eval env (cstack, y::x::stack', c) prg'
    | TAG (t, n)              -> let x::stack' = stack in
                                 eval env (cstack, (Value.of_int @@ match x with Value.Sexp (t', a) when t' = t && List.length a = n -> 1 | _ -> 0) :: stack', c) prg'
    | ARRAY n                 -> let x::stack' = stack in
                                 eval env (cstack, (Value.of_int @@ match x with Value.Array a when List.length a = n -> 1 | _ -> 0) :: stack', c) prg'
    | PATT StrCmp             -> let x::y::stack' = stack in
                                 eval env (cstack, (Value.of_int @@ match x, y with (Value.String xs, Value.String ys) when xs = ys -> 1 | _ -> 0) :: stack', c) prg'                                      
    | PATT Array              -> let x::stack' = stack in
                                 eval env (cstack, (Value.of_int @@ match x with Value.Array _ -> 1 | _ -> 0) :: stack', c) prg'
    | PATT String             -> let x::stack' = stack in
                                 eval env (cstack, (Value.of_int @@ match x with Value.String _ -> 1 | _ -> 0) :: stack', c) prg'
    | PATT Sexp               -> let x::stack' = stack in
                                 eval env (cstack, (Value.of_int @@ match x with Value.Sexp _ -> 1 | _ -> 0) :: stack', c) prg'
    | PATT Boxed              -> let x::stack' = stack in
                                 eval env (cstack, (Value.of_int @@ match x with Value.Int _ -> 0 | _ -> 1) :: stack', c) prg'
    | PATT UnBoxed            -> let x::stack' = stack in
                                 eval env (cstack, (Value.of_int @@ match x with Value.Int _ -> 1 | _ -> 0) :: stack', c) prg'
    | ENTER xs                -> let vs, stack' = split (List.length xs) stack in
                                 eval env (cstack, stack', (State.push st (List.fold_left (fun s (x, v) -> State.bind x v s) State.undefined (List.combine xs vs)) xs, i, o)) prg'
    | LEAVE                   -> eval env (cstack, stack, (State.drop st, i, o)) prg'
   ) 

(* Top-level evaluation

     val run : prg -> int list -> int list

   Takes a program, an input stream, and returns an output stream this program calculates
*)
let run p i =
  (* print_prg p; *)
  let module M = Map.Make (String) in
  let rec make_map m = function
  | []              -> m
  | (LABEL l) :: tl -> make_map (M.add l tl m) tl
  | _ :: tl         -> make_map m tl
  in
  let m = make_map M.empty p in
  let (_, _, (_, _, o)) =
    eval
      (object
         method is_label l = M.mem l m
         method labeled l = M.find l m
         method builtin (cstack, stack, (st, i, o)) f n p =
           let f = match f.[0] with 'L' -> String.sub f 1 (String.length f - 1) | _ -> f in
           let args, stack' = split n stack in
           let (st, i, o, r) = Language.Builtin.eval (st, i, o, None) (List.rev args) f in
           let stack'' = if p then stack' else let Some r = r in r::stack' in
           (*Printf.printf "Builtin:\n";*)
           (cstack, stack'', (st, i, o))
       end
      )
      ([], [], (State.empty, i, []))
      p
  in
  o

(* Stack machine compiler

     val compile : Language.t -> prg

   Takes a program in the source language and returns an equivalent program for the
   stack machine
*)
let compile (defs, p) =
  let label s = "L" ^ s in
  let rec call f args p =
    let args_code = List.concat @@ List.map expr args in
    args_code @ [CALL (label f, List.length args, p)]
  and pattern env lfalse = function
  | Stmt.Pattern.Wildcard        -> env, false, [DROP]
  | Stmt.Pattern.Named   (_, p)  -> pattern env lfalse p
  | Stmt.Pattern.Const   c       -> env, true, [CONST c; BINOP "=="; CJMP ("z", lfalse)]
  | Stmt.Pattern.String  s       -> env, true, [STRING s; PATT StrCmp; CJMP ("z", lfalse)]
  | Stmt.Pattern.ArrayTag        -> env, true, [PATT Array; CJMP ("z", lfalse)]
  | Stmt.Pattern.StringTag       -> env, true, [PATT String; CJMP ("z", lfalse)]
  | Stmt.Pattern.SexpTag         -> env, true, [PATT Sexp; CJMP ("z", lfalse)]
  | Stmt.Pattern.UnBoxed         -> env, true, [PATT UnBoxed; CJMP ("z", lfalse)]
  | Stmt.Pattern.Boxed           -> env, true, [PATT Boxed; CJMP ("z", lfalse)]
  | Stmt.Pattern.Array    ps     ->
     let lhead, env   = env#get_label in
     let ldrop, env   = env#get_label in
     let tag          = [DUP; ARRAY (List.length ps); CJMP ("nz", lhead); LABEL ldrop; DROP; JMP lfalse; LABEL lhead] in
     let code, env    = pattern_list lhead ldrop env ps in
     env, true, tag @ code @ [DROP]
  | Stmt.Pattern.Sexp    (t, ps) ->
     let lhead, env   = env#get_label in
     let ldrop, env   = env#get_label in
     let tag          = [DUP; TAG (t, List.length ps); CJMP ("nz", lhead); LABEL ldrop; DROP; JMP lfalse; LABEL lhead] in
     let code, env    = pattern_list lhead ldrop env ps in
     env, true, tag @ code @ [DROP]
  and pattern_list lhead ldrop env ps =
    let _, env, code =
      List.fold_left
        (fun (i, env, code) p ->
           let env, _, pcode = pattern env ldrop p in
           i+1, env, ([DUP; CONST i; CALL (".elem", 2, false)] @ pcode) :: code
        )
        (0, env, [])
        ps
    in
    List.flatten (List.rev code), env            
  and bindings p =
    let bindings =
      transform(Stmt.Pattern.t)
        (fun fself ->
           object inherit [int list, (string * int list) list, _] @Stmt.Pattern.t 
             method c_Wildcard  path _      = []
             method c_Named     path _ s p  = [s, path] @ fself path p
             method c_Sexp      path _ x ps = List.concat @@ List.mapi (fun i p -> fself (path @ [i]) p) ps
             method c_UnBoxed   _ _         = []
             method c_StringTag _ _         = []
             method c_String    _ _ _       = []
             method c_SexpTag   _ _         = []
             method c_Const     _ _ _       = []
             method c_Boxed     _ _         = []
             method c_ArrayTag  _ _         = []
             method c_Array     path _ ps   = List.concat @@ List.mapi (fun i p -> fself (path @ [i]) p) ps
           end)
        []
        p
    in
    List.concat 
      (List.map
        (fun (name, path) ->
           [DUP] @
           List.concat (List.map (fun i -> [CONST i; CALL (".elem", 2, false)]) path) @
           [SWAP]
        )
        (List.rev bindings)
      ) @
    [DROP; ENTER (List.map fst bindings)]
  and expr = function
  | Expr.Var    x         -> [LD x]
  | Expr.Const  n         -> [CONST n]
  | Expr.String s         -> [STRING s]
  | Expr.Binop (op, x, y) -> expr x @ expr y @ [BINOP op]
  | Expr.Call  (f, args)  -> call f args false
  | Expr.Array  xs        -> List.flatten (List.map expr xs) @ [CALL (".array", List.length xs, false)]
  | Expr.Sexp (t, xs)     -> List.flatten (List.map expr xs) @ [SEXP (t, List.length xs)]
  | Expr.Elem (a, i)      -> expr a @ expr i @ [CALL (".elem", 2, false)]
  | Expr.Length e         -> expr e @ [CALL (".length", 1, false)]
  | Expr.StringVal e      -> expr e @ [CALL (".stringval", 1, false)]
  in
  let rec compile_stmt l env = function  
  | Stmt.Assign (x, [], e)  -> env, false, expr e @ [ST x]
  | Stmt.Assign (x, is, e)  -> env, false, List.flatten (List.map expr (is @ [e])) @ [STA (x, List.length is)]
  | Stmt.Skip               -> env, false, []

  | Stmt.Seq    (s1, s2)    -> let l2, env = env#get_label in
                               let env, flag1, s1 = compile_stmt l2 env s1 in
                               let env, flag2, s2 = compile_stmt l  env s2 in
                               env, flag2, s1 @ (if flag1 then [LABEL l2] else []) @ s2                                      

  | Stmt.If     (c, s1, s2) -> let l2, env = env#get_label in
                               let env, flag1, s1 = compile_stmt l env s1 in
                               let env, flag2, s2 = compile_stmt l env s2 in
                               env, true, expr c @ [CJMP ("z", l2)] @ s1 @ (if flag1 then [] else [JMP l]) @ [LABEL l2] @ s2 @ (if flag2 then [] else [JMP l]) 
                               
  | Stmt.While  (c, s)      -> let loop, env = env#get_label in
                               let cond, env = env#get_label in
                               let env, _, s = compile_stmt cond env s in
                               env, false, [JMP cond; LABEL loop] @ s @ [LABEL cond] @ expr c @ [CJMP ("nz", loop)]
                                                                                                  
  | Stmt.Repeat (s, c)      -> let loop , env = env#get_label in
                               let check, env = env#get_label in
                               let env  , flag, body = compile_stmt check env s in
                               env, false, [LABEL loop] @ body @ (if flag then [LABEL check] else []) @ (expr c) @ [CJMP ("z", loop)]
                                                                                                                     
  | Stmt.Call   (f, args)   -> env, false, call f args true
                                                         
  | Stmt.Return e           -> env, false, (match e with Some e -> expr e | None -> []) @ [RET (e <> None)]

  | Stmt.Leave              -> env, false, [LEAVE]
                                             
  | Stmt.Case (e, [p, s]) ->
     let ldrop, env          = env#get_label in
     let env, ldrop' , pcode = pattern env ldrop p in
     let env, ldrop'', scode = compile_stmt ldrop env (Stmt.Seq (s, Stmt.Leave))  in
     if ldrop' || ldrop''
     then env, true , expr e @ [DUP] @ pcode @ bindings p @ scode @ [JMP l; LABEL ldrop; DROP]
     else env, false, expr e @ [DUP] @ pcode @ bindings p @ scode 
                                    
  | Stmt.Case (e, brs) ->
     let n                  = List.length brs - 1 in
     let env, _, _, code, _ =
       List.fold_left
         (fun ((env, lab, i, code, continue) as acc) (p, s) ->
             if continue
             then
               let (lfalse, env), jmp =
                 if i = n
                 then (l, env), []
                 else env#get_label, [JMP l]
               in
               let env, lfalse', pcode = pattern env lfalse p in
               let env, l'     , scode = compile_stmt l env (Stmt.Seq (s, Stmt.Leave)) in
               (env, Some lfalse, i+1, ((match lab with None -> [] | Some l -> [LABEL l; DUP]) @ pcode @ bindings p @ scode @ jmp) :: code, lfalse')
             else acc
         )
         (env, None, 0, [], true) brs
     in
     env, true, expr e @ [DUP] @ (List.flatten @@ List.rev code) @ [JMP l] 
  in
  let compile_def env (name, (args, locals, stmt)) =
    let lend, env       = env#get_label in
    let env, flag, code = compile_stmt lend env stmt in
    env,
    [LABEL name; BEGIN (name, args, locals)] @
    code @
    (if flag then [LABEL lend] else []) @
    [END]
  in
  let env =
    object
      val ls = 0
      method get_label = (label @@ string_of_int ls), {< ls = ls + 1 >}
    end
  in
  let env, def_code =
    List.fold_left
      (fun (env, code) (name, others) -> let env, code' = compile_def env (label name, others) in env, code'::code)
      (env, [])
      defs
  in
  let lend, env = env#get_label in
  let _, flag, code = compile_stmt lend env p in
  (if flag then code @ [LABEL lend] else code) @ [END] @ (List.concat def_code) 

