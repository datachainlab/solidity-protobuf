.PHONY: protoc-python
protoc-python:
	protoc -I protobuf-solidity/src/protoc/include \
		--python_out=protobuf-solidity/src/protoc/plugin \
		protobuf-solidity/src/protoc/include/solidity-protobuf-extensions.proto

.PHONY: protoc-go
protoc-go:
	protoc -I protobuf-solidity/src/protoc/include \
		--go_out=. \
		protobuf-solidity/src/protoc/include/*.proto
	cp -rp github.com/datachainlab/solidity-protobuf/* .
	rm -rf github.com

.PHONY: test
test:
	./test.sh
