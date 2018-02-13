(*
open Expr

(* read x; 
   read y; 
   z = y*y; 
   write (x+z) 
*)
let t = 
  Seq (
    Read "x", 
    Seq (
      Read "y", 
      Seq (
        Assign ("z", Mul (Var "y", Var "y")), 
        Write (Add (Var "x", Var "z"))
      )
    )
  )
    
let _ = match run [2; 3] t with [result] -> Printf.printf "Result: %d\n" result
let _ = try ignore (run [2] t) with Failure s -> Printf.printf "Error: %s\n" s
    
let ( ! ) x = Var x
let ( % ) n = Const n
let ( + ) e1 e2 = Add (e1, e2)
let ( * ) e1 e2 = Mul (e1, e2)
    
let skip         = Skip
let (:=) x e     = Assign (x, e)
let read   x     = Read x
let write  e     = Write e
let (|>)   s1 s2 = Seq (s1, s2)
    
let t = 
  read "x" |> 
  read "y" |> 
  ("z" := !"y" * !"y") |> 
  write (!"x" + !"z")
    
let _ = match run [2; 3] t with [result] -> Printf.printf "Result: %d\n" result
let _ = try ignore (run [2] t) with Failure s -> Printf.printf "Error: %s\n" s

let run input stmt = srun input (compile_stmt stmt)

let _ = match run [2; 3] t with [result] -> Printf.printf "Result: %d\n" result
let _ = try ignore (run [2] t) with Failure s -> Printf.printf "Error: %s\n" s

 *)
