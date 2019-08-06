pragma solidity ^0.5.0;

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
    return TestMap.get_map_field(memoryData, mapKey);
  }

  function storeTestMap(address key, string memory mapKey, string memory mapValue) public {
    TestMap.Data memory memoryData;
    TestMap.add_map_field(memoryData, mapKey, mapValue);
    bytes memory encoded = TestMap.encode(memoryData);
    ProtoBufRuntime.encodeStorage(contracts[key], encoded);
  }

  function createTestState(address key) public {
    TestMap.Data memory memoryData;
    TestMap.add_map_field(memoryData, "zero", "zero_value");
    TestMap.add_map_field(memoryData, "one", "one_value");
    TestMap.add_map_field(memoryData, "two", "two_value");
    TestMap.add_map_field(memoryData, "three", "three_value");
    TestMap.add_map_field(memoryData, "four", "four_value");
    TestMap.add_map_field(memoryData, "three", "three_value_new");
    TestMap.rm_map_field(memoryData, "zero");
    TestMap.rm_map_field(memoryData, "invalid");
    bytes memory encoded = TestMap.encode(memoryData);
    ProtoBufRuntime.encodeStorage(contracts[key], encoded);
  }
}
