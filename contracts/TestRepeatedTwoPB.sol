pragma solidity <0.9.0;

import "./libs/test_repeated_two.sol";

contract TestRepeatedTwoPB {
  mapping(address => bytes) public contracts;

  function getTestRepeatedString(address key) public view returns (string memory) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufRuntime.decodeStorage(location);
    TestRepeatedTwo.Data memory data = TestRepeatedTwo.decode(encoded);
    return data.string_field;
  }

  function getTestRepeatedBool(address key) public view returns (bool) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufRuntime.decodeStorage(location);
    TestRepeatedTwo.Data memory data = TestRepeatedTwo.decode(encoded);
    return data.bool_field;
  }

  function getTestRepeatedUint256(address key) public view returns (uint[] memory) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufRuntime.decodeStorage(location);
    TestRepeatedTwo.Data memory data = TestRepeatedTwo.decode(encoded);
    return data.uint256s;
  }

  function getTestRepeatedInt64(address key) public view returns (int64[] memory) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufRuntime.decodeStorage(location);
    TestRepeatedTwo.Data memory data = TestRepeatedTwo.decode(encoded);
    return data.sint64s;
  }

  function getTestRepeatedUnpackedInt32(address key) public view returns (int32[] memory) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufRuntime.decodeStorage(location);
    TestRepeatedTwo.Data memory data = TestRepeatedTwo.decode(encoded);
    return data.unpacked_int32s;
  }

  function getTestRepeatedPackedInt32(address key) public view returns (int32[] memory) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufRuntime.decodeStorage(location);
    TestRepeatedTwo.Data memory data = TestRepeatedTwo.decode(encoded);
    return data.packed_int32s;
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
    TestRepeatedTwo.Data memory data = TestRepeatedTwo.Data({
      string_field: string_field,
      uint256s: uint256s,
      sint64s: sint64s,
      bool_field: bool_field,
      unpacked_int32s: unpacked_int32s,
      packed_int32s: packed_int32s
    });
    bytes memory encoded = TestRepeatedTwo.encode(data);
    ProtoBufRuntime.encodeStorage(contracts[key], encoded);
  }
}
