pragma solidity <0.9.0;

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
    Data memory data = Data({bytes2_field: bytes2(value), bytes10_field: bytes10(value),
      bytes17_field: bytes17(value), bytes31_field: bytes31(value)});
    contracts[key] = data;
  }
}
