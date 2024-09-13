#use "topfind";;
#require "str";;
let demos = ["Expressions"; "Functions"; "Hello"; "PatternMatching"; "Values"]

let template = {|
(rule
 (targets %DEMO%.exe)
 %COND%
 (deps (:lama %DEMOSRC%.lama) %RUNTIME%/runtime.a %STDLIB%/Fun.i)
 (mode
  (promote (until-clean)))
 (action
  (setenv
   LAMA
   "%RUNTIME%"
   (run
    %{project_root}/src/Driver.exe
    %EXTRASWITCHES%
    %{lama}
    -I
    %STDLIB%
    -I
    %RUNTIME%
    -o
    %{targets}))))
|}

let () =
  Out_channel.with_open_text "dune" (fun ch ->
    List.iter (fun demo ->
      template
      |> Str.global_replace (Str.regexp "%DEMO%") (demo^".x32")
      |> Str.global_replace (Str.regexp "%DEMOSRC%") demo
      |> Str.global_replace (Str.regexp "%COND%") {|(enabled_if (= %{ocaml-config:os_type} "linux"))|}
      |> Str.global_replace (Str.regexp "%RUNTIME%") "../runtime32"
      |> Str.global_replace (Str.regexp "%STDLIB%") "../stdlib/x32"
      |> Str.global_replace (Str.regexp "%EXTRASWITCHES%") "-march=x86"
      |> output_string ch;
      template
      |> Str.global_replace (Str.regexp "%DEMO%") (demo^".x64")
      |> Str.global_replace (Str.regexp "%DEMOSRC%") demo
      |> Str.global_replace (Str.regexp "%COND%") ""
      |> Str.global_replace (Str.regexp "%RUNTIME%") "../runtime"
      |> Str.global_replace (Str.regexp "%STDLIB%") "../stdlib/x64"
      |> Str.global_replace (Str.regexp "%EXTRASWITCHES%") "-march=x86_64"
      |> output_string ch;
    ) demos)
