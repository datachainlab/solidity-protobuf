pragma solidity <0.9.0;

import "./libs/test_map.sol";

contract TestMapPB {
  mapping(address => bytes) public contracts;

  function getTestMapSize(address key) public view returns (uint){
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufRuntime.decodeStorage(location);
    TestMap.Data memory memoryData = TestMap.decode(encoded);
    return memoryData._size_map_field;
  }

  function getTestMap(address key, string memory mapKey) public view returns (string memory){
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufRuntime.decodeStorage(location);
    TestMap.Data memory memoryData = TestMap.decode(encoded);
    return TestMap.getMapField(memoryData, mapKey);
  }

  function storeTestMap(address key, string memory mapKey, string memory mapValue) public {
    TestMap.Data memory memoryData;
    TestMap.addMapField(memoryData, mapKey, mapValue);
    bytes memory encoded = TestMap.encode(memoryData);
    ProtoBufRuntime.encodeStorage(contracts[key], encoded);
  }

  function createTestState(address key) public {
    TestMap.Data memory memoryData;
    TestMap.addMapField(memoryData, "zero", "zero_value");
    TestMap.addMapField(memoryData, "one", "one_value");
    TestMap.addMapField(memoryData, "two", "two_value");
    TestMap.addMapField(memoryData, "three", "three_value");
    TestMap.addMapField(memoryData, "four", "four_value");
    TestMap.addMapField(memoryData, "three", "three_value_new");
    TestMap.rmMapField(memoryData, "zero");
    TestMap.rmMapField(memoryData, "invalid");
    bytes memory encoded = TestMap.encode(memoryData);
    ProtoBufRuntime.encodeStorage(contracts[key], encoded);
  }
}
