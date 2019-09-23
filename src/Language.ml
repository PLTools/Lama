(* Opening a library for generic programming (https://github.com/dboulytchev/GT).
   The library provides "@type ..." syntax extension and plugins like show, etc.
*)
module OrigList = List
open GT

(* Opening a library for combinator-based syntax analysis *)
open Ostap
open Combinators

exception Semantic_error of string

let unquote s = String.sub s 1 (String.length s - 2)

(* Values *)
module Value =
  struct

    @type ('a, 'b) t =
    | Empty
    | Var     of string
    | Elem    of ('a, 'b) t * int
    | Int     of int
    | String  of bytes
    | Array   of ('a, 'b) t array
    | Sexp    of string * ('a, 'b) t array
    | Closure of string list * 'a * 'b
    | Builtin of string
    with show

    let to_int = function
    | Int n -> n
    | _ -> failwith "int value expected"

    let to_string = function
    | String s -> s
    | _ -> failwith "string value expected"

    let to_array = function
    | Array a -> a
    | _       -> failwith "array value expected"

    let sexp   s vs = Sexp (s, Array.of_list vs)
    let of_int    n = Int    n
    let of_string s = String s
    let of_array  a = Array  a

    let tag_of = function
    | Sexp (t, _) -> t
    | _ -> failwith "symbolic expression expected"

    let update_string s i x = Bytes.set s i x; s
    let update_array  a i x = a.(i) <- x; a

    let update_elem x i v =
      match x with
      | Sexp (_, a) | Array a -> ignore (update_array a i v)
      | String a -> ignore (update_string a i (Char.chr @@ to_int v))

    let string_val v =
      let buf      = Buffer.create 128 in
      let append s = Buffer.add_string buf s in
      let rec inner = function
      | Int    n    -> append (string_of_int n)
      | String s    -> append "\""; append @@ Bytes.to_string s; append "\""
      | Array  a    -> let n = Array.length a in
                       append "["; Array.iteri (fun i a -> (if i > 0 then append ", "); inner a) a; append "]"
      | Sexp (t, a) -> let n = Array.length a in
                       if t = "cons"
                       then (
                         append "{";
                         let rec inner_list = function
                         | [||]                    -> ()
                         | [|x; Int 0|]            -> inner x
                         | [|x; Sexp ("cons", a)|] -> inner x; append ", "; inner_list a
                         in inner_list a;
                         append "}"
                       )
                       else (
                         append t;
                         (if n > 0 then (append " ("; Array.iteri (fun i a -> (if i > 0 then append ", "); inner a) a;
                                         append ")"))
                       )
      in
      inner v;
      Bytes.of_string @@ Buffer.contents buf

  end

(* Builtins *)
module Builtin =
  struct

    let list        = ["read"; "write"; ".elem"; ".length"; ".array"; ".stringval"]
    let bindings () = List.map (fun name -> name, Value.Builtin name) list
    let names       = List.map (fun name -> name, false) list
                 
    let eval (st, i, o, vs) args = function
    | "read"     -> (match i with z::i' -> (st, i', o, (Value.of_int z)::vs) | _ -> failwith "Unexpected end of input")
    | "write"    -> (st, i, o @ [Value.to_int @@ List.hd args], Value.Empty :: vs)
    | ".elem"    -> let [b; j] = args in
                    (st, i, o, let i = Value.to_int j in
                               (match b with
                                | Value.String   s  -> Value.of_int @@ Char.code (Bytes.get s i)
                                | Value.Array    a  -> a.(i)
                                | Value.Sexp (_, a) -> a.(i)
                               ) :: vs
                    )
    | ".length"     -> (st, i, o, (Value.of_int (match List.hd args with Value.Sexp (_, a) | Value.Array a -> Array.length a | Value.String s -> Bytes.length s))::vs)
    | ".array"      -> (st, i, o, (Value.of_array @@ Array.of_list args)::vs)
    | ".stringval"  -> let [a] = args in (st, i, o, (Value.of_string @@ Value.string_val a)::vs)

  end

(* States *)
module State =
  struct

    (* State: global state, local state, scope variables *)
    type 'a t =
    | I
    | G of (string * bool) list * (string -> ('a, 'a t) Value.t)
    | L of (string * bool) list * (string -> ('a, 'a t) Value.t) * 'a t
      
    (* Undefined state *)
    let undefined x = failwith (Printf.sprintf "Undefined variable: %s" x)

    (* Create a state from bindings list *)
    let from_list l = fun x -> try List.assoc x l with Not_found -> invalid_arg (Printf.sprintf "undefined variable %s" x)
                             
    (* Bind a variable to a value in a state *)
    let bind x v s = fun y -> if x = y then v else s y

    (* empty state *)
    let empty = I

    (* initialize empty state *)
    let init st vars list =
      match st with
      | I -> G (vars @ Builtin.names, List.fold_left (fun s (name, value) -> bind name value s) (from_list list) (Builtin.bindings ()))
      | _ -> invalid_arg "state already initialzied"
    
    (* Scope operation: checks if a name is in a scope *)
    let in_scope x s = List.exists (fun (y, _) -> y = x) s

    (* Scope operation: checks if a name designates variable *)
    let is_var x s = try List.assoc x s with Not_found -> false
                    
    (* Update: non-destructively "modifies" the state s by binding the variable x
       to value v and returns the new state w.r.t. a scope
    *)
    let update x v s =      
      let rec inner = function
      | I -> invalid_arg "uninitialized state"
      | G (scope, s) ->
         if is_var x scope
         then G (scope, bind x v s)
         else invalid_arg (Printf.sprintf "name %s is undefined or does not designate a variable" x)
      | L (scope, s, enclosing) ->
         if in_scope x scope
         then if is_var x scope
              then L (scope, bind x v s, enclosing)
              else invalid_arg (Printf.sprintf "name %s does not designate a variable" x)
         else L (scope, s, inner enclosing)
      in
      inner s      

    (* Evals a variable in a state w.r.t. a scope *)
    let rec eval s x =
      match s with
      | I                       -> invalid_arg "uninitialized state"           
      | G (_, s)                -> s x
      | L (scope, s, enclosing) -> if in_scope x scope then s x else eval enclosing x

    (* Drops a scope *)
    let leave st st' =
      let rec get = function
      | I           -> invalid_arg "uninitialized state"
      | G _ as st   -> st
      | L (_, _, e) -> get e
      in
      let g = get st in
      let rec recurse = function
      | I               -> g 
      | L (scope, s, e) -> L (scope, s, recurse e)
      | G _             -> g
      in
      recurse st'

    (* Creates a new scope, based on a given state *)
    let rec enter st xs =
      match st with
      | I           -> invalid_arg "uninitialized state"                   
      | G _         -> L (xs, undefined, st)
      | L (_, _, e) -> enter e xs

    (* Push a new local scope *)
    let push st s xs = L (xs, s, st)

    (* Drop a local scope *)
    let drop (L (_, _, e)) = e

    (* Observe a variable in a state and print it to stderr *)
    let observe st x =
      Printf.eprintf "%s=%s\n%!" x (try show (Value.t) (fun _ -> "<expr>") (fun _ -> "<state>") @@ eval st x with _ -> "undefined")
      
  end

(* Patterns *)
module Pattern =
  struct

    (* The type for patterns *)
    @type t =
    (* wildcard "-"     *) | Wildcard
    (* S-expression     *) | Sexp   of string * t list
    (* array            *) | Array  of t list
    (* identifier       *) | Named  of string * t
    (* ground integer   *) | Const  of int
    (* ground string    *) | String of string
    (* boxed value      *) | Boxed
    (* unboxed value    *) | UnBoxed
    (* any string value *) | StringTag
    (* any sexp value   *) | SexpTag
    (* any array value  *) | ArrayTag
    with show, foldl

    (* Pattern parser *)
    ostap (
      parse:
        !(Ostap.Util.expr
           (fun x -> x)
	   (Array.map (fun (a, s) ->
              a,
              List.map (fun s -> ostap(- $(s)), (fun x y -> Sexp ("cons", [x; y]))) s)
          [|`Righta, [":"]|]
	 )
	 primary);
      primary:
        %"_"                                         {Wildcard}
      | t:UIDENT ps:(-"(" !(Util.list)[parse] -")")? {Sexp (t, match ps with None -> [] | Some ps -> ps)}
      | "[" ps:(!(Util.list0)[parse]) "]"            {Array ps}
      | "{" ps:(!(Util.list0)[parse]) "}"            {match ps with
                                                      | [] -> UnBoxed
                                                      | _  -> List.fold_right (fun x acc -> Sexp ("cons", [x; acc])) ps UnBoxed
                                                     }
      | x:LIDENT y:(-"@" parse)?                     {match y with None -> Named (x, Wildcard) | Some y -> Named (x, y)}
      | c:DECIMAL                                    {Const c}
      | s:STRING                                     {String (unquote s)}
      | c:CHAR                                       {Const  (Char.code c)}
      | "#" %"boxed"                                 {Boxed}
      | "#" %"unboxed"                               {UnBoxed}
      | "#" %"string"                                {StringTag}
      | "#" %"sexp"                                  {SexpTag}
      | "#" %"array"                                 {ArrayTag}
      | -"(" parse -")"
    )

    let vars p = transform(t) (fun f -> object inherit [string list, _] @t[foldl] f method c_Named s _ name p = name :: f s p end) [] p

  end

(* Simple expressions: syntax and semantics *)
module Expr =
  struct
    (* The type of configuration: a state, an input stream, an output stream,
       and a stack of values
    *)
    type 'a config = 'a State.t * int list * int list * ('a, 'a State.t) Value.t list

    (* The type for expressions. Note, in regular OCaml there is no "@type..."
       notation, it came from GT.
    *)
    type t =
    (* integer constant           *) | Const     of int
    (* array                      *) | Array     of t list
    (* string                     *) | String    of string
    (* S-expressions              *) | Sexp      of string * t list
    (* variable                   *) | Var       of string
    (* reference (aka "lvalue")   *) | Ref       of string
    (* binary operator            *) | Binop     of string * t * t
    (* element extraction         *) | Elem      of t * t
    (* reference to an element    *) | ElemRef   of t * t
    (* length                     *) | Length    of t
    (* string conversion          *) | StringVal of t
    (* function call              *) | Call      of t * t list
    (* assignment                 *) | Assign    of t * t
    (* composition                *) | Seq       of t * t
    (* empty statement            *) | Skip
    (* conditional                *) | If        of t * t * t
    (* loop with a pre-condition  *) | While     of t * t
    (* loop with a post-condition *) | Repeat    of t * t
    (* pattern-matching           *) | Case      of t * (Pattern.t * t) list
    (* return statement           *) | Return    of t option
    (* ignore a value             *) | Ignore    of t
    (* unit value                 *) | Unit
    (* entering the scope         *) | Scope     of [`Global | `Local] * (string * [`Fun of string list * t | `Variable of t option]) list * t
    (* leave a scope              *) | Leave
    (* intrinsic (for evaluation) *) | Intrinsic of (t config -> t config)
    (* control (for control flow) *) | Control   of (t config -> t * t config) 

    (* Reff : parsed expression should return value Reff (look for ":=");
       Val : -//- returns simple value;
       Void : parsed expression should not return any value;  *)
    type atr = Reff | Void | Val
                           
    let notRef  x = match x with Reff -> false | _ -> true
    let isVoid  x = match x with Void -> true  | _ -> false
    let isValue x = match x with Void -> false | _ -> true       (* functions for handling atribute *)

    (* Available binary operators:
        !!                   --- disjunction
        &&                   --- conjunction
        ==, !=, <=, <, >=, > --- comparisons
        +, -                 --- addition, subtraction
        *, /, %              --- multiplication, division, reminder
    *)

    (* Update state *)
    let update st x v =      
      match x with
      | Value.Var x       -> State.update x v st
      | Value.Elem (x, i) -> Value.update_elem x i v; st
      | _                 -> invalid_arg (Printf.sprintf "invalid value %s in update" @@ show(Value.t) (fun _ -> "<expr>") (fun _ -> "<state>") x)

    (* Expression evaluator

          val eval : env -> config -> k -> t -> config


       Takes an environment, a configuration and an expresion, and returns another configuration. The
       environment supplies the following method

           method definition : env -> string -> int list -> config -> config

       which takes an environment (of the same type), a name of the function, a list of actual parameters and a configuration,
       an returns a pair: the return value for the call and the resulting configuration
    *)
    let to_func op =
      let bti   = function true -> 1 | _ -> 0 in
      let itb b = b <> 0 in
      let (|>) f g   = fun x y -> f (g x y) in
      match op with
      | "+"  -> (+)
      | "-"  -> (-)
      | "*"  -> ( * )
      | "/"  -> (/)
      | "%"  -> (mod)
      | "<"  -> bti |> (< )
      | "<=" -> bti |> (<=)
      | ">"  -> bti |> (> )
      | ">=" -> bti |> (>=)
      | "==" -> bti |> (= )
      | "!=" -> bti |> (<>)
      | "&&" -> fun x y -> bti (itb x && itb y)
      | "!!" -> fun x y -> bti (itb x || itb y)
      | _    -> failwith (Printf.sprintf "Unknown binary operator %s" op)

    let seq x = function Skip -> x | y -> Seq (x, y)

    let schedule_list h::tl =
      List.fold_left seq h tl

    let rec take = function
    | 0 -> fun rest  -> [], rest
    | n -> fun h::tl -> let tl', rest = take (n-1) tl in h :: tl', rest

    let rec eval env ((st, i, o, vs) as conf) k expr =
      let print_values vs =
        Printf.eprintf "Values:\n%!";
        List.iter (fun v -> Printf.eprintf "%s\n%!" @@ show(Value.t) (fun _ -> "<expr>") (fun _ -> "<state>") v) vs;
        Printf.eprintf "End Values\n%!"        
      in
      match expr with
      | Scope (kind, defs, body) ->
         let vars, body, bnds =
           List.fold_left
             (fun (vs, bd, bnd) -> function
              | (name, `Variable value) -> (name, true) :: vs, (match value with None -> bd | Some v -> Seq (Assign (Ref name, v), bd)), bnd
              | (name, `Fun (args, b))  -> (name, false) :: vs, bd, (name, Value.Closure (args, b, st)) :: bnd
             )
             ([], body, [])
             (List.rev defs)
         in
         eval env
           ((match kind with
             | `Local  -> State.push st (State.from_list bnds) vars
             | `Global -> State.init st vars bnds
            ), i, o, vs)
           k
           (match kind with `Global -> body | `Local -> Seq (body, Leave))
      | Unit ->
         eval env (st, i, o, Value.Empty :: vs) Skip k
      | Ignore s ->
         eval env conf k (schedule_list [s; Intrinsic (fun (st, i, o, vs) -> (st, i, o, List.tl vs))])
      | Control f ->
         let s, conf' = f conf in
         eval env conf' k s
      | Intrinsic f ->
         eval env (f conf) Skip k
      | Const n ->
         eval env (st, i, o, (Value.of_int n) :: vs) Skip k
      | String s ->
         eval env (st, i, o, (Value.of_string @@ Bytes.of_string s) :: vs) Skip k
      | StringVal s ->
         eval env conf k (schedule_list [s; Intrinsic (fun (st, i, o, s::vs) -> (st, i, o, (Value.of_string @@ Value.string_val s)::vs))])
      | Var x ->
         eval env (st, i, o, (State.eval st x) :: vs) Skip k
      | Ref x ->
         eval env (st, i, o, (Value.Var x) :: vs) Skip k
      | Array xs ->
         eval env conf k (schedule_list (xs @ [Intrinsic (fun (st, i, o, vs) -> let es, vs' = take (List.length xs) vs in Builtin.eval (st, i, o, vs') (List.rev es) ".array")]))
      | Sexp (t, xs) ->
         eval env conf k (schedule_list (xs @ [Intrinsic (fun (st, i, o, vs) -> let es, vs' = take (List.length xs) vs in (st, i, o, Value.Sexp (t, Array.of_list (List.rev es)) :: vs'))]))
      | Binop (op, x, y) ->
         eval env conf k (schedule_list [x; y; Intrinsic (fun (st, i, o, y::x::vs) -> (st, i, o, (Value.of_int @@ to_func op (Value.to_int x) (Value.to_int y)) :: vs))])
      | Elem (b, i) ->
         eval env conf k (schedule_list [b; i; Intrinsic (fun (st, i, o, j::b::vs) -> Builtin.eval (st, i, o, vs) [b; j] ".elem")])
      | ElemRef (b, i) ->
         eval env conf k (schedule_list [b; i; Intrinsic (fun (st, i, o, j::b::vs) -> (st, i, o, (Value.Elem (b, Value.to_int j))::vs))])
      | Length e ->
         eval env conf k (schedule_list [e; Intrinsic (fun (st, i, o, v::vs) -> Builtin.eval (st, i, o, vs) [v] ".length")])
      | Call (f, args) ->
         eval env conf k (schedule_list (f :: args @ [Intrinsic (fun (st, i, o, vs) ->
            let es, vs' = take (List.length args + 1) vs in
            let f :: es = List.rev es in
            (match f with
             | Value.Builtin name ->
                Builtin.eval (st, i, o, vs') es name
             | Value.Closure (args, body, closure) ->
                let st' = State.push (State.leave st closure) (State.from_list @@ List.combine args es) (List.map (fun x -> x, true) args) in
                let st'', i', o', vs'' = eval env (st', i, o, []) Skip body in
                (State.leave st'' st, i', o', match vs'' with [v] -> v::vs' | _ -> Value.Empty :: vs')                      
             | _ -> invalid_arg (Printf.sprintf "callee did not evaluate to a function: %s" (show(Value.t) (fun _ -> "<expr>") (fun _ -> "<state>") f))
            ))]))
        
      | Leave  -> eval env (State.drop st, i, o, vs) Skip k
      | Assign (x, e)  ->
         eval env conf k (schedule_list [x; e; Intrinsic (fun (st, i, o, v::x::vs) -> (update st x v, i, o, v::vs))])
      | Seq (s1, s2) ->
         eval env conf (seq s2 k) s1
      | Skip ->
         (match k with Skip -> conf | _ -> eval env conf Skip k)
      | If (e, s1, s2) ->
         eval env conf k (schedule_list [e; Control (fun (st, i, o, e::vs) -> (if Value.to_int e <> 0 then s1 else s2), (st, i, o, vs))])
      | While (e, s) ->
         eval env conf k (schedule_list [e; Control (fun (st, i, o, e::vs) -> (if Value.to_int e <> 0 then seq s expr else Skip), (st, i, o, vs))])
      | Repeat (s, e) ->
         eval env conf (seq (While (Binop ("==", e, Const 0), s)) k) s
      | Return e -> (match e with None -> (st, i, o, []) | Some e -> eval env (st, i, o, []) Skip e)
      | Case (e, bs)->
         let rec branch ((st, i, o, v::vs) as conf) = function
         | [] -> failwith (Printf.sprintf "Pattern matching failed: no branch is selected while matching %s\n" (show(Value.t) (fun _ -> "<expr>") (fun _ -> "<state>") v))
         | (patt, body)::tl ->
             let rec match_patt patt v st =
               let update x v = function
               | None   -> None
               | Some s -> Some (State.bind x v s)
               in
               match patt, v with
               | Pattern.Named (x, p), v                                                                   -> update x v (match_patt p v st )
               | Pattern.Wildcard    , _                                                                   -> st
               | Pattern.Sexp (t, ps), Value.Sexp (t', vs) when t = t' && List.length ps = Array.length vs -> match_list ps (Array.to_list vs) st
               | Pattern.Array ps    , Value.Array vs when List.length ps = Array.length vs                -> match_list ps (Array.to_list vs) st
               | Pattern.Const n     , Value.Int n'    when n = n'                                         -> st
               | Pattern.String s    , Value.String s' when s = Bytes.to_string s'                         -> st
               | Pattern.Boxed       , Value.String _
               | Pattern.Boxed       , Value.Array  _
               | Pattern.UnBoxed     , Value.Int    _
               | Pattern.Boxed       , Value.Sexp  (_, _)
               | Pattern.StringTag   , Value.String _
               | Pattern.ArrayTag    , Value.Array  _
               | Pattern.SexpTag     , Value.Sexp  (_, _)                                                  -> st
               | _                                                                                         -> None
             and match_list ps vs s =
               match ps, vs with
               | [], []       -> s
               | p::ps, v::vs -> match_list ps vs (match_patt p v s)
               | _            -> None
             in
             match match_patt patt v (Some State.undefined) with
             | None     -> branch conf tl
             | Some st' -> eval env (State.push st st' (List.map (fun x -> x, false) @@ Pattern.vars patt), i, o, vs) k (Seq (body, Leave))
         in
         eval env conf Skip (schedule_list [e; Intrinsic (fun conf -> branch conf bs)])

    (* Expression parser. You can use the following terminals:

         LIDENT  --- a non-empty identifier a-z[a-zA-Z0-9_]* as a string
         UIDENT  --- a non-empty identifier A-Z[a-zA-Z0-9_]* as a string
         DECIMAL --- a decimal constant [0-9]+ as a string
    *)

    (* Propagates *)
    let rec propagate_ref = function
    | Var   x          -> Ref x
    | Elem (e, i)      -> ElemRef (e, i)
    | Seq  (s1, s2)    -> Seq (s1, propagate_ref s2)
    | If   (e, t1, t2) -> If (e, propagate_ref t1, propagate_ref t2)
    | Case (e, bs)     -> Case (e, List.map (fun (p, e) -> p, propagate_ref e) bs)
    | _                -> raise (Semantic_error "not a destination")

    (* Balance values *)
    let rec balance_value = function
    | Array     es        -> Array     (List.map balance_value es)
    | Sexp      (s, es)   -> Sexp      (s, List.map balance_value es)
    | Binop     (o, l, r) -> Binop     (o, balance_value l, balance_value r)
    | Elem      (b, i)    -> Elem      (balance_value b, balance_value i)
    | ElemRef   (b, i)    -> ElemRef   (balance_value b, balance_value i)
    | Length    x         -> Length    (balance_value x)
    | StringVal x         -> StringVal (balance_value x)
    | Call      (f, es)   -> Call      (balance_value f, List.map balance_value es)
    | Assign    (d, s)    -> Assign    (balance_value d, balance_value s)
    | Seq       (l, r)    -> Seq       (balance_void l, balance_value r)
    | If        (c, t, e) -> If        (balance_value c, balance_value t, balance_value e)
    | Case      (e, ps)   -> Case      (balance_value e, List.map (fun (p, e) -> p, balance_value e) ps)

    | Return    _
    | While     _
    | Repeat    _
    | Skip        -> raise (Semantic_error "missing value")

    | e                   -> e
    and balance_void = function
    | If     (c, t, e) -> If     (balance_value c, balance_void t, balance_void e)
    | Seq    (l, r)    -> Seq    (balance_void l, balance_void r)
    | Case   (e, ps)   -> Case   (balance_value e, List.map (fun (p, e) -> p, balance_void e) ps)
    | While  (e, s)    -> While  (balance_value e, balance_void s)
    | Repeat (s, e)    -> Repeat (balance_void s, balance_value e)
    | Return (Some e)  -> Return (Some (balance_value e))
    | Return None      -> Return None
    | Skip             -> Skip
    | e                -> Ignore (balance_value e)

  (* places ignore if expression should be void *)
  let ignore atr expr = if isVoid atr then Ignore expr else expr

  (* semantics for infixes creaed in runtime *)
  let sem s = (fun x atr y -> ignore atr (Call (Var s, [x; y]))), (fun _ -> Val, Val)

  let sem_init s = fun x atr y ->
    ignore atr (
       match s with
       | ":"  -> Sexp   ("cons", [x; y])
       | "++" -> Call   (Var "strcat", [x; y])
       | ":=" -> Assign (x, y)
       | _ -> Binop  (s, x, y)
    )

    (* ======= *)

    let left  f c x a y = f (c x) a y
    let right f c x a y = c (f x a y)

    let expr f ops opnd atr =
      let ops =
        Array.map
          (fun (assoc, (atrs, list)) ->
            let g = match assoc with `Lefta | `Nona -> left | `Righta -> right in
            assoc = `Nona, (atrs, altl (List.map (fun (oper, sema) -> ostap (!(oper) {g sema})) list))
          )
          ops
      in
      let atrr i atr = snd (fst (snd ops.(i)) atr) in
      let atrl i atr = fst (fst (snd ops.(i)) atr) in
      let n      = Array.length ops  in
      let op   i = snd (snd ops.(i)) in
      let nona i = fst ops.(i)      in
      let id   x = x                in
      let ostap (
        inner[l][c][atr]: f[ostap (
          {n = l                } => x:opnd[atr] {c x}
        | {n > l && not (nona l)} => (-x:inner[l+1][id][atrl l atr] -o:op[l] y:inner[l][o c x atr][atrr l atr] |
                                       x:inner[l+1][id][atr] {c x})
        | {n > l && nona l} => (x:inner[l+1][id][atrl l atr] o:op[l] y:inner[l+1][id][atrr l atr] {c (o id x atr y)} |
                                x:inner[l+1][id][atr] {c x})
          )]
      )
      in
      ostap (inner[0][id][atr])

    (* ======= *)
    ostap (
      parse[def][infix][atr]: h:basic[def][infix][Void] -";" t:parse[def][infix][atr] {Seq (h, t)}
                              | basic[def][infix][atr];
      scope[kind][def][infix][atr][e]: <(d, infix')> : def[infix] expr:e[infix'][atr] {Scope (kind, d, expr)};

      basic[def][infix][atr]: !(expr (fun x -> x) (Array.map (fun (a, (atr, l)) -> a, (atr, List.map (fun (s, f) -> ostap (- $(s)), f) l)) infix) (primary def infix) atr);

      primary[def][infix][atr]:
        b:base[def][infix][Val] is:(  "[" i:parse[def][infix][Val] "]"                     {`Elem i}
                                    | -"." (%"length" {`Len} | %"string" {`Str} | f:LIDENT {`Post f})
                                    | "(" args:!(Util.list0)[parse def infix Val] ")"      {`Call args}  
                                   )+
        => {match (List.hd (List.rev is)), atr with
            | `Elem i, Reff -> true            
            |  _,      Reff -> false
            |  _,      _    -> true} =>
        {
          let lastElem = List.hd (List.rev is) in
          let is = List.rev (List.tl (List.rev is)) in
          let b =
            List.fold_left
              (fun b ->
                function
                | `Elem i    -> Elem (b, i)
                | `Len       -> Length b
                | `Str       -> StringVal b
                | `Post f    -> Call (Var f, [b])
                | `Call args -> (match b with Sexp _ -> invalid_arg "retry!" | _ -> Call (b, args)) 
              )
              b
              is
          in
          let res = match lastElem, atr with
                    | `Elem i, Reff -> ElemRef (b, i)
                    | `Elem i,  _   -> Elem (b, i)
                    | `Len,     _   -> Length b
                    | `Str,     _   -> StringVal b
                    | `Post f,  _   -> Call (Var f, [b])
                    | `Call args, _ -> (match b with Sexp _ -> invalid_arg "retry!" | _ -> Call (b, args))
          in
          ignore atr res
        }
        | base[def][infix][atr];
      base[def][infix][atr]:
        n:DECIMAL                                 => {notRef atr} => {ignore atr (Const n)}
      | s:STRING                                  => {notRef atr} => {ignore atr (String (unquote s))}
      | c:CHAR                                    => {notRef atr} => {ignore atr (Const  (Char.code c))}
      | "[" es:!(Util.list0)[parse def infix Val] "]" => {notRef atr} => {ignore atr (Array es)}
      | -"{" scope[`Local][def][infix][atr][parse def] -"}" 
      | "{" es:!(Util.list0)[parse def infix Val] "}" => {notRef atr} => {ignore atr (match es with
                                                                                      | [] -> Const 0
                                                                                      | _  -> List.fold_right (fun x acc -> Sexp ("cons", [x; acc])) es (Const 0))
                                                                         }
      | t:UIDENT args:(-"(" !(Util.list)[parse def infix Val] -")")? => {notRef atr} => {ignore atr (Sexp (t, match args with
                                                                                                              | None -> []
                                                                                                              | Some args -> args))
                                                                                        }
      | x:LIDENT {if notRef atr then Var x else Ref x}                 

      | {isVoid atr} => %"skip" {Skip}

      | %"if" e:parse[def][infix][Val] %"then" the:scope[`Local][def][infix][atr][parse def]
                                elif:(%"elif" parse[def][infix][Val] %"then" scope[`Local][def][infix][atr][parse def])*
                                   %"else" els:scope[`Local][def][infix][atr][parse def] %"fi"
                                                                     {If (e, the, List.fold_right (fun (e, t) elif -> If (e, t, elif)) elif els)}
      | %"if" e:parse[def][infix][Val] %"then" the:scope[`Local][def][infix][Void][parse def]
                             elif:(%"elif" parse[def][infix][Val] %"then" scope[`Local][def][infix][atr][parse def])*
                             => {isVoid atr} => %"fi"
                                                                     {If (e, the, List.fold_right (fun (e, t) elif -> If (e, t, elif)) elif Skip)}

      | %"while" e:parse[def][infix][Val] %"do" s:scope[`Local][def][infix][Void][parse def]
                                            => {isVoid atr} => %"od" {While (e, s)}

      | %"for" i:parse[def][infix][Void] "," c:parse[def][infix][Val] "," s:parse[def][infix][Void] %"do" b:scope[`Local][def][infix][Void][parse def] => {isVoid atr} => %"od"
                                                                     {Seq (i, While (c, Seq (b, s)))}

      | %"repeat" s:scope[`Local][def][infix][Void][parse def] %"until" e:basic[def][infix][Val]
                                                  => {isVoid atr} => {Repeat (s, e)}
      | %"return" e:basic[def][infix][Val]?            => {isVoid atr} => {Return e}

      | %"case" e:parse[def][infix][Val] %"of" bs:!(Util.listBy1)[ostap ("|")][ostap (!(Pattern.parse) -"->" parse[def][infix][atr])] %"esac"
                                                                     {Case (e, bs)}
      | %"case" e:parse[def][infix][Val] %"of" bs:(!(Pattern.parse) -"->" parse[def][infix][Void]) => {isVoid atr} => %"esac"
                                                                     {Case (e, [bs])}

      | -"(" parse[def][infix][atr] -")"
    )

    end

(* Infix helpers *)
module Infix =
  struct

    type t = ([`Lefta | `Righta | `Nona] * ((Expr.atr -> (Expr.atr * Expr.atr)) * ((string * (Expr.t -> Expr.atr -> Expr.t -> Expr.t)) list))) array

    let name infix =
      let b = Buffer.create 64 in
      Buffer.add_string b "__Infix_";
      Seq.iter (fun c -> Buffer.add_string b (string_of_int @@ Char.code c)) @@ String.to_seq infix;
      Buffer.contents b

    let default : t =
      Array.map (fun (a, s) ->
        a,
        ((fun _ -> (if (List.hd s) = ":=" then Expr.Reff else Expr.Val), Expr.Val),
        List.map (fun s -> s, Expr.sem_init s) s)
      )
      [|
        `Righta, [":="];
        `Righta, [":"];
	`Lefta , ["!!"];
	`Lefta , ["&&"];
	`Nona  , ["=="; "!="; "<="; "<"; ">="; ">"];
	`Lefta , ["++"; "+" ; "-"];
	`Lefta , ["*" ; "/"; "%"];
      |]

    exception Break of [`Ok of t | `Fail of string]

    let find_op infix op cb ce =
      try
        Array.iteri (fun i (_, (_, l)) -> if List.exists (fun (s, _) -> s = op) l then raise (Break (cb i))) infix;
        ce ()
      with Break x -> x

    let no_op op coord = `Fail (Printf.sprintf "infix ``%s'' not found in the scope at %s" op (Msg.Coord.toString coord))

    let at coord op newp (sem, _) infix =
      find_op infix op
        (fun i ->
          `Ok (Array.init (Array.length infix)
                 (fun j ->
                   if j = i
                   then let (a, (atr, l)) = infix.(i) in (a, (atr, ((newp, sem) :: l)))
                   else infix.(j)
            ))
        )
        (fun _ -> no_op op coord)

    let before coord op newp ass (sem, atr) infix =
      find_op infix op
        (fun i ->
          `Ok (Array.init (1 + Array.length infix)
                 (fun j ->
                   if j < i
                   then infix.(j)
                   else if j = i then (ass, (atr, [newp, sem]))
                   else infix.(j-1)
                 ))
        )
        (fun _ -> no_op op coord)

    let after coord op newp ass (sem, atr) infix =
      find_op infix op
        (fun i ->
          `Ok (Array.init (1 + Array.length infix)
                 (fun j ->
                   if j <= i
                   then infix.(j)
                   else if j = i+1 then (ass, (atr, [newp, sem]))
                   else infix.(j-1)
                 ))
        )
        (fun _ -> no_op op coord)

  end

(* Function and procedure definitions *)
module Definition =
  struct

    (* The type for a definition: aither a function/infix, or a local variable *)
    type t = string * [`Fun of string list * Expr.t | `Variable of Expr.t option]
      
    ostap (
      arg : LIDENT;
      position[ass][coord][newp]:
        %"at" s:STRING {Infix.at coord (unquote s) newp}
        | f:(%"before" {Infix.before} | %"after" {Infix.after}) s:STRING {f coord (unquote s) newp ass};
      head[infix]:
        %"fun" name:LIDENT {name, infix}
      | ass:(%"infix" {`Nona} | %"infixl" {`Lefta} | %"infixr" {`Righta})
        l:$ op:(s:STRING {unquote s})
        md:position[ass][l#coord][op] {
          let name = Infix.name op in
          match md (Expr.sem name) infix with
          | `Ok infix' -> name, infix'
          | `Fail msg  -> raise (Semantic_error msg)
      };
      local_var[infix][expr][def]: name:LIDENT value:(-"=" expr[def][infix][Expr.Val])? {name, `Variable value};
      parse[kind][infix][expr][def]:
        kind locs:!(Util.list (local_var infix expr def)) ";" {locs, infix}
      | <(name, infix')> : head[infix] "(" args:!(Util.list0 arg) ")"
         body:expr[def][infix'][Expr.Void] {
           [(name, `Fun (args, body))], infix'
      }
    )

  end

(* The top-level definitions *)

(* The top-level syntax category is a pair of definition list and statement (program body) *)
type t = Definition.t list * Expr.t

(* Top-level evaluator

     eval : t -> int list -> int list

   Takes a program and its input stream, and returns the output stream
*)
let eval expr i =
  let _, _, o, _ = Expr.eval (object end) (State.empty, i, [], []) Skip expr in
  o

(* Top-level parser *)
ostap (
  parse[infix]: !(Expr.scope `Global (definitions global) infix Expr.Void (Expr.parse (definitions local)));
  local: %"local" {`Local};
  global: %"global" {`Global};
  definitions[kind][infix]:
    <(def, infix')> : !(Definition.parse kind infix Expr.basic (definitions local)) <(defs, infix'')> : definitions[kind][infix'] {def @ defs, infix''}
  | empty {[], infix}
)
