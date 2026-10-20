  $ ../../src/Driver.exe -runtime ../../runtime -I ../../stdlib/x64 -b ../test054.lama
  Fatal error: exception Failure("Indirect assignment is not supported yet: If (Var (\"z\"), Scope ([], Ref (\"x\")), Scope ([], Ref (\"y\")))")
  [2]
  $ ../../virtual_machine/lama.exe test054.bc < ../test054.input
  Failed to load unit 'test054'
  [1]
