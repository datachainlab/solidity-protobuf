pragma solidity ^0.5.0;
import "./runtime.sol";
library pb_Test{
  //enum definition

  //struct definition
  struct Data {
    int232 test_int232;
    //non serialized field for map

  }
  // Decoder section
  function decode(bytes memory bs) internal pure returns (Data memory) {
    (Data memory x,) = _decode(32, bs, bs.length);
    return x;
  }
  function decode(Data storage self, bytes memory bs) internal {
    (Data memory x,) = _decode(32, bs, bs.length);
    store(x, self);
  }
  // innter decoder
  function _decode(uint p, bytes memory bs, uint sz)
      internal pure returns (Data memory, uint) {
    Data memory r;
    uint[2] memory counters;
    uint fieldId;
    _pb.WireType wireType;
    uint bytesRead;
    uint offset = p;
    while(p < offset+sz) {
      (fieldId, wireType, bytesRead) = _pb._decode_key(p, bs);
      p += bytesRead;
      if (false) {}
      else if(fieldId == 1)
          p += _read_test_int232(p, bs, r, counters);
      else revert();
    }
    p = offset;

    while(p < offset+sz) {
      (fieldId, wireType, bytesRead) = _pb._decode_key(p, bs);
      p += bytesRead;
      if (false) {}
      else if(fieldId == 1)
          p += _read_test_int232(p, bs, nil(), counters);
      else revert();
    }
    return (r, sz);
  }

  // field readers
  function _read_test_int232(uint p, bytes memory bs, Data memory r, uint[2] memory counters) internal pure returns (uint) {
    (int232 x, uint sz) = _pb._decode_sol_int232(p, bs);
    if(isNil(r)) {
      counters[1] += 1;
    } else {
      r.test_int232 = x;
      if(counters[1] > 0) counters[1] -= 1;
    }
    return sz;
  }

  // struct decoder

  // Encoder section
  function encode(Data memory r) internal pure returns (bytes memory) {
    bytes memory bs = new bytes(_estimate(r));
    uint sz = _encode(r, 32, bs);
    assembly { mstore(bs, sz) }
    return bs;
  }

  // inner encoder
  function _encode(Data memory r, uint p, bytes memory bs)
      internal pure returns (uint) {
    uint offset = p;

    p += _pb._encode_key(1, _pb.WireType.LengthDelim, p, bs);
    p += _pb._encode_sol_int232(r.test_int232, p, bs);

    return p - offset;
  }

  // nested encoder
  function _encode_nested(Data memory r, uint p, bytes memory bs)
      internal pure returns (uint) {
    uint offset = p;
    p += _pb._encode_varint(_estimate(r), p, bs);
    p += _encode(r, p, bs);
    return p - offset;
  }

  // estimator
  function _estimate(Data memory /* r */) internal pure returns (uint) {
    uint e;

    e += 1 + 3;

    return e;
  }


  //store function
  function store(Data memory input, Data storage output) internal{
    output.test_int232 = input.test_int232;

  }


  //utility functions
  function nil() internal pure returns (Data memory r) {
    assembly { r := 0 }
  }
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly { r := iszero(x) }
  }
} //library pb_Test
