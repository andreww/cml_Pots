#!/bin/sh -e

m4 -DTESTINPUT="$1" test_str.f90.in > test_str.f90
make test_str.exe > /dev/null 2>&1
OUT=`./test_str.exe`
rm -f test_str.exe test_str.o test_str.f90

echo $OUT $2

if [ "$OUT" = \!"$2"\! ]; then
  echo Passed: $2
  echo 1 >> passed.score
  exit 0
else
  echo Failed: $2
  echo Failed: $2 >> failed.out
  echo 1 >> failed.score
  exit 1
fi
