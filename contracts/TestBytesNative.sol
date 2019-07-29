pragma solidity ^0.5.0;

contract TestBytesNative {
  struct Data {
    bytes2 bytes2_field;
    bytes10 bytes10_field;
    bytes17 bytes17_field;
    bytes31 bytes31_field;

  }
  mapping(address => Data) public contracts;
  function getTestBytesBytes2(address key) public view returns (bytes2) {
    return contracts[key].bytes2_field;
  }

  function getTestBytesBytes10(address key) public view returns (bytes10) {
    return contracts[key].bytes10_field;
  }

  function getTestBytesBytes17(address key) public view returns (bytes17) {
    return contracts[key].bytes17_field;
  }

  function getTestBytesBytes31(address key) public view returns (bytes31) {
    return contracts[key].bytes31_field;
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
    Data memory data = Data({bytes2_field: bytes2(bytes32(bytes2_field)), bytes10_field: bytes10(bytes32(bytes10_field)),
      bytes17_field: bytes17(bytes32(bytes17_field)), bytes31_field: bytes31(bytes32(bytes31_field))});
    contracts[key] = data;
  }
}
