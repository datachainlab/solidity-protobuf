pragma solidity ^0.5.0;
import "./runtime.sol";
library pb_TestBytes{
  //enum definition

  //struct definition
  struct Data {
    bytes2 bytes2_field;
    bytes10 bytes10_field;
    bytes17 bytes17_field;
    bytes31 bytes31_field;
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
    uint[5] memory counters;
    uint fieldId;
    _pb.WireType wireType;
    uint bytesRead;
    uint offset = p;
    while(p < offset+sz) {
      (fieldId, wireType, bytesRead) = _pb._decode_key(p, bs);
      p += bytesRead;
      if (false) {}
      else if(fieldId == 1)
          p += _read_bytes2_field(p, bs, r, counters);
      else if(fieldId == 2)
          p += _read_bytes10_field(p, bs, r, counters);
      else if(fieldId == 3)
          p += _read_bytes17_field(p, bs, r, counters);
      else if(fieldId == 4)
          p += _read_bytes31_field(p, bs, r, counters);
      else revert();
    }
    p = offset;

    while(p < offset+sz) {
      (fieldId, wireType, bytesRead) = _pb._decode_key(p, bs);
      p += bytesRead;
      if (false) {}
      else if(fieldId == 1)
          p += _read_bytes2_field(p, bs, nil(), counters);
      else if(fieldId == 2)
          p += _read_bytes10_field(p, bs, nil(), counters);
      else if(fieldId == 3)
          p += _read_bytes17_field(p, bs, nil(), counters);
      else if(fieldId == 4)
          p += _read_bytes31_field(p, bs, nil(), counters);
      else revert();
    }
    return (r, sz);
  }

  // field readers
  function _read_bytes2_field(uint p, bytes memory bs, Data memory r, uint[5] memory counters) internal pure returns (uint) {
    (bytes2 x, uint sz) = _pb._decode_sol_bytes2(p, bs);
    if(isNil(r)) {
      counters[1] += 1;
    } else {
      r.bytes2_field = x;
      if(counters[1] > 0) counters[1] -= 1;
    }
    return sz;
  }
  function _read_bytes10_field(uint p, bytes memory bs, Data memory r, uint[5] memory counters) internal pure returns (uint) {
    (bytes10 x, uint sz) = _pb._decode_sol_bytes10(p, bs);
    if(isNil(r)) {
      counters[2] += 1;
    } else {
      r.bytes10_field = x;
      if(counters[2] > 0) counters[2] -= 1;
    }
    return sz;
  }
  function _read_bytes17_field(uint p, bytes memory bs, Data memory r, uint[5] memory counters) internal pure returns (uint) {
    (bytes17 x, uint sz) = _pb._decode_sol_bytes17(p, bs);
    if(isNil(r)) {
      counters[3] += 1;
    } else {
      r.bytes17_field = x;
      if(counters[3] > 0) counters[3] -= 1;
    }
    return sz;
  }
  function _read_bytes31_field(uint p, bytes memory bs, Data memory r, uint[5] memory counters) internal pure returns (uint) {
    (bytes31 x, uint sz) = _pb._decode_sol_bytes31(p, bs);
    if(isNil(r)) {
      counters[4] += 1;
    } else {
      r.bytes31_field = x;
      if(counters[4] > 0) counters[4] -= 1;
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
    p += _pb._encode_sol_bytes2(r.bytes2_field, p, bs);
    p += _pb._encode_key(2, _pb.WireType.LengthDelim, p, bs);
    p += _pb._encode_sol_bytes10(r.bytes10_field, p, bs);
    p += _pb._encode_key(3, _pb.WireType.LengthDelim, p, bs);
    p += _pb._encode_sol_bytes17(r.bytes17_field, p, bs);
    p += _pb._encode_key(4, _pb.WireType.LengthDelim, p, bs);
    p += _pb._encode_sol_bytes31(r.bytes31_field, p, bs);

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

    e += 1 + 5;
    e += 1 + 13;
    e += 1 + 20;
    e += 1 + 34;

    return e;
  }


  //store function
  function store(Data memory input, Data storage output) internal{
    output.bytes2_field = input.bytes2_field;
    output.bytes10_field = input.bytes10_field;
    output.bytes17_field = input.bytes17_field;
    output.bytes31_field = input.bytes31_field;

  }


  //utility functions
  function nil() internal pure returns (Data memory r) {
    assembly { r := 0 }
  }
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly { r := iszero(x) }
  }
} //library pb_TestBytes
