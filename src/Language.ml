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

    @type t =
    | Empty
    | Var    of string
    | Elem   of t * int
    | Int    of int
    | String of bytes
    | Array  of t array
    | Sexp   of string * t array
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

(* States *)
module State =
  struct

    (* State: global state, local state, scope variables *)
    type t =
    | G of (string -> Value.t)
    | L of string list * (string -> Value.t) * t

    (* Undefined state *)
    let undefined x = failwith (Printf.sprintf "Undefined variable: %s" x)

    (* Bind a variable to a value in a state *)
    let bind x v s = fun y -> if x = y then v else s y

    (* Empty state *)
    let empty = G undefined

    (* Update: non-destructively "modifies" the state s by binding the variable x
       to value v and returns the new state w.r.t. a scope
    *)
    let update x v s =
      let rec inner = function
      | G s -> G (bind x v s)
      | L (scope, s, enclosing) ->
         if List.mem x scope then L (scope, bind x v s, enclosing) else L (scope, s, inner enclosing)
      in
      inner s

    (* Evals a variable in a state w.r.t. a scope *)
    let rec eval s x =
      match s with
      | G s -> s x
      | L (scope, s, enclosing) -> if List.mem x scope then s x else eval enclosing x

    (* Creates a new scope, based on a given state *)
    let rec enter st xs =
      match st with
      | G _         -> L (xs, undefined, st)
      | L (_, _, e) -> enter e xs

    (* Drops a scope *)
    let leave st st' =
      let rec get = function
      | G _ as st -> st
      | L (_, _, e) -> get e
      in
      let g = get st in
      let rec recurse = function
      | L (scope, s, e) -> L (scope, s, recurse e)
      | G _             -> g
      in
      recurse st'

    (* Push a new local scope *)
    let push st s xs = L (xs, s, st)

    (* Drop a local scope *)
    let drop (L (_, _, e)) = e

  end

(* Builtins *)
module Builtin =
  struct

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
    type config = State.t * int list * int list * Value.t list

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
    (* leave a scope              *) | Leave
    (* intrinsic (for evaluation) *) | Intrinsic of (config -> config)
    (* control (for control flow) *) | Control   of (config -> t * config)

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
      match expr with
      | Unit     -> eval env (st, i, o, Value.Empty :: vs) Skip k
      | Ignore s -> eval env conf k (schedule_list [s; Intrinsic (fun (st, i, o, vs) -> (st, i, o, List.tl vs))])
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
         eval env conf k (schedule_list (xs @ [Intrinsic (fun (st, i, o, vs) -> let es, vs' = take (List.length xs) vs in env#definition env ".array" (List.rev es) (st, i, o, vs'))]))
      | Sexp (t, xs) ->
         eval env conf k (schedule_list (xs @ [Intrinsic (fun (st, i, o, vs) -> let es, vs' = take (List.length xs) vs in (st, i, o, Value.Sexp (t, Array.of_list (List.rev es)) :: vs'))]))
      | Binop (op, x, y) ->
         eval env conf k (schedule_list [x; y; Intrinsic (fun (st, i, o, y::x::vs) -> (st, i, o, (Value.of_int @@ to_func op (Value.to_int x) (Value.to_int y)) :: vs))])
      | Elem (b, i) ->
         eval env conf k (schedule_list [b; i; Intrinsic (fun (st, i, o, j::b::vs) -> env#definition env ".elem" [b; j] (st, i, o, vs))])
      | ElemRef (b, i) ->
         eval env conf k (schedule_list [b; i; Intrinsic (fun (st, i, o, j::b::vs) -> (st, i, o, (Value.Elem (b, Value.to_int j))::vs))])
      | Length e ->
         eval env conf k (schedule_list [e; Intrinsic (fun (st, i, o, v::vs) -> env#definition env ".length" [v] (st, i, o, vs))])
      | Call (Var f, args) ->
         eval env conf k (schedule_list (args @ [Intrinsic (fun (st, i, o, vs) -> let es, vs' = take (List.length args) vs in
                                                                                  env#definition env f (List.rev es) (st, i, o, vs'))]))
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
         | [] -> failwith (Printf.sprintf "Pattern matching failed: no branch is selected while matching %s\n" (show(Value.t) v))
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
             | Some st' -> eval env (State.push st st' (Pattern.vars patt), i, o, vs) k (Seq (body, Leave))
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

    (* ======= *)

    let left  f c x y = f (c x) y
    let right f c x y = c (f x y)

    let expr f ops opnd =
      let ops =
        Array.map
          (fun (assoc, list) ->
            let g = match assoc with `Lefta | `Nona -> left | `Righta -> right in
            assoc = `Nona, altl (List.map (fun (oper, sema) -> ostap (!(oper) {g sema})) list)
          )
          ops
      in
      let n      = Array.length ops in
      let op   i = snd ops.(i)      in
      let nona i = fst ops.(i)      in
      let id   x = x                in
      let ostap (
              inner[l][c]: f[ostap (
              {n = l                } => x:opnd {c x}
            | {n > l && not (nona l)} => x:inner[l+1][id] b:(-o:op[l] inner[l][o c x])? {
                                                                                                 match b with None -> c x | Some x -> x
                                                                                               }
                               | {n > l && nona l} => x:inner[l+1][id] b:(op[l] inner[l+1][id])? {
                                                            c (match b with None -> x | Some (o, y) -> o id x y)
                })]
            )
      in
      ostap (inner[0][id])

    (* ======= *)

    ostap (
      parse[infix]: h:basic[infix] t:(-";" parse[infix])? {match t with None -> h | Some t -> Seq (h, t)};
      basic[infix]:
	  !(expr
             (fun x -> x)
             (Array.map (fun (a, l) -> a, List.map (fun (s, f) -> ostap (- $(s)), f) l) infix)
	     (primary infix));
      primary[infix]:
        b:base[infix] is:(-"[" i:parse[infix] -"]" {`Elem i} | -"." (%"length" {`Len} | %"string" {`Str} | f:LIDENT {`Post f})) * {
        List.fold_left
          (fun b ->
            function
            | `Elem i -> Elem (b, i)
            | `Len    -> Length b
            | `Str    -> StringVal b
            | `Post f -> Call (Var f, [b])
          )
          b
          is
      };
      base[infix]:
        n:DECIMAL                                            {Const n}
      | s:STRING                                             {String (unquote s)}
      | c:CHAR                                               {Const  (Char.code c)}
      | "[" es:!(Util.list0)[parse infix] "]"                {Array es}
      | "{" es:!(Util.list0)[parse infix] "}"                {match es with
                                                              | [] -> Const 0
                                                              | _  -> List.fold_right (fun x acc -> Sexp ("cons", [x; acc])) es (Const 0)
                                                             }
      | t:UIDENT args:(-"(" !(Util.list)[parse infix] -")")? {Sexp (t, match args with None -> [] | Some args -> args)}
      | x:LIDENT s:("(" args:!(Util.list0)[parse infix] ")"  {Call (Var x, args)} | empty {Var x}) {s}

      | %"skip"                                              {Skip}

      | %"if" e:!(parse infix)
	%"then" the:parse[infix]
          elif:(%"elif" parse[infix] %"then" parse[infix])*
	  els:(%"else" parse[infix])?
        %"fi" {
          If (e, the,
	         List.fold_right
		   (fun (e, t) elif -> If (e, t, elif))
		   elif
		   (match els with None -> Skip | Some s -> s)
          )
        }

      | %"while" e:parse[infix] %"do" s:parse[infix] %"od" {While (e, s)}

      | %"for" i:parse[infix] "," c:parse[infix] "," s:parse[infix] %"do" b:parse[infix] %"od" {
	  Seq (i, While (c, Seq (b, s)))
                                                                                            }

      | %"repeat" s:parse[infix] %"until" e:basic[infix]  {Repeat (s, e)}
      | %"return" e:basic[infix]?                         {Return e}

      | %"case" e:parse[infix] %"of" bs:!(Util.listBy)[ostap ("|")][ostap (!(Pattern.parse) -"->" parse[infix])] %"esac" {Case (e, bs)}

      | -"(" parse[infix] -")"
    )

  end

(* Infix helpers *)
module Infix =
  struct

    type t = ([`Lefta | `Righta | `Nona] * (string * (Expr.t -> Expr.t -> Expr.t)) list) array

    let name infix =
      let b = Buffer.create 64 in
      Buffer.add_string b "__Infix_";
      Seq.iter (fun c -> Buffer.add_string b (string_of_int @@ Char.code c)) @@ String.to_seq infix;
      Buffer.contents b

    let default : t =
      Array.map (fun (a, s) ->
        a,
        List.map (fun s -> s,
                           (fun x y ->
                              match s with
                              | ":"  -> Expr.Sexp   ("cons", [x; y])
                              | "++" -> Expr.Call   (Var "strcat", [x; y])
                              | ":=" -> Expr.Assign (Expr.propagate_ref x, y)
                              | _    -> Expr.Binop  (s, x, y)
                           )
          ) s
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
        Array.iteri (fun i (_, l) -> if List.exists (fun (s, _) -> s = op) l then raise (Break (cb i))) infix;
        ce ()
      with Break x -> x

    let no_op op coord = `Fail (Printf.sprintf "infix ``%s'' not found in the scope at %s" op (Msg.Coord.toString coord))

    let sem name x y = Expr.Call (Var name, [x; y])

    let at coord op newp name infix =
      find_op infix op
        (fun i ->
          `Ok (Array.init (Array.length infix)
                 (fun j ->
                   if j = i
                   then let (a, l) = infix.(i) in (a, (newp, sem name) :: l)
                   else infix.(j)
            ))
        )
        (fun _ -> no_op op coord)

    let before coord op newp ass name infix =
      find_op infix op
        (fun i ->
          `Ok (Array.init (1 + Array.length infix)
                 (fun j ->
                   if j < i
                   then infix.(j)
                   else if j = i then (ass, [newp, sem name])
                   else infix.(j-1)
                 ))
        )
        (fun _ -> no_op op coord)

    let after coord op newp ass name infix =
      find_op infix op
        (fun i ->
          `Ok (Array.init (1 + Array.length infix)
                 (fun j ->
                   if j <= i
                   then infix.(j)
                   else if j = i+1 then (ass, [newp, sem name])
                   else infix.(j-1)
                 ))
        )
        (fun _ -> no_op op coord)

  end

(* Function and procedure definitions *)
module Definition =
  struct

    (* The type for a definition: name, argument list, local variables, body *)
    type t = string * (string list * string list * Expr.t)

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
          match md name infix with
          | `Ok infix' -> name, infix'
          | `Fail msg  -> raise (Semantic_error msg)
      };
      parse[infix]:
        <(name, infix')> : head[infix] "(" args:!(Util.list0 arg) ")"
           locs:(%"local" !(Util.list arg))?
        "{" body:!(Expr.parse infix') "}" {
        (name, (args, (match locs with None -> [] | Some l -> l), Expr.balance_void body)), infix'
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
let eval (defs, body) i =
  let module M = Map.Make (String) in
  let m          = List.fold_left (fun m ((name, _) as def) -> M.add name def m) M.empty defs in
  let _, _, o, _ =
    Expr.eval
      (object
         method definition env f args ((st, i, o, vs) as conf) =
           try
             let xs, locs, s       = snd @@ M.find f m in
             let st'               = List.fold_left (fun st (x, a) -> State.update x a st) (State.enter st (xs @ locs)) (List.combine xs args) in
             let st'', i', o', vs' = Expr.eval env (st', i, o, []) Skip s in
             (State.leave st'' st, i', o', match vs' with [v] -> v::vs | _ -> Value.Empty :: vs)
           with Not_found -> Builtin.eval conf args f
       end)
      (State.empty, i, [], [])
      Skip
      body
  in
  o

(* Top-level parser *)
ostap (
  parse[infix]: <(defs, infix')> : definitions[infix] body:!(Expr.parse infix') {defs, Expr.balance_void body};
  definitions[infix]:
    <(def, infix')> : !(Definition.parse infix) <(defs, infix'')> : definitions[infix'] {def::defs, infix''}
  | empty {[], infix}
)
