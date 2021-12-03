#!/usr/bin/env bash
set -e
for file in proto/*
do
  if [[ -f $file ]]; then
    echo "Generating "$file
    protoc -I$(pwd)/proto -I$(pwd)/protobuf-solidity/src/protoc/include --plugin=protoc-gen-sol=$(pwd)/protobuf-solidity/src/protoc/plugin/gen_sol.py --"sol_out=gen_runtime=ProtoBufRuntime.sol&solc_version=0.8.10:$(pwd)/contracts/libs/" $(pwd)/$file
  fi
done

container_id=$(docker run --rm -d -p 7545:8545 trufflesuite/ganache-cli)
trap "docker stop $container_id" EXIT
while ! (wget -q -O - localhost:7545 || [ $? -eq 8 ]); do sleep 1; done

npx --no-install truffle test
