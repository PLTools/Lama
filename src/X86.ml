open GT

(* X86 codegeneration interface *)

(* The registers: *)
let regs = [|"%ebx"; "%ecx"; "%esi"; "%edi"; "%eax"; "%edx"; "%ebp"; "%esp"|]

(* We can not freely operate with all register; only 3 by now *)
let num_of_regs = Array.length regs - 5

(* We need to know the word size to calculate offsets correctly *)
let word_size = 4;;

(* We need to distinguish the following operand types: *)
@type opnd =
| R of int    (* hard register                    *)
| S of int    (* a position on the hardware stack *)
| M of string (* a named memory location          *)
| L of int    (* an immediate operand             *)
| I of opnd   (* an indirect operand              *)
with show

let show_opnd = show(opnd)

(* For convenience we define the following synonyms for the registers: *)
let ebx = R 0
let ecx = R 1
let esi = R 2
let edi = R 3
let eax = R 4
let edx = R 5
let ebp = R 6
let esp = R 7

(* Now x86 instruction (we do not need all of them): *)
type instr =
(* copies a value from the first to the second operand   *) | Mov   of opnd * opnd
(* loads an address of the first operand into the second *) | Lea   of opnd * opnd
(* makes a binary operation; note, the first operand     *) | Binop of string * opnd * opnd
(* designates x86 operator, not the source language one  *)
(* x86 integer division, see instruction set reference   *) | IDiv  of opnd
(* see instruction set reference                         *) | Cltd
(* sets a value from flags; the first operand is the     *) | Set   of string * string
(* suffix, which determines the value being set, the     *)
(* the second --- (sub)register name                     *)
(* pushes the operand on the hardware stack              *) | Push  of opnd
(* pops from the hardware stack to the operand           *) | Pop   of opnd
(* call a function by a name                             *) | Call  of string
(* returns from a function                               *) | Ret
(* a label in the code                                   *) | Label of string
(* a conditional jump                                    *) | CJmp  of string * string
(* a non-conditional jump                                *) | Jmp   of string
(* directive                                             *) | Meta  of string

(* arithmetic correction: decrement                      *) | Dec   of opnd
(* arithmetic correction: or 0x0001                      *) | Or1   of opnd
(* arithmetic correction: shl 1                          *) | Sal1  of opnd
(* arithmetic correction: shr 1                          *) | Sar1  of opnd
                                                            | Repmovsl
(* Instruction printer *)
let show instr =
  let binop = function
  | "+"   -> "addl"
  | "-"   -> "subl"
  | "*"   -> "imull"
  | "&&"  -> "andl"
  | "!!"  -> "orl"
  | "^"   -> "xorl"
  | "cmp" -> "cmpl"
  | _     -> failwith "unknown binary operator"
  in
  let rec opnd = function
  | R i -> regs.(i)
  | S i -> if i >= 0
           then Printf.sprintf "-%d(%%ebp)" ((i+1) * word_size)
           else Printf.sprintf "%d(%%ebp)"  (8+(-i-1) * word_size)
  | M x -> x
  | L i -> Printf.sprintf "$%d" i
  | I x -> Printf.sprintf "(%s)" (opnd x)
  in
  match instr with
  | Cltd               -> "\tcltd"
  | Set   (suf, s)     -> Printf.sprintf "\tset%s\t%s"     suf s
  | IDiv   s1          -> Printf.sprintf "\tidivl\t%s"     (opnd s1)
  | Binop (op, s1, s2) -> Printf.sprintf "\t%s\t%s,\t%s"   (binop op) (opnd s1) (opnd s2)
  | Mov   (s1, s2)     -> Printf.sprintf "\tmovl\t%s,\t%s" (opnd s1) (opnd s2)
  | Lea   (x,  y)      -> Printf.sprintf "\tleal\t%s,\t%s" (opnd x) (opnd y)
  | Push   s           -> Printf.sprintf "\tpushl\t%s"     (opnd s)
  | Pop    s           -> Printf.sprintf "\tpopl\t%s"      (opnd s)
  | Ret                -> "\tret"
  | Call   p           -> Printf.sprintf "\tcall\t%s" p
  | Label  l           -> Printf.sprintf "%s:\n" l
  | Jmp    l           -> Printf.sprintf "\tjmp\t%s" l
  | CJmp  (s , l)      -> Printf.sprintf "\tj%s\t%s" s l
  | Meta   s           -> Printf.sprintf "%s\n" s
  | Dec    s           -> Printf.sprintf "\tdecl\t%s" (opnd s)
  | Or1    s           -> Printf.sprintf "\torl\t$0x0001,\t%s" (opnd s)
  | Sal1   s           -> Printf.sprintf "\tsall\t%s" (opnd s)
  | Sar1   s           -> Printf.sprintf "\tsarl\t%s" (opnd s)
  | Repmovsl           -> Printf.sprintf "\trep movsl\t"

(* Opening stack machine to use instructions without fully qualified names *)
open SM

(* Symbolic stack machine evaluator

     compile : env -> prg -> env * instr list

   Take an environment, a stack machine program, and returns a pair --- the updated environment and the list
   of x86 instructions
*)
let compile env code =
  (* SM.print_prg code; *)
  flush stdout;
  let suffix = function
  | "<"  -> "l"
  | "<=" -> "le"
  | "==" -> "e"
  | "!=" -> "ne"
  | ">=" -> "ge"
  | ">"  -> "g"
  | _    -> failwith "unknown operator"
  in
  let rec compile' env scode =
    let on_stack = function S _ -> true | _ -> false in
    let mov x s = if on_stack x && on_stack s then [Mov (x, eax); Mov (eax, s)] else [Mov (x, s)]  in
    let call env f n =
      let f =
        match f.[0] with '.' -> "B" ^ String.sub f 1 (String.length f - 1) | _ -> f
      in
      let pushr, popr =
        List.split @@ List.map (fun r -> (Push r, Pop r)) (env#live_registers n)
      in
      let env, code =
        let rec push_args env acc = function
        | 0 -> env, acc
        | n -> let x, env = env#pop in
               push_args env ((Push x)::acc) (n-1)
        in
        let env, pushs = push_args env [] n in
        let pushs      =
          match f with
          | "Barray" -> List.rev @@ (Push (L n)) :: pushs
          | "Bsexp"  -> List.rev @@ (Push (L n)) :: pushs
          | "Bsta"   -> pushs
          | _        -> List.rev pushs
        in
        env, pushr @ pushs @ [Call f; Binop ("+", L (4 * List.length pushs), esp)] @ (List.rev popr)
      in
      let y, env = env#allocate in env, code @ [Mov (eax, y)]
    in
    match scode with
    | [] -> env, []
    | instr :: scode' ->
        let stack = env#show_stack in
        let env', code' =
          match instr with
  	  | CONST n ->
             let s, env' = env#allocate in
	     (env', [Mov (L ((n lsl 1) lor 1), s)])

          | STRING s ->
             let s, env = env#string s in
             let l, env = env#allocate in
             let env, call = call env ".string" 1 in
             (env, Mov (M ("$" ^ s), l) :: call)

          | LDA x ->
             let s, env' = (env#variable x)#allocate in
             env',
             (match s with
	      | S _ | M _ -> [Lea (env'#loc x, eax); Mov (eax, s)]
	      | _         -> [Lea (env'#loc x, s)]
             )

	  | LD x ->
             let s, env' = (env#variable x)#allocate in
             env',
	     (match s with
	      | S _ | M _ -> [Mov (env'#loc x, eax); Mov (eax, s)]
	      | _         -> [Mov (env'#loc x, s)]
	     )

          | ST x ->
	     let env' = env#variable x in
             let s    = env'#peek      in
             env',
             (match s with
              | S _ | M _ -> [Mov (s, eax); Mov (eax, env'#loc x)]
              | _         -> [Mov (s, env'#loc x)]
	     )

          | STA ->
             call env ".sta" 3

	  | STI ->
             let v, x, env' = env#pop2 in
             env'#push x,
             (match x with
              | S _ | M _ -> [Mov (v, edx); Mov (x, eax); Mov (edx, I eax); Mov (edx, x)]
              | _         -> [Mov (v, eax); Mov (eax, I x); Mov (eax, x)]
             )

          | BINOP op ->
	     let x, y, env' = env#pop2 in
             env'#push y,
             (match op with
	      | "/" ->
                 [Mov (y, eax);
                  Sar1 eax;
                  Cltd;
                  (* x := x >> 1 ?? *)
                  Sar1 x; (*!!!*)
                  IDiv x;
                  Sal1 eax;
                  Or1 eax;
                  Mov (eax, y)
                 ]
              | "%" ->
                 [Mov (y, eax);
                  Sar1 eax;
                  Cltd;
                  (* x := x >> 1 ?? *)
                  Sar1 x; (*!!!*)
                  IDiv x;
                  Sal1 edx;
                  Or1  edx;
                  Mov (edx, y)
                 ]
              | "<" | "<=" | "==" | "!=" | ">=" | ">" ->
                 (match x with
                  | M _ | S _ ->
                     [Binop ("^", eax, eax);
                      Mov   (x, edx);
                      Binop ("cmp", edx, y);
                      Set   (suffix op, "%al");
                      Sal1   eax;
                      Or1    eax;
                      Mov   (eax, y)
                     ]
                  | _ ->
                     [Binop ("^"  , eax, eax);
                      Binop ("cmp", x, y);
                      Set   (suffix op, "%al");
                      Sal1   eax;
                      Or1    eax;
                      Mov   (eax, y)
                     ]
                 )
              | "*" ->
                 if on_stack y
                 then [Dec y; Mov (x, eax); Sar1 eax; Binop (op, y, eax); Or1 eax; Mov (eax, y)]
                 else [Dec y; Mov (x, eax); Sar1 eax; Binop (op, eax, y); Or1 y]
	      | "&&" ->
		 [Dec    x; (*!!!*)
                  Mov   (x, eax);
		  Binop (op, x, eax);
		  Mov   (L 0, eax);
		  Set   ("ne", "%al");

                  Dec    y; (*!!!*)
		  Mov   (y, edx);
		  Binop (op, y, edx);
		  Mov   (L 0, edx);
		  Set   ("ne", "%dl");

                  Binop (op, edx, eax);
		  Set   ("ne", "%al");
                  Sal1  eax;
                  Or1   eax;
		  Mov   (eax, y)
                 ]
	      | "!!" ->
		 [Mov   (y, eax);
                  Sar1  eax;
                  Sar1  x; (*!!!*)
		  Binop (op, x, eax);
                  Mov   (L 0, eax);
		  Set   ("ne", "%al");
                  Sal1  eax;
                  Or1   eax;
		  Mov   (eax, y)
                 ]
	      | "+" ->
                 if on_stack x && on_stack y
                 then [Mov   (x, eax); Dec eax; Binop ("+", eax, y)]
                 else [Binop (op, x, y); Dec y]
              | "-" ->
                 if on_stack x && on_stack y
                 then [Mov   (x, eax); Binop (op, eax, y); Or1 y]
                 else [Binop (op, x, y); Or1 y]
             )
          | LABEL s     -> (if env#is_barrier then (env#drop_barrier)#retrieve_stack s else env), [Label s]

	  | JMP   l     -> (env#set_stack l)#set_barrier, [Jmp l]

          | CJMP (s, l) ->
              let x, env = env#pop in
              env#set_stack l, [Sar1 x; (*!!!*) Binop ("cmp", L 0, x); CJmp  (s, l)]

          | BEGIN (f, a, l) ->
             env#assert_empty_stack;
             let env = env#enter f a l in
             env, [Push ebp; Mov (esp, ebp); Binop ("-", M ("$" ^ env#lsize), esp);
                        Mov (esp, edi);
	                Mov (M "$filler", esi);
	                Mov (M ("$" ^ (env#allocated_size)), ecx);
	                Repmovsl
                  ]

          | END ->
             env#endfunc, [Label env#epilogue;
                   Mov (ebp, esp);
                   Pop ebp;
                   Ret;
                   Meta (Printf.sprintf "\t.set\t%s,\t%d" env#lsize (env#allocated * word_size));
                   Meta (Printf.sprintf "\t.set\t%s,\t%d" env#allocated_size env#allocated)
                  ]

          | RET ->
             let x, env = env#pop in
             env, [Mov (x, eax); Jmp env#epilogue]

          | CALL (f, n) -> call env f n

          | SEXP (t, n) ->
             let s, env = env#allocate in
             let env, code = call env ".sexp" (n+1) in
             env, [Mov (L env#hash t, s)] @ code

          | DROP ->
             snd env#pop, []

          | DUP  ->
             let x      = env#peek in
             let s, env = env#allocate in
             env, mov x s

          | SWAP ->
             let x, y = env#peek2 in
             env, [Push x; Push y; Pop x; Pop y]

          | TAG (t, n) ->
             let s1, env = env#allocate in
             let s2, env = env#allocate in
             let env, code = call env ".tag" 3 in
             env, [Mov (L env#hash t, s1); Mov (L n, s2)] @ code

          | ARRAY n ->
             let s, env    = env#allocate in
             let env, code = call env ".array_patt" 2 in
             env, [Mov (L n, s)] @ code

          | PATT StrCmp -> call env ".string_patt" 2

          | PATT patt ->
             call env
               (match patt with
                | Boxed   -> ".boxed_patt"
                | UnBoxed -> ".unboxed_patt"
                | Array   -> ".array_tag_patt"
                | String  -> ".string_tag_patt"
                | Sexp    -> ".sexp_tag_patt"
               ) 1

          | ENTER xs ->
             let env, code =
               List.fold_left
                 (fun (env, code) v ->
                    let s, env = env#pop in
                    env, (mov s @@ env#loc v) :: code
                 )
                 (env#scope @@ List.rev xs, []) xs
             in
             env, List.flatten @@ List.rev code

          | LEAVE -> env#unscope, []
        in
        let env'', code'' = compile' env' scode' in
	env'', [Meta (Printf.sprintf "# %s / % s" (GT.show(SM.insn) instr) stack)] @ code' @ code''
  in
  compile' env code

(* A set of strings *)
module S = Set.Make (String)

(* A map indexed by strings *)
module M = Map.Make (String)

(* Environment implementation *)
class env =
  let chars          = "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" in
  let make_assoc l i = List.combine l (List.init (List.length l) (fun x -> x + i)) in
  let rec assoc  x   = function [] -> raise Not_found | l :: ls -> try List.assoc x l with Not_found -> assoc x ls in
  object (self)
    val globals     = S.empty (* a set of global variables         *)
    val stringm     = M.empty (* a string map                      *)
    val scount      = 0       (* string count                      *)
    val stack_slots = 0       (* maximal number of stack positions *)
    val static_size = 0       (* static data size                  *)
    val stack       = []      (* symbolic stack                    *)
    val args        = []      (* function arguments                *)
    val locals      = []      (* function local variables          *)
    val fname       = ""      (* function name                     *)
    val stackmap    = M.empty (* labels to stack map               *)
    val barrier     = false   (* barrier condition                 *)
    val max_locals_size = 0

    method max_locals_size = max_locals_size

    method endfunc =
      if stack_slots > max_locals_size
      then {< max_locals_size = stack_slots >}
      else self

    method show_stack =
      GT.show(list) (GT.show(opnd)) stack

    method print_locals =
      Printf.printf "LOCALS: size = %d\n" static_size;
      List.iter
        (fun l ->
          Printf.printf "(";
          List.iter (fun (a, i) -> Printf.printf "%s=%d " a i) l;
          Printf.printf ")\n"
        ) locals;
      Printf.printf "END LOCALS\n"

    (* Assert empty stack *)
    method assert_empty_stack = assert (stack = [])

    (* check barrier condition *)
    method is_barrier = barrier

    (* set barrier *)
    method set_barrier = {< barrier = true >}

    (* drop barrier *)
    method drop_barrier = {< barrier = false >}

    (* associates a stack to a label *)
    method set_stack l = (*Printf.printf "Setting stack for %s\n" l;*) {< stackmap = M.add l stack stackmap >}

    (* retrieves a stack for a label *)
    method retrieve_stack l = (*Printf.printf "Retrieving stack for %s\n" l;*)
      try {< stack = M.find l stackmap >} with Not_found -> self

    (* gets a name for a global variable *)
    method loc x =
      try S (- (List.assoc x args)  -  1)
      with Not_found ->
        try S (assoc x locals) with Not_found -> M ("global_" ^ x)

    (* allocates a fresh position on a symbolic stack *)
    method allocate =
      let x, n =
        let rec allocate' = function
        | []                            -> ebx          , 0
        | (S n)::_                      -> S (n+1)      , n+2
        | (R n)::_ when n < num_of_regs -> R (n+1)      , stack_slots
        | _                             -> S static_size, static_size+1
        in
        allocate' stack
      in
      x, {< stack_slots = max n stack_slots; stack = x::stack >}

    (* pushes an operand to the symbolic stack *)
    method push y = {< stack = y::stack >}

    (* pops one operand from the symbolic stack *)
    method pop = let x::stack' = stack in x, {< stack = stack' >}

    (* pops two operands from the symbolic stack *)
    method pop2 = let x::y::stack' = stack in x, y, {< stack = stack' >}

    (* peeks the top of the stack (the stack does not change) *)
    method peek = List.hd stack

    (* peeks two topmost values from the stack (the stack itself does not change) *)
    method peek2 = let x::y::_ = stack in x, y

    (* tag hash: gets a hash for a string tag *)
    method hash tag =
      let h = Pervasives.ref 0 in
      for i = 0 to min (String.length tag - 1) 4 do
        h := (!h lsl 6) lor (String.index chars tag.[i])
      done;
      !h

    (* registers a variable in the environment *)
    method variable x =
      match self#loc x with
      | M name -> {< globals = S.add name globals >}
      | _      -> self

    (* registers a string constant *)
    method string x =
      try M.find x stringm, self
      with Not_found ->
        let y = Printf.sprintf "string_%d" scount in
        let m = M.add x y stringm in
        y, {< scount = scount + 1; stringm = m>}

    (* gets all global variables *)
    method globals = S.elements globals

    (* gets all string definitions *)
    method strings = M.bindings stringm

    (* gets a number of stack positions allocated *)
    method allocated = stack_slots

    method allocated_size = Printf.sprintf "LS%s_SIZE" fname

    (* enters a function *)
    method enter f a l =
      let n = List.length l in
      {< static_size = n; stack_slots = n; stack = []; locals = [make_assoc l 0]; args = make_assoc a 0; fname = f >}

    (* enters a scope *)
    method scope vars =
      let n = List.length vars in
      let static_size' = n + static_size in
      {< stack_slots = max stack_slots static_size'; static_size = static_size'; locals = (make_assoc vars static_size) :: locals >}

    (* leaves a scope *)
    method unscope =
      let n = List.length (List.hd locals) in
      {< static_size = static_size - n; locals = List.tl locals >}

    (* returns a label for the epilogue *)
    method epilogue = Printf.sprintf "L%s_epilogue" fname

    (* returns a name for local size meta-symbol *)
    method lsize = Printf.sprintf "L%s_SIZE" fname

    (* returns a list of live registers *)
    method live_registers depth =
      let rec inner d acc = function
      | []             -> acc
      | (R _ as r)::tl -> inner (d+1) (if d >= depth then (r::acc) else acc) tl
      | _::tl          -> inner (d+1) acc tl
      in
      inner 0 [] stack

  end

(* Generates an assembler text for a program: first compiles the program into
   the stack code, then generates x86 assember code, then prints the assembler file
*)
let genasm (ds, stmt) =
  let stmt =
    Language.Expr.Seq (
        Language.Expr.Ignore (Language.Expr.Call (Language.Expr.Var "__gc_init", [])),
        Language.Expr.Seq (stmt, Language.Expr.Return (Some (Language.Expr.Call (Language.Expr.Var "raw", [Language.Expr.Const 0]))))
      )
  in
  let env, code =
    compile
      (new env)
      ((LABEL "main") :: (BEGIN ("main", [], [])) :: SM.compile (ds, stmt))
  in
  let gc_start, gc_end = "__gc_data_start", "__gc_data_end" in
  let data = [Meta "\t.data";
              Meta (Printf.sprintf "filler:\t.fill\t%d, 4, 1" env#max_locals_size);
              Meta (Printf.sprintf "\t.globl\t%s" gc_start); Meta (Printf.sprintf "\t.globl\t%s" gc_end)] @
             [Meta (Printf.sprintf "%s:" gc_start)] @
             (List.map (fun s      -> Meta (Printf.sprintf "%s:\t.int\t1"         s  )) env#globals) @
             [Meta (Printf.sprintf "%s:" gc_end)] @
             (List.map (fun (s, v) -> Meta (Printf.sprintf "%s:\t.string\t\"%s\"" v s)) env#strings)
  in
  let asm = Buffer.create 1024 in
  List.iter
    (fun i -> Buffer.add_string asm (Printf.sprintf "%s\n" @@ show i))
    (data @ [Meta "\t.text"; Meta "\t.globl\tmain"] @ code);
  Buffer.contents asm

(* Builds a program: generates the assembler file and compiles it with the gcc toolchain *)
let build prog name =
  let outf = open_out (Printf.sprintf "%s.s" name) in
  Printf.fprintf outf "%s" (genasm prog);
  close_out outf;
  let inc = try Sys.getenv "RC_RUNTIME" with _ -> "../runtime" in
  Sys.command (Printf.sprintf "gcc -g -m32 -o %s %s.s %s/runtime.a" name name inc)
