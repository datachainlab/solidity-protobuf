pragma solidity ^0.5.0;

import "./libs/test_integer.sol";
contract TestIntegerDeserialization {
  function getTestIntegerUint64(bytes memory encoded) public pure returns (uint64) {
    TestInteger.Data memory data = TestInteger.decode(encoded);
    return data.uint64_field;
  }

  function getTestAddress(bytes memory encoded) public pure returns (address) {
    TestInteger.Data memory data = TestInteger.decode(encoded);
    return data.address_field;
  }
}
