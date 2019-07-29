pragma solidity ^0.5.0;
import "./runtime.sol";
library pb_TestInteger{
  //enum definition

  //struct definition
  struct Data {
    int32 sint32_field;
    int32 int32_field;
    uint32 fixed32_field;
    uint64 fixed64_field;
    int256 int256_field;
    uint256 uint256_field;
    address address_field;
    int64 int64_field;
    uint64 uint64_field;
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
    uint[10] memory counters;
    uint fieldId;
    _pb.WireType wireType;
    uint bytesRead;
    uint offset = p;
    while(p < offset+sz) {
      (fieldId, wireType, bytesRead) = _pb._decode_key(p, bs);
      p += bytesRead;
      if (false) {}
      else if(fieldId == 1)
          p += _read_sint32_field(p, bs, r, counters);
      else if(fieldId == 2)
          p += _read_int32_field(p, bs, r, counters);
      else if(fieldId == 5)
          p += _read_fixed32_field(p, bs, r, counters);
      else if(fieldId == 6)
          p += _read_fixed64_field(p, bs, r, counters);
      else if(fieldId == 3)
          p += _read_int256_field(p, bs, r, counters);
      else if(fieldId == 4)
          p += _read_uint256_field(p, bs, r, counters);
      else if(fieldId == 7)
          p += _read_address_field(p, bs, r, counters);
      else if(fieldId == 8)
          p += _read_int64_field(p, bs, r, counters);
      else if(fieldId == 9)
          p += _read_uint64_field(p, bs, r, counters);
      else revert();
    }
    p = offset;

    while(p < offset+sz) {
      (fieldId, wireType, bytesRead) = _pb._decode_key(p, bs);
      p += bytesRead;
      if (false) {}
      else if(fieldId == 1)
          p += _read_sint32_field(p, bs, nil(), counters);
      else if(fieldId == 2)
          p += _read_int32_field(p, bs, nil(), counters);
      else if(fieldId == 5)
          p += _read_fixed32_field(p, bs, nil(), counters);
      else if(fieldId == 6)
          p += _read_fixed64_field(p, bs, nil(), counters);
      else if(fieldId == 3)
          p += _read_int256_field(p, bs, nil(), counters);
      else if(fieldId == 4)
          p += _read_uint256_field(p, bs, nil(), counters);
      else if(fieldId == 7)
          p += _read_address_field(p, bs, nil(), counters);
      else if(fieldId == 8)
          p += _read_int64_field(p, bs, nil(), counters);
      else if(fieldId == 9)
          p += _read_uint64_field(p, bs, nil(), counters);
      else revert();
    }
    return (r, sz);
  }

  // field readers
  function _read_sint32_field(uint p, bytes memory bs, Data memory r, uint[10] memory counters) internal pure returns (uint) {
    (int32 x, uint sz) = _pb._decode_sint32(p, bs);
    if(isNil(r)) {
      counters[1] += 1;
    } else {
      r.sint32_field = x;
      if(counters[1] > 0) counters[1] -= 1;
    }
    return sz;
  }
  function _read_int32_field(uint p, bytes memory bs, Data memory r, uint[10] memory counters) internal pure returns (uint) {
    (int32 x, uint sz) = _pb._decode_int32(p, bs);
    if(isNil(r)) {
      counters[2] += 1;
    } else {
      r.int32_field = x;
      if(counters[2] > 0) counters[2] -= 1;
    }
    return sz;
  }
  function _read_fixed32_field(uint p, bytes memory bs, Data memory r, uint[10] memory counters) internal pure returns (uint) {
    (uint32 x, uint sz) = _pb._decode_fixed32(p, bs);
    if(isNil(r)) {
      counters[5] += 1;
    } else {
      r.fixed32_field = x;
      if(counters[5] > 0) counters[5] -= 1;
    }
    return sz;
  }
  function _read_fixed64_field(uint p, bytes memory bs, Data memory r, uint[10] memory counters) internal pure returns (uint) {
    (uint64 x, uint sz) = _pb._decode_fixed64(p, bs);
    if(isNil(r)) {
      counters[6] += 1;
    } else {
      r.fixed64_field = x;
      if(counters[6] > 0) counters[6] -= 1;
    }
    return sz;
  }
  function _read_int256_field(uint p, bytes memory bs, Data memory r, uint[10] memory counters) internal pure returns (uint) {
    (int256 x, uint sz) = _pb._decode_sol_int256(p, bs);
    if(isNil(r)) {
      counters[3] += 1;
    } else {
      r.int256_field = x;
      if(counters[3] > 0) counters[3] -= 1;
    }
    return sz;
  }
  function _read_uint256_field(uint p, bytes memory bs, Data memory r, uint[10] memory counters) internal pure returns (uint) {
    (uint256 x, uint sz) = _pb._decode_sol_uint256(p, bs);
    if(isNil(r)) {
      counters[4] += 1;
    } else {
      r.uint256_field = x;
      if(counters[4] > 0) counters[4] -= 1;
    }
    return sz;
  }
  function _read_address_field(uint p, bytes memory bs, Data memory r, uint[10] memory counters) internal pure returns (uint) {
    (address x, uint sz) = _pb._decode_sol_address(p, bs);
    if(isNil(r)) {
      counters[7] += 1;
    } else {
      r.address_field = x;
      if(counters[7] > 0) counters[7] -= 1;
    }
    return sz;
  }
  function _read_int64_field(uint p, bytes memory bs, Data memory r, uint[10] memory counters) internal pure returns (uint) {
    (int64 x, uint sz) = _pb._decode_sol_int64(p, bs);
    if(isNil(r)) {
      counters[8] += 1;
    } else {
      r.int64_field = x;
      if(counters[8] > 0) counters[8] -= 1;
    }
    return sz;
  }
  function _read_uint64_field(uint p, bytes memory bs, Data memory r, uint[10] memory counters) internal pure returns (uint) {
    (uint64 x, uint sz) = _pb._decode_sol_uint64(p, bs);
    if(isNil(r)) {
      counters[9] += 1;
    } else {
      r.uint64_field = x;
      if(counters[9] > 0) counters[9] -= 1;
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

    p += _pb._encode_key(1, _pb.WireType.Varint, p, bs);
    p += _pb._encode_sint32(r.sint32_field, p, bs);
    p += _pb._encode_key(2, _pb.WireType.Varint, p, bs);
    p += _pb._encode_int32(r.int32_field, p, bs);
    p += _pb._encode_key(5, _pb.WireType.Fixed32, p, bs);
    p += _pb._encode_fixed32(r.fixed32_field, p, bs);
    p += _pb._encode_key(6, _pb.WireType.Fixed64, p, bs);
    p += _pb._encode_fixed64(r.fixed64_field, p, bs);
    p += _pb._encode_key(3, _pb.WireType.LengthDelim, p, bs);
    p += _pb._encode_sol_int256(r.int256_field, p, bs);
    p += _pb._encode_key(4, _pb.WireType.LengthDelim, p, bs);
    p += _pb._encode_sol_uint256(r.uint256_field, p, bs);
    p += _pb._encode_key(7, _pb.WireType.LengthDelim, p, bs);
    p += _pb._encode_sol_address(r.address_field, p, bs);
    p += _pb._encode_key(8, _pb.WireType.LengthDelim, p, bs);
    p += _pb._encode_sol_int64(r.int64_field, p, bs);
    p += _pb._encode_key(9, _pb.WireType.LengthDelim, p, bs);
    p += _pb._encode_sol_uint64(r.uint64_field, p, bs);

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
  function _estimate(Data memory r) internal pure returns (uint) {
    uint e;

    e += 1 + _pb._sz_sint32(r.sint32_field);
    e += 1 + _pb._sz_int32(r.int32_field);
    e += 1 + 4;
    e += 1 + 8;
    e += 1 + 35;
    e += 1 + 35;
    e += 1 + 23;
    e += 1 + 11;
    e += 1 + 11;

    return e;
  }


  //store function
  function store(Data memory input, Data storage output) internal{
    output.sint32_field = input.sint32_field;
    output.int32_field = input.int32_field;
    output.fixed32_field = input.fixed32_field;
    output.fixed64_field = input.fixed64_field;
    output.int256_field = input.int256_field;
    output.uint256_field = input.uint256_field;
    output.address_field = input.address_field;
    output.int64_field = input.int64_field;
    output.uint64_field = input.uint64_field;

  }


  //utility functions
  function nil() internal pure returns (Data memory r) {
    assembly { r := 0 }
  }
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly { r := iszero(x) }
  }
} //library pb_TestInteger
