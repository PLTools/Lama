open GT       
open Language
       
(* The type for the stack machine instructions *)
@type insn =
(* binary operator                 *) | BINOP   of string
(* put a constant on the stack     *) | CONST   of int
(* put a string on the stack       *) | STRING  of string                      
(* load a variable to the stack    *) | LD      of string
(* store a variable from the stack *) | ST      of string
(* store in an array               *) | STA     of string * int
(* a label                         *) | LABEL   of string
(* unconditional jump              *) | JMP     of string
(* conditional jump                *) | CJMP    of string * string
(* begins procedure definition     *) | BEGIN   of string * string list * string list
(* end procedure definition        *) | END
(* calls a function/procedure      *) | CALL    of string * int * bool
(* returns from a function         *) | RET     of bool with show
                                                   
(* The type for the stack machine program *)
type prg = insn list

let print_prg p = List.iter (fun i -> Printf.printf "%s\n" (show(insn) i)) p
                            
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
           Printf.printf "Builtin: %s\n";
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
  and expr = function
  | Expr.Var    x         -> [LD x]
  | Expr.Const  n         -> [CONST n]
  | Expr.String s         -> [STRING s]
  | Expr.Binop (op, x, y) -> expr x @ expr y @ [BINOP op]
  | Expr.Call  (f, args)  -> call f args false
  | Expr.Array  xs        -> List.flatten (List.map expr xs) @ [CALL ("$array", List.length xs, false)]
  | Expr.Elem (a, i)      -> expr a @ expr i @ [CALL ("$elem", 2, false)]
  | Expr.Length e         -> expr e @ [CALL ("$length", 1, false)]
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

