(* let () =

  let lamas = List.filter (String.ends_with ~suffix:".lama") (Sys.readdir "." |> Array.to_list)
  |> List.sort String.compare in
  (* List.iter print_endline lamas; *)
  ()
 *)

let () =
  for i=0 to 2 do
    let test = In_channel.with_open_text (Printf.sprintf "generated%05d.input" i) In_channel.input_all in
    let test = String.split_on_char '\n' test
      (* |> List.filter ((<>)"") *)
    in

    Out_channel.with_open_text (Printf.sprintf "r%05d.t" i) (fun ch ->
      Printf.fprintf ch "  $ cat > test.input <<EOF\n";
      List.iter (Printf.fprintf ch "  > %s\n") test;
      Printf.fprintf ch "  > EOF\n";
      Printf.fprintf ch "  $ cat test.input\n";
      Printf.fprintf ch "  $ ls -l\n";
      Printf.fprintf ch "  $ LAMA=../../runtime ../../src/Driver.exe -i generated%05d.lama" i
      )
  done