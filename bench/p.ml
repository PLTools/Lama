open Language

class pp_pattern fself = object
  inherit [Pattern.t] Pattern.fmt_t_t fself

  method! c_Wildcard ppf _ = Format.fprintf ppf "_"
  method! c_Const ppf _ = Format.fprintf ppf "%d"
  method! c_Named ppf _ name _ =
    (* TODO: should I ignore another argument? *)
    Format.fprintf ppf "%s" name
  method! c_Sexp ppf _ name xs =
    match name,xs with
    | "cons", [l; r] ->
        Format.fprintf ppf "%a@ :@ %a" fself l fself r
    | _ ->
        Format.fprintf ppf "@[%s@ (" name;
        xs |> List.iter (Format.fprintf ppf "%a@ " fself);
        Format.fprintf ppf ")@] "

  method! c_Array ppf _ xs =
    Format.fprintf ppf "@[{ ";
    Format.pp_print_list ~pp_sep:(fun ppf () -> Format.fprintf ppf ", ")
      fself ppf xs;
    Format.fprintf ppf " }@]"

  method! c_ArrayTag ppf _ = Format.fprintf ppf "#array"
  method! c_SexpTag ppf _ = Format.fprintf ppf "#sexp"
  method! c_ClosureTag ppf _ = Format.fprintf ppf "#fun"
end

let pp_pattern fmt p =
  GT.transform Pattern.t (new pp_pattern) fmt p

HEADER_EXPR
METH(Const, ppf, n, Const n, Format.fprintf ppf "%d" n)
METH(Var, ppf, s, Var s, Format.fprintf ppf "%s" s)
METH(Ref, ppf, s, Ref s, Format.fprintf ppf "%s" s)
METH(String, ppf, s, String s, Format.fprintf ppf "\"%s\"" s)
METH(Array, ppf, xs, Array xs, [[Format.fprintf ppf "@[{@ ";
xs |> List.iteri (fun i ->
  if i<>0 then Format.fprintf ppf ",@ ";
  fself ppf);
Format.fprintf ppf " }@]"]]
)
METH(Sexp, ppf, name xs, [[Sexp (name,xs)]], [[(match name,xs with
| "cons", [l;r] -> Format.fprintf ppf "@[%a : %a@]" fself l fself r
| _ ->
    Format.fprintf ppf "@[%s@ (" name;
    xs |> List.iteri (fun i x ->
      if i<>0 then Format.fprintf ppf ", ";
      fself ppf x
    );
    Format.fprintf ppf ")@]")
]])
METH(Binop, ppf, op l r, Binop (op, l, r), [[Format.fprintf ppf "@[%a@ %s@ %a@]" fself l op fself r]])
METH(Elem, ppf, l idx, Elem (l,idx), [[Format.fprintf ppf "%a[%a]" fself l fself idx]])
METH(ElemRef, ppf, l idx, ElemRef (l,idx), [[Format.fprintf ppf "%a[%a]" fself l fself idx]])
METH(Length, ppf, e, Length e, [[Format.fprintf ppf "@[(%a).length@]" fself e]])

METH(StringVal, ppf, _x__519_, StringVal _x__519_, [[Format.fprintf ppf "StringVal @[(@,%a@,)@]" fself _x__519_]])



METH(Call, ppf, f args, Call (f,args), [[Format.fprintf ppf "@[%a @[(" fself f;
args |> List.iteri (fun i arg ->
  Format.fprintf ppf "%s%a" (if i<>0 then ", " else "") fself arg
);
Format.fprintf ppf ")@]@]"]])

METH(Assign, ppf, l r, Assign (l,r), [[Format.fprintf ppf "@[%a@ :=@ %a@]" fself l fself r]])
METH(Seq, ppf, l r, Seq (l,r), [[Format.fprintf ppf "@[<v>%a;@ %a@]" fself l fself r]])


METH(Skip, ppf, , Skip, [[ Format.fprintf ppf "skip" ]])

METH(If, ppf, c th el, If (c,th,el), [[
Format.fprintf ppf "@[if %a then @[<v 2>{@,%a@]@ @[<v 2>} else {@,%a@]@ } fi@]"
  fself c fself th fself el]])

METH(While, ppf, cond body, While(cond,body), [[
Format.fprintf ppf "@[<v 2>";
Format.fprintf ppf "while %a do@," fself cond;
fself ppf body;
Format.fprintf ppf "@]@ ";
Format.fprintf ppf "od"]])

METH(Repeat, ppf, cond body, Repeat(cond,body), [[
Format.fprintf ppf "@[<v 2>";
Format.fprintf ppf "repeat@,%a" fself body;
Format.fprintf ppf "until %a@]" fself cond]])

METH(Case, ppf, scru cases _ _, Case(scru, cases, _,_), [[
Format.fprintf ppf "@[<v>";
Format.fprintf ppf "@[case %a of@ @]@," fself scru;
Format.fprintf ppf "@[<v 0>";
cases |> List.iteri (fun i (p,e) ->
  Format.fprintf ppf "@[%s %a@ ->@ %a@]@ " (if i=0 then " " else "|") pp_pattern p fself e
);
Format.fprintf ppf "@]";
Format.fprintf ppf "@[esac@]";
Format.fprintf ppf "@]"]])

METH(Return, ppf, e, Return e, [[(match e with
| None -> Format.fprintf ppf "return"
| Some e -> Format.fprintf ppf "@[return@ %a@]" fself e)]])

METH(Ignore, ppf, e, Ignore e, Format.fprintf ppf "@[%a@]" fself e)
METH(Unit, ppf, , Unit, Format.fprintf ppf "Unit ")
METH(Scope, ppf, xs body, Scope(xs,body), [[Format.fprintf ppf "@[<v>";
Format.pp_print_list ~pp_sep:(fun fmt () -> ())
  (fun ppf (name, d) ->
    Format.fprintf ppf "@[%a@]@," (fun ppf -> pp_decl (name,ppf)) d)
  ppf xs;
fself ppf body;
Format.fprintf ppf "@]"]])

METH(Lambda, ppf, args body, Lambda(args, body), [[
Format.fprintf ppf "@[fun (%a) { %a }@]"
    (Format.pp_print_list ~pp_sep:Format.pp_print_space Format.pp_print_text)
    args
    fself
    body
]])

METH(Leave, ppf, , Leave, Format.fprintf ppf "Leave ")

METH(Intrinsic, ppf, _x__584_, Intrinsic _, Format.fprintf ppf "Intrinsic ")
METH(Control, ppf, _x__584_, Control _, Format.fprintf ppf "Control ")

FOOTER_EXPR

let args ppf =
  Format.fprintf ppf "%a" @@
  Format.pp_print_list ~pp_sep:(fun ppf () -> Format.fprintf ppf ",")
    (Format.pp_print_text)

let pp_qualifier ppf : Expr.qualifier -> _ = function
  | `Local -> ()
  | `Extern -> Format.fprintf ppf "extern@ "
  | `Public -> Format.fprintf ppf "public@ "
  | `PublicExtern -> Format.fprintf ppf "not implemented %d" __LINE__

HEADER_DECL
METH0(DECL, (name,ppf), (qual,item), [[
  let _: [`Fun of string list * Expr.t | `Variable of Expr.t GT.option] = item in
  match item with
  | `Variable(None) -> Format.fprintf ppf "local %s;" name
  | `Variable(Some e) ->
      Format.fprintf ppf "local %s = %a;" name pp_expr e
  | `Fun (ss,e) ->
      Format.fprintf ppf "@[<v>";
      Format.fprintf ppf "@[%afun %s (%a) @]@," pp_qualifier qual name args ss;
      Format.fprintf ppf "@[<v 2>{@,@[%a@]@]@ " pp_expr e;
      Format.fprintf ppf "}";
      Format.fprintf ppf "@]"]]
)
FOOTER_DECL

FIX
