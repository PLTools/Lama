open GT
open Language

(* X86 codegeneration interface *)

(* The registers: *)
(* let regs = [| "%ebx"; "%ecx"; "%esi"; "%edi"; "%eax"; "%edx"; "%ebp"; "%esp" |] *)
(* Registers %rbp, %rbx and %r12 through %r15 “belong” to the calling function and the called function is required to preserve their values.  *)

let temp_regs = [| "%r10"; "%r11"; "%r12"; "%r13"; "%r14"; "%r15"; "%rbx" |]
(* "%r16";
   "%r17";
   "%r18";
   "%r19";
   "%r20";
   "%r21";
   "%r22";
   "%r23";
   "%r24";
   "%r25";
   "%r26";
   "%r27";
   "%r28";
   "%r29";
   "%r30";
   "%r31"; *)

(* rbx --- callee-saved *)
(* callee-saved *)
(* let callee_saved_regs = [| "%rbx"; "%r15"; "%r12"; "%r13"; "%r14" |] *)
let callee_saved_regs = [||]

(* rax preserved for return value and temporal values *)
(* rdx used to pass 3rd argument to functions; 2nd return register (we do not use it) *)
(* rbp --- base pointer; callee-saved *)
let args_regs = [| "%rdi"; "%rsi"; "%rdx"; "%rcx"; "%r8"; "%r9" |]

let regs =
  Array.append
    (Array.append (Array.append temp_regs callee_saved_regs) args_regs)
    [| "%rax"; "%rbp"; "%rsp" |]

(* We can not freely operate with all register; only 3 by now *)
(* let num_of_regs = Array.length regs - 5 *)
(* let num_of_regs = Array.length regs *)
let num_of_regs = Array.length temp_regs
let max_free_arg_regs = Array.length args_regs

(* Simpliest algo:
   1. Temporary registers are used for register allocation
   1.1. We save all alive temp registers before function call (I guess)
   2. args_regs are used to pass arguments
   3. rax is used for return value and special temporary register *)

(* We need to know the word size to calculate offsets correctly *)
(* let word_size = 4 *)
let word_size = 8

(* We need to distinguish the following operand types: *)
type opnd =
  | R of int (* hard register                    *)
  | S of int (* a position on the hardware stack *)
  | C (* a saved closure                  *)
  | M of string (* a named memory location          *)
  | L of int (* an immediate operand             *)
  | I of int * opnd (* an indirect operand with offset  *)
[@@deriving gt ~options:{ show }]

let show_opnd = show opnd

(* For convenience we define the following synonyms for the registers: *)
(* TODO: fix *)
let args_regs_ind =
  [|
    Array.length regs - 9;
    Array.length regs - 8;
    Array.length regs - 7;
    Array.length regs - 6;
    Array.length regs - 5;
    Array.length regs - 4;
  |]

let r10 = R 0
let rbx = R 6
let rcx = R (Array.length regs - 6)
let r8 = R (Array.length regs - 5)
let r9 = R (Array.length regs - 4)
let rsi = R (Array.length regs - 8)
let rdi = R (Array.length regs - 9)
let rax = R (Array.length regs - 3)
let rdx = R (Array.length regs - 7)
let rbp = R (Array.length regs - 2)
let rsp = R (Array.length regs - 1)

(* Now x86 instruction (we do not need all of them): *)
type instr =
  (* copies a value from the first to the second operand   *)
  | Mov of opnd * opnd
  (* loads an address of the first operand into the second *)
  | Lea of opnd * opnd
  (* makes a binary operation; note, the first operand     *)
  | Binop of string * opnd * opnd
  (* designates x86 operator, not the source language one  *)
  (* x86 integer division, see instruction set reference   *)
  | IDiv of opnd
  (* see instruction set reference                         *)
  | Cltd
  (* sets a value from flags; the first operand is the     *)
  | Set of string * string
  (* suffix, which determines the value being set, the     *)
  (* the second --- (sub)register name                     *)
  (* pushes the operand on the hardware stack              *)
  | Push of opnd
  (* pops from the hardware stack to the operand           *)
  | Pop of opnd
  (* call a function by a name                             *)
  | Call of string
  (* call a function by indirect address                   *)
  | CallI of opnd
  (* returns from a function                               *)
  | Ret
  (* a label in the code                                   *)
  | Label of string
  (* a conditional jump                                    *)
  | CJmp of string * string
  (* a non-conditional jump                                *)
  | Jmp of string
  (* directive                                             *)
  | Meta of string
  (* arithmetic correction: decrement                      *)
  | Dec of opnd
  (* arithmetic correction: or 0x0001                      *)
  | Or1 of opnd
  (* arithmetic correction: shl 1                          *)
  | Sal1 of opnd
  (* arithmetic correction: shr 1                          *)
  | Sar1 of opnd
  | Repmovsl

(* Instruction printer *)
let stack_offset i =
  if i >= 0 then (i + 1) * word_size else 8 + ((-i - 1) * word_size)

let show instr =
  let rec opnd = function
    | R i -> regs.(i)
    (* | C -> "4(%ebp)" *)
    | C -> Printf.sprintf "%d(%%rbp)" word_size
    | S i ->
        if i >= 0 then Printf.sprintf "-%d(%%rbp)" (stack_offset i)
        else Printf.sprintf "%d(%%rbp)" (stack_offset i)
    | M x -> x
    | L i -> Printf.sprintf "$%d" i
    | I (0, x) -> Printf.sprintf "(%s)" (opnd x)
    | I (n, x) -> Printf.sprintf "%d(%s)" n (opnd x)
  in
  let binop = function
    | "+" -> "add"
    | "-" -> "sub"
    | "*" -> "imul"
    | "&&" -> "and"
    | "!!" -> "or"
    | "^" -> "xor"
    | "cmp" -> "cmp"
    | "test" -> "test"
    | _ -> failwith "unknown binary operator"
  in
  match instr with
  | Cltd -> "\tcqo"
  | Set (suf, s) -> Printf.sprintf "\tset%s\t%s" suf s
  | IDiv s1 -> Printf.sprintf "\tidivq\t%s" (opnd s1)
  | Binop (op, s1, s2) ->
      Printf.sprintf "\t%s\t%s,\t%s" (binop op) (opnd s1) (opnd s2)
  | Mov (s1, s2) -> Printf.sprintf "\tmovq\t%s,\t%s" (opnd s1) (opnd s2)
  | Lea (x, y) -> Printf.sprintf "\tlea\t%s,\t%s" (opnd x) (opnd y)
  | Push s -> Printf.sprintf "\tpushq\t%s" (opnd s)
  | Pop s -> Printf.sprintf "\tpopq\t%s" (opnd s)
  | Ret -> "\tret"
  | Call p -> Printf.sprintf "\tcall\t%s" p
  | CallI o -> Printf.sprintf "\tcall\t*(%s)" (opnd o)
  | Label l -> Printf.sprintf "%s:\n" l
  | Jmp l -> Printf.sprintf "\tjmp\t%s" l
  | CJmp (s, l) -> Printf.sprintf "\tj%s\t%s" s l
  | Meta s -> Printf.sprintf "%s\n" s
  | Dec s -> Printf.sprintf "\tdec\t%s" (opnd s)
  | Or1 s -> Printf.sprintf "\tor\t$0x0001,\t%s" (opnd s)
  | Sal1 s -> Printf.sprintf "\tsal\t%s" (opnd s)
  | Sar1 s -> Printf.sprintf "\tsar\t%s" (opnd s)
  | Repmovsl -> Printf.sprintf "\trep movsq\t"

(* Opening stack machine to use instructions without fully qualified names *)
open SM

(* Symbolic stack machine evaluator

     compile : env -> prg -> env * instr list

   Take an environment, a stack machine program, and returns a pair --- the updated environment and the list
   of x86 instructions
*)
let compile cmd env imports code =
  (* SM.print_prg code; *)
  flush stdout;
  let suffix = function
    | "<" -> "l"
    | "<=" -> "le"
    | "==" -> "e"
    | "!=" -> "ne"
    | ">=" -> "ge"
    | ">" -> "g"
    | _ -> failwith "unknown operator"
  in
  let box n = (n lsl 1) lor 1 in
  let rec compile' env scode =
    let on_stack = function S _ -> true | _ -> false in
    let mov x s =
      if on_stack x && on_stack s then [ Mov (x, rax); Mov (rax, s) ]
      else [ Mov (x, s) ]
    in
    let callc env n tail =
      failwith (Printf.sprintf "Not implemented %s: %d" __FILE__ __LINE__)
    in
    let trololo env n tail =
      let tail = tail && env#nargs = n in
      if tail then
        let rec push_args env acc = function
          | 0 -> (env, acc)
          | n ->
              let x, env = env#pop in
              if x = env#loc (Value.Arg (n - 1)) then push_args env acc (n - 1)
              else
                push_args env (mov x (env#loc (Value.Arg (n - 1))) @ acc) (n - 1)
        in
        let env, pushs = push_args env [] n in
        let closure, env = env#pop in
        let _, env = env#allocate in
        ( env,
          pushs
          @ [
              Mov (closure, rdx); Mov (I (0, rdx), rax); Mov (rbp, rsp); Pop rbp;
            ]
          @ (if env#has_closure then [ Pop rbx ] else [])
          @ [ Jmp "*%eax" ] ) (* UGLY!!! *)
      else
        let pushr, popr =
          List.split
          @@ List.map (fun r -> (Push r, Pop r)) (env#live_registers n)
        in
        let pushr, popr = (env#save_closure @ pushr, env#rest_closure @ popr) in
        let env, code =
          let rec push_args env acc = function
            | 0 -> (env, acc)
            | n ->
                let x, env = env#pop in
                push_args env (Push x :: acc) (n - 1)
          in
          let env, pushs = push_args env [] n in
          let pushs = List.rev pushs in
          let closure, env = env#pop in
          let call_closure =
            if on_stack closure then
              [ Mov (closure, rdx); Mov (rdx, rax); CallI rax ]
            else [ Mov (closure, rdx); CallI closure ]
          in
          ( env,
            pushr @ pushs @ call_closure
            @ [ Binop ("+", L (word_size * List.length pushs), rsp) ]
            @ List.rev popr )
        in
        let y, env = env#allocate in
        (env, code @ [ Mov (rax, y) ])
    in
    let call env f n tail =
      let tail = tail && env#nargs = n && f.[0] <> '.' in
      let f =
        match f.[0] with
        | '.' -> "B" ^ String.sub f 1 (String.length f - 1)
        | _ -> f
      in
      (* TODO *)
      (* if tail then
           (* failwith (Printf.sprintf "Not implemented %s: %d" __FILE__ __LINE__) *)
           let rec push_args env acc = function
             | 0 -> (env, acc)
             | n ->
                 (* TODO *)
                 let x, env = env#pop in
                 if x = env#loc (Value.Arg (n - 1)) then push_args env acc (n - 1)
                 else
                   push_args env (mov x (env#loc (Value.Arg (n - 1))) @ acc) (n - 1)
           in
           let env, pushs = push_args env [] n in
           let _, env = env#allocate in
           ( env,
             pushs
             @ [ Mov (rbp, rsp); Pop rbp ]
             @ (if env#has_closure then [ Pop rbx ] else [])
             @ [ Jmp f ] )
         else *)
      let pushr, popr =
        List.split @@ List.map (fun r -> (Push r, Pop r)) (env#live_registers n)
      in
      let pushr, popr = (env#save_closure @ pushr, env#rest_closure @ popr) in
      let env, code =
        let stack_slots, env, pushs =
          let rec popn env acc = function
            | 0 -> (env, acc)
            | n ->
                let t, env = env#pop in
                popn env (t :: acc) (n - 1)
          in
          let push_args2 env args =
            let rec push_args' env acc stack_slots_acc = function
              | [] -> (stack_slots_acc, env, acc)
              | arg :: args -> (
                  let y, env = env#pop_for_arg_2 in
                  match y with
                  | R _ ->
                      push_args' env (Mov (arg, y) :: acc) stack_slots_acc args
                  | L 0 ->
                      push_args' env (Push arg :: acc) (stack_slots_acc + 1)
                        args
                  | _ ->
                      failwith
                        (Printf.sprintf "Should never happend %s: %d" __FILE__
                           __LINE__))
            in
            push_args' env [] 0 args
          in
          let fix_locs locs =
            match f with
            | "Bsta" -> List.rev locs
            | "Barray" -> L (box n) :: locs
            | "Bsexp" -> L (box n) :: locs
            | _ -> locs
          in
          (*TODO B functions!*)
          let env, locs = popn env [] n in
          let locs = fix_locs locs in
          let stack_slots, env, pushsc = push_args2 env locs in
          (stack_slots, env, pushsc)
        in
        (* (* TODO: wrong arguments order *)
           let push_args env acc n =
             let rec push_args' env acc = function
               | 0 -> (env, acc)
               | 1 when String.equal f "Bsexp" ->
                   let y, env = env#pop_for_arg 1 in
                   (env, Mov (L (box n), y) :: acc)
               | n -> (
                   let x, env = env#pop in
                   let y, env = env#pop_for_arg n in
                   match y with
                   | R _ -> push_args' env (Mov (x, y) :: acc) (n - 1)
                   | _ ->
                       failwith
                         (Printf.sprintf "Not implemented %s: %d" __FILE__ __LINE__)
                   (* push_args env (Push x :: acc) (n - 1)) *))
             in
             match f with
             | "Bsexp" -> push_args' env [] (n + 1)
             | _ -> push_args' env [] n
           in
           let env, pushs = push_args env [] n in
           (* TODO: rdi!!!! look above
              let pushs =
                match f with
                | "Barray" -> List.rev @@ (Push (L (box n)) :: pushs)
                (* | "Bsexp" -> List.rev @@ (Push (L (box n)) :: pushs) *)
                | "Bsexp" -> List.rev @@ (Mov (L (box n), rdi) :: pushs)
                | "Bsta" -> pushs
                | _ -> List.rev pushs
              in *)
        *)
        (* TODO: we have to know if stack is aligned *)
        let aligned, align_prologue, align_epilogue =
          ( List.length pushr mod 2 == 0,
            [ Binop ("-", L 8, rsp) ],
            [ Binop ("+", L 8, rsp) ] )
        in
        let push_arg_registers =
          [ Push rdi; Push rsi; Push rdx; Push rcx; Push r8; Push r9 ]
        in
        let pop_arg_registers =
          [ Pop r9; Pop r8; Pop rcx; Pop rdx; Pop rsi; Pop rdi ]
        in
        let nullify_argument_registers, _ =
          Array.fold_left
            (fun (acc, i) a ->
              if i < max_free_arg_regs - env#get_n_free_arg_regs then
                (acc, i + 1)
              else (acc @ [ R a ], i + 1))
            ([], 0) args_regs_ind
        in
        ( env#restore_n_free_arg_regs,
          pushr
          (* @ List.map (fun a -> Mov (L 0, a)) nullify_argument_registers *)
          @ push_arg_registers
          @ (if not aligned then align_prologue else [])
          @ pushs
          (* TODO *)
          (* @ [ Call f; Binop ("+", L (word_size * List.length pushs), rsp) ] *)
          (* TODO: stack has to be aligned by 16!!! i.e. two words *)
          (* @ [ Push (L 0); Call f; Binop ("+", L word_size, rsp) ] *)
          @ [ Call f ]
          (* @ (if env#get_n_free_arg_regs == 0 then
               [
                 Binop
                   ( "+",
                     L ((word_size * List.length pushs) - max_free_arg_regs),
                     rsp );
               ]
             else []) *)
          @ (if not aligned then align_epilogue else [])
          @ (if stack_slots != 0 then
               [ Binop ("+", L (word_size * stack_slots), rsp) ]
             else [])
          @ pop_arg_registers @ List.rev popr )
      in
      let y, env = env#allocate in
      (env, code @ [ Mov (rax, y) ])
    in
    match scode with
    | [] -> (env, [])
    | instr :: scode' ->
        let stack = "" (* env#show_stack*) in
        (* Printf.printf "insn=%s, stack=%s\n%!" (GT.show(insn) instr) (env#show_stack);   *)
        let env', code' =
          if env#is_barrier then
            match instr with
            | LABEL s ->
                if env#has_stack s then
                  (env#drop_barrier#retrieve_stack s, [ Label s ])
                else (env#drop_stack, [])
            | FLABEL s -> (env#drop_barrier, [ Label s ])
            | SLABEL s -> (env, [ Label s ])
            | _ -> (env, [])
          else
            match instr with
            | PUBLIC name -> (env#register_public name, [])
            | EXTERN name -> (env#register_extern name, [])
            | IMPORT _ -> (env, [])
            | CLOSURE (name, closure) ->
                let pushr, popr =
                  List.split
                  @@ List.map (fun r -> (Push r, Pop r)) (env#live_registers 0)
                in
                let closure_len = List.length closure in
                let push_closure =
                  List.map (fun d -> Push (env#loc d)) @@ List.rev closure
                in
                let s, env = env#allocate in
                ( env,
                  pushr @ push_closure
                  @ [
                      Push (M ("$" ^ name));
                      Push (L (box closure_len));
                      Call "Bclosure";
                      Binop ("+", L (word_size * (closure_len + 2)), rsp);
                      Mov (rax, s);
                    ]
                  @ List.rev popr @ env#reload_closure )
            | CONST n ->
                let s, env' = env#allocate in
                (env', [ Mov (L (box n), s) ])
            | STRING s ->
                let s, env = env#string s in
                let l, env = env#allocate in
                let env, call = call env ".string" 1 false in
                (env, Mov (M ("$" ^ s), l) :: call)
            | LDA x ->
                let s, env' = (env#variable x)#allocate in
                let s', env'' = env'#allocate in
                (env'', [ Lea (env'#loc x, rax); Mov (rax, s); Mov (rax, s') ])
            | LD x -> (
                let s, env' = (env#variable x)#allocate in
                ( env',
                  match s with
                  | S _ | M _ -> [ Mov (env'#loc x, rax); Mov (rax, s) ]
                  | _ -> [ Mov (env'#loc x, s) ] ))
            | ST x -> (
                let env' = env#variable x in
                let s = env'#peek in
                ( env',
                  match s with
                  | S _ | M _ -> [ Mov (s, rax); Mov (rax, env'#loc x) ]
                  | _ -> [ Mov (s, env'#loc x) ] ))
            | STA -> call env ".sta" 3 false
            | STI -> (
                let v, x, env' = env#pop2 in
                ( env'#push x,
                  match x with
                  | S _ | M _ ->
                      [
                        Mov (v, rdx);
                        Mov (x, rax);
                        Mov (rdx, I (0, rax));
                        Mov (rdx, x);
                      ]
                      @ env#reload_closure
                  | _ -> [ Mov (v, rax); Mov (rax, I (0, x)); Mov (rax, x) ] ))
            | BINOP op -> (
                let x, y, env' = env#pop2 in
                ( env'#push y,
                  (* (match op with
                     |"<" | "<=" | "==" | "!=" | ">=" | ">" ->
                      [Push (eax);
                      Push (edx);
                      Mov (y, eax);
                      Binop("&&", L(1), eax);
                      Mov (x, edx);
                      Binop("&&", L(1), edx);
                      Binop("cmp", eax, edx);
                      CJmp ("nz", "_ERROR2");
                      Pop (edx);
                      Pop (eax)]
                     (* | "+" | "-" | "*" | "/" -> *)
                     | _ ->
                     [Mov (y, eax);
                      Binop("&&", L(1), eax);
                      Binop("cmp", L(0), eax);
                      CJmp ("z", "_ERROR");
                      Mov (x, eax);
                      Binop("&&", L(1), eax);
                      Binop("cmp", L(0), eax);
                      CJmp ("z", "_ERROR")]
                      | _ -> []) @ *)
                  match op with
                  | "/" ->
                      [
                        Mov (y, rax);
                        Sar1 rax;
                        Binop ("^", rdx, rdx);
                        Cltd;
                        Sar1 x;
                        IDiv x;
                        Sal1 rax;
                        Or1 rax;
                        Mov (rax, y);
                      ]
                      (* [
                           Mov (y, rax);
                           Sar1 rax;
                           Cltd;
                           (* x := x >> 1 ?? *)
                           Sar1 x;
                           (*!!!*)
                           IDiv x;
                           Sal1 rax;
                           Or1 rax;
                           Mov (rax, y);
                         ] *)
                  | "%" ->
                      [
                        Mov (y, rax);
                        Sar1 rax;
                        Cltd;
                        (* x := x >> 1 ?? *)
                        Sar1 x;
                        (*!!!*)
                        IDiv x;
                        Sal1 rdx;
                        Or1 rdx;
                        Mov (rdx, y);
                      ]
                      @ env#reload_closure
                  | "<" | "<=" | "==" | "!=" | ">=" | ">" -> (
                      match x with
                      | M _ | S _ ->
                          [
                            Binop ("^", rax, rax);
                            Mov (x, rdx);
                            Binop ("cmp", rdx, y);
                            Set (suffix op, "%al");
                            Sal1 rax;
                            Or1 rax;
                            Mov (rax, y);
                          ]
                          @ env#reload_closure
                      | _ ->
                          [
                            Binop ("^", rax, rax);
                            (* TODO: WTF?!?: why are they in wrong order?!? *)
                            Binop ("cmp", x, y);
                            (* Binop ("cmp", y, x); *)
                            Set (suffix op, "%al");
                            Sal1 rax;
                            Or1 rax;
                            Mov (rax, y);
                          ])
                  | "*" ->
                      if on_stack y then
                        [
                          Dec y;
                          Mov (x, rax);
                          Sar1 rax;
                          Binop (op, y, rax);
                          Or1 rax;
                          Mov (rax, y);
                        ]
                      else
                        [
                          Dec y;
                          Mov (x, rax);
                          Sar1 rax;
                          Binop (op, rax, y);
                          Or1 y;
                        ]
                  | "&&" ->
                      [
                        Dec x;
                        (*!!!*)
                        Mov (x, rax);
                        Binop (op, x, rax);
                        Mov (L 0, rax);
                        Set ("ne", "%al");
                        Dec y;
                        (*!!!*)
                        Mov (y, rdx);
                        Binop (op, y, rdx);
                        Mov (L 0, rdx);
                        Set ("ne", "%dl");
                        Binop (op, rdx, rax);
                        Set ("ne", "%al");
                        Sal1 rax;
                        Or1 rax;
                        Mov (rax, y);
                      ]
                      @ env#reload_closure
                  | "!!" ->
                      [
                        Mov (y, rax);
                        Sar1 rax;
                        Sar1 x;
                        (*!!!*)
                        Binop (op, x, rax);
                        Mov (L 0, rax);
                        Set ("ne", "%al");
                        Sal1 rax;
                        Or1 rax;
                        Mov (rax, y);
                      ]
                  | "+" ->
                      if on_stack x && on_stack y then
                        [ Mov (x, rax); Dec rax; Binop ("+", rax, y) ]
                      else [ Binop (op, x, y); Dec y ]
                  | "-" ->
                      if on_stack x && on_stack y then
                        [ Mov (x, rax); Binop (op, rax, y); Or1 y ]
                      else [ Binop (op, x, y); Or1 y ]
                  | _ ->
                      failwith
                        (Printf.sprintf "Unexpected pattern: %s: %d" __FILE__
                           __LINE__) ))
            | LABEL s | FLABEL s | SLABEL s -> (env, [ Label s ])
            | JMP l -> ((env#set_stack l)#set_barrier, [ Jmp l ])
            | CJMP (s, l) ->
                let x, env = env#pop in
                ( env#set_stack l,
                  [ Sar1 x; (*!!!*) Binop ("cmp", L 0, x); CJmp (s, l) ] )
            | BEGIN (f, nargs, nlocals, closure, args, scopes) ->
                let rec stabs_scope scope =
                  let names =
                    List.map
                      (fun (name, index) ->
                        Meta
                          (Printf.sprintf "\t.stabs \"%s:1\",128,0,0,-%d" name
                             (stack_offset index)))
                      scope.names
                  in
                  names
                  @ (if names = [] then []
                     else
                       [
                         Meta
                           (Printf.sprintf "\t.stabn 192,0,0,%s-%s" scope.blab f);
                       ])
                  @ (List.flatten @@ List.map stabs_scope scope.subs)
                  @
                  if names = [] then []
                  else
                    [
                      Meta
                        (Printf.sprintf "\t.stabn 224,0,0,%s-%s" scope.elab f);
                    ]
                in
                let name =
                  if f.[0] = 'L' then String.sub f 1 (String.length f - 1)
                  else f
                in
                env#assert_empty_stack;
                let has_closure = closure <> [] in
                let env = env#enter f nargs nlocals has_closure in
                ( env,
                  [ Meta (Printf.sprintf "\t.type %s, @function" name) ]
                  @ (if f = "main" then []
                     else
                       [
                         Meta
                           (Printf.sprintf "\t.stabs \"%s:F1\",36,0,0,%s" name f);
                       ]
                       @ List.mapi
                           (fun i a ->
                             Meta
                               (Printf.sprintf "\t.stabs \"%s:p1\",160,0,0,%d" a
                                  ((i * 4) + 8)))
                           args
                       @ List.flatten
                       @@ List.map stabs_scope scopes)
                  @ [ Meta "\t.cfi_startproc" ]
                  @ (if has_closure then [ Push rdx ] else [])
                  @ (if f = cmd#topname then
                       [
                         Mov (M "_init", rax);
                         Binop ("test", rax, rax);
                         CJmp ("z", "_continue");
                         Ret;
                         Label "_ERROR";
                         Call "Lbinoperror";
                         Ret;
                         Label "_ERROR2";
                         Call "Lbinoperror2";
                         Ret;
                         Label "_continue";
                         Mov (L 1, M "_init");
                       ]
                     else [])
                  @ [
                      Push rbp;
                      Meta
                        ("\t.cfi_def_cfa_offset\t"
                        ^ if has_closure then "12" else "8");
                      Meta
                        ("\t.cfi_offset 5, -"
                        ^ if has_closure then "12" else "8");
                      Mov (rsp, rbp);
                      Meta "\t.cfi_def_cfa_register\t5";
                      Binop ("-", M ("$" ^ env#lsize), rsp);
                      (*TODO*)
                      (* Mov (rsp, edi);
                         Mov (M "$filler", rsi);
                         Mov (M ("$" ^ env#allocated_size), rcx);
                         Repmovsl; *)
                    ]
                  @ (if f = "main" then
                       (* TODO: numbers! *)
                       [
                         Call "__gc_init";
                         (*
                            Push (I (12, rbp));
                            Push (I (8, rbp));
                            Call "set_args";
                            Binop ("+", L 8, rsp); *)
                       ]
                     else [])
                  @
                  if f = cmd#topname then
                    List.map
                      (fun i -> Call ("init" ^ i))
                      (List.filter (fun i -> i <> "Std") imports)
                  else [] )
            | END ->
                let x, env = env#pop in
                env#assert_empty_stack;
                let name = env#fname in
                ( env#leave,
                  [
                    Mov (x, rax);
                    (*!!*)
                    Label env#epilogue;
                    Mov (rbp, rsp);
                    Pop rbp;
                  ]
                  @ env#rest_closure
                  @ (if name = "main" then [ Binop ("^", rax, rax) ] else [])
                  @ [
                      Meta "\t.cfi_restore\t5";
                      Meta "\t.cfi_def_cfa\t4, 4";
                      Ret;
                      Meta "\t.cfi_endproc";
                      Meta
                        (Printf.sprintf "\t.set\t%s,\t%d" env#lsize
                           (if env#allocated * word_size mod 16 == 0 then
                              env#allocated * word_size
                            else 8 + (env#allocated * word_size)));
                      Meta
                        (Printf.sprintf "\t.set\t%s,\t%d" env#allocated_size
                           env#allocated);
                      Meta (Printf.sprintf "\t.size %s, .-%s" name name);
                    ] )
            | RET ->
                let x = env#peek in
                (env, [ Mov (x, rax); Jmp env#epilogue ])
            | ELEM -> call env ".elem" 2 false
            | CALL (f, n, tail) -> call env f n tail
            | CALLC (n, tail) -> callc env n tail
            | SEXP (t, n) ->
                let s, env = env#allocate in
                let env, code = call env ".sexp" (n + 1) false in
                (env, [ Mov (L (box (env#hash t)), s) ] @ code)
            | DROP -> (snd env#pop, [])
            | DUP ->
                let x = env#peek in
                let s, env = env#allocate in
                (env, mov x s)
            | SWAP ->
                let x, y = env#peek2 in
                (env, [ Push x; Push y; Pop x; Pop y ])
            | TAG (t, n) ->
                let s1, env = env#allocate in
                let s2, env = env#allocate in
                let env, code = call env ".tag" 3 false in
                ( env,
                  [ Mov (L (box (env#hash t)), s1); Mov (L (box n), s2) ] @ code
                )
            | ARRAY n ->
                let s, env = env#allocate in
                let env, code = call env ".array_patt" 2 false in
                (env, [ Mov (L (box n), s) ] @ code)
            | PATT StrCmp -> call env ".string_patt" 2 false
            | PATT patt ->
                call env
                  (match patt with
                  | Boxed -> ".boxed_patt"
                  | UnBoxed -> ".unboxed_patt"
                  | Array -> ".array_tag_patt"
                  | String -> ".string_tag_patt"
                  | Sexp -> ".sexp_tag_patt"
                  | Closure -> ".closure_tag_patt"
                  | StrCmp ->
                      failwith
                        (Printf.sprintf "Unexpected pattern: StrCmp %s: %d"
                           __FILE__ __LINE__))
                  1 false
            | LINE line -> env#gen_line line
            | FAIL ((line, col), value) ->
                let v, env = if value then (env#peek, env) else env#pop in
                let s, env = env#string cmd#get_infile in
                ( env,
                  [
                    Push (L (box col));
                    Push (L (box line));
                    Push (M ("$" ^ s));
                    Push v;
                    Call "Bmatch_failure";
                    Binop ("+", L (4 * word_size), rsp);
                  ] )
            | i ->
                invalid_arg
                  (Printf.sprintf "invalid SM insn: %s\n" (GT.show insn i))
        in
        let env'', code'' = compile' env' scode' in
        ( env'',
          [ Meta (Printf.sprintf "# %s / %s" (GT.show SM.insn instr) stack) ]
          @ code' @ code'' )
  in
  compile' env code

(* A set of strings *)
module S = Set.Make (String)

(* A map indexed by strings *)
module M = Map.Make (String)

(* Environment implementation *)
class env prg =
  let chars =
    "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'"
  in
  (* let make_assoc l i =
       List.combine l (List.init (List.length l) (fun x -> x + i))
     in *)
  (* let rec assoc x = function
       | [] -> raise Not_found
       | l :: ls -> ( try List.assoc x l with Not_found -> assoc x ls)
     in *)
  object (self)
    inherit SM.indexer prg
    val globals = S.empty (* a set of global variables         *)
    val stringm = M.empty (* a string map                      *)
    val scount = 0 (* string count                      *)
    val stack_slots = 0 (* maximal number of stack positions *)

    val n_free_arg_regs =
      Array.length args_regs (* number of free argument refisters *)

    method get_n_free_arg_regs = n_free_arg_regs

    method restore_n_free_arg_regs =
      {<n_free_arg_regs = Array.length args_regs>}

    val static_size = 0 (* static data size                  *)
    val stack = [] (* symbolic stack                    *)
    val nargs = 0 (* number of function arguments      *)
    val locals = [] (* function local variables          *)
    val fname = "" (* function name                     *)
    val stackmap = M.empty (* labels to stack map               *)
    val barrier = false (* barrier condition                 *)
    val max_locals_size = 0
    val has_closure = false
    val publics = S.empty
    val externs = S.empty
    val nlabels = 0
    val first_line = true
    method publics = S.elements publics
    method register_public name = {<publics = S.add name publics>}
    method register_extern name = {<externs = S.add name externs>}
    method max_locals_size = max_locals_size
    method has_closure = has_closure
    method save_closure = if has_closure then [ Push rdx ] else []
    method rest_closure = if has_closure then [ Pop rdx ] else []
    method reload_closure = if has_closure then [ Mov (C (*S 0*), rdx) ] else []
    method fname = fname

    method leave =
      if stack_slots > max_locals_size then {<max_locals_size = stack_slots>}
      else self

    method show_stack = GT.show list (GT.show opnd) stack

    method print_locals =
      Printf.printf "LOCALS: size = %d\n" static_size;
      List.iter
        (fun l ->
          Printf.printf "(";
          List.iter (fun (a, i) -> Printf.printf "%s=%d " a i) l;
          Printf.printf ")\n")
        locals;
      Printf.printf "END LOCALS\n"

    (* Assert empty stack *)
    method assert_empty_stack = assert (stack = [])

    (* check barrier condition *)
    method is_barrier = barrier

    (* set barrier *)
    method set_barrier = {<barrier = true>}

    (* drop barrier *)
    method drop_barrier = {<barrier = false>}

    (* drop stack *)
    method drop_stack = {<stack = []>}

    (* associates a stack to a label *)
    method set_stack l =
      (*Printf.printf "Setting stack for %s\n" l;*)
      {<stackmap = M.add l stack stackmap>}

    (* retrieves a stack for a label *)
    method retrieve_stack l =
      (*Printf.printf "Retrieving stack for %s\n" l;*)
      try {<stack = M.find l stackmap>} with Not_found -> self

    (* checks if there is a stack for a label *)
    method has_stack l =
      (*Printf.printf "Retrieving stack for %s\n" l;*)
      M.mem l stackmap

    (* gets a name for a global variable *)
    method loc x =
      match x with
      | Value.Global name -> M ("global_" ^ name)
      | Value.Fun name -> M ("$" ^ name)
      | Value.Local i -> S i
      (* | Value.Arg i -> S (-(i + if has_closure then 2 else 1)) *)
      | Value.Arg 0 -> rdi
      | Value.Arg 1 -> rsi
      | Value.Arg 2 -> rdx
      | Value.Arg 3 -> rcx
      | Value.Arg 4 -> r8
      | Value.Arg 5 -> r9
      | Value.Arg i -> S (-(i - 5 + if has_closure then 2 else 1))
      | Value.Access i -> I (word_size * (i + 1), rdx)

    (* allocates a fresh position on a symbolic stack *)
    method allocate =
      let x, n =
        let allocate' = function
          (* | [] -> (rbx, 0) *)
          | [] -> (r10, 0)
          | S n :: _ -> (S (n + 1), n + 2)
          | R n :: _ when n < num_of_regs -> (R (n + 1), stack_slots)
          | _ -> (S static_size, static_size + 1)
        in
        allocate' stack
      in
      (x, {<stack_slots = max n stack_slots; stack = x :: stack>})

    (* pushes an operand to the symbolic stack *)
    method push y = {<stack = y :: stack>}

    (* pops one operand from the symbolic stack *)
    method pop =
      let[@ocaml.warning "-8"] (x :: stack') = stack in
      (x, {<stack = stack'>})

    (* pops one operand from the symbolic stack *)
    method pop_for_arg_2 =
      if n_free_arg_regs > 0 then
        let n' = n_free_arg_regs - 1 in
        (R (Array.length regs - 3 - n' - 1), {<n_free_arg_regs = n'>})
      else (L 0, {<>})
    (* failwith (Printf.sprintf "Not implemented %s: %d" __FILE__ __LINE__) *)

    method pop_for_arg n =
      if n_free_arg_regs > 0 then
        let n' = n_free_arg_regs - 1 in
        (* (R (Array.length regs - 3 - n' - 1), {<n_free_arg_regs = n'>}) *)
        ( R (Array.length regs - 3 - max_free_arg_regs + n - 1),
          {<n_free_arg_regs = n'>} )
      else failwith (Printf.sprintf "Not implemented %s: %d" __FILE__ __LINE__)
    (*
             let[@ocaml.warning "-8"] (x :: stack') = stack in
             (x, {<stack = stack'>}) *)

    (* pops two operands from the symbolic stack *)
    method pop2 =
      let[@ocaml.warning "-8"] (x :: y :: stack') = stack in
      (x, y, {<stack = stack'>})

    (* peeks the top of the stack (the stack does not change) *)
    method peek = List.hd stack

    (* peeks two topmost values from the stack (the stack itself does not change) *)
    method peek2 =
      let[@ocaml.warning "-8"] (x :: y :: _) = stack in
      (x, y)

    (* tag hash: gets a hash for a string tag *)
    method hash tag =
      let h = Stdlib.ref 0 in
      for i = 0 to min (String.length tag - 1) 4 do
        h := (!h lsl 6) lor String.index chars tag.[i]
      done;
      !h

    (* registers a variable in the environment *)
    method variable x =
      match x with
      | Value.Global name -> {<globals = S.add ("global_" ^ name) globals>}
      | _ -> self

    (* registers a string constant *)
    method string x =
      let escape x =
        let n = String.length x in
        let buf = Buffer.create (n * 2) in
        let rec iterate i =
          if i < n then (
            (match x.[i] with
            | '"' -> Buffer.add_string buf "\\\""
            | '\n' -> Buffer.add_string buf "\n"
            | '\t' -> Buffer.add_string buf "\t"
            | c -> Buffer.add_char buf c);
            iterate (i + 1))
        in
        iterate 0;
        Buffer.contents buf
      in
      let x = escape x in
      try (M.find x stringm, self)
      with Not_found ->
        let y = Printf.sprintf "string_%d" scount in
        let m = M.add x y stringm in
        (y, {<scount = scount + 1; stringm = m>})

    (* gets number of arguments in the current function *)
    method nargs = nargs

    (* gets all global variables *)
    method globals = S.elements (S.diff globals externs)

    (* gets all string definitions *)
    method strings = M.bindings stringm

    (* gets a number of stack positions allocated *)
    method allocated = stack_slots
    method allocated_size = Printf.sprintf "LS%s_SIZE" fname

    (* enters a function *)
    method enter f nargs nlocals has_closure =
      {<nargs
       ; static_size = nlocals
       ; stack_slots = nlocals
       ; stack = []
       ; fname = f
       ; has_closure
       ; first_line = true>}

    (* returns a label for the epilogue *)
    method epilogue = Printf.sprintf "L%s_epilogue" fname

    (* returns a name for local size meta-symbol *)
    method lsize = Printf.sprintf "L%s_SIZE" fname

    (* returns a list of live registers *)
    method live_registers depth =
      let rec inner d acc = function
        | [] -> acc
        | (R _ as r) :: tl ->
            inner (d + 1) (if d >= depth then r :: acc else acc) tl
        | _ :: tl -> inner (d + 1) acc tl
      in
      inner 0 [] stack

    (* generate a line number information for current function *)
    method gen_line line =
      let lab = Printf.sprintf ".L%d" nlabels in
      ( {<nlabels = nlabels + 1; first_line = false>},
        if fname = "main" then
          [ Meta (Printf.sprintf "\t.stabn 68,0,%d,%s" line lab); Label lab ]
        else
          (if first_line then
             [ Meta (Printf.sprintf "\t.stabn 68,0,%d,0" line) ]
           else [])
          @ [
              Meta (Printf.sprintf "\t.stabn 68,0,%d,%s-%s" line lab fname);
              Label lab;
            ] )
  end

(* Generates an assembler text for a program: first compiles the program into
   the stack code, then generates x86 assember code, then prints the assembler file
*)
let genasm cmd prog =
  let sm = SM.compile cmd prog in
  let env, code = compile cmd (new env sm) (fst (fst prog)) sm in
  let globals =
    List.map (fun s -> Meta (Printf.sprintf "\t.globl\t%s" s)) env#publics
  in
  let data =
    [ Meta "\t.data" ]
    @ List.map
        (fun (s, v) -> Meta (Printf.sprintf "%s:\t.string\t\"%s\"" v s))
        env#strings
    @ [
        Meta "_init:\t.quad 0";
        Meta "\t.section custom_data,\"aw\",@progbits";
        Meta (Printf.sprintf "filler:\t.fill\t%d, 8, 1" env#max_locals_size);
      ]
    @ List.concat
    @@ List.map
         (fun s ->
           [
             Meta
               (Printf.sprintf "\t.stabs \"%s:S1\",40,0,0,%s"
                  (String.sub s (String.length "global_")
                     (String.length s - String.length "global_"))
                  s);
             Meta (Printf.sprintf "%s:\t.quad\t1" s);
           ])
         env#globals
  in
  let asm = Buffer.create 1024 in
  List.iter
    (fun i -> Buffer.add_string asm (Printf.sprintf "%s\n" @@ show i))
    ([
       Meta (Printf.sprintf "\t.file \"%s\"" cmd#get_absolute_infile);
       Meta
         (Printf.sprintf "\t.stabs \"%s\",100,0,0,.Ltext"
            cmd#get_absolute_infile);
     ]
    @ globals @ data
    @ [
        Meta "\t.text";
        Label ".Ltext";
        Meta "\t.stabs \"data:t1=r1;0;4294967295;\",128,0,0,0";
      ]
    @ code);
  Buffer.contents asm

let get_std_path () =
  match Sys.getenv_opt "LAMA" with Some s -> s | None -> Stdpath.path

(* Builds a program: generates the assembler file and compiles it with the gcc toolchain *)
let build cmd prog =
  let find_objects imports paths =
    let module S = Set.Make (String) in
    let rec iterate acc s = function
      | [] -> acc
      | import :: imports ->
          if S.mem import s then iterate acc s imports
          else
            let path, intfs = Interface.find import paths in
            iterate
              (Filename.concat path (import ^ ".o") :: acc)
              (S.add import s)
              ((List.map (function
                  | `Import name -> name
                  | _ -> invalid_arg "must not happen")
               @@ List.filter (function `Import _ -> true | _ -> false) intfs)
              @ imports)
    in
    iterate [] (S.add "Std" S.empty) imports
  in
  cmd#dump_file "s" (genasm cmd prog);
  cmd#dump_file "i" (Interface.gen prog);
  let inc = get_std_path () in
  let compiler = "gcc" in
  let flags = "-no-pie" in
  match cmd#get_mode with
  | `Default ->
      let objs = find_objects (fst @@ fst prog) cmd#get_include_paths in
      let buf = Buffer.create 255 in
      List.iter
        (fun o ->
          Buffer.add_string buf o;
          Buffer.add_string buf " ")
        objs;
      let gcc_cmdline =
        Printf.sprintf "%s %s %s %s %s.s %s %s/runtime.a" compiler flags
          cmd#get_debug cmd#get_output_option cmd#basename (Buffer.contents buf)
          inc
      in
      Sys.command gcc_cmdline
  | `Compile ->
      Sys.command
        (Printf.sprintf "%s %s %s -c %s.s" compiler flags cmd#get_debug
           cmd#basename)
  | _ -> invalid_arg "must not happen"
