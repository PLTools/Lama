#!/usr/bin/env bash

mkdir tmp-lama
cp runtime/Std.i tmp-lama
cp runtime/runtime.a tmp-lama
cp -R stdlib/* tmp-lama
