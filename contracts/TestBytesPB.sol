pragma solidity ^0.5.0;

import "./libs/test_bytes_pb.sol";

contract TestBytesPB {
  mapping(address => bytes) public contracts;
  function getTestBytesBytes2(address key) public view returns (bytes2) {
    bytes storage location = contracts[key];
    bytes memory encoded = _pb.decode_storage(location);
    pb_TestBytes.Data memory data = pb_TestBytes.decode(encoded);
    return data.bytes2_field;
  }

  function getTestBytesBytes10(address key) public view returns (bytes10) {
    bytes storage location = contracts[key];
    bytes memory encoded = _pb.decode_storage(location);
    pb_TestBytes.Data memory data = pb_TestBytes.decode(encoded);
    return data.bytes10_field;
  }

  function getTestBytesBytes17(address key) public view returns (bytes17) {
    bytes storage location = contracts[key];
    bytes memory encoded = _pb.decode_storage(location);
    pb_TestBytes.Data memory data = pb_TestBytes.decode(encoded);
    return data.bytes17_field;
  }

  function getTestBytesBytes31(address key) public view returns (bytes31) {
    bytes storage location = contracts[key];
    bytes memory encoded = _pb.decode_storage(location);
    pb_TestBytes.Data memory data = pb_TestBytes.decode(encoded);
    return data.bytes31_field;
  }

  function getBytes2FromInteger(uint value) public pure returns(bytes2) {
    return bytes2(bytes32(value));
  }

  function getBytes10FromInteger(uint value) public pure returns(bytes10) {
    return bytes10(bytes32(value));
  }

  function getBytes17FromInteger(uint value) public pure returns(bytes17) {
    return bytes17(bytes32(value));
  }

  function getBytes31FromInteger(uint value) public pure returns(bytes31) {
    return bytes31(bytes32(value));
  }

  function storeTestBytes(address key, uint bytes2_field,
    uint bytes10_field, uint bytes17_field,
    uint bytes31_field) public {
    pb_TestBytes.Data memory data = pb_TestBytes.Data({bytes2_field: bytes2(bytes32(bytes2_field)), bytes10_field: bytes10(bytes32(bytes10_field)),
      bytes17_field: bytes17(bytes32(bytes17_field)), bytes31_field: bytes31(bytes32(bytes31_field))});
    bytes memory encoded = pb_TestBytes.encode(data);
    _pb.encode_storage(contracts[key], encoded);
  }

  function sizeTestBytes(address key, uint bytes2_field,
    uint bytes10_field, uint bytes17_field,
    uint bytes31_field) public pure returns (uint) {
      pb_TestBytes.Data memory data = pb_TestBytes.Data({bytes2_field: bytes2(bytes32(bytes2_field)), bytes10_field: bytes10(bytes32(bytes10_field)),
        bytes17_field: bytes17(bytes32(bytes17_field)), bytes31_field: bytes31(bytes32(bytes31_field))});
      bytes memory encoded = pb_TestBytes.encode(data);
      return encoded.length;
    }
}
