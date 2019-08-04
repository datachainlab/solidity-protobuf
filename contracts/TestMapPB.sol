pragma solidity ^0.5.0;

import "./libs/test_map_pb.sol";

contract TestMapPB {
  mapping(address => bytes) public contracts;

  function getTestMapSize(address key) public view returns (uint){
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufParser.decodeStorage(location);
    ProtoBufTestMap.Data memory memoryData = ProtoBufTestMap.decode(encoded);
    return memoryData._size_map_field;
  }

  function getTestMap(address key, string memory mapKey) public view returns (string memory){
    bytes storage location = contracts[key];
    bytes memory encoded = ProtoBufParser.decodeStorage(location);
    ProtoBufTestMap.Data memory memoryData = ProtoBufTestMap.decode(encoded);
    return ProtoBufTestMap.get_map_field(memoryData, mapKey);
  }

  function storeTestMap(address key, string memory mapKey, string memory mapValue) public {
    ProtoBufTestMap.Data memory memoryData;
    ProtoBufTestMap.add_map_field(memoryData, mapKey, mapValue);
    bytes memory encoded = ProtoBufTestMap.encode(memoryData);
    ProtoBufParser.encodeStorage(contracts[key], encoded);
  }

  function createTestState(address key) public {
    ProtoBufTestMap.Data memory memoryData;
    ProtoBufTestMap.add_map_field(memoryData, "zero", "zero_value");
    ProtoBufTestMap.add_map_field(memoryData, "one", "one_value");
    ProtoBufTestMap.add_map_field(memoryData, "two", "two_value");
    ProtoBufTestMap.add_map_field(memoryData, "three", "three_value");
    ProtoBufTestMap.add_map_field(memoryData, "four", "four_value");
    ProtoBufTestMap.add_map_field(memoryData, "three", "three_value_new");
    ProtoBufTestMap.rm_map_field(memoryData, "zero");
    ProtoBufTestMap.rm_map_field(memoryData, "invalid");
    bytes memory encoded = ProtoBufTestMap.encode(memoryData);
    ProtoBufParser.encodeStorage(contracts[key], encoded);
  }
}
