(* A deep embedding of simple expressions in OCaml. *)

(* Opening GT yet again. *)
open GT
       
(* Opening the substrate module for convenience. *)
open Syntax

(* Shortcuts for leaf constructors *)
let ( ! ) x = Expr.Var x
let ( !? ) n = Expr.Const n

(* Implementation of operators *)
let binop op x y = Expr.Binop (op, x, y)
                         
let ( +  ) = binop "+"
let ( -  ) = binop "-"
let ( *  ) = binop "*"
let ( /  ) = binop "/"
let ( %  ) = binop "%"
let ( <  ) = binop "<"
let ( <= ) = binop "<="
let ( >  ) = binop ">"
let ( >= ) = binop ">="
let ( == ) = binop "=="
let ( != ) = binop "!="
let ( && ) = binop "&&"
let ( || ) = binop "!!"

let ( =:= ) x e = Stmt.Assign (x, e)
let read  x = Stmt.Read x
let write e = Stmt.Write e
let (|>) x y = Stmt.Seq (x, y)
                             
(* Some predefined names for variables *)
let x = !"x"
let y = !"y"
let z = !"z"
let t = !"t"
