open Language

(* Test using:
    mkae -C tools && LAMA=./runtime tools/gtd.exe tools/demo1.lama -pos 20,22 -use
  should give:
    found definition for `f` at (17,19)
    Total 2 usages found
    (5,25) (5,22)
*)
type mode = GoToDef | Usages
type config =
  { mutable filename : string
  ; mutable pos : string
  ; mutable line : int
  ; mutable col: int
  ; mutable mode: mode
  ; mutable includes : string list
  }

let config = { filename= "file.ml"; pos="0,0"; line=0; col=0; mode = GoToDef; includes = ["."; "./runtime"] }
let _ = if false then config.pos <- "" else ignore config.pos
let parse_loc loc =
  Scanf.sscanf loc "%d,%d" (fun l c -> config.line <- l; config.col <- c)

let () =
  Arg.parse
    [ "-pos", String parse_loc, "L,C when L is line and C is column"
    ; "-def", Unit (fun () -> config.mode <- GoToDef), "go to definition"
    ; "-use", Unit (fun () -> config.mode <- Usages), "find usages"
    ; "-I", String (fun s -> config.includes <- s :: config.includes), " Add include path"
    ]
    (fun name -> config.filename <- name)
    "Help"


module Introduced = struct
  include Map.Make(String)
  let extend k v map =
    (* Format.printf "extending '%s' -> (%d,%d)\n%!" k (fst v) (snd v); *)
    add k (k,v) map
end
exception DefinitionFound of (string * Loc.t)

let do_find e =
  let on_name name map =
    match Loc.get name with
    | Some (l,c) when l=config.line && c = config.col ->
        (* we found what we want *)
        let (key,(l,c)) = Introduced.find name map in
        raise (DefinitionFound (key,(l,c)))
    | _ -> map
  in

  (* looks for line,col in the tree *)
  let ooo (foldl_decl, fself) = object
    inherit [_,_] Language.Expr.foldl_t_t_stub (foldl_decl, fself) as super
    method! c_Var _inh _ name = on_name name _inh
    method! c_Ref _inh _ name = on_name name _inh
    method! c_Scope init e names r =
      let map = ListLabels.fold_left ~init names ~f:(fun acc (fname,(_,info)) ->
        let acc = Introduced.extend fname (Loc.get_exn fname) acc in
        match info with
        | `Variable _ ->  acc
        | `Fun (args, body) ->
            let acc2 = List.fold_left (fun acc arg_name -> Introduced.extend arg_name (Loc.get_exn arg_name) acc) acc args in
            let _ = fself acc2 body in
            acc
        )
      in
      super#c_Scope map e names r
  end in

  (* Format.printf "STUB. Ht size = %d\n%!" (Loc.H.length Loc.tab);
  Loc.H.iter (fun k (l,c) -> Format.printf "%s -> (%d,%d)\n%!" k l c) Loc.tab; *)

  let (_,fold_t) = Expr.fix_decl_t Expr.foldl_decl_0 ooo in
  match fold_t Introduced.empty e with
  | exception (DefinitionFound arg) -> Some arg
  | _ -> None


let find_usages root (def_name,(_,_)) =
  let on_name name acc =
    if String.equal def_name name
    then (Loc.get_exn name) :: acc
    else acc
  in

  let ooo (foldl_decl, fself) = object(self)
    inherit [_,_] Language.Expr.foldl_t_t_stub (foldl_decl, fself) as super
    method! c_Var (acc,in_scope) _ name =
      if in_scope then (on_name name acc, in_scope) else (acc, in_scope)
    method! c_Ref (acc,in_scope) _ name =
      self#c_Var (acc,in_scope) (Var name) name
    method! c_Scope init e names r =
      ListLabels.fold_left ~init names ~f:(fun ((acc, in_scope) as inh) (name,info) ->
        match (in_scope, String.equal def_name name) with
        | (true, true) -> (acc, false)
        | (true, _) -> begin
            match snd info with
            | `Fun (args, _) when List.mem def_name args ->  inh
            | `Fun (_, body) -> fself inh body
            | `Variable (Some rhs) -> fself inh rhs
            | `Variable None -> inh
        end
        | (false, true) -> super#c_Scope (acc,true) e names r
        | false,false -> begin
            match snd info with
            | `Fun (args, body) when List.memq def_name args -> fself (acc,true) body
            | `Fun (_, body) -> fself inh body
            | `Variable (Some rhs) -> fself inh rhs
            | `Variable None -> inh
        end
      ) |> (fun acc -> fself acc r)
  end in

  let (_,fold_t) = Expr.fix_decl_t Expr.foldl_decl_0 ooo in
  fold_t ([],false) root


let () =
  let cfg = object
    method get_include_paths = ["."; "./runtime"; "../runtime"]
    method get_infile = config.filename
    method is_workaround = false
  end
  in
  match Language.run_parser cfg with
  | `Fail s -> failwith s
  | `Ok ((_,_), e) ->
      (* Format.printf "%s\n%!" (GT.show Expr.t e); *)
      match do_find e with
      | None -> Format.printf "Definition not found\n%!"
      | Some (name,(l,c)) ->
          match config.mode with
          | GoToDef -> Format.printf "found definition for `%s` at (%d,%d)\n%!" name l c;
          | Usages ->
              Format.printf "found definition for `%s` at (%d,%d)\n%!" name l c;
              let (locs,_) = find_usages e (name,(l,c)) in
              Format.printf "Total %d usages found\n%!" (List.length locs);
              List.iter (fun (l,c) -> Format.printf "(%d,%d) %!" l c) locs;
              Format.printf "\n%!"
