open GT

@type expr = 
| Const of int 
| Var of string 
| Add of expr * expr 
| Mul of expr * expr with show, html, gmap

let rec eval state expr =
  match expr with
  | Const  n       -> n
  | Var    x       -> state x
  | Add   (e1, e2) -> eval state e1 + eval state e2
  | Mul   (e1, e2) -> eval state e1 * eval state e2
;;

@type stmt =
| Skip
| Assign of string * expr
| Read   of string
| Write  of expr
| Seq    of stmt * stmt with show, html, gmap

let run input stmt = 
  let rec run' (state, output, input) stmt =
    let eval' e = eval (fun x -> List.assoc x state) e in
    match stmt with
    | Skip            -> (state, output, input)
    | Assign (x, e)   -> ((x, eval' e)::state, output, input)
    | Write   e       -> (state, output @ [eval' e], input)
    | Seq    (s1, s2) -> run' (run' (state, output, input) s1) s2
    | Read    x       -> 
	(match input with
	 | []          -> failwith "empty input"
	 | y :: input' -> ((x, y)::state, output, input')
	)
  in
  let (_, output, _) = run' ([], [], input) stmt in
  output
;;

@type instr =
| S_READ 
| S_WRITE
| S_PUSH of int
| S_LD   of string
| S_ST   of string
| S_ADD  
| S_MUL with show, html, gmap

let srun input code =
  let rec srun' (state, stack, input, output) code =
    match code with
    | [] -> output
    | instr :: code' ->
	srun' (match instr with
	       | S_READ   -> (match input with y::input' -> (state, y::stack, input', output      ) | [] -> failwith "empty input"    )
	       | S_WRITE  -> (match stack with y::stack' -> (state, stack'  , input , output @ [y]) | [] -> failwith "stack underflow") 
	       | S_PUSH n -> (state, n::stack, input, output)
	       | S_LD   x -> (state, (List.assoc x state)::stack, input, output)
	       | S_ST   x -> (match stack with y::stack' -> ((x, y)::state, stack, input, output)    | [] -> failwith "stack underflow")
	       | S_ADD    -> (match stack with x::y::stack' -> (state, (y+x)::stack', input, output) | [] -> failwith "stack underflow")
	       | S_MUL    -> (match stack with x::y::stack' -> (state, (y*x)::stack', input, output) | [] -> failwith "stack underflow")
              ) 
	      code'
  in
  srun' ([], [], input, []) code

let rec compile_expr expr =
  match expr with
  | Var    x       -> [S_LD x]
  | Const  n       -> [S_PUSH n]
  | Add   (e1, e2) -> compile_expr e1 @ compile_expr e2 @ [S_ADD]
  | Mul   (e1, e2) -> compile_expr e1 @ compile_expr e2 @ [S_MUL]

let rec compile_stmt stmt =
  match stmt with
  | Skip            -> []
  | Assign (x, e)   -> compile_expr e @ [S_ST x]
  | Read    x       -> [S_READ; S_ST x]
  | Write   e       -> compile_expr e @ [S_WRITE]
  | Seq    (s1, s2) -> compile_stmt s1 @ compile_stmt s2
