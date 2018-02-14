open GT
open Expr
open Embedding

let state ps = List.fold_right (fun (x, v) s -> update x v s) ps empty
let eval s e = Printf.printf "%d\n" (eval s e)
