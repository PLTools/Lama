This file was autogenerated.
  $ ../../src/Driver.exe -runtime ../../runtime -I ../../runtime -I ../../stdlib/x64 -ds -dp test16.lama -o test | grep -v 'section .note.GNU-stack'
  /usr/bin/ld: warning: printf.o: missing .note.GNU-stack section implies executable stack
  /usr/bin/ld: NOTE: This behaviour is deprecated and will be removed in a future version of the linker
  [1]
  $ ./test
  Succ (Eq ("a", "a"))
  Succ (Eq ("b", "b"))
  Succ (Eq (Mul ("a", "a"), Mul ("a", "a")))
  Succ (Eq (Mul ("b", "b"), Mul ("b", "b")))
  Succ (Eq (Add (Mul ("a", "a"), Sub (Div ("a", "a"), Mul ("a", "a"))), Sub (Mul ("a", "a"), "a")))
  Succ (Eq (Add (Mul ("b", "b"), Sub (Div ("b", "b"), Mul ("b", "b"))), Sub (Mul ("b", "b"), "b")))
