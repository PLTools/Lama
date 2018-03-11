open GT       
open Language
       
(* The type for the stack machine instructions *)
@type insn =
(* binary operator                 *) | BINOP of string
(* put a constant on the stack     *) | CONST of int                 
(* read to stack                   *) | READ
(* write from stack                *) | WRITE
(* load a variable to the stack    *) | LD    of string
(* store a variable from the stack *) | ST    of string
(* a label                         *) | LABEL of string
(* unconditional jump              *) | JMP   of string                                                                                                                
(* conditional jump                *) | CJMP  of string * string with show
                                                   
(* The type for the stack machine program *)                                                               
type prg = insn list

(* The type for the stack machine configuration: a stack and a configuration from statement
   interpreter
 *)
type config = int list * Stmt.config

(* Stack machine interpreter

     val eval : env -> config -> prg -> config

   Takes an environment, a configuration and a program, and returns a configuration as a result. The
   environment is used to locate a label to jump to (via method env#labeled <label_name>)
*)                         
let rec eval env ((stack, ((st, i, o) as c)) as conf) = function
| [] -> conf
| insn :: prg' ->
   (match insn with
    | BINOP op    -> let y::x::stack' = stack in eval env (Expr.to_func op x y :: stack', c) prg'
    | READ        -> let z::i' = i     in eval env (z::stack, (st, i', o)) prg'
    | WRITE       -> let z::stack' = stack in eval env (stack', (st, i, o @ [z])) prg'
    | CONST i     -> eval env (i::stack, c) prg'
    | LD x        -> eval env (st x :: stack, c) prg'
    | ST x        -> let z::stack' = stack in eval env (stack', (Expr.update x z st, i, o)) prg'
    | LABEL _     -> eval env conf prg'
    | JMP   l     -> eval env conf (env#labeled l)
    | CJMP (c, l) -> let x::stack' = stack in eval env conf (if (c = "z" && x = 0) || (c = "nz" && x <> 0) then env#labeled l else prg')
   ) 

(* Top-level evaluation

     val run : prg -> int list -> int list

   Takes a program, an input stream, and returns an output stream this program calculates
*)
let run p i =
  let module M = Map.Make (String) in
  let rec make_map m = function
  | []              -> m
  | (LABEL l) :: tl -> make_map (M.add l tl m) tl
  | _ :: tl         -> make_map m tl
  in
  let m = make_map M.empty p in
  let (_, (_, _, o)) = eval (object method labeled l = M.find l m end) ([], (Expr.empty, i, [])) p in o

(* Stack machine compiler

     val compile : Language.Stmt.t -> prg

   Takes a program in the source language and returns an equivalent program for the
   stack machine
*)
let compile p =
  let rec expr = function
  | Expr.Var   x          -> [LD x]
  | Expr.Const n          -> [CONST n]
  | Expr.Binop (op, x, y) -> expr x @ expr y @ [BINOP op]
  in
  let rec compile' l env = function  
  | Stmt.Read    x          -> env, false, [READ; ST x]
  | Stmt.Write   e          -> env, false, expr e @ [WRITE]
  | Stmt.Assign (x, e)      -> env, false, expr e @ [ST x]
  | Stmt.Skip               -> env, false, []

  | Stmt.Seq    (s1, s2)    -> let l2, env = env#get_label in
                               let env, flag1, s1 = compile' l2 env s1 in
                               let env, flag2, s2 = compile' l  env s2 in
                               env, flag2, s1 @ (if flag1 then [LABEL l2] else []) @ s2                                      

  | Stmt.If     (c, s1, s2) -> let l2, env = env#get_label in
                               let env, flag1, s1 = compile' l env s1 in
                               let env, flag2, s2 = compile' l env s2 in
                               env, true, expr c @ [CJMP ("z", l2)] @ s1 @ (if flag1 then [] else [JMP l]) @ [LABEL l2] @ s2 @ (if flag2 then [] else [JMP l])
                               
  | Stmt.While  (c, s)      -> let loop, env = env#get_label in
                               let cond, env = env#get_label in
                               let env, _, s = compile' cond env s in
                               env, false, [JMP cond; LABEL loop] @ s @ [LABEL cond] @ expr c @ [CJMP ("nz", loop)]
  in
  let env =
    object
      val label = 0
      method get_label = "L_" ^ string_of_int label, {< label = label + 1 >}
    end
  in
  let lend, env = env#get_label in
  let _, flag, code = compile' lend env p in
  if flag then code @ [LABEL lend] else code
