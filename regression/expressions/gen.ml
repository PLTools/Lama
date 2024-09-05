
let count = 10000
let () =
  Out_channel.with_open_text "dune" (fun dunech ->
    let dprintfn fmt = Format.kasprintf (Printf.fprintf dunech "%s\n") fmt in
    dprintfn "(cram (deps ../../src/Driver.exe ../../runtime/Std.i))\n";
  for i=0 to count / 10 do
    let cram_buf = Buffer.create 100 in
    let cram_printfn fmt = Format.kasprintf (Printf.bprintf cram_buf "%s\n") fmt in
    let cram_file = Printf.sprintf "r%04dx.t" i in
    let deps = ref [] in
    for j=0 to 9 do
      let k = (i*10+j) in
      let lama_file = Printf.sprintf "generated%05d.lama" k in

      if Sys.file_exists lama_file then
        let test =
          In_channel.with_open_text (Printf.sprintf "generated%05d.input" k) In_channel.input_all
          |> String.split_on_char '\n' |> List.filter ((<>)"")
        in
        (
        deps := lama_file :: !deps;
        cram_printfn "  $ cat > test.input <<EOF";
        List.iter (cram_printfn "  > %s") test;
        cram_printfn "  > EOF";
        cram_printfn "  $ LAMA=../../runtime ../../src/Driver.exe -i generated%05d.lama < test.input" k
        )
    done;
    match !deps with
    | [] -> ()
    | xs ->
       (Printf.fprintf dunech "(cram (applies_to r%04dx)\n" i;
        Printf.fprintf dunech "  (deps %s))\n%!" (String.concat " " xs);
        Out_channel.with_open_text cram_file (fun ch ->
          output_string ch (Buffer.contents cram_buf)
        )
        )
  done
  )
(*
let () =

    for i=0 to count do
      if Sys.file_exists (Printf.sprintf "generated%05d.lama" i) then
        (Printf.fprintf ch "(cram (applies_to r%05d)\n" i;
        Printf.fprintf ch "  (deps generated%05d.lama))\n%!" i;)
    done *)
