pragma solidity ^0.6.0;


contract TestRepeatedNative {
  struct Data {
    string string_field;
    uint256[] uint256s;
    int64[] sint64s;
    bool bool_field;

  }
  mapping(address => Data) public contracts;

  function getTestRepeatedString(address key) public view returns (string memory) {
    return contracts[key].string_field;
  }

  function getTestRepeatedBool(address key) public view returns (bool) {
    return contracts[key].bool_field;
  }

  function getTestRepeatedUint256(address key) public view returns (uint[] memory) {
    return contracts[key].uint256s;
  }

  function getTestRepeatedInt64(address key) public view returns (int64[] memory) {
    return contracts[key].sint64s;
  }

  function storeTestRepeated(address key, string memory string_field,
    uint256[] memory uint256s, int64[] memory sint64s,
    bool bool_field) public {
      Data memory data = Data({string_field: string_field, uint256s: uint256s,
        sint64s: sint64s, bool_field: bool_field});
      contracts[key] = data;
  }
}
