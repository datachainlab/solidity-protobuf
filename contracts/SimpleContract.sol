pragma solidity ^0.5.0;
//pragma experimental ABIEncoderV2;

import "./libs/test_pb.sol";
contract SimpleContract {
  uint constant WORD_LENGTH = 32;
  uint constant HEADER_SIZE_LENGTH_IN_BYTES = 4;
  uint constant BYTE_SIZE = 8;
  uint constant REMAINING_LENGTH = WORD_LENGTH - HEADER_SIZE_LENGTH_IN_BYTES;
  mapping(address => bytes) public contracts;

  function getSimpleContract(address key) public view returns (int256) {
    bytes storage location = contracts[key];
    bytes memory encoded = _pb.decode_storage(location);
    pb_Test.Data memory data = pb_Test.decode(encoded);
    return data.test3;
  }

  function storeSimpleContract(address key, int32 v1, int256 v2, int256 v3) public {
    pb_Test.Data memory data = pb_Test.Data({test: v1, test2: v2, test3: v3});
    bytes memory encoded = pb_Test.encode(data);
    _pb.encode_storage(contracts[key], encoded);
  }

  function getInt32(int32 x) public pure returns (uint, uint) {
    // uint64 twosComplement; // use signextend here?
    // assembly {
    //   twosComplement := signextend(3, x)
    // }
    bytes memory test = new bytes(4);
    uint size = _pb._encode_varint(uint(uint64(x)), 32, test);
    uint size_2 = _pb._sz_varint(uint(uint64(x)));
    return (size, size_2);
  }

  // function getRealSize(int256 v1, int256 v2, int256 v3) public pure returns (uint256) {
  //   pb_Test.Data memory data = pb_Test.Data({test: bytes32(v1), test2: v2, test3: v3});
  //   bytes memory encoded = pb_Test.encode(data);
  //   return encoded.length;
  // }

  function getIntSize(int256 x) public pure returns (uint256) {
    return _pb._get_real_size(x, 32);
  }

  function getBytes32(int256 x) public pure returns (bytes31) {
    return bytes31(bytes32(x));
  }

  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m;
  }

  function getByteLength(int256 x, uint sz) public pure returns (uint) {
    return _pb._get_real_size(x, sz);
  }
}
