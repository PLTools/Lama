(* Run as `ocaml gen.ml` *)

let count = 35
let stdlib = ["Array"; "Buffer"; "Collection"; "Data"; "Fun"; "Lazy"; "List"; "Matcher"; "Ostap"; "Random"; "Ref"; "STM"; "Timer" ]
let sprintf = Printf.sprintf

let () =
  Out_channel.with_open_text "dune" (fun dunech ->
      let dprintfn fmt = Format.kasprintf (Printf.fprintf dunech "%s\n") fmt in
      dprintfn "; This file was autogenerated\n";
      dprintfn "(cram (deps ../../src/Driver.exe))";
      dprintfn "(cram (deps ../../runtime32/runtime.a ../../runtime32/Std.i))";
      dprintfn "(cram (deps ../../runtime/runtime.a ../../runtime/Std.i))";
      dprintfn "(cram (deps %s))"
        (String.concat " " (List.concat_map (fun s ->
            [sprintf "../x32/%s.i" s
            ;sprintf "../x32/%s.o" s
            ])
            stdlib));
      dprintfn "(cram (deps %s))"
      (String.concat " " (List.concat_map (fun s ->
          [sprintf "../x64/%s.i" s
          ;sprintf "../x64/%s.o" s
          ])
          stdlib));

      for i = 0 to count - 1 do
        let cram_buf = Buffer.create 100 in
        let cram_printfn fmt =
          Format.kasprintf (Printf.bprintf cram_buf "%s\n") fmt
        in
        let cram_file = ref (Printf.sprintf "test%02d.t" i) in
        let lama_file = ref (Printf.sprintf "test%02d.lama" i) in

        let found =
          if Sys.file_exists !lama_file && i <> 30 then (
            (* cram_printfn "  $ ls ../x64"; *)
            cram_printfn
              "  $ LAMA=../../runtime ../../src/Driver.exe -I ../x64 -ds -dp test%02d.lama -o test" i;
            cram_printfn "  $ ./test";
            true)
          else   false
        in
        if found then (
          dprintfn "(cram (applies_to test%02d)"            i;
          dprintfn "  (deps %s))" !lama_file;
          Out_channel.with_open_text !cram_file (fun ch ->
              output_string ch "This file was autogenerated.\n";
              output_string ch (Buffer.contents cram_buf)))
      done)