pragma solidity ^0.5.0;

import "./libs/test_bytes.sol";
contract TestBytesDeserialization {
  function getTestBytesBytes2(bytes memory encoded) public pure returns (bytes2) {
    TestBytes.Data memory data = TestBytes.decode(encoded);
    return data.bytes2_field;
  }
}
