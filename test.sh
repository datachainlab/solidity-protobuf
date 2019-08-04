#!/usr/bin/env bash
set -e
for file in proto/*
do
  if [[ -f $file ]]; then
    echo "Generating "$file
    protoc -I$(pwd)/proto -I$(pwd)/pb3sol/src/protoc/include --plugin=protoc-gen-sol=$(pwd)/pb3sol/src/protoc/plugin/gen_sol.py --sol_out=gen_runtime=runtime.sol:$(pwd)/contracts/libs/ $(pwd)/$file
  fi
done

truffle compile

truffle test
