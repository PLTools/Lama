open GT
open Language

(* X86 codegeneration interface *)

module Register : sig
  type t

  val from_names : l8:string -> l64:string -> t
  val from_number : int -> t
  val of_8bit : t -> t
  val of_64bit : t -> t
  val show : t -> string
end = struct
  (* Other sizes skipped as they are not used *)
  type register_desc = { name8 : string; name64 : string }
  type t = string * register_desc

  let from_names ~l8 ~l64 = (l64, { name8 = l8; name64 = l64 })

  let from_number n =
    let name64 = Printf.sprintf "%%r%s" (string_of_int n) in
    let name8 = Printf.sprintf "%%r%sb" (string_of_int n) in
    (name64, { name8; name64 })

  let of_8bit (_, { name8; name64 }) = (name8, { name8; name64 })
  let of_64bit (_, { name8; name64 }) = (name64, { name8; name64 })
  let show (name, _) = name
end

module Registers : sig
  val rax : Register.t
  val rdi : Register.t
  val rsi : Register.t
  val rdx : Register.t
  val rcx : Register.t
  val rbp : Register.t
  val rsp : Register.t
  val r8 : Register.t
  val r9 : Register.t
  val r10 : Register.t
  val r11 : Register.t
  val r12 : Register.t
  val r13 : Register.t
  val r14 : Register.t
  val r15 : Register.t

  val argument_registers : Register.t array
  (** All of argument registers are caller-saved *)

  val extra_caller_saved_registers : Register.t array
  (** Caller saved registers that are not used for arguments *)
end = struct
  (* Caller-saved special registers *)
  let rax = Register.from_names ~l8:"%al" ~l64:"%rax"

  (* Caller-saved special and argument registers *)
  let rdx = Register.from_names ~l8:"%dl" ~l64:"%rdx"

  (* Caller-saved argument registers *)
  let rdi = Register.from_names ~l8:"%dil" ~l64:"%rdi"
  let rsi = Register.from_names ~l8:"%sil" ~l64:"%rsi"
  let rcx = Register.from_names ~l8:"%cl" ~l64:"%rcx"
  let r8 = Register.from_number 8
  let r9 = Register.from_number 9

  (* Extra caller-saved registers *)
  let r10 = Register.from_number 10
  let r11 = Register.from_number 11

  (* Callee-saved special registers *)
  let rbp = Register.from_names ~l8:"%bpl" ~l64:"%rbp"
  let rsp = Register.from_names ~l8:"%spl" ~l64:"%rsp"

  (* r12-15 registes are calee-saved in X86_64
     But we are using them as caller-save for simplicity
     This disallows calling Lama code from C
     While does not affects C calls from Lama *)
  let r12 = Register.from_number 12
  let r13 = Register.from_number 13
  let r14 = Register.from_number 14
  let r15 = Register.from_number 15
  let argument_registers = [| rdi; rsi; rdx; rcx; r8; r9 |]
  let extra_caller_saved_registers = [| r10; r11; r12; r13; r14 |]
end

(* We need to know the word size to calculate offsets correctly *)
let word_size = 8

(* We need to distinguish the following operand types: *)
type opnd =
  | R of Register.t (* hard register                    *)
  | S of int (* a position on the hardware stack *)
  | M of string (* a named memory location          *)
  | L of int (* an immediate operand             *)
  | I of int * opnd (* an indirect operand with offset  *)

let as_register opnd =
  match opnd with R r -> r | _ -> failwith "as_register: not a register"

type argument_location = Register of opnd | Stack

let rec show_opnd = function
  | R r -> Printf.sprintf "R %s" (Register.show r)
  | S i -> Printf.sprintf "S %d" i
  | M s -> Printf.sprintf "M %s" s
  | L i -> Printf.sprintf "L %d" i
  | I (i, o) -> Printf.sprintf "I %d %s" i (show_opnd o)

(* We need to know the word size to calculate offsets correctly *)

(* For convenience we define the following synonyms for the registers: *)
let rax = R Registers.rax
let rdx = R Registers.rdx
let rbp = R Registers.rbp
let rsp = R Registers.rsp
let rdi = R Registers.rdi
let rsi = R Registers.rsi
let rcx = R Registers.rcx
let r8 = R Registers.r8
let r9 = R Registers.r9
let r10 = R Registers.r10
let r11 = R Registers.r11
let r12 = R Registers.r12
let r13 = R Registers.r13
let r14 = R Registers.r14
let r15 = R Registers.r15

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
  (* sets a value from flags; the first operand is the
     suffix, which determines the value being set, the
     the second --- (sub)register name *)
  | Set of string * Register.t
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
  (* a non-conditional jump by a name                      *)
  | Jmp of string
  (* a non-conditional jump by indirect address            *)
  | JmpI of opnd
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
  if i >= 0 then (i + 1) * word_size else (-i + 1) * word_size

let show instr =
  let rec opnd = function
    | R r -> Register.show r
    | S i ->
        if i >= 0 then Printf.sprintf "-%d(%%rbp)" (stack_offset i)
        else Printf.sprintf "%d(%%rbp)" (stack_offset i)
    | M x -> x
    | L i -> Printf.sprintf "$%d" i
    | I (0, x) -> Printf.sprintf "(%s)" (opnd x)
    | I (n, x) -> Printf.sprintf "%d(%s)" n (opnd x)
  in
  let binop = function
    | "+" -> "addq"
    | "-" -> "subq"
    | "*" -> "imulq"
    | "&&" -> "andq"
    | "!!" -> "orq"
    | "^" -> "xorq"
    | "cmp" -> "cmpq"
    | "test" -> "test"
    | _ -> failwith "unknown binary operator"
  in
  match instr with
  | Cltd -> "\tcqo"
  | Set (suf, r) ->
      Printf.sprintf "\tset%s\t%s" suf (Register.show (Register.of_8bit r))
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
  | JmpI o -> Printf.sprintf "\tjmp\t*(%s)" (opnd o)
  | CJmp (s, l) -> Printf.sprintf "\tj%s\t%s" s l
  | Meta s -> Printf.sprintf "%s\n" s
  | Dec s -> Printf.sprintf "\tdecq\t%s" (opnd s)
  | Or1 s -> Printf.sprintf "\torq\t$0x0001,\t%s" (opnd s)
  | Sal1 s -> Printf.sprintf "\tsalq\t%s" (opnd s)
  | Sar1 s -> Printf.sprintf "\tsarq\t%s" (opnd s)
  | Repmovsl -> Printf.sprintf "\trep movsq\t"

let vararg_functions =
  [
    "Lprintf";
    "Lfprintf";
    "Lsprintf";
    "Lassert";
    "Bsexp";
    "Blosure";
    "Barray";
    "Bsexp";
    "Lfailure";
  ]

let is_vararg fname = List.mem fname vararg_functions

(* Opening stack machine to use instructions without fully qualified names *)
open SM

let in_memory = function M _ | S _ | I _ -> true | R _ | L _ -> false

let mov x s =
  if x = s then []
  else if in_memory x && in_memory s then [ Mov (x, rax); Mov (rax, s) ]
  else [ Mov (x, s) ]

let box n = (n lsl 1) lor 1

(*
  Compile binary operation

  compile_binop : env -> string -> env * instr list
 *)
let compile_binop env op =
  let suffix = function
    | "<" -> "l"
    | "<=" -> "le"
    | "==" -> "e"
    | "!=" -> "ne"
    | ">=" -> "ge"
    | ">" -> "g"
    | _ -> failwith "unknown operator"
  in
  let x, y = env#peek2 in
  let without_extra op =
    let _x, env = env#pop in
    (env, op ())
  in
  let with_rdx op =
    if not env#rdx_in_use then
      let _x, env = env#pop in
      (env, op rdx)
    else
      let extra, env = env#allocate in
      let _extra, env = env#pop in
      let _x, env = env#pop in
      let code = op rdx in
      (env, [ Mov (rdx, extra) ] @ code @ [ Mov (extra, rdx) ])
  in
  let with_extra op =
    let extra, env = env#allocate in
    let _extra, env = env#pop in
    let _x, env = env#pop in
    if in_memory extra then
      (env, [ Mov (rdx, extra) ] @ op extra @ [ Mov (extra, rdx) ])
    else (env, op extra)
  in
  match op with
  | "/" ->
      with_rdx (fun rdx ->
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
          ])
  | "%" ->
      with_rdx (fun rdx ->
          [
            Mov (y, rax);
            Sar1 rax;
            Cltd;
            Sar1 x;
            IDiv x;
            Sal1 rdx;
            Or1 rdx;
            Mov (rdx, y);
          ])
  | "<" | "<=" | "==" | "!=" | ">=" | ">" ->
      if in_memory x then
        with_extra (fun extra ->
            [
              Binop ("^", rax, rax);
              Mov (x, extra);
              Binop ("cmp", extra, y);
              Set (suffix op, Registers.rax);
              Sal1 rax;
              Or1 rax;
              Mov (rax, y);
            ])
      else
        without_extra (fun () ->
            [
              Binop ("^", rax, rax);
              Binop ("cmp", x, y);
              Set (suffix op, Registers.rax);
              Sal1 rax;
              Or1 rax;
              Mov (rax, y);
            ])
  | "*" ->
      without_extra (fun () ->
          if in_memory y then
            [
              Dec y;
              Mov (x, rax);
              Sar1 rax;
              Binop (op, y, rax);
              Or1 rax;
              Mov (rax, y);
            ]
          else [ Dec y; Mov (x, rax); Sar1 rax; Binop (op, rax, y); Or1 y ])
  | "&&" ->
      with_extra (fun extra ->
          [
            Dec x;
            Mov (x, rax);
            Binop (op, x, rax);
            Mov (L 0, rax);
            Set ("ne", Registers.rax);
            Dec y;
            Mov (y, extra);
            Binop (op, y, extra);
            Mov (L 0, extra);
            Set ("ne", as_register extra);
            Binop (op, extra, rax);
            Set ("ne", Registers.rax);
            Sal1 rax;
            Or1 rax;
            Mov (rax, y);
          ])
  | "!!" ->
      without_extra (fun () ->
          [
            Mov (y, rax);
            Sar1 rax;
            Sar1 x;
            Binop (op, x, rax);
            Mov (L 0, rax);
            Set ("ne", Registers.rax);
            Sal1 rax;
            Or1 rax;
            Mov (rax, y);
          ])
  | "+" ->
      without_extra (fun () ->
          if in_memory x && in_memory y then
            [ Mov (x, rax); Dec rax; Binop ("+", rax, y) ]
          else [ Binop (op, x, y); Dec y ])
  | "-" ->
      without_extra (fun () ->
          if in_memory x && in_memory y then
            [ Mov (x, rax); Binop (op, rax, y); Or1 y ]
          else [ Binop (op, x, y); Or1 y ])
  | _ ->
      failwith (Printf.sprintf "Unexpected pattern: %s: %d" __FILE__ __LINE__)

let compile_call env ?fname nargs tail =
  let is_vararg fname =
    match fname with Some fname -> is_vararg fname | None -> false
  in
  let tail_call_optimization_applicable =
    let allowed_function =
      match fname with Some fname -> not (fname.[0] = '.') | None -> true
    in
    let same_arguments_count = env#nargs = nargs in
    tail && allowed_function && same_arguments_count && not (is_vararg fname)
  in
  let compile_tail_call env fname nargs =
    let _assert_valid_arguments_count =
      if nargs != env#nargs then
        failwith
          (Printf.sprintf
             "Tail call with different amount of arguments.\n\
              Expected: %d, actual %d, %s\n"
             env#nargs nargs
             (match fname with Some fname -> fname | None -> "closure"))
    in
    let _assert_allowed_function =
      match fname with
      | Some fname ->
          if fname.[0] = '.' then
            failwith
              (Printf.sprintf "Tail call to a build-in function: %s\n" fname)
      | None -> ()
    in
    let rec push_args env acc = function
      | 0 -> (env, acc)
      | n ->
          let x, env = env#pop in
          push_args env (mov x (env#loc (Value.Arg (n - 1))) @ acc) (n - 1)
    in
    let env, pushs = push_args env [] nargs in
    let env, jump =
      match fname with
      | Some fname -> (env, [ Jmp fname ])
      | None ->
          let closure, env = env#pop in
          (env, [ Mov (closure, r15); JmpI r15 ])
    in
    let _, env = env#allocate in
    (env, pushs @ [ Mov (rbp, rsp); Pop rbp ] @ jump)
  in
  let compile_common_call env fname nargs =
    let adjust_builtin_function_name fname =
      match fname with
      | Some fname ->
          Some
            (match fname.[0] with
            | '.' -> "B" ^ String.sub fname 1 (String.length fname - 1)
            | _ -> fname)
      | None -> None
    in
    let fix_arguments fname args =
      match fname with
      | Some "Bsta" -> List.rev args
      | Some "Barray" -> L (box (List.length args)) :: args
      | Some "Bsexp" -> L (box (List.length args)) :: args
      | Some "Bclosure" -> L (box (List.length args - 1)) :: args
      | _ -> args
    in
    let setup_arguments env fname nargs vararg =
      let rec pop_arguments env acc = function
        | 0 -> (env, acc)
        | n ->
            let x, env = env#pop in
            pop_arguments env (x :: acc) (n - 1)
      in
      let move_arguments vararg args arg_locs =
        List.fold_left2
          (fun acc arg arg_loc ->
            match arg_loc with
            | Register r when vararg -> Mov (arg, r) :: Push arg :: acc
            | Register r -> Mov (arg, r) :: acc
            | Stack -> Push arg :: acc)
          [] args arg_locs
      in
      let env, args = pop_arguments env [] nargs in
      let args = fix_arguments fname args in
      let arg_locs, stack_slots = env#arguments_locations (List.length args) in
      let setup_args_code = move_arguments vararg args arg_locs in
      if not vararg then (stack_slots, env, setup_args_code)
      else (nargs, env, setup_args_code @ [ Mov (L 0, rax) ])
    in
    let protect_registers env =
      let pushr, popr =
        List.split @@ List.map (fun r -> (Push r, Pop r)) env#live_registers
      in
      if env#has_closure then (Push r15 :: pushr, Pop r15 :: popr)
      else (pushr, popr)
    in
    let align_stack saved_registers stack_arguments =
      let aligned = (saved_registers + stack_arguments) mod 2 == 0 in
      if aligned && stack_arguments = 0 then ([], [])
      else if aligned then
        ([], [ Binop ("+", L (word_size * stack_arguments), rsp) ])
      else
        ( [ Push (M "$filler") ],
          [ Binop ("+", L (word_size * (1 + stack_arguments)), rsp) ] )
    in
    let call env fname =
      match fname with
      | Some fname -> (env, [ Call fname ])
      | None ->
          let closure, env = env#pop in
          (env, [ Mov (closure, r15); CallI r15 ])
    in
    let move_result env =
      let y, env = env#allocate in
      (env, [ Mov (rax, y) ])
    in
    let fname = adjust_builtin_function_name fname in
    let vararg = is_vararg fname in
    let stack_slots, env, setup_args_code =
      setup_arguments env fname nargs vararg
    in
    let push_registers, pop_registers = protect_registers env in
    let align_prologue, align_epilogue =
      align_stack (List.length push_registers) stack_slots
    in
    let env, call = call env fname in
    let env, move_result = move_result env in
    ( env,
      push_registers @ align_prologue @ setup_args_code @ call @ align_epilogue
      @ List.rev pop_registers @ move_result )
  in
  if tail_call_optimization_applicable then compile_tail_call env fname nargs
  else compile_common_call env fname nargs

(* Symbolic stack machine evaluator

     compile : env -> prg -> env * instr list

   Take an environment, a stack machine program, and returns a pair ---
   the updated environment and the list of x86 instructions
*)
let compile cmd env imports code =
  (* SM.print_prg code;
     flush stdout; *)
  let rec compile' env scode =
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
                let l, env = env#allocate in
                if is_vararg name then
                  Printf.eprintf
                    "Warning: closure for vararg function %s is not fully \
                     supported. Do it on your own risk.\n"
                    name;
                let env, push_closure_code =
                  List.fold_left
                    (fun (env, code) c ->
                      let cr, env = env#allocate in
                      (env, mov (env#loc c) cr @ code))
                    (env, []) closure
                in
                let env, call_code =
                  compile_call env ~fname:".closure"
                    (1 + List.length closure)
                    false
                in
                (env, push_closure_code @ (Mov (M ("$" ^ name), l) :: call_code))
            | CONST n ->
                let s, env' = env#allocate in
                (env', [ Mov (L (box n), s) ])
            | STRING s ->
                let s, env = env#string s in
                let l, env = env#allocate in
                let env, call = compile_call env ~fname:".string" 1 false in
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
            | STA -> compile_call env ~fname:".sta" 3 false
            | STI -> (
                let v, env = env#pop in
                let x = env#peek in
                ( env,
                  match x with
                  | S _ | M _ ->
                      [
                        Mov (v, rdx);
                        Mov (x, rax);
                        Mov (rdx, I (0, rax));
                        Mov (rdx, x);
                      ]
                  | _ -> [ Mov (v, rax); Mov (rax, I (0, x)); Mov (rax, x) ] ))
            | BINOP op -> compile_binop env op
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
                      (* romanv: incorrect *)
                      Meta "\t.cfi_def_cfa_offset\t8";
                      Meta "\t.cfi_offset 5, -8";
                      Mov (rsp, rbp);
                      Meta "\t.cfi_def_cfa_register\t5";
                      Binop ("-", M ("$" ^ env#lsize), rsp);
                      Mov (rdi, r12);
                      Mov (rsi, r13);
                      Mov (rcx, r14);
                      Mov (rsp, rdi);
                      Mov (M "$filler", rsi);
                      Mov (M ("$" ^ env#allocated_size), rcx);
                      Repmovsl;
                      Mov (r12, rdi);
                      Mov (r13, rsi);
                      Mov (r14, rcx);
                    ]
                  @ (if f = "main" then
                       [
                         Push (R Registers.rdi);
                         Push (R Registers.rsi);
                         Call "__gc_init";
                         Pop (R Registers.rsi);
                         Pop (R Registers.rdi);
                         Call "set_args";
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
            | ELEM -> compile_call env ~fname:".elem" 2 false
            | CALL (fname, n, tail) -> compile_call env ~fname n tail
            | CALLC (n, tail) -> compile_call env n tail
            | SEXP (t, n) ->
                let s, env = env#allocate in
                let env, code = compile_call env ~fname:".sexp" (n + 1) false in
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
                let env, code = compile_call env ~fname:".tag" 3 false in
                ( env,
                  [ Mov (L (box (env#hash t)), s1); Mov (L (box n), s2) ] @ code
                )
            | ARRAY n ->
                let s, env = env#allocate in
                let env, code = compile_call env ~fname:".array_patt" 2 false in
                (env, [ Mov (L (box n), s) ] @ code)
            | PATT StrCmp -> compile_call env ~fname:".string_patt" 2 false
            | PATT patt ->
                compile_call env
                  ~fname:
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
                let vr, env = env#allocate in
                let sr, env = env#allocate in
                let liner, env = env#allocate in
                let colr, env = env#allocate in
                let env, code =
                  compile_call env ~fname:".match_failure" 4 false
                in
                let _, env = env#pop in
                ( env,
                  [
                    Mov (L col, colr);
                    Mov (L line, liner);
                    Mov (M ("$" ^ s), sr);
                    Mov (v, vr);
                  ]
                  @ code )
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

module AbstractSymbolicStack : sig
  type 'a t
  type 'a symbolic_location = Stack of int | Register of 'a

  val empty : 'a array -> 'a t
  val is_empty : _ t -> bool
  val live_registers : 'a t -> 'a list
  val stack_size : _ t -> int
  val allocate : 'a t -> 'a t * 'a symbolic_location
  val pop : 'a t -> 'a t * 'a symbolic_location
  val peek : 'a t -> 'a symbolic_location
  val peek2 : 'a t -> 'a symbolic_location * 'a symbolic_location
end = struct
  type 'a symbolic_location = Stack of int | Register of 'a

  (* Last allocated position on symbolic stack *)
  type stack_state = S of int | R of int | E
  type 'a t = stack_state * 'a array

  let empty registers = (E, registers)

  let next (state, registers) =
    let state =
      match state with
      | S n -> S (n + 1)
      | R n when n + 1 = Array.length registers -> S 0
      | R n -> R (n + 1)
      | E -> R 0
    in
    (state, registers)

  let previos (state, registers) =
    let state =
      match state with
      | S 0 -> R (Array.length registers - 1)
      | S n -> S (n - 1)
      | R 0 -> E
      | R n -> R (n - 1)
      | E -> failwith (Printf.sprintf "Empty stack %s: %d" __FILE__ __LINE__)
    in
    (state, registers)

  let location (state, registers) =
    match state with
    | S n -> Stack n
    | R n -> Register registers.(n)
    | E -> failwith (Printf.sprintf "Empty stack %s: %d" __FILE__ __LINE__)

  let is_empty (state, _) = match state with E -> true | _ -> false

  let live_registers (stack, registers) =
    match stack with
    | S _ -> Array.to_list registers
    | R n -> Array.to_list (Array.sub registers 0 (n + 1))
    | E -> []

  let stack_size (state, _) = match state with S n -> n + 1 | R _ | E -> 0

  let allocate state =
    let state = next state in
    (state, location state)

  let pop stack = (previos stack, location stack)
  let peek stack = location stack
  let peek2 stack = (location stack, location (previos stack))
end

module SymbolicStack : sig
  type t

  val empty : int -> int -> t
  val is_empty : t -> bool
  val live_registers : t -> opnd list
  val stack_size : t -> int
  val allocate : t -> t * opnd
  val pop : t -> t * opnd
  val peek : t -> opnd
  val peek2 : t -> opnd * opnd
end = struct
  type t = { state : Register.t AbstractSymbolicStack.t; nlocals : int }

  (* romanv: add free args registers? *)
  let empty _nargs nlocals =
    {
      state = AbstractSymbolicStack.empty Registers.extra_caller_saved_registers;
      nlocals;
    }

  let opnd_from_loc v = function
    | AbstractSymbolicStack.Register r -> R r
    | AbstractSymbolicStack.Stack n -> S (n + v.nlocals)

  let is_empty v = AbstractSymbolicStack.is_empty v.state

  let live_registers v =
    List.map (fun r -> R r) (AbstractSymbolicStack.live_registers v.state)

  let stack_size v = AbstractSymbolicStack.stack_size v.state

  let allocate v =
    let state, loc = AbstractSymbolicStack.allocate v.state in
    ({ v with state }, opnd_from_loc v loc)

  let pop v =
    let state, loc = AbstractSymbolicStack.pop v.state in
    ({ v with state }, opnd_from_loc v loc)

  let peek v = opnd_from_loc v (AbstractSymbolicStack.peek v.state)

  let peek2 v =
    let loc1, loc2 = AbstractSymbolicStack.peek2 v.state in
    (opnd_from_loc v loc1, opnd_from_loc v loc2)
end

(* Environment for symbolic stack machine *)

(* A set of strings *)
module S = Set.Make (String)

(* A map indexed by strings *)
module M = Map.Make (String)

(* Environment implementation *)
class env prg =
  let chars =
    "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'"
  in
  let argument_registers =
    Array.map (fun r -> R r) Registers.argument_registers
  in
  let num_of_argument_registers = Array.length argument_registers in
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
    val static_size = 0 (* static data size                  *)
    val stack = SymbolicStack.empty 0 0 (* symbolic stack                    *)
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
    method fname = fname

    method leave =
      if stack_slots > max_locals_size then {<max_locals_size = stack_slots>}
      else self

    method show_stack = show_opnd (SymbolicStack.peek stack)

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
    method assert_empty_stack = assert (SymbolicStack.is_empty stack)

    (* check barrier condition *)
    method is_barrier = barrier

    (* set barrier *)
    method set_barrier = {<barrier = true>}

    (* drop barrier *)
    method drop_barrier = {<barrier = false>}

    (* drop stack *)
    method drop_stack = {<stack = SymbolicStack.empty nargs static_size>}

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
      | Value.Arg i when i < num_of_argument_registers -> argument_registers.(i)
      | Value.Arg i -> S (-(i - num_of_argument_registers) - 1)
      | Value.Access i -> I (word_size * (i + 1), r15)

    (* allocates a fresh position on a symbolic stack *)
    method allocate =
      let stack, opnd = SymbolicStack.allocate stack in
      let stack_slots =
        max stack_slots (static_size + SymbolicStack.stack_size stack)
      in
      (opnd, {<stack_slots; stack>})

    (* pops one operand from the symbolic stack *)
    method pop =
      let stack, opnd = SymbolicStack.pop stack in
      (opnd, {<stack>})

    (* is rdx register in use *)
    method rdx_in_use = nargs > 2

    method arguments_locations n =
      if n < num_of_argument_registers then
        ( Array.to_list (Array.sub argument_registers 0 n)
          |> List.map (fun r -> Register r),
          0 )
      else
        ( (Array.to_list argument_registers |> List.map (fun r -> Register r))
          @ List.init (n - num_of_argument_registers) (fun _ -> Stack),
          n - num_of_argument_registers )

    (* peeks the top of the stack (the stack does not change) *)
    method peek = SymbolicStack.peek stack

    (* peeks two topmost values from the stack (the stack itself does not change) *)
    method peek2 = SymbolicStack.peek2 stack

    (* tag hash: gets a hash for a string tag *)
    method hash tag =
      let h = Stdlib.ref 0 in
      for i = 0 to min (String.length tag - 1) 9 do
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
       ; stack = SymbolicStack.empty nargs nlocals
       ; fname = f
       ; has_closure
       ; first_line = true>}

    (* returns a label for the epilogue *)
    method epilogue = Printf.sprintf "L%s_epilogue" fname

    (* returns a name for local size meta-symbol *)
    method lsize = Printf.sprintf "L%s_SIZE" fname

    (* returns a list of live registers *)
    method live_registers =
      Array.to_list
        (Array.sub argument_registers 0
           (min nargs (Array.length argument_registers)))
      @ SymbolicStack.live_registers stack

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
