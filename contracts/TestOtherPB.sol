pragma solidity ^0.5.0;

import "./libs/test_other_pb.sol";

contract TestOtherPB {
  mapping(address => bytes) public contracts;
  function getTestOtherBytes(address key) public view returns (bytes memory) {
    bytes storage location = contracts[key];
    bytes memory encoded = _pb.decode_storage(location);
    pb_TestOther.Data memory data = pb_TestOther.decode(encoded);
    return data.bytes_field;
  }

  function getTestOtherString(address key) public view returns (string memory) {
    bytes storage location = contracts[key];
    bytes memory encoded = _pb.decode_storage(location);
    pb_TestOther.Data memory data = pb_TestOther.decode(encoded);
    return data.string_field;
  }

  function getTestOtherBool(address key) public view returns (bool) {
    bytes storage location = contracts[key];
    bytes memory encoded = _pb.decode_storage(location);
    pb_TestOther.Data memory data = pb_TestOther.decode(encoded);
    return data.bool_field;
  }

  function getTestOtherEnum(address key) public view returns (int64) {
    bytes storage location = contracts[key];
    bytes memory encoded = _pb.decode_storage(location);
    pb_TestOther.Data memory data = pb_TestOther.decode(encoded);
    return data.enum_field;
  }

  function storeTestOther(address key, bytes memory bytes_field,
    string memory string_field, bool bool_field,
    int64 enum_field) public {
      pb_TestOther.Data memory data = pb_TestOther.Data({bytes_field: bytes_field, string_field: string_field,
        bool_field: bool_field, enum_field: enum_field});
      bytes memory encoded = pb_TestOther.encode(data);
      _pb.encode_storage(contracts[key], encoded);
  }
}
