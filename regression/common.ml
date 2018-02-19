open GT
open Syntax
       
let conj = (&&)
             
open Embedding

let state ps = List.fold_right (fun (x, v) (s, p) -> Expr.update x v s, (x =:= !? v) :: p) ps (Expr.empty, [])
let eval  (s, p) e =
  let orig      = Expr.eval s e in
  let stmt      = List.fold_right (fun p s -> p |> s) p (Stmt.Write e) in
  let [s_orig]  = eval [] stmt in
  let [sm_orig] = SM.run [] (SM.compile stmt) in
  if conj (orig = s_orig) (orig = sm_orig)
  then Printf.printf "%d\n" orig
  else Printf.printf "*** divergence: %d <?> %d <?> %d\n" orig s_orig sm_orig
