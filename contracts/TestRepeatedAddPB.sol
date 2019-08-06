pragma solidity ^0.5.0;

import "./libs/test_repeated_add.sol";

contract TestRepeatedAddPB {
  mapping(address => bytes) public contracts;

  function getTestRepeatedUint256(address key) public view returns (uint[] memory) {
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufRuntime.decodeStorage(location);
    TestRepeatedAdd.Data memory data = TestRepeatedAdd.decode(encoded);
    return data.uint256s;
  }

  function storeTestRepeated(address key, uint256[] memory uint256s) public {
      TestRepeatedAdd.Data memory data = TestRepeatedAdd.Data({uint256s: uint256s});
      TestRepeatedAdd.add_uint256s(data, 12800);
      bytes memory encoded = TestRepeatedAdd.encode(data);
      ProtoBufRuntime.encodeStorage(contracts[key], encoded);
  }
}
