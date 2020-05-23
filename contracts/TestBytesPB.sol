pragma solidity ^0.6.0;

import "./libs/test_bytes.sol";

contract TestBytesPB {
  mapping(address => bytes) public contracts;
  function getTestBytesBytes2(address key) public view returns (bytes2) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufRuntime.decodeStorage(location);
    TestBytes.Data memory data = TestBytes.decode(encoded);
    return data.bytes2_field;
  }

  function getTestBytesBytes10(address key) public view returns (bytes10) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufRuntime.decodeStorage(location);
    TestBytes.Data memory data = TestBytes.decode(encoded);
    return data.bytes10_field;
  }

  function getTestBytesBytes17(address key) public view returns (bytes17) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufRuntime.decodeStorage(location);
    TestBytes.Data memory data = TestBytes.decode(encoded);
    return data.bytes17_field;
  }

  function getTestBytesBytes31(address key) public view returns (bytes31) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufRuntime.decodeStorage(location);
    TestBytes.Data memory data = TestBytes.decode(encoded);
    return data.bytes31_field;
  }

  function getBytes2FromBytes32(bytes32 value) public pure returns(bytes2) {
    return bytes2(value);
  }

  function getBytes10FromBytes32(bytes32 value) public pure returns(bytes10) {
    return bytes10(value);
  }

  function getBytes17FromBytes32(bytes32 value) public pure returns(bytes17) {
    return bytes17(value);
  }

  function getBytes31FromBytes32(bytes32 value) public pure returns(bytes31) {
    return bytes31(value);
  }

  function storeTestBytes(address key, bytes32 value) public {
    TestBytes.Data memory data = TestBytes.Data({bytes2_field: bytes2(value), bytes10_field: bytes10(value),
      bytes17_field: bytes17(value), bytes31_field: bytes31(value)});
    bytes memory encoded = TestBytes.encode(data);
    ProtoBufRuntime.encodeStorage(contracts[key], encoded);
  }
}
