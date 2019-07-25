pragma solidity ^0.5.0;

contract SimpleContractV2 {
  struct Data {
    uint232 test_uint232;
    int232 test_int232;
    //non serialized field for map

  }
  mapping(address => Data) public contracts;

  function getSimpleContractUint232(address key) public view returns (uint232) {
    return contracts[key].test_uint232;
  }

  function getSimpleContractInt232(address key) public view returns (int232) {
    return contracts[key].test_int232;
  }

  function storeSimpleContract(address key, uint232 v1, int232 v2) public {
    Data memory data = Data({test_uint232: v1, test_int232: v2});
    contracts[key] = data;
  }
}
