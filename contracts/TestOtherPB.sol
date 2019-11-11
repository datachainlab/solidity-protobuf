pragma solidity ^0.5.0;

import "./libs/test_other.sol";

contract TestOtherPB {
  mapping(address => bytes) public contracts;
  function getTestOtherBytes(address key) public view returns (bytes memory) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufRuntime.decodeStorage(location);
    TestOther.Data memory data = TestOther.decode(encoded);
    return data.bytes_field;
  }

  function getTestOtherString(address key) public view returns (string memory) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufRuntime.decodeStorage(location);
    TestOther.Data memory data = TestOther.decode(encoded);
    return data.string_field;
  }

  function getTestOtherBool(address key) public view returns (bool) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufRuntime.decodeStorage(location);
    TestOther.Data memory data = TestOther.decode(encoded);
    return data.bool_field;
  }

  function getTestOtherEnum(address key) public view returns (TestOther.Corpus) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufRuntime.decodeStorage(location);
    TestOther.Data memory data = TestOther.decode(encoded);
    return data.enum_field;
  }

  function storeTestOther(address key, bytes memory bytes_field,
    string memory string_field, bool bool_field,
    TestOther.Corpus enum_field) public {
      TestOther.Data memory data = TestOther.Data({bytes_field: bytes_field, string_field: string_field,
        bool_field: bool_field, enum_field: enum_field});
      bytes memory encoded = TestOther.encode(data);
      ProtoBufRuntime.encodeStorage(contracts[key], encoded);
  }
}
