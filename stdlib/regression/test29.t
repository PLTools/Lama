This file was autogenerated.
  $ ../../src/Driver.exe -runtime ../../runtime -I ../../runtime -I ../../stdlib/x64 -ds -dp test29.lama -o test | grep -v 'section .note.GNU-stack'
  /usr/bin/ld: warning: printf.o: missing .note.GNU-stack section implies executable stack
  /usr/bin/ld: NOTE: This behaviour is deprecated and will be removed in a future version of the linker
  [1]
  $ ./test
  Succ (Seq ("a", "b"))
  Succ (Alt ("a"))
  Succ (Alt ("b"))
  Succ (Rep ({"a", "a", "a"}))
