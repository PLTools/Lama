#!/bin/bash
for i in {1..9}
do
   make test00$i
done

for i in {0..9}
do
  make test01$i
done

for i in {0..9}
do
  make test02$i
done

make test034
make test036

