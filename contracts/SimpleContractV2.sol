pragma solidity ^0.5.0;
import "./libs/test_pb.sol";
contract SimpleContractV2 {
  struct Data {
    int32 test;
    int256 test2;
    int256 test3;
  }
  mapping(address => Data) public contracts;

  function getRandomUint256() public view returns (uint256) {
    return uint256(keccak256(abi.encode(block.timestamp, block.difficulty)));
  }

  function getSimpleContract(address key) public view returns (int32){
    return contracts[key].test;
  }

  function storeSimpleContract(address key, int32 v1, int256 v2, int256 v3) public {
    Data memory data = Data({test: v1, test2: v2, test3: v3});
    contracts[key] = data;
  }

  function getBytes32(int256 x) public pure returns (bytes32) {
    return bytes32(x);
  }
}
