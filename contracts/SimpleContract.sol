pragma solidity ^0.5.0;
//pragma experimental ABIEncoderV2;

import "./libs/test_pb.sol";
contract SimpleContract {
  mapping(address => bytes) public contracts;

  // function getSimpleContractUint232(address key) public view returns (uint232) {
  //   return pb_Test.decode(contracts[key]).test_uint232;
  // }

  function getSimpleContractInt232(address key) public view returns (int232) {
    return pb_Test.decode(contracts[key]).test_int232;
  }

  function storeSimpleContract(address key, uint232 v1, int232 v2) public {
    pb_Test.Data memory data = pb_Test.Data({test_int232: v2});
    contracts[key] = pb_Test.encode(data);
  }
}
