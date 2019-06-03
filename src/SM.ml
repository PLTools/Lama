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
(* load a variable address to the stack      *) | LDA     of string
(* store a value into a variable             *) | ST      of string
(* store a value into a reference            *) | STI
(* store a value into array/sexp/string      *) | STA                                  
(* a label                                   *) | LABEL   of string
(* unconditional jump                        *) | JMP     of string
(* conditional jump                          *) | CJMP    of string * string
(* begins procedure definition               *) | BEGIN   of string * string list * string list
(* end procedure definition                  *) | END
(* calls a function/procedure                *) | CALL    of string * int 
(* returns from a function                   *) | RET     
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

let print_prg p = List.iter (fun i -> Printf.printf "%s\n" (show(insn) i)) p
                            
(* The type for the stack machine configuration: control stack, stack and configuration from statement
   interpreter
*)
type config = (prg * State.t) list * Value.t list * (State.t * int list * int list) 

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
 (*Printf.printf "Stack: %s\n" (show(list) (show(Value.t)) stack); *)
| [] -> conf
| insn :: prg' ->
   (match insn with
    | BINOP  op               -> let y::x::stack' = stack in eval env (cstack, (Value.of_int @@ Expr.to_func op (Value.to_int x) (Value.to_int y)) :: stack', c) prg'
    | CONST i                 -> eval env (cstack, (Value.of_int i)::stack, c) prg'
    | STRING s                -> eval env (cstack, (Value.of_string @@ Bytes.of_string s)::stack, c) prg'
    | SEXP (s, n)             -> let vs, stack' = split n stack in                                 
                                 eval env (cstack, (Value.sexp s @@ List.rev vs)::stack', c) prg'
    | LD x                    -> eval env (cstack, State.eval st x :: stack, c) prg'
    | LDA x                   -> eval env (cstack, (Value.Var x) :: stack, c) prg'
    | ST  x                   -> let z::stack' = stack in eval env (cstack, z::stack', (State.update x z st, i, o)) prg'
    | STI                     -> let z::r::stack' = stack in eval env (cstack, z::stack', (Expr.update st r z, i, o)) prg'
    | STA                     -> let v::j::x::stack' = stack in eval env (cstack, v::stack', (Expr.update st (Value.Elem (x, Value.to_int j)) v, i, o)) prg'
    | LABEL  _                -> eval env conf prg'
    | JMP    l                -> eval env conf (env#labeled l)
    | CJMP  (c, l)            -> let x::stack' = stack in eval env (cstack, stack', (st, i, o)) (if (c = "z" && Value.to_int x = 0) || (c = "nz" && Value.to_int x <> 0) then env#labeled l else prg')
    | CALL  (f, n)            -> if env#is_label f
                                 then eval env ((prg', st)::cstack, stack, c) (env#labeled f)
                                 else eval env (env#builtin conf f n) prg'
    | BEGIN (_, args, locals) -> let vs, stack' = split (List.length args) stack in
                                 let state      = List.combine args @@ List.rev vs in
                                 eval env (cstack, stack', (List.fold_left (fun s (x, v) -> State.update x v s) (State.enter st (args @ locals)) state, i, o)) prg'
    | END                     -> (match cstack with
                                  | (prg', st')::cstack' -> eval env (cstack', Value.Empty :: stack, (State.leave st st', i, o)) prg'
                                  | []                   -> conf
                                 )
  
    | RET                     -> (match cstack with
                                  | (prg', st')::cstack' -> eval env (cstack', stack, (State.leave st st', i, o)) prg'
                                  | []                   -> conf
                                 )
                               
    | DROP                    -> eval env (cstack, List.tl stack, c) prg'
    | DUP                     -> eval env (cstack, List.hd stack :: stack, c) prg'
    | SWAP                    -> let x::y::stack' = stack in
                                 eval env (cstack, y::x::stack', c) prg'
    | TAG (t, n)              -> let x::stack' = stack in
                                 eval env (cstack, (Value.of_int @@ match x with Value.Sexp (t', a) when t' = t && Array.length a = n -> 1 | _ -> 0) :: stack', c) prg'
    | ARRAY n                 -> let x::stack' = stack in
                                 eval env (cstack, (Value.of_int @@ match x with Value.Array a when Array.length a = n -> 1 | _ -> 0) :: stack', c) prg'
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
         method builtin (cstack, stack, (st, i, o)) f n =
           let f = match f.[0] with 'L' -> String.sub f 1 (String.length f - 1) | _ -> f in
           let args, stack' = split n stack in
           let (st, i, o, r) = Language.Builtin.eval (st, i, o, []) (List.rev args) f in
           (*Printf.printf "Builtin:\n";*)
           (cstack, (match r with [r] -> r::stack' | _ -> Value.Empty :: stack'), (st, i, o))
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
  let rec pattern env lfalse = function
  | Pattern.Wildcard        -> env, false, [DROP]
  | Pattern.Named   (_, p)  -> pattern env lfalse p
  | Pattern.Const   c       -> env, true, [CONST c; BINOP "=="; CJMP ("z", lfalse)]
  | Pattern.String  s       -> env, true, [STRING s; PATT StrCmp; CJMP ("z", lfalse)]
  | Pattern.ArrayTag        -> env, true, [PATT Array; CJMP ("z", lfalse)]
  | Pattern.StringTag       -> env, true, [PATT String; CJMP ("z", lfalse)]
  | Pattern.SexpTag         -> env, true, [PATT Sexp; CJMP ("z", lfalse)]
  | Pattern.UnBoxed         -> env, true, [PATT UnBoxed; CJMP ("z", lfalse)]
  | Pattern.Boxed           -> env, true, [PATT Boxed; CJMP ("z", lfalse)]
  | Pattern.Array    ps     ->
     let lhead, env   = env#get_label in
     let ldrop, env   = env#get_label in
     let tag          = [DUP; ARRAY (List.length ps); CJMP ("nz", lhead); LABEL ldrop; DROP; JMP lfalse; LABEL lhead] in
     let code, env    = pattern_list lhead ldrop env ps in
     env, true, tag @ code @ [DROP]
  | Pattern.Sexp    (t, ps) ->
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
           i+1, env, ([DUP; CONST i; CALL (".elem", 2)] @ pcode) :: code
        )
        (0, env, [])
        ps
    in
    List.flatten (List.rev code), env            
  and bindings p =
    let bindings =
      transform(Pattern.t)
        (fun fself ->
           object inherit [int list, _, (string * int list) list] @Pattern.t 
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
           List.concat (List.map (fun i -> [CONST i; CALL (".elem", 2)]) path) @
           [SWAP]
        )
        (List.rev bindings)
      ) @
    [DROP; ENTER (List.map fst bindings)]
  and add_code (env, flag, s) l f s' = env, f, s @ (if flag then [LABEL l] else []) @ s'
  and compile_list l env = function
  | []    -> env, false, []
  | [e]   -> compile_expr l env e
  | e::es ->
     let les, env = env#get_label in
     let env, flag1, s1 = compile_expr les env e  in
     let env, flag2, s2 = compile_list l   env es in
     add_code (env, flag1, s1) les flag2 s2
  and compile_expr l env = function
  | Expr.Unit               -> env, false, [CONST 0]
                               
  | Expr.Ignore   s         -> let ls, env = env#get_label in
                               add_code (compile_expr ls env s) ls false [DROP]                             

  | Expr.ElemRef (x, i)     -> compile_list l env [x; i]                               
  | Expr.Var      x         -> env, false, [LD x]
  | Expr.Ref      x         -> env, false, [LDA x]
  | Expr.Const    n         -> env, false, [CONST n]
  | Expr.String   s         -> env, false, [STRING s]
  | Expr.Binop (op, x, y)   -> let lop, env = env#get_label in
                               add_code (compile_list lop env [x; y]) lop false [BINOP op]
                                 
  | Expr.Call  (f, args)    -> let Expr.Var fn = f in
                               let lcall, env = env#get_label in
                               add_code (compile_list lcall env args) lcall false [CALL (label fn, List.length args)]
                                    
  | Expr.Array  xs          -> let lar, env = env#get_label in
                               add_code (compile_list lar env xs) lar false [CALL (".array", List.length xs)]
                               
  | Expr.Sexp (t, xs)       -> let lsexp, env = env#get_label in
                               add_code (compile_list lsexp env xs) lsexp false [SEXP (t, List.length xs)]
                             
  | Expr.Elem (a, i)        -> let lelem, env = env#get_label in
                               add_code (compile_list lelem env [a; i]) lelem false [CALL (".elem", 2)]
                               
  | Expr.Length e           -> let llen, env = env#get_label in
                               add_code (compile_expr llen env e) llen false [CALL (".length", 1)]
                               
  | Expr.StringVal e        -> let lsv, env = env#get_label in
                               add_code (compile_expr lsv env e) lsv false [CALL (".stringval", 1)]

  | Expr.Assign (x, e)      -> let lassn, env = env#get_label in
                               add_code (compile_list lassn env [x; e]) lassn false [match x with Expr.ElemRef _ -> STA | _ -> STI]
                               (* (match x with
                                *  | Expr.Ref x -> add_code (compile_expr lassn env e) lassn false [ST x]
                                *  | _          -> add_code (compile_list lassn env [x; e]) lassn false [match x with Expr.ElemRef _ -> STA | _ -> STI]) *)
                             
  | Expr.Skip               -> env, false, []

  | Expr.Seq    (s1, s2)    -> compile_list l env [s1; s2]

  | Expr.If     (c, s1, s2) -> let le, env = env#get_label in 
                               let l2, env = env#get_label in
                               let env, fe   , se = compile_expr le env c in
                               let env, flag1, s1 = compile_expr l  env s1 in
                               let env, flag2, s2 = compile_expr l  env s2 in
                               env, true, se @ (if fe then [LABEL le] else []) @ [CJMP ("z", l2)] @ s1 @ (if flag1 then [] else [JMP l]) @ [LABEL l2] @ s2 @ (if flag2 then [] else [JMP l]) 
                               
  | Expr.While  (c, s)      -> let lexp, env = env#get_label in                               
                               let loop, env = env#get_label in
                               let cond, env = env#get_label in
                               let env, fe, se = compile_expr lexp env c in
                               let env, _ , s  = compile_expr cond env s in
                               env, false, [JMP cond; LABEL loop] @ s @ [LABEL cond] @ se @ (if fe then [LABEL lexp] else []) @ [CJMP ("nz", loop)]
                                                                                                  
  | Expr.Repeat (s, c)      -> let lexp , env = env#get_label in
                               let loop , env = env#get_label in
                               let check, env = env#get_label in
                               let env, fe  , se   = compile_expr lexp env c in
                               let env, flag, body = compile_expr check env s in
                               env, false, [LABEL loop] @ body @ (if flag then [LABEL check] else []) @ se @ (if fe then [LABEL lexp] else []) @ [CJMP ("z", loop)]

  | Expr.Return (Some e)    -> let lret, env = env#get_label in
                               add_code (compile_expr lret env e) lret false [RET]
                               
  | Expr.Return None        -> env, false, [CONST 0; RET]

  | Expr.Leave              -> env, false, [LEAVE]
                                             
  | Expr.Case (e, [p, s]) ->
     let lexp , env          = env#get_label in
     let ldrop, env          = env#get_label in
     let env, fe     , se    = compile_expr lexp env e in
     let env, ldrop' , pcode = pattern env ldrop p in
     let env, ldrop'', scode = compile_expr ldrop env (Expr.Seq (s, Expr.Leave))  in
     if ldrop' || ldrop''
     then env, true , se @ (if fe then [LABEL lexp] else []) @ [DUP] @ pcode @ bindings p @ scode @ [JMP l; LABEL ldrop; DROP]
     else env, false, se @ (if fe then [LABEL lexp] else []) @ [DUP] @ pcode @ bindings p @ scode 
                                    
  | Expr.Case (e, brs) ->
     let n         = List.length brs - 1 in
     let lexp, env = env#get_label in
     let env , fe  , se      = compile_expr lexp env e in
     let env , _, _, code, _ =
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
               let env, l'     , scode = compile_expr l env (Expr.Seq (s, Expr.Leave)) in
               (env, Some lfalse, i+1, ((match lab with None -> [] | Some l -> [LABEL l; DUP]) @ pcode @ bindings p @ scode @ jmp) :: code, lfalse')
             else acc
         )
         (env, None, 0, [], true) brs
     in
     env, true, se @ (if fe then [LABEL lexp] else []) @ [DUP] @ (List.flatten @@ List.rev code) @ [JMP l] 
  in
  let compile_def env (name, (args, locals, stmt)) =
    let lend, env       = env#get_label in
    let env, flag, code = compile_expr lend env stmt in
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
  let _, flag, code = compile_expr lend env p in
  (if flag then code @ [LABEL lend] else code) @ [END] @ (List.concat def_code) 
