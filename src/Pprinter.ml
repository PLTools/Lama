open Language

class pp_pattern fself = object
  inherit [Format.formatter, Pattern.t, unit] Pattern.t_t

  method c_Wildcard ppf _ = Format.fprintf ppf "_"
  method c_Const ppf _ = Format.fprintf ppf "%d"
  method c_Named ppf _ name _ =
    (* TODO: should I ignore another argument? *)
    Format.fprintf ppf "%s" name
  method c_Sexp ppf _ name xs =
    match name,xs with
    | "cons", [l; r] ->
        Format.fprintf ppf "%a@ :@ %a" fself l fself r
    | _ ->
        Format.fprintf ppf "@[%s@ (" name;
        xs |> List.iter (Format.fprintf ppf "%a@ " fself);
        Format.fprintf ppf ")@] "

  method c_Array ppf _ xs =
    Format.fprintf ppf "@[{ ";
    Format.pp_print_list ~pp_sep:(fun ppf () -> Format.fprintf ppf ", ")
      fself ppf xs;
    Format.fprintf ppf " }@]"

  method c_ArrayTag ppf _ = Format.fprintf ppf "#array"
  method c_SexpTag ppf _ = Format.fprintf ppf "#sexp"
  method c_ClosureTag ppf _ = Format.fprintf ppf "#fun"
  method c_UnBoxed ppf _ = failwith "not implemented"
  method c_String ppf _ = failwith "not implemented"
  method c_StringTag ppf _ = failwith "not implemented"
  method c_Boxed ppf _ = failwith "not implemented"
end

let pp_pattern fmt p =
  GT.transform Pattern.t (new pp_pattern) fmt p

class pp_expr on_decl fself =
object
  inherit [Format.formatter, Expr.t, unit] Expr.t_t
  method c_Const ppf _ = Format.fprintf ppf "%d"
  method c_Var ppf _ = Format.fprintf ppf "%s"
  method c_Ref ppf _ = Format.fprintf ppf "%s"
  method c_Array ppf _ xs =
    Format.fprintf ppf "@[{@ ";
    xs |> List.iteri (fun i ->
      if i<>0 then Format.fprintf ppf ",@ ";
      fself ppf);
    Format.fprintf ppf " }@]"
  method c_String ppf _ s = Format.fprintf ppf "\"%s\"" s

  method c_Sexp ppf _ name xs =
    match name,xs with
    | "cons", [l;r] -> Format.fprintf ppf "@[%a : %a@]" fself l fself r
    | _ ->
        Format.fprintf ppf "@[%s@ (" name;
        xs |> List.iteri (fun i x ->
          if i<>0 then Format.fprintf ppf ", ";
          fself ppf x
        );
        Format.fprintf ppf ")@]"

  method c_Binop ppf _ op l r =
    Format.fprintf ppf "@[%a@ %s@ %a@]" fself l op fself r
  method c_Elem ppf _ l idx =
    Format.fprintf ppf "%a[%a]" fself l fself idx
  method c_ElemRef ppf _ l idx =
    (* TODO: should Elem and ElemRef be the same? *)
    Format.fprintf ppf "%a[%a]" fself l fself idx
  method c_Length ppf _ e =
    Format.fprintf ppf "@[(%a).length@]" fself e
  method c_StringVal ppf _ _x__519_ =
    Format.fprintf ppf "StringVal @[(@,%a@,)@]" fself _x__519_
  method c_Call ppf _ f args =
    Format.fprintf ppf "@[%a @[(" fself f;
    args |> List.iteri (fun i arg ->
      Format.fprintf ppf "%s%a" (if i<>0 then ", " else "") fself arg
    );
    Format.fprintf ppf ")@]@]"


  method c_Assign ppf _ _x__526_ _x__527_ =
    Format.fprintf ppf "@[%a@ :=@ %a@]" fself _x__526_ fself _x__527_
  method c_Seq ppf _ l r =
    Format.fprintf ppf "@[<v>%a;@ %a@]" fself l fself r
  method c_Skip ppf _ = Format.fprintf ppf "skip"
  method c_If ppf _ _x__533_ _x__534_ _x__535_ =
    Format.fprintf ppf "@[if %a then @[<v 2>{@,%a@]@ @[<v 2>} else {@,%a@]@ } fi@]"
      fself _x__533_ fself _x__534_ fself _x__535_
  method c_While ppf _ cond body =
    Format.fprintf ppf "@[<v 2>";
    Format.fprintf ppf "while %a do@," fself cond;
    fself ppf body;
    Format.fprintf ppf "@]@ ";
    Format.fprintf ppf "od";
    (*Format.fprintf inh___536_ "While @[(@,%a,@,@ %a@,)@]" fself
      cond fself body*)
  method c_Repeat ppf _ cond body =
    Format.fprintf ppf "@[<v 2>";
    Format.fprintf ppf "repeat@,%a" fself body;
    Format.fprintf ppf "until %a@]" fself cond


  method c_Case ppf _ scru cases _ _ =
    Format.fprintf ppf "@[<v>";
    Format.fprintf ppf "@[case %a of@ @]@," fself scru;
    Format.fprintf ppf "@[<v 0>";
    cases |> List.iteri (fun i (p,e) ->
      Format.fprintf ppf "@[%s %a@ ->@ %a@]@ " (if i=0 then " " else "|") pp_pattern p fself e
    );
    Format.fprintf ppf "@]";
    Format.fprintf ppf "@[esac@]";
    Format.fprintf ppf "@]"


  method c_Return ppf _ e =
    match e with
    | None -> Format.fprintf ppf "return"
    | Some e -> Format.fprintf ppf "@[return@ %a@]" fself e

  method c_Ignore ppf _ e =
    Format.fprintf ppf "@[%a@]" fself e
  method c_Unit ppf _ = Format.fprintf ppf "Unit "
  method c_Scope ppf _ xs body =
    Format.fprintf ppf "@[<v>";
    Format.pp_print_list ~pp_sep:(fun fmt () -> ())
      (fun ppf (name, d) ->
        Format.fprintf ppf "@[%a@]@," (fun ppf -> on_decl (name,ppf)) d)
      ppf xs;
    fself ppf body;
    Format.fprintf ppf "@]"

  method c_Lambda ppf _ args body =
    Format.fprintf ppf "@[fun (%a) { %a }@]"
      (Format.pp_print_list ~pp_sep:Format.pp_print_space Format.pp_print_text)
      args
      fself
      body

  method c_Leave ppf _ = Format.fprintf ppf "Leave "
  method c_Intrinsic ppf _ _ =
    Format.fprintf ppf "Intrinsic"

  method c_Control ppf _ _ =
    Format.fprintf ppf "Control"

end

class pp_decl fself on_expr  = object(self)
  inherit [ (string*Format.formatter), _, unit] Expr.decl_t
  method qualifier ppf : Expr.qualifier -> _ = function
    | `Local -> ()
    | `Extern -> Format.fprintf ppf "extern@ "
    | `Public -> Format.fprintf ppf "public@ "
    | `PublicExtern -> Format.fprintf ppf "not implemented %d" __LINE__

  method args ppf =
    Format.fprintf ppf "%a" @@
    Format.pp_print_list ~pp_sep:(fun ppf () -> Format.fprintf ppf ",")
      (Format.pp_print_text)

  method c_DECL (name,ppf) (qual, (item: [`Fun of string list * Expr.t | `Variable of Expr.t GT.option])) =
    match item with
    | `Variable(None) -> Format.fprintf ppf "local %s;" name
    | `Variable(Some e) ->
        Format.fprintf ppf "local %s = %a;" name on_expr e
    | `Fun (ss,e) ->
        Format.fprintf ppf "@[<v>";
        Format.fprintf ppf "@[%afun %s (%a) @]@," self#qualifier qual name self#args ss;
        Format.fprintf ppf "@[<v 2>{@,@[%a@]@]@ " on_expr e;
        Format.fprintf ppf "}";
        Format.fprintf ppf "@]"

end


let fix_decl decl0 t0 =
  let rec traitdecl inh subj =
    Expr.gcata_decl (decl0 traitdecl traitt) inh subj
  and traitt inh subj =
    Expr.gcata_t (t0 traitdecl traitt) inh subj
  in
  (traitdecl, traitt)

let pp fmt s =
  snd (fix_decl (new pp_decl) (new pp_expr)) fmt s

let pp ppf ast =
  let margin =
    try int_of_string @@ Sys.getenv "LAMA_MARGIN"
    with Failure _ | Not_found -> 35
  in
  Format.set_margin margin;
  Format.set_max_indent 15;
  Format.printf "%a\n%!" pp ast
