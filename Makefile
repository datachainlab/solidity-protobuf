.PHONY: protoc-python
protoc-python:
	protoc -I protobuf-solidity/src/protoc/include \
		--python_out=protobuf-solidity/src/protoc/plugin \
		protobuf-solidity/src/protoc/include/solidity-protobuf-extensions.proto

.PHONY: test
test:
	./test.sh
