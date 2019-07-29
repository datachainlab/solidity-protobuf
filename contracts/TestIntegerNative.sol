pragma solidity ^0.5.0;

contract TestIntegerNative {
  struct Data {
    int32 sint32_field;
    int32 int32_field;
    uint32 fixed32_field;
    uint64 fixed64_field;
    int256 int256_field;
    uint256 uint256_field;
    address address_field;
    int64 int64_field;
    uint64 uint64_field;

  }
  mapping(address => Data) public contracts;
  function getTestIntegerSint32(address key) public view returns (int32) {
    return contracts[key].sint32_field;
  }

  function getTestIntegerInt32(address key) public view returns (int32) {
    return contracts[key].int32_field;
  }

  function getTestIntegerFixed32(address key) public view returns (uint32) {
    return contracts[key].fixed32_field;
  }

  function getTestIntegerFixed64(address key) public view returns (uint64) {
    return contracts[key].fixed64_field;
  }

  function getTestIntegerUint256(address key) public view returns (uint256) {
    return contracts[key].uint256_field;
  }

  function getTestIntegerInt256(address key) public view returns (int256) {
    return contracts[key].int256_field;
  }

  function getTestIntegerAddress(address key) public view returns (address) {
    return contracts[key].address_field;
  }

  function getTestIntegerUint64(address key) public view returns (uint64) {
    return contracts[key].uint64_field;
  }

  function getTestIntegerInt64(address key) public view returns (int64) {
    return contracts[key].int64_field;
  }

  function storeTestInteger(address key, int32 sint32_field,
    int32 int32_field, uint32 fixed32_field,
    uint64 fixed64_field, int256 int256_field,
    uint256 uint256_field, address address_field,
    int64 int64_field, uint64 uint64_field) public {
    Data memory data = Data({sint32_field: sint32_field, int32_field: int32_field,
      fixed32_field: fixed32_field, fixed64_field: fixed64_field,
      int256_field: int256_field, uint256_field: uint256_field,
      address_field: address_field, int64_field: int64_field,
      uint64_field: uint64_field});
    contracts[key] = data;
  }
}
