(* Opening a library for generic programming (https://github.com/dboulytchev/GT).
   The library provides "@type ..." syntax extension and plugins like show, etc.
*)
module OrigList = List

open GT

(* Opening a library for combinator-based syntax analysis *)
open Ostap
open Combinators

module Subst =
  struct

    module H = Hashtbl.Make (struct type t = string let hash = Hashtbl.hash let equal = (=) end)

    let tab = (H.create 1024 : string H.t)
          
    let attach infix op = H.add tab infix op
    let subst  id       = match H.find_opt tab id with None -> id | Some op -> op
    
  end
   
let infix_name infix =
  let b = Buffer.create 64 in
  Buffer.add_string b "i__Infix_";
  Seq.iter (fun c -> Buffer.add_string b (string_of_int @@ Char.code c)) @@ String.to_seq infix;
  let s = Buffer.contents b in
  Subst.attach s ("infix " ^ infix);
  s
  
let sys_infix_name infix =
  let b = Buffer.create 64 in
  Buffer.add_string b "s__Infix_";
  Seq.iter (fun c -> Buffer.add_string b (string_of_int @@ Char.code c)) @@ String.to_seq infix;
  let s = Buffer.contents b in
  Subst.attach s ("infix " ^ infix);
  s

exception Semantic_error of string

module Loc =
  struct
    @type t = int * int with show, html

    module H = Hashtbl.Make (struct type t = string let hash = Hashtbl.hash let equal = (==) end)

    let tab = (H.create 1024 : t H.t)
          
    let attach s loc = H.add tab s loc
    let get          = H.find_opt tab 
      
  end

let report_error ?(loc=None) str =
  raise (Semantic_error (str ^ match loc with None -> "" | Some (l, c) -> Printf.sprintf " at (%d, %d)" l c))
  
(* Values *)
module Value =
  struct

    (* The type for name designation: global or local variable, argument, reference to closure, etc. *)
    @type designation =
    | Global of string
    | Local  of int
    | Arg    of int
    | Access of int
    | Fun    of string
    with show, html   

    @type ('a, 'b) t =
    | Empty
    | Var     of designation
    | Elem    of ('a, 'b) t * int
    | Int     of int
    | String  of bytes
    | Array   of ('a, 'b) t array
    | Sexp    of string * ('a, 'b) t array
    | Closure of string list * 'a * 'b
    | FunRef  of string * string list * 'a * int
    | Builtin of string
    with show, html

    let to_int = function
    | Int n -> n
    | x -> failwith (Printf.sprintf "int value expected (%s)\n" (show(t) (fun _ -> "<not supported>") (fun _ -> "<not supported>") x))

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
    @type 'a t =
    | I
    | G of (string * bool) list * (string, 'a) arrow
    | L of (string * bool) list * (string, 'a) arrow * 'a t
    with show, html

    (* Get the depth level of a state *)
    let rec level = function
    | I            -> 0
    | G _          -> 1
    | L (_, _, st) -> 1 + level st

    (* Prune state to a certain level *)
    let prune st n =
      let rec inner n st =
        match st with
        | I              -> st, 0
        | G (xs, s)      -> st, 1
        | L (xs, s, st') ->
           let st'', l = inner n st' in
           (if l >= n then st'' else st), l+1
      in
      fst @@ inner n st
                    
    (* Undefined state *)
    let undefined x =
      report_error ~loc:(Loc.get x) (Printf.sprintf "undefined name \"%s\"" (Subst.subst x))

    (* Create a state from bindings list *)
    let from_list l = fun x -> try List.assoc x l with Not_found -> report_error ~loc:(Loc.get x) (Printf.sprintf "undefined name \"%s\"" (Subst.subst x))
                             
    (* Bind a variable to a value in a state *)
    let bind x v s = fun y -> if x = y then v else s y

    (* empty state *)
    let empty = I

    (* Scope operation: checks if a name is in a scope *)
    let in_scope x s = List.exists (fun (y, _) -> y = x) s

    (* Scope operation: checks if a name designates variable *)
    let is_var x s = try List.assoc x s with Not_found -> false
                    
    (* Update: non-destructively "modifies" the state s by binding the variable x
       to value v and returns the new state w.r.t. a scope
    *)
    let update x v s = 
      let rec inner = function
      | I -> report_error "uninitialized state"
      | G (scope, s) ->
         if is_var x scope
         then G (scope, bind x v s)
         else report_error ~loc:(Loc.get x) (Printf.sprintf "name \"%s\" is undefined or does not designate a variable" (Subst.subst x))
      | L (scope, s, enclosing) ->
         if in_scope x scope
         then if is_var x scope
              then L (scope, bind x v s, enclosing)
              else report_error ~loc:(Loc.get x) (Printf.sprintf "name \"%s\" does not designate a variable" (Subst.subst x))
         else L (scope, s, inner enclosing)
      in
      inner s      

    (* Evals a variable in a state w.r.t. a scope *)
    let rec eval s x =
      match s with
      | I                       -> report_error "uninitialized state"           
      | G (_, s)                -> s x
      | L (scope, s, enclosing) -> if in_scope x scope then s x else eval enclosing x

    (* Drops a scope *)
    let leave st st' =
      let rec get = function
      | I           -> report_error "uninitialized state"
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
      | I           -> report_error "uninitialized state"                   
      | G _         -> L (xs, undefined, st)
      | L (_, _, e) -> enter e xs

    (* Push a new local scope *)
    let push st s xs =
      match st with
      | I -> G (xs @ Builtin.names, List.fold_left (fun s (name, value) -> bind name value s) s (Builtin.bindings ()))
      | _ -> L (xs, s, st)

    (* Drop a local scope *)
    let drop = function L (_, _, e) -> e | G _ -> I

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
    (* any closure      *) | ClosureTag
    with show, foldl, html

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
                                                      | [] -> Const 0
                                                      | _  -> List.fold_right (fun x acc -> Sexp ("cons", [x; acc])) ps (Const 0)
                                                     }
      | l:$ x:LIDENT y:(-"@" parse)?                 {Loc.attach x l#coord; match y with None -> Named (x, Wildcard) | Some y -> Named (x, y)}
      | s:("-")? c:DECIMAL                           {Const (match s with None -> c | _ -> ~-c)}
      | s:STRING                                     {String s}
      | c:CHAR                                       {Const  (Char.code c)}
      | %"true"                                      {Const 1}
      | %"false"                                     {Const 0}
      | "#" %"boxed"                                 {Boxed}
      | "#" %"unboxed"                               {UnBoxed}
      | "#" %"string"                                {StringTag}
      | "#" %"sexp"                                  {SexpTag}
      | "#" %"array"                                 {ArrayTag}
      | "#" %"fun"                                   {ClosureTag}
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
    @type 'a value  = ('a, 'a value State.t array) Value.t with show, html
    @type 'a config = 'a value State.t * int list * int list * 'a value list with show, html
    (* Reff : parsed expression should return value Reff (look for ":=");
       Val : -//- returns simple value;
       Void : parsed expression should not return any value;  *)
    @type atr = Reff | Void | Val | Weak with show, html
    (* The type for expressions. Note, in regular OCaml there is no "@type..."
       notation, it came from GT.
    *)
    @type t =
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
    (* pattern-matching           *) | Case      of t * (Pattern.t * t) list * Loc.t * atr
    (* return statement           *) | Return    of t option
    (* ignore a value             *) | Ignore    of t
    (* unit value                 *) | Unit
    (* entering the scope         *) | Scope     of (string * decl) list * t 
    (* lambda expression          *) | Lambda    of string list * t
    (* leave a scope              *) | Leave
    (* intrinsic (for evaluation) *) | Intrinsic of (t config, t config) arrow
    (* control (for control flow) *) | Control   of (t config, t * t config) arrow
    and decl = [`Local | `Public | `Extern | `PublicExtern ] * [`Fun of string list * t | `Variable of t option]
    with show, html
                           
    let notRef = function Reff -> false | _ -> true
    let isVoid = function Void | Weak -> true  | _ -> false
    
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
      | Value.Var (Value.Global x) -> State.update x v st
      | Value.Elem (x, i) -> Value.update_elem x i v; st
      | _                 -> report_error (Printf.sprintf "invalid value \"%s\" in update" @@ show(Value.t) (fun _ -> "<expr>") (fun _ -> "<state>") x)

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

    let rec eval ((st, i, o, vs) as conf) k expr =
      let print_values vs =
        Printf.eprintf "Values:\n%!";
        List.iter (fun v -> Printf.eprintf "%s\n%!" @@ show(Value.t) (fun _ -> "<expr>") (fun _ -> "<state>") v) vs;
        Printf.eprintf "End Values\n%!"        
      in
      match expr with
      | Lambda (args, body) ->
         eval (st, i, o, Value.Closure (args, body, [|st|]) :: vs) Skip k        
      | Scope (defs, body) ->
         let vars, body, bnds =
           List.fold_left
             (fun (vs, bd, bnd) -> function
              | (name, (_, `Variable value)) -> (name, true) :: vs, (match value with None -> bd | Some v -> Seq (Ignore (Assign (Ref name, v)), bd)), bnd
              | (name, (_, `Fun (args, b)))  -> (name, false) :: vs, bd, (name, Value.FunRef (name, args, b, 1 + State.level st)) :: bnd
             )
             ([], body, [])
             (List.rev @@
              List.map (function
                        | (name, (`Extern, _)) -> report_error (Printf.sprintf "external names (\"%s\") not supported in evaluation" (Subst.subst name))
                        | x -> x
                       )
              defs)
         in
         eval (State.push st (State.from_list bnds) vars, i, o, vs) k (Seq (body, Leave))
      | Unit ->
         eval (st, i, o, Value.Empty :: vs) Skip k
      | Ignore s ->
         eval conf k (schedule_list [s; Intrinsic (fun (st, i, o, vs) -> (st, i, o, List.tl vs))])
      | Control f ->
         let s, conf' = f conf in
         eval conf' k s
      | Intrinsic f ->
         eval (f conf) Skip k
      | Const n ->
         eval (st, i, o, (Value.of_int n) :: vs) Skip k
      | String s ->
         eval (st, i, o, (Value.of_string @@ Bytes.of_string s) :: vs) Skip k
      | StringVal s ->
         eval conf k (schedule_list [s; Intrinsic (fun (st, i, o, s::vs) -> (st, i, o, (Value.of_string @@ Value.string_val s)::vs))])
      | Var x ->
         let v =
           match State.eval st x with
           | Value.FunRef (_, args, body, level) ->
              Value.Closure (args, body, [|State.prune st level|])
           | v -> v
         in
         eval (st, i, o, v :: vs) Skip k
      | Ref x ->
         eval (st, i, o, (Value.Var (Value.Global x)) :: vs) Skip k (* only Value.Global is supported in interpretation *)
      | Array xs ->
         eval conf k (schedule_list (xs @ [Intrinsic (fun (st, i, o, vs) -> let es, vs' = take (List.length xs) vs in Builtin.eval (st, i, o, vs') (List.rev es) ".array")]))
      | Sexp (t, xs) ->
         eval conf k (schedule_list (xs @ [Intrinsic (fun (st, i, o, vs) -> let es, vs' = take (List.length xs) vs in (st, i, o, Value.Sexp (t, Array.of_list (List.rev es)) :: vs'))]))
      | Binop (op, x, y) ->
         eval conf k (schedule_list [x; y; Intrinsic (fun (st, i, o, y::x::vs) -> (st, i, o, (Value.of_int @@ to_func op (Value.to_int x) (Value.to_int y)) :: vs))])
      | Elem (b, i) ->
         eval conf k (schedule_list [b; i; Intrinsic (fun (st, i, o, j::b::vs) -> Builtin.eval (st, i, o, vs) [b; j] ".elem")])
      | ElemRef (b, i) ->
         eval conf k (schedule_list [b; i; Intrinsic (fun (st, i, o, j::b::vs) -> (st, i, o, (Value.Elem (b, Value.to_int j))::vs))])
      | Length e ->
         eval conf k (schedule_list [e; Intrinsic (fun (st, i, o, v::vs) -> Builtin.eval (st, i, o, vs) [v] ".length")])
      | Call (f, args) ->
         eval conf k (schedule_list (f :: args @ [Intrinsic (fun (st, i, o, vs) ->
            let es, vs' = take (List.length args + 1) vs in
            let f :: es = List.rev es in
            (match f with
             | Value.Builtin name ->
                Builtin.eval (st, i, o, vs') es name
             | Value.Closure (args, body, closure) ->
                let st' = State.push (State.leave st closure.(0)) (State.from_list @@ List.combine args es) (List.map (fun x -> x, true) args) in
                let st'', i', o', vs'' = eval (st', i, o, []) Skip body in
                closure.(0) <- st'';
                (State.leave st'' st, i', o', match vs'' with [v] -> v::vs' | _ -> Value.Empty :: vs')                      
             | _ -> report_error (Printf.sprintf "callee did not evaluate to a function: \"%s\"" (show(Value.t) (fun _ -> "<expr>") (fun _ -> "<state>") f))
            ))]))
        
      | Leave  -> eval (State.drop st, i, o, vs) Skip k
      | Assign (x, e)  ->
         eval conf k (schedule_list [x; e; Intrinsic (fun (st, i, o, v::x::vs) -> (update st x v, i, o, v::vs))])
      | Seq (s1, s2) ->
         eval conf (seq s2 k) s1
      | Skip ->
         (match k with Skip -> conf | _ -> eval conf Skip k)
      | If (e, s1, s2) ->
         eval conf k (schedule_list [e; Control (fun (st, i, o, e::vs) -> (if Value.to_int e <> 0 then s1 else s2), (st, i, o, vs))])
      | While (e, s) ->
         eval conf k (schedule_list [e; Control (fun (st, i, o, e::vs) -> (if Value.to_int e <> 0 then seq s expr else Skip), (st, i, o, vs))])
      | Repeat (s, e) ->
         eval conf (seq (While (Binop ("==", e, Const 0), s)) k) s
      | Return e -> (match e with None -> (st, i, o, []) | Some e -> eval (st, i, o, []) Skip e)
      | Case (e, bs, _, _)->
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
               | Pattern.ClosureTag  , Value.Closure _                                           
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
             | Some st' -> eval (State.push st st' (List.map (fun x -> x, false) @@ Pattern.vars patt), i, o, vs) k (Seq (body, Leave))
         in
         eval conf Skip (schedule_list [e; Intrinsic (fun conf -> branch conf bs)])

  (* Expression parser. You can use the following terminals:
       LIDENT  --- a non-empty identifier a-z[a-zA-Z0-9_]* as a string
       UIDENT  --- a non-empty identifier A-Z[a-zA-Z0-9_]* as a string
       DECIMAL --- a decimal constant [0-9]+ as a string
  *)

  (* places ignore if expression should be void *)
  let ignore atr expr = match atr with Void -> Ignore expr | _ -> expr

  (* places dummy value if required *)
  let materialize atr expr =
    match atr with
    | Weak -> Seq (expr, Const 0)
    | _    -> expr
    
  (* semantics for infixes created in runtime *)
  let sem s = (fun x atr y -> ignore atr (Call (Var s, [x; y]))), (fun _ -> Val, Val)

  let sem_init s = fun x atr y ->
    ignore atr (
       match s with
       | ":"  -> Sexp   ("cons", [x; y])
       | ":=" -> Assign (x, y)
       | _    -> Binop  (s, x, y)
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
      
    let atr' = atr
    let not_a_reference s = new Reason.t (Msg.make "not a reference" [||] (Msg.Locator.Point s#coord))
                          
    (* UGLY! *)
    let predefined_op : (Obj.t -> Obj.t -> Obj.t) ref = Pervasives.ref (fun _ _ -> invalid_arg "must not happen")

    let defCell = Pervasives.ref 0 
                                                      
    (* ======= *)
    let makeParsers env = 
    let makeParser, makeBasicParser, makeScopeParser =
      let def s   = let Some def = Obj.magic !defCell in def s in
      let ostap (
      parse[infix][atr]: h:basic[infix][Void] -";" t:parse[infix][atr] {Seq (h, t)} | basic[infix][atr];
      scope[infix][atr]: <(d, infix')> : def[infix] expr:parse[infix'][atr] {Scope (d, expr)} | <(d, infix')> : def[infix] => {d <> []} => {Scope (d, materialize atr Skip)}; 
      basic[infix][atr]: !(expr (fun x -> x) (Array.map (fun (a, (atr, l)) -> a, (atr, List.map (fun (s, _, f) -> ostap (- $(s)), f) l)) infix) (primary infix) atr);
      primary[infix][atr]:
          s:(s:"-"? {match s with None -> fun x -> x | _ -> fun x -> Binop ("-", Const 0, x)})  
          b:base[infix][Val] is:(  "." f:LIDENT args:(-"(" !(Util.list)[parse infix Val] -")")? {`Post (f, args)}
                                      | "." %"length"                                           {`Len}
                                      | "." %"string"                                           {`Str}
                                      | "[" i:parse[infix][Val] "]"                             {`Elem i}                                    
                                      | "(" args:!(Util.list0)[parse infix Val] ")"             {`Call args}  
          )+
        => {match (List.hd (List.rev is)), atr with
            | `Elem i, Reff -> true            
            |  _,      Reff -> false
            |  _,      _    -> true} =>
        {
          let is =
            let rec fix_is = function
            | [ ]                                                 -> []
            | [x]                                                 -> [x]
            | `Post (f, None) :: `Call args :: tl when args != [] -> `Post (f, Some args) :: fix_is tl
            | x :: tl                                             -> x :: fix_is tl
            in
            fix_is is
          in
          let lastElem = List.hd (List.rev is) in
          let is = List.rev (List.tl (List.rev is)) in
          let b =
            List.fold_left
              (fun b ->
                function
                | `Elem i         -> Elem (b, i)
                | `Len            -> Length b
                | `Str            -> StringVal b
                | `Post (f, args) -> Call (Var f, b :: match args with None -> [] | Some args -> args)
                | `Call args      -> (match b with Sexp _ -> invalid_arg "retry!" | _ -> Call (b, args)) 
              )
              b
              is
          in
          let res = match lastElem, atr with
                    | `Elem i        , Reff -> ElemRef (b, i)
                    | `Elem i        , _    -> Elem (b, i)
                    | `Len           , _    -> Length b
                    | `Str           , _    -> StringVal b
                    | `Post (f, args), _    -> Call (Var f, b :: match args with None -> [] | Some args -> args)
                    | `Call args     , _    -> (match b with Sexp _ -> invalid_arg "retry!"  | _ -> Call (b, args))
          in
          ignore atr (s res)
        }
      | base[infix][atr];
      base[infix][atr]:
        l:$ n:DECIMAL                              => {notRef atr} :: (not_a_reference l) => {ignore atr (Const n)}
      | l:$ s:STRING                               => {notRef atr} :: (not_a_reference l) => {ignore atr (String s)}
      | l:$ c:CHAR                                 => {notRef atr} :: (not_a_reference l) => {ignore atr (Const  (Char.code c))}
      
      | l:$ c:(%"true" {Const 1} | %"false" {Const 0}) => {notRef atr} :: (not_a_reference l) => {ignore atr c} 
       
      | l:$ %"infix" s:INFIX => {notRef atr} :: (not_a_reference l) => {
          if ((* UGLY! *) Obj.magic !predefined_op) infix s
          then (
            if s = ":="
            then report_error ~loc:(Some l#coord) (Printf.sprintf "can not capture predefined operator \":=\"")
            else
              let name = sys_infix_name s in Loc.attach name l#coord; ignore atr (Var name)
          )            
          else (
            let name = infix_name s in Loc.attach name l#coord; ignore atr (Var name)
          )
      }
      | l:$ %"fun" "(" args:!(Util.list0)[Pattern.parse] ")"
           "{" body:scope[infix][Weak] "}"=> {notRef atr} :: (not_a_reference l) => {
          let args, body =
            List.fold_right
              (fun arg (args, body) ->
                 match arg with
                 | Pattern.Named (name, Pattern.Wildcard) -> name :: args, body
                 | Pattern.Wildcard -> env#get_tmp :: args, body
                 | p ->
                    let arg = env#get_tmp in
                    arg :: args, Case (Var arg, [p, body], l#coord, Weak)
              )
              args
              ([], body)
          in
          ignore atr (Lambda (args, body))
      }

      | l:$ "[" es:!(Util.list0)[parse infix Val] "]" => {notRef atr} :: (not_a_reference l) => {ignore atr (Array es)}
      | -"{" scope[infix][atr] -"}" 
      | l:$ "{" es:!(Util.list0)[parse infix Val] "}" => {notRef atr} :: (not_a_reference l) => {ignore atr (match es with
                                                                                      | [] -> Const 0
                                                                                      | _  -> List.fold_right (fun x acc -> Sexp ("cons", [x; acc])) es (Const 0))
                                                                         }
      | l:$ t:UIDENT args:(-"(" !(Util.list)[parse infix Val] -")")? => {notRef atr} :: (not_a_reference l) => {ignore atr (Sexp (t, match args with
                                                                                                              | None -> []
                                                                                                              | Some args -> args))
                                                                                        }
      | l:$ x:LIDENT {Loc.attach x l#coord; if notRef atr then ignore atr (Var x) else Ref x}                 

      | {isVoid atr} => %"skip" {materialize atr Skip}

      | %"if" e:parse[infix][Val] %"then" the:scope[infix][atr]
        elif:(%"elif" parse[infix][Val] %"then" scope[infix][atr])*
        els:(%"else" scope[infix][atr])? %"fi"
          {If (e, the, List.fold_right (fun (e, t) elif -> If (e, t, elif)) elif (match els with Some e -> e | _ -> materialize atr Skip))}
      | %"while" e:parse[infix][Val] %"do" s:scope[infix][Void]
                                            => {isVoid atr} => %"od" {materialize atr (While (e, s))}

      | %"for" i:scope[infix][Void] ","
               c:parse[infix][Val]             ","
               s:parse[infix][Void] %"do" b:scope[infix][Void] => {isVoid atr} => %"od"
               {materialize atr
                  (match i with
                  | Scope (defs, i) -> Scope (defs, Seq (i, While (c, Seq (b, s))))
                  | _               -> Seq (i, While (c, Seq (b, s))))
               }

      | %"repeat" s:scope[infix][Void] %"until" e:basic[infix][Val] => {isVoid atr} => {
          materialize atr @@
            match s with
            | Scope (defs, s) ->
               let defs, s =
                 List.fold_right (fun (name, def) (defs, s) ->
                     match def with
                     | (`Local, `Variable (Some expr)) ->
                        (name, (`Local, `Variable None)) :: defs, Seq (Ignore (Assign (Ref name, expr)), s)
                     | def -> (name, def) :: defs, s)
                   defs
                   ([], s)
               in
               Scope (defs, Repeat (s, e))
            | _  -> Repeat (s, e)
      }
      | %"return" e:basic[infix][Val]? => {isVoid atr} => {Return e}
      | %"case" l:$ e:parse[infix][Val] %"of" bs:!(Util.listBy)[ostap ("|")][ostap (!(Pattern.parse) -"->" scope[infix][atr])] %"esac"{Case (e, bs, l#coord, atr)}
      | l:$ %"lazy" e:basic[infix][Val] => {notRef atr} :: (not_a_reference l) => {env#add_import "Lazy"; ignore atr (Call (Var "makeLazy", [Lambda ([], e)]))}
      | l:$ %"eta"  e:basic[infix][Val] => {notRef atr} :: (not_a_reference l) => {let name = env#get_tmp in ignore atr (Lambda ([name], Call (e, [Var name])))}
      | l:$ %"syntax" "(" e:syntax[infix] ")" => {notRef atr} :: (not_a_reference l) => {env#add_import "Ostap"; ignore atr e}
      | -"(" parse[infix][atr] -")";
      syntax[infix]: ss:!(Util.listBy)[ostap ("|")][syntaxSeq infix] {
        List.fold_right (fun s -> function
                                  | Var "" -> s
                                  | acc    -> Call (Var "alt", [s; acc])
                        ) ss (Var "")
      };
      syntaxSeq[infix]: ss:syntaxBinding[infix]+ sema:(-"{" scope[infix][Val] -"}")? {
        let sema, ss =
          match sema with
          | Some s -> s, ss
          | None   ->
             let arr, ss = 
               List.fold_left (fun (arr, ss) ((loc, omit, p, s) as elem) ->
                                 match omit with
                                 | None   -> (match p with
                                              | None                           -> let tmp = env#get_tmp in
                                                                                  ((Var tmp) :: arr, (loc, omit, Some (Pattern.Named (tmp, Pattern.Wildcard)), s) :: ss)
                                              | Some (Pattern.Named (name, _)) -> ((Var name) :: arr, elem :: ss)
                                              | Some p                         -> let tmp = env#get_tmp in
                                                                                  ((Var tmp) :: arr, (loc, omit, Some (Pattern.Named (tmp, p)), s) :: ss)
                                             )
                                 | Some _ -> (arr, elem :: ss)
                 ) ([], []) ss
             in
             (match arr with [a] -> a | _ -> Array (List.rev arr)), List.rev ss
        in
        List.fold_right (fun (loc, _, p, s) ->
                           let make_right =
                             match p with
                             | None                                          -> (fun body -> Lambda ([env#get_tmp], body))
                             | Some (Pattern.Named (name, Pattern.Wildcard)) -> (fun body -> Lambda ([name], body))
                             | Some p                                        -> (fun body ->
                                                                                   let arg = env#get_tmp in
                                                                                   Lambda ([arg], Case (Var arg, [p, body], loc#coord, Val))
                                                                                )
                           in
                           function
                           | Var "" -> Call (Var (infix_name "@"), [s; make_right sema])
                           | acc    -> Call (Var "seq", [s; make_right acc])
                        ) ss (Var "")
      };
      syntaxBinding[infix]: l:$ omit:"-"? p:(!(Pattern.parse) -"=")? s:syntaxPostfix[infix];
      syntaxPostfix[infix]: s:syntaxPrimary[infix] p:("*" {`Rep0} | "+" {`Rep} | "?" {`Opt})? {
        match p with
        | None       -> s
        | Some `Opt  -> Call (Var "opt" , [s])
        | Some `Rep  -> Call (Var "rep" , [s])
        | Some `Rep0 -> Call (Var "rep0", [s])
      };
      syntaxPrimary[infix]: l:$ p:LIDENT args:(-"[" !(Util.list0)[parse infix Val] -"]")* {
        Loc.attach p l#coord;
        List.fold_left (fun acc args -> Call (acc, args)) (Var p) args
      }
      | -"(" syntax[infix] -")"
      | -"$(" parse[infix][Val] -")" 
    ) in (fun def -> defCell := Obj.magic !def; parse),
         (fun def -> defCell := Obj.magic !def; basic),
         (fun def -> defCell := Obj.magic !def; scope)
    in
    makeParser, makeBasicParser, makeScopeParser
                                   
    (* Workaround until Ostap starts to memoize properly *)
    ostap (
      constexpr:
        n:DECIMAL                                          {Const n}
      | s:STRING                                           {String s}
      | c:CHAR                                             {Const (Char.code c)}      
      | %"true"                                            {Const 1}
      | %"false"                                           {Const 0}       
      | "[" es:!(Util.list0)[constexpr] "]"                {Array es}
      | "{" es:!(Util.list0)[constexpr] "}"                {match es with [] -> Const 0 | _  -> List.fold_right (fun x acc -> Sexp ("cons", [x; acc])) es (Const 0)}
      | t:UIDENT args:(-"(" !(Util.list)[constexpr] -")")? {Sexp (t, match args with None -> [] | Some args -> args)}
      | l:$ x:LIDENT                                       {Loc.attach x l#coord; Var x}
      | -"(" constexpr -")"
    )
    (* end of the workaround *)

  end

(* Infix helpers *)
module Infix =
  struct
    
    @type kind     = Predefined | Public | Local with show
    @type ass      = [`Lefta | `Righta | `Nona] with show
    @type loc      = [`Before of string | `After of string | `At of string] with show
    @type export   = (ass * string * loc) list with show
    @type showable = (ass * string * kind) list array with show
                                                                                                     
    type t = ([`Lefta | `Righta | `Nona] * ((Expr.atr -> (Expr.atr * Expr.atr)) * ((string * kind * (Expr.t -> Expr.atr -> Expr.t -> Expr.t)) list))) array

    let show_infix (infix : t) =
      show(showable) @@ Array.map (fun (ass, (_, l)) -> List.map (fun (str, kind, _) -> ass, str, kind) l) infix

    let extract_exports infix =
      let ass_string = function `Lefta -> "L" | `Righta -> "R" | _ -> "I" in
      let exported = 
        Array.map
          (fun (ass, (_, ops)) ->
            (ass, List.rev @@ List.map (fun (s, kind, _) -> s, kind) @@ List.filter (function (_, Public, _) | (_, Predefined, _) -> true | _ -> false) ops)
          )
          infix
      in
      let _, exports =
        Array.fold_left
          (fun (loc, acc) (ass, list) ->
            let rec inner (loc, acc) = function
              | [] -> (loc, acc)
              | (s, kind) :: tl ->
                 let loc' = match tl with [] -> `After s | _ -> `At s in
                 (fun again ->
                    match kind with
                    | Public -> again (loc', (ass, s, loc) :: acc) 
                    | _      -> again (loc', acc) 
                 )
                 (match tl with [] -> fun acc -> acc | _ -> fun acc -> inner acc tl)
            in
            inner (loc, acc) list
          )
          (`Before ":=", [])
          exported
      in List.rev exports

    let is_predefined op =      
      List.exists (fun x -> op = x) [":"; "!!"; "&&"; "=="; "!="; "<="; "<"; ">="; ">"; "+"; "-"; "*" ; "/"; "%"; ":="]
      
    (*
    List.iter (fun op ->
        Printf.eprintf "F,%s\n" (sys_infix_name op);
        (*
        Printf.eprintf "// Functional synonym for built-in operator \"%s\";\n" op;
        Printf.eprintf "int L%s (void *p, void *q) {\n" (sys_infix_name op);
        Printf.eprintf "  ASSERT_UNBOXED(\"captured %s:1\", p);\n" op;
        Printf.eprintf "  ASSERT_UNBOXED(\"captured %s:2\", q);\n\n" op;
        Printf.eprintf "  return BOX(UNBOX(p) %s UNBOX(q));\n" op;
        Printf.eprintf "}\n\n"        *)
      ) [":"; "!!"; "&&"; "=="; "!="; "<="; "<"; ">="; ">"; "+"; "-"; "*" ; "/"; "%"]
     *)
      
    let default : t =
      Array.map (fun (a, s) ->
        a,
        ((fun _ -> (if (List.hd s) = ":=" then Expr.Reff else Expr.Val), Expr.Val),
        List.map (fun s -> s, Predefined, Expr.sem_init s) s)
      )
      [|
        `Righta, [":="];
        `Righta, [":"];
	`Lefta , ["!!"];
	`Lefta , ["&&"];
	`Nona  , ["=="; "!="; "<="; "<"; ">="; ">"];
	`Lefta , ["+" ; "-"];
	`Lefta , ["*" ; "/"; "%"];
      |]

    exception Break of [`Ok of t | `Fail of string]
      
    let find_op infix op cb ce =
      try
        Array.iteri (fun i (_, (_, l)) -> if List.exists (fun (s, _, _) -> s = op) l then raise (Break (cb i))) infix;
        ce ()
      with Break x -> x

    let predefined_op infix op =      
      Array.exists
        (fun (_, (_, l)) ->
           List.exists (fun (s, p, _) -> s = op && p = Predefined) l
        )
        infix;;

    (* UGLY!!! *)
    Expr.predefined_op := (Obj.magic) predefined_op;;
                          
    let no_op op coord = `Fail (Printf.sprintf "infix \"%s\" not found in the scope" op) 

    let kind_of = function true -> Public | _ -> Local
                                               
    let at coord op newp public (sem, _) (infix : t) =
      find_op infix op
        (fun i ->
          `Ok (Array.init (Array.length infix)
                 (fun j ->
                   if j = i
                   then let (a, (atr, l)) = infix.(i) in (a, ( (*atr*) (fun _ -> Expr.Val, Expr.Val), ((newp, kind_of public, sem) :: (List.filter (fun (op', _, _) -> op' <> newp) l))))
                   else infix.(j)
            ))
        )
        (fun _ -> no_op op coord)

    let before coord op newp ass public (sem, atr) (infix : t) =
      find_op infix op
        (fun i ->
          `Ok (Array.init (1 + Array.length infix)
                 (fun j ->
                   if j < i
                   then infix.(j)
                   else if j = i then (ass, (atr, [newp, kind_of public, sem]))
                   else infix.(j-1)
                 ))
        )
        (fun _ -> no_op op coord)

    let after coord op newp ass public (sem, atr) (infix : t) =
      find_op infix op
        (fun i ->
          `Ok (Array.init (1 + Array.length infix)
                 (fun j ->
                   if j <= i
                   then infix.(j)
                   else if j = i+1 then (ass, (atr, [newp, kind_of public, sem]))
                   else infix.(j-1)
                 ))
        )
        (fun _ -> no_op op coord)

  end

(* Function and procedure definitions *)
module Definition =
  struct

    (* The type for a definition: either a function/infix, or a local variable *)
    type t = string * [`Fun of string list * Expr.t | `Variable of Expr.t option]

    let unopt_mod = function None -> `Local | Some m -> m

    ostap (
      (* Workaround until Ostap starts to memoize properly *)
      const_var: l:$ name:LIDENT "=" value:!(Expr.constexpr) {
        Loc.attach name l#coord;
        name, (`Public, `Variable (Some value))
       };
      constdef: %"public" d:!(Util.list (const_var)) ";" {d}
      (* end of the workaround *)
    )
                                                      
    let makeParser env exprBasic exprScope =
    let ostap (
      arg : l:$ x:LIDENT {Loc.attach x l#coord; x};       
      position[pub][ass][coord][newp]:
        %"at" s:INFIX {match ass with
                       | `Nona -> Infix.at coord s newp pub
                       | _     -> report_error ~loc:(Some coord) (Printf.sprintf "associativity for infix \"%s\" can not be specified (it is inherited from that for \"%s\")" newp s)
           }
        | f:(%"before" {Infix.before} | %"after" {Infix.after}) s:INFIX {f coord s newp ass pub};
      head[infix]:
        m:(%"external" {`Extern} | %"public" e:(%"external")? {match e with None -> `Public | _ -> `PublicExtern})? %"fun" l:$ name:LIDENT {Loc.attach name l#coord; unopt_mod m, name, name, infix, false}
    |   m:(%"public" {`Public})? ass:(%"infix" {`Nona} | %"infixl" {`Lefta} | %"infixr" {`Righta})
        l:$ op:(s:INFIX {s})
        md:position[match m with Some _ -> true | _ -> false][ass][l#coord][op] {
          if m <> None && Infix.is_predefined op then report_error ~loc:(Some l#coord) (Printf.sprintf "redefinition of standard infix operator \"%s\" can not be exported" op);
          let name = infix_name op in
          Loc.attach name l#coord;
          match md (Expr.sem name) infix with
          | `Ok infix' -> unopt_mod m, op, name, infix', true
          | `Fail msg  -> report_error ~loc:(Some l#coord) msg
      };
      local_var[m][infix]: l:$ name:LIDENT value:(-"=" exprBasic[infix][Expr.Val])? {
        Loc.attach name l#coord;                                                                  
        match m, value with
        | `Extern, Some _ -> report_error ~loc:(Some l#coord) (Printf.sprintf "initial value for an external variable \"%s\" can not be specified" name)
        | _               -> name, (m,`Variable value)
      };

      parse[infix]:
        m:(%"local" {`Local} | %"public" e:(%"external")? {match e with None -> `Public | Some _ -> `PublicExtern} | %"external" {`Extern})
          locs:!(Util.list (local_var m infix)) next:";" {locs, infix}
    | - <(m, orig_name, name, infix', flag)> : head[infix] -"(" -args:!(Util.list0)[Pattern.parse] -")"
          (l:$ "{" body:exprScope[infix'][Expr.Weak] "}" {
            if flag && List.length args != 2 then report_error ~loc:(Some l#coord) "infix operator should accept two arguments";
            match m with
            | `Extern -> report_error ~loc:(Some l#coord) (Printf.sprintf "a body for external function \"%s\" can not be specified" (Subst.subst orig_name))
            | _       ->
               let args, body =
                 List.fold_right
                   (fun arg (args, body) ->
                     match arg with
                     | Pattern.Named (name, Pattern.Wildcard) -> name :: args, body
                     | Pattern.Wildcard -> env#get_tmp :: args, body
                     | p ->
                        let arg = env#get_tmp in
                        arg :: args, Expr.Case (Expr.Var arg, [p, body], l#coord, Expr.Weak)
                   )
                   args
                   ([], body)
               in
               [(name, (m, `Fun (args, body)))], infix'
         } |
         l:$ ";" {
            match m with
            | `Extern -> [(name, (m, `Fun ((List.map (fun _ -> env#get_tmp) args), Expr.Skip)))], infix' 
            | _       -> report_error ~loc:(Some l#coord) (Printf.sprintf "missing body for the function/infix \"%s\"" orig_name)
         })           
    ) in parse

  end
  
module Interface =
  struct
    
    (* Generates an interface file. *)
    let gen ((imps, ifxs), p) =
      let buf = Buffer.create 256 in
      let append str = Buffer.add_string buf str in
      List.iter (fun i -> append "I,"; append i; append ";\n") imps;
      (match p with
       | Expr.Scope (decls, _) ->
          List.iter
            (function
             | (name, (`Public, item)) | (name, (`PublicExtern, item))  ->
                (match item with
                 | `Fun _      -> append "F,"; append name; append ";\n"
                 | `Variable _ -> append "V,"; append name; append ";\n"
                )
             | _ -> ()
            )
            decls;
       | _ -> ());      
      List.iter
        (function (ass, op, loc) ->
           let append_op op = append "\""; append op; append "\"" in
           append (match ass with `Lefta -> "L," | `Righta -> "R," | _ -> "N,");
           append_op op;
           append ",";
           (match loc with `At op -> append "T,"; append_op op | `After op -> append "A,"; append_op op | `Before op -> append "B,"; append_op op);
           append ";\n"
        ) ifxs;
      Buffer.contents buf
      
    (* Read an interface file *)
    let read fname =
      let ostap (
              funspec: "F" "," i:IDENT ";" {`Fun i};
              varspec: "V" "," i:IDENT ";" {`Variable i};
              import : "I" "," i:IDENT ";" {`Import i};
              infix  : a:ass "," op:STRING "," l:loc ";" {`Infix (a, op, l)};
              ass    : "L" {`Lefta} | "R" {`Righta} | "N" {`Nona};
              loc    : m:mode "," op:STRING {m op};
              mode   : "T" {fun x -> `At x} | "A" {fun x -> `After x} | "B" {fun x -> `Before x};
              interface: (funspec | varspec | import | infix)*
            )
      in
      try
        let s = Util.read fname in
        (match Util.parse (object
                             inherit Matcher.t s
                             inherit Util.Lexers.ident [] s
                             inherit Util.Lexers.string s
                             inherit Util.Lexers.skip  [Matcher.Skip.whitespaces " \t\n"] s
                           end)             
                          (ostap (interface -EOF))
         with
         | `Ok intfs -> Some intfs
         | `Fail er  -> report_error (Printf.sprintf "malformed interface file \"%s\": %s" fname er)
        )
      with Sys_error _ -> None                        

    let find import paths =
      (*Printf.printf "Paths to search import in: %s" (show(list) (show(string)) paths); *)
      let rec inner = function
      | [] -> None
      | p::paths ->
         (match read (Filename.concat p (import ^ ".i")) with
          | None   -> inner paths
          | Some i -> Some (p, i)
         )
      in
      match inner paths with
      | Some (path, intfs) -> path, intfs
      | None               -> report_error (Printf.sprintf "could not find an interface file for import \"%s\"" import)

  end

(* The top-level definitions *)

(* Top-level evaluator

     eval : t -> int list -> int list

   Takes a program and its input stream, and returns the output stream
*)
let eval (_, expr) i =
  let _, _, o, _ = Expr.eval (State.empty, i, [], []) Skip expr in
  o

(* Top-level parser *)

ostap (
  imports[cmd]: l:$ is:(%"import" !(Util.list (ostap (UIDENT))) -";")* {
  let is    = "Std" :: List.flatten is in
  let infix =
    List.fold_left
      (fun infix import ->
        List.fold_left
          (fun infix item ->
             let insert name infix md = 
               let name = infix_name name in
               match md (Expr.sem name) infix with
               | `Ok infix' -> infix'
               | `Fail msg  -> report_error msg
             in
             match item with
             | `Infix (_  , op, `At     op') -> insert op infix (Infix.at l#coord op' op false)
             | `Infix (ass, op, `Before op') -> insert op infix (Infix.before l#coord op' op ass false)
             | `Infix (ass, op, `After  op') -> insert op infix (Infix.after l#coord op' op ass false)
             | _                             -> infix
          )
          infix
          (snd (Interface.find import cmd#get_include_paths))
      )
      Infix.default
      is
  in
  is, infix
};

(* Workaround until Ostap starts to memoize properly *)
    constparse[cmd]: <(is, infix)> : imports[cmd] d:!(Definition.constdef) {(is, []), Expr.Scope (d, Expr.materialize Expr.Weak Expr.Skip)}
(* end of the workaround *)
)

let parse cmd =
  let env =
    object
      val imports   = Pervasives.ref ([] : string list)
      val tmp_index = Pervasives.ref 0
                    
      method add_import imp = imports := imp :: !imports 
      method get_tmp        = let index = !tmp_index in incr tmp_index; Printf.sprintf "__tmp%d" index
      method get_imports    = !imports
    end
  in

  let makeDefinitions env exprBasic exprScope =
    let def = Definition.makeParser env exprBasic exprScope in
    let ostap (
      definitions[infix]:
         <(def, infix')> : def[infix] <(defs, infix'')> : definitions[infix'] {
           def @ defs, infix''
         }
      | empty {[], infix}
    )
    in
    definitions
  in

  let definitions = Pervasives.ref None in
  
  let (makeParser, makeBasicParser, makeScopeParser) = Expr.makeParsers env in
  
  let expr        s = makeParser      definitions s in
  let exprBasic   s = makeBasicParser definitions s in
  let exprScope   s = makeScopeParser definitions s in
  
  definitions := Some (makeDefinitions env exprBasic exprScope);

  let Some definitions = !definitions in
  
  let ostap (
      parse[cmd]:
        <(is, infix)> : imports[cmd]
        <(d, infix')> : definitions[infix] 
        expr:expr[infix'][Expr.Weak]? {
            (env#get_imports @ is, Infix.extract_exports infix'), Expr.Scope (d, match expr with None -> Expr.materialize Expr.Weak Expr.Skip | Some e -> e)
          }
        )
  in
  parse cmd
