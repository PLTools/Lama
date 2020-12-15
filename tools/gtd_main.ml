open Language
type mode = GoToDef | Usages
type config =
  { mutable filename : string
  ; mutable pos : string
  ; mutable line : int
  ; mutable col: int
  ; mutable mode: mode
  }

let config = { filename= "file.ml"; pos="0,0"; line=0; col=0; mode = GoToDef }
let parse_loc loc =
  Scanf.sscanf loc "%d,%d" (fun l c -> config.line <- l; config.col <- c)

let () =
  Arg.parse
    [ "-pos", String parse_loc, "L,C when L is line and C is column"
    ; "-def", Unit (fun () -> config.mode <- GoToDef), "go to definition"
    ; "-use", Unit (fun () -> config.mode <- Usages), "find usages"
    ]
    (fun name -> config.filename <- name)
    "Help"


module Introduced = Map.Make(String)

exception DefinitionFound of (string * Loc.t)

let do_find e =
  let on_name name map =
    match Loc.get name with
    | Some (l,c) when l=config.line && c = config.col ->
        (* we found what we want *)
        let (l,c) = Introduced.find name map in
        raise (DefinitionFound (name,(l,c)))
    | _ -> map
  in

  (* looks for line,col in the tree *)
  let ooo (foldl_decl, fself) = object
    inherit [_,_] Language.Expr.foldl_t_t_stub (foldl_decl, fself) as super
    method! c_Var _inh _ name = on_name name _inh
    method! c_Ref _inh _ name = on_name name _inh
    method c_Scope inh e names r =
      let map = ListLabels.fold_left ~init:inh names ~f:(fun acc (fname,(_,info)) ->
        let acc = Introduced.add fname (Loc.get_exn fname) acc in
        match info with
        | `Variable _ ->  acc
        | `Fun (args, _body) ->
            List.fold_left (fun acc name -> Introduced.add name (Loc.get_exn name) acc) acc args
        )
      in
      super#c_Scope map e names r
  end in

  (* Format.printf "STUB. Ht size = %d\n%!" (Loc.H.length Loc.tab);
  Loc.H.iter (fun k (l,c) -> Format.printf "%s -> (%d,%d)\n%!" k l c) Loc.tab; *)

  let (_,fold_t) = Expr.fix_decl Expr.foldl_decl_0 ooo in
  match fold_t Introduced.empty e with
  | exception (DefinitionFound arg) -> Some arg
  | _ -> None


let find_usages root (def_name,(_,_)) =
  let on_name name acc =
    if String.equal def_name name
    then (Loc.get_exn name) :: acc
    else acc
  in

  let ooo (foldl_decl, fself) = object
    inherit [_,_] Language.Expr.foldl_t_t_stub (foldl_decl, fself) as super
    method! c_Var _inh _ name = on_name name _inh
    method! c_Ref _inh _ name = on_name name _inh
    method c_Scope inh e names r =
      (* if we hide interesting name, then we stop the search *)
      if List.exists (fun (n,_) -> String.equal n def_name) (names : (string * _) list)
      then inh
      else super#c_Scope inh e names r
  end in

  let (_,fold_t) = Expr.fix_decl Expr.foldl_decl_0 ooo in
  fold_t [] root


let () =
  let cfg = object
    method get_include_paths = ["."; "./runtime"] method get_infile = config.filename method is_workaround=false end
  in
  match Language.run_parser cfg with
  | `Fail s -> failwith s
  | `Ok ((_,_), e) ->
      Format.printf "%s\n%!" (GT.show Expr.t e);
      match do_find e with
      | None -> Format.printf "Definition not found\n%!"
      | Some (name,(l,c)) ->
          match config.mode with
          | GoToDef -> Format.printf "found definition for `%s` at (%d,%d)\n%!" name l c;
          | Usages ->
              let locs = find_usages e (name,(l,c)) in
              Format.printf "Total %d usages found\n%!" (List.length locs);
              List.iter (fun (l,c) -> Format.printf "(%d,%d) %!" l c) locs;
              Format.printf "\n%!"
