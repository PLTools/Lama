This file was autogenerated.
  $ ../../src/Driver.exe -runtime ../../runtime -I ../../runtime -I ../../stdlib/x64 -ds -dp test28.lama -o test 2>&1 | grep -v 'missing .note.GNU-stack'
  /usr/bin/ld: NOTE: This behaviour is deprecated and will be removed in a future version of the linker
  $ ./test
  Succ (Seq ("a", "b"))
  Succ (Alt ("a"))
  Succ (Alt ("b"))
  Succ (Rep ({"a", "a", "a"}))
