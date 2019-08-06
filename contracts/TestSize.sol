pragma solidity ^0.5.0;

import "./libs/ProtoBufRuntime.sol";
contract TestSize {
  function getSignedSize(int val) public pure returns (uint) {
    return ProtoBufRuntime._get_real_size(val, 32);
  }

  function getUnsingedSize(uint val) public pure returns (uint) {
    return ProtoBufRuntime._get_real_size(val, 32);
  }
}
