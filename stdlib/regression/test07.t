This file was autogenerated.
  $ ../../src/Driver.exe -runtime ../../runtime -I ../../runtime -I ../../stdlib/x64 -ds -dp test07.lama -o test | grep -v 'section .note.GNU-stack'
  /usr/bin/ld: warning: printf.o: missing .note.GNU-stack section implies executable stack
  /usr/bin/ld: NOTE: This behaviour is deprecated and will be removed in a future version of the linker
  [1]
  $ ./test
  HashTab internal structure: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, {[{1, 2, 3}, 100]}, 0, 0, 0]
  HashTab internal structure: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, {[{1, 2, 3}, 200], [{1, 2, 3}, 100]}, 0, 0, 0]
  Searching: Some (200)
  Searching: Some (200)
  Replaced: Some (800)
  Restored: Some (200)
