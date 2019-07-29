pragma solidity ^0.5.0;
import "./runtime.sol";
library pb_TestRepeated{
  //enum definition

  //struct definition
  struct Data {
    string string_field;
    uint256[] uint256s;
    int64[] sint64s;
    bool bool_field;
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
          p += _read_string_field(p, bs, r, counters);
      else if(fieldId == 2)
          p += _read_uint256s(p, bs, nil(), counters);
      else if(fieldId == 3)
          p += _read_sint64s(p, bs, nil(), counters);
      else if(fieldId == 4)
          p += _read_bool_field(p, bs, r, counters);
      else revert();
    }
    p = offset;
    r.uint256s = new uint256[](counters[2]);
    r.sint64s = new int64[](counters[3]);

    while(p < offset+sz) {
      (fieldId, wireType, bytesRead) = _pb._decode_key(p, bs);
      p += bytesRead;
      if (false) {}
      else if(fieldId == 1)
          p += _read_string_field(p, bs, nil(), counters);
      else if(fieldId == 2)
          p += _read_uint256s(p, bs, r, counters);
      else if(fieldId == 3)
          p += _read_sint64s(p, bs, r, counters);
      else if(fieldId == 4)
          p += _read_bool_field(p, bs, nil(), counters);
      else revert();
    }
    return (r, sz);
  }

  // field readers
  function _read_string_field(uint p, bytes memory bs, Data memory r, uint[5] memory counters) internal pure returns (uint) {
    (string memory x, uint sz) = _pb._decode_string(p, bs);
    if(isNil(r)) {
      counters[1] += 1;
    } else {
      r.string_field = x;
      if(counters[1] > 0) counters[1] -= 1;
    }
    return sz;
  }
  function _read_uint256s(uint p, bytes memory bs, Data memory r, uint[5] memory counters) internal pure returns (uint) {
    (uint256 x, uint sz) = _pb._decode_sol_uint256(p, bs);
    if(isNil(r)) {
      counters[2] += 1;
    } else {
      r.uint256s[ r.uint256s.length - counters[2] ] = x;
      if(counters[2] > 0) counters[2] -= 1;
    }
    return sz;
  }
  function _read_sint64s(uint p, bytes memory bs, Data memory r, uint[5] memory counters) internal pure returns (uint) {
    (int64 x, uint sz) = _pb._decode_sint64(p, bs);
    if(isNil(r)) {
      counters[3] += 1;
    } else {
      r.sint64s[ r.sint64s.length - counters[3] ] = x;
      if(counters[3] > 0) counters[3] -= 1;
    }
    return sz;
  }
  function _read_bool_field(uint p, bytes memory bs, Data memory r, uint[5] memory counters) internal pure returns (uint) {
    (bool x, uint sz) = _pb._decode_bool(p, bs);
    if(isNil(r)) {
      counters[4] += 1;
    } else {
      r.bool_field = x;
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
uint i;
    p += _pb._encode_key(1, _pb.WireType.LengthDelim, p, bs);
    p += _pb._encode_string(r.string_field, p, bs);
    for(i=0; i<r.uint256s.length; i++) {
      p += _pb._encode_key(2, _pb.WireType.LengthDelim, p, bs);
      p += _pb._encode_sol_uint256(r.uint256s[i], p, bs);
    }
    for(i=0; i<r.sint64s.length; i++) {
      p += _pb._encode_key(3, _pb.WireType.Varint, p, bs);
      p += _pb._encode_sint64(r.sint64s[i], p, bs);
    }
    p += _pb._encode_key(4, _pb.WireType.Varint, p, bs);
    p += _pb._encode_bool(r.bool_field, p, bs);

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
uint i;
    e += 1 + _pb._sz_lendelim(bytes(r.string_field).length);
    for(i=0; i<r.uint256s.length; i++) e+= 1 + 35;
    for(i=0; i<r.sint64s.length; i++) e+= 1 + _pb._sz_sint64(r.sint64s[i]);
    e += 1 + 1;

    return e;
  }


  //store function
  function store(Data memory input, Data storage output) internal{
    output.string_field = input.string_field;
    output.uint256s = input.uint256s;
    output.sint64s = input.sint64s;
    output.bool_field = input.bool_field;

  }


  //utility functions
  function nil() internal pure returns (Data memory r) {
    assembly { r := 0 }
  }
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly { r := iszero(x) }
  }
} //library pb_TestRepeated
