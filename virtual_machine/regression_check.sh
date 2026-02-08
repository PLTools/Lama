#!/usr/bin/env bash

# credit: ProgramSnail

make build

prefix="../regression/"
suffix=".lama"

compiler=../_build/default/src/Driver.exe

echo "Used compiler path:"
echo $compiler

for test in ../regression/*.lama; do
  echo $test
  $compiler -b $test >/dev/null
  test_path="${test%.*}"
  test_file="${test_path##*/}"
  echo $test_path: $test_file
  cat $test_path.input | ./vm.exe $test_file.bc >test.log 2>&1
  sed -E '1d;s/^//' $test_path.t >test_orig.log
  diff -w test.log test_orig.log

  rm $test_file.bc
  rm test.log test_orig.log
  echo "done"
done

rm *.o
