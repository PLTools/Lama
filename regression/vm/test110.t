  $ ../../src/Driver.exe -runtime ../../runtime -I ../../stdlib/x64 -b ../test110.lama
  Fatal error: exception Failure("Indirect assignment is not supported yet: If (Const (1), Scope ([], ElemRef (Var (\"x\"), Const (0))), Scope ([], ElemRef (Var (\"y\"), Const (0))))")
  [2]
  $ ../../virtual_machine/lama.exe test110.bc < ../test110.input
  Failed to load unit 'test110'
  [1]
