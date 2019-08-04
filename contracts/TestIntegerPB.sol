pragma solidity ^0.5.0;

import "./libs/test_integer_pb.sol";

contract TestIntegerPB {
  mapping(address => bytes) public contracts;
  function getTestIntegerSint32(address key) public view returns (int32) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufParser.decodeStorage(location);
    ProtoBufTestInteger.Data memory data = ProtoBufTestInteger.decode(encoded);
    return data.sint32_field;
  }

  function getTestIntegerInt32(address key) public view returns (int32) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufParser.decodeStorage(location);
    ProtoBufTestInteger.Data memory data = ProtoBufTestInteger.decode(encoded);
    return data.int32_field;
  }

  function getTestIntegerFixed32(address key) public view returns (uint32) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufParser.decodeStorage(location);
    ProtoBufTestInteger.Data memory data = ProtoBufTestInteger.decode(encoded);
    return data.fixed32_field;
  }

  function getTestIntegerFixed64(address key) public view returns (uint64) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufParser.decodeStorage(location);
    ProtoBufTestInteger.Data memory data = ProtoBufTestInteger.decode(encoded);
    return data.fixed64_field;
  }

  function getTestIntegerUint256(address key) public view returns (uint256) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufParser.decodeStorage(location);
    ProtoBufTestInteger.Data memory data = ProtoBufTestInteger.decode(encoded);
    return data.uint256_field;
  }

  function getTestIntegerInt256(address key) public view returns (int256) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufParser.decodeStorage(location);
    ProtoBufTestInteger.Data memory data = ProtoBufTestInteger.decode(encoded);
    return data.int256_field;
  }

  function getTestIntegerAddress(address key) public view returns (address) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufParser.decodeStorage(location);
    ProtoBufTestInteger.Data memory data = ProtoBufTestInteger.decode(encoded);
    return data.address_field;
  }

  function getTestIntegerUint64(address key) public view returns (uint64) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufParser.decodeStorage(location);
    ProtoBufTestInteger.Data memory data = ProtoBufTestInteger.decode(encoded);
    return data.uint64_field;
  }

  function getTestIntegerInt64(address key) public view returns (int64) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufParser.decodeStorage(location);
    ProtoBufTestInteger.Data memory data = ProtoBufTestInteger.decode(encoded);
    return data.int64_field;
  }

  function storeTestInteger(address key, int32 sint32_field,
    int32 int32_field, uint32 fixed32_field,
    uint64 fixed64_field, int256 int256_field,
    uint256 uint256_field, address address_field,
    int64 int64_field, uint64 uint64_field) public {
    ProtoBufTestInteger.Data memory data = ProtoBufTestInteger.Data({sint32_field: sint32_field, int32_field: int32_field,
      fixed32_field: fixed32_field, fixed64_field: fixed64_field,
      int256_field: int256_field, uint256_field: uint256_field,
      address_field: address_field, int64_field: int64_field,
      uint64_field: uint64_field});
    bytes memory encoded = ProtoBufTestInteger.encode(data);
    ProtoBufParser.encodeStorage(contracts[key], encoded);
  }
}
