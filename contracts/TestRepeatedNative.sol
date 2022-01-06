pragma solidity <0.9.0;


contract TestRepeatedNative {
  struct Data {
    string string_field;
    uint256[] uint256s;
    int64[] sint64s;
    bool bool_field;
    int32[] unpacked_int32s;
    int32[] packed_int32s;
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


  function getTestRepeatedUnpackedInt32(address key) public view returns (int32[] memory) {
    return contracts[key].unpacked_int32s;
  }

  function getTestRepeatedPackedInt32(address key) public view returns (int32[] memory) {
    return contracts[key].packed_int32s;
  }

  function storeTestRepeated(
    address key,
    string memory string_field,
    uint256[] memory uint256s,
    int64[] memory sint64s,
    bool bool_field,
    int32[] memory unpacked_int32s,
    int32[] memory packed_int32s
  ) public {
    Data memory data = Data({
      string_field: string_field,
      uint256s: uint256s,
      sint64s: sint64s,
      bool_field: bool_field,
      unpacked_int32s: unpacked_int32s,
      packed_int32s: packed_int32s
    });
    contracts[key] = data;
  }
}
