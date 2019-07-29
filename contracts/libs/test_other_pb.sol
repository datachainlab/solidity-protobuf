pragma solidity ^0.5.0;
import "./runtime.sol";
library pb_TestOther{
  //enum definition
  int64 public constant _Corpus_UNIVERSAL = 0;
  function Corpus_UNIVERSAL() internal pure returns (int64) { return _Corpus_UNIVERSAL; }
  int64 public constant _Corpus_WEB = 1;
  function Corpus_WEB() internal pure returns (int64) { return _Corpus_WEB; }
  int64 public constant _Corpus_IMAGES = 2;
  function Corpus_IMAGES() internal pure returns (int64) { return _Corpus_IMAGES; }
  //struct definition
  struct Data {
    bytes bytes_field;
    string string_field;
    bool bool_field;
    int64 enum_field;
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
          p += _read_bytes_field(p, bs, r, counters);
      else if(fieldId == 2)
          p += _read_string_field(p, bs, r, counters);
      else if(fieldId == 3)
          p += _read_bool_field(p, bs, r, counters);
      else if(fieldId == 4)
          p += _read_enum_field(p, bs, r, counters);
      else revert();
    }
    p = offset;

    while(p < offset+sz) {
      (fieldId, wireType, bytesRead) = _pb._decode_key(p, bs);
      p += bytesRead;
      if (false) {}
      else if(fieldId == 1)
          p += _read_bytes_field(p, bs, nil(), counters);
      else if(fieldId == 2)
          p += _read_string_field(p, bs, nil(), counters);
      else if(fieldId == 3)
          p += _read_bool_field(p, bs, nil(), counters);
      else if(fieldId == 4)
          p += _read_enum_field(p, bs, nil(), counters);
      else revert();
    }
    return (r, sz);
  }

  // field readers
  function _read_bytes_field(uint p, bytes memory bs, Data memory r, uint[5] memory counters) internal pure returns (uint) {
    (bytes memory x, uint sz) = _pb._decode_bytes(p, bs);
    if(isNil(r)) {
      counters[1] += 1;
    } else {
      r.bytes_field = x;
      if(counters[1] > 0) counters[1] -= 1;
    }
    return sz;
  }
  function _read_string_field(uint p, bytes memory bs, Data memory r, uint[5] memory counters) internal pure returns (uint) {
    (string memory x, uint sz) = _pb._decode_string(p, bs);
    if(isNil(r)) {
      counters[2] += 1;
    } else {
      r.string_field = x;
      if(counters[2] > 0) counters[2] -= 1;
    }
    return sz;
  }
  function _read_bool_field(uint p, bytes memory bs, Data memory r, uint[5] memory counters) internal pure returns (uint) {
    (bool x, uint sz) = _pb._decode_bool(p, bs);
    if(isNil(r)) {
      counters[3] += 1;
    } else {
      r.bool_field = x;
      if(counters[3] > 0) counters[3] -= 1;
    }
    return sz;
  }
  function _read_enum_field(uint p, bytes memory bs, Data memory r, uint[5] memory counters) internal pure returns (uint) {
    (int64 x, uint sz) = _pb._decode_enum(p, bs);
    if(isNil(r)) {
      counters[4] += 1;
    } else {
      r.enum_field = x;
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
    p += _pb._encode_bytes(r.bytes_field, p, bs);
    p += _pb._encode_key(2, _pb.WireType.LengthDelim, p, bs);
    p += _pb._encode_string(r.string_field, p, bs);
    p += _pb._encode_key(3, _pb.WireType.Varint, p, bs);
    p += _pb._encode_bool(r.bool_field, p, bs);
    p += _pb._encode_key(4, _pb.WireType.Varint, p, bs);
    p += _pb._encode_enum(r.enum_field, p, bs);

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

    e += 1 + _pb._sz_lendelim(r.bytes_field.length);
    e += 1 + _pb._sz_lendelim(bytes(r.string_field).length);
    e += 1 + 1;
    e += 1 + _pb._sz_enum(r.enum_field);

    return e;
  }


  //store function
  function store(Data memory input, Data storage output) internal{
    output.bytes_field = input.bytes_field;
    output.string_field = input.string_field;
    output.bool_field = input.bool_field;
    output.enum_field = input.enum_field;

  }


  //utility functions
  function nil() internal pure returns (Data memory r) {
    assembly { r := 0 }
  }
  function isNil(Data memory x) internal pure returns (bool r) {
    assembly { r := iszero(x) }
  }
} //library pb_TestOther
