#!/usr/bin/env bash
set -e
for file in proto/*
do
  if [[ -f $file ]]; then
    echo "Generating "$file
    protoc -I$(pwd)/proto -I$(pwd)/protobuf-solidity/src/protoc/include --plugin=protoc-gen-sol=$(pwd)/protobuf-solidity/src/protoc/plugin/gen_sol.py --"sol_out=gen_runtime=ProtoBufRuntime.sol&solc_version=0.5.16:$(pwd)/contracts/libs/" $(pwd)/$file
  fi
done

truffle compile

truffle test
