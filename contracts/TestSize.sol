pragma solidity ^0.5.0;

import "./libs/runtime.sol";
contract TestSize {
  function getSignedSize(int val) public pure returns (uint) {
    return ProtoBufParser._get_real_size(val, 32);
  }

  function getUnsingedSize(uint val) public pure returns (uint) {
    return ProtoBufParser._get_real_size(val, 32);
  }
}
