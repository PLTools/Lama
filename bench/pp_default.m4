changequote([[,]])
define(HEADER_EXPR, [[
let rec pp_e pp_decl fself ppf root =
  let open Expr in
  match root with]])

define(METH, [[
  | $4 ->
      $5]])
define(METH0, [[
  | $3 ->
      $4]])
define(FOOTER_EXPR, [[]])
define(HEADER_DECL, [[
let rec pp_d fself pp_expr (name,ppf) root =
  let open Expr in
  match root with]])


define(FOOTER_DECL, [[]])

define(FIX, [[
let rec pp_decl ppf = pp_d pp_decl pp ppf
and pp ppf = pp_e pp_decl pp ppf
]])
