changequote([[,]])
define(HEADER_EXPR, [[
class pp_e pp_decl fself  = object
  inherit [Format.formatter, Expr.t, unit] Expr.t_t
  ]])

define(METH, [[
  method c_$1 $2 _ $3 =
    $5
]])
define(METH0, [[
  method c_$1 $2 $3 =
    $4]])
define(FOOTER_EXPR, [[
end (* class *)
]])
define(HEADER_DECL, [[
class pp_d fself pp_expr  =
let (_: (string*Format.formatter) -> Expr.decl -> unit) = fself in
let (_: Format.formatter -> Expr.t -> unit) = pp_expr  in
object
  inherit [(string*Format.formatter), _, unit] Expr.decl_t]])


define(FOOTER_DECL, [[
end (* class *)
]])
define(FIX, [[

let fix_decl decl0 t0 =
  let rec traitdecl inh subj =
    Expr.gcata_decl (decl0 traitdecl traitt) inh subj
  and traitt inh subj =
    Expr.gcata_t (t0 traitdecl traitt) inh subj
  in
  (traitdecl, traitt)

let pp fmt s =
  snd (fix_decl (new pp_d) (new pp_e)) fmt s
]])
