This file was autogenerated.
  $ ../../src/Driver.exe -runtime ../../runtime -I ../../runtime -I ../../stdlib/x64 -ds -dp test06.lama -o test | grep -v 'section .note.GNU-stack'
  /usr/bin/ld: warning: printf.o: missing .note.GNU-stack section implies executable stack
  /usr/bin/ld: NOTE: This behaviour is deprecated and will be removed in a future version of the linker
  [1]
  $ ./test
  Flattening: 0
  Flattening: {0, 0, 0, 0}
  Flattening: 0
  Flattening: {1, 2, 3}
  Flattening: {1, 2, 3, 4, 5, 6, 7, 8, 9}
  List to array: [1, 2, 3, 4, 5]
  Array to list: {1, 2, 3, 4, 5}
