pragma solidity ^0.5.0;

import "./libs/test_bytes.sol";
contract TestBytesDeserialization {
  function getTestBytesBytes2(bytes memory encoded) public pure returns (bytes2) {
    TestBytes.Data memory data = TestBytes.decode(encoded);
    return data.bytes2_field;
  }

  function getEncodedMessage(bytes2 b) public pure returns (bytes memory) {
    TestBytes.Data memory data;
    data.bytes2_field = bytes2(0x1234);
    return TestBytes.encode(data);
  }
}
