pragma solidity ^0.5.0;

library _pb {

  enum WireType { Varint, Fixed64, LengthDelim, StartGroup, EndGroup, Fixed32 }

  // Decoders

  function _decode_uint32(uint p, bytes memory bs) internal pure returns (uint32, uint) {
    (uint varint, uint sz) = _decode_varint(p, bs);
    return (uint32(varint), sz);
  }

  function _decode_uint64(uint p, bytes memory bs) internal pure returns (uint64, uint) {
    (uint varint, uint sz) = _decode_varint(p, bs);
    return (uint64(varint), sz);
  }

  function _decode_int32(uint p, bytes memory bs) internal pure returns (int32, uint) {
    (uint varint, uint sz) = _decode_varint(p, bs);
    int32 r; assembly { r := varint }
    return (r, sz);
  }

  function _decode_int64(uint p, bytes memory bs) internal pure returns (int64, uint) {
    (uint varint, uint sz) = _decode_varint(p, bs);
    int64 r; assembly { r := varint }
    return (r, sz);
  }

  function _decode_enum(uint p, bytes memory bs) internal pure returns (int64, uint) {
    return _decode_int64(p, bs);
  }

  function _decode_sint32(uint p, bytes memory bs) internal pure returns (int32, uint) {
    (int varint, uint sz) = _decode_varints(p, bs);
    return (int32(varint), sz);
  }

  function _decode_sint64(uint p, bytes memory bs) internal pure returns (int64, uint) {
    (int varint, uint sz) = _decode_varints(p, bs);
    return (int64(varint), sz);
  }

  function _decode_bool(uint p, bytes memory bs) internal pure returns (bool, uint) {
    (uint varint, uint sz) = _decode_varint(p, bs);
    if (varint == 0) return (false, sz);
    return (true, sz);
  }

  function _decode_string(uint p, bytes memory bs) internal pure returns (string memory, uint) {
    (bytes memory x, uint sz) = _decode_lendelim(p, bs);
    return (string(x), sz);
  }

  function _decode_bytes(uint p, bytes memory bs) internal pure returns (bytes memory, uint) {
    return _decode_lendelim(p, bs);
  }

  function _decode_key(uint p, bytes memory bs) internal pure returns (uint, WireType, uint) {
    (uint x, uint n) = _decode_varint(p, bs);
    WireType typeId  = WireType(x & 7);
    uint fieldId = x / 8; //x >> 3;
    return (fieldId, typeId, n);
  }

  function _decode_varint(uint p, bytes memory bs) internal pure returns (uint, uint) {
    uint x = 0;
    uint sz = 0;
    assembly {
      let b := 0x80
      p     := add(bs, p)
      for {} eq(0x80, and(b, 0x80)) {} {
        b  := byte(0, mload(p))
        x  := or(x, mul(and(0x7f, b), exp(2, mul(7, sz))))
        sz := add(sz, 1)
        p  := add(p, 0x01)
      }
    }
    return (x, sz);
  }

  function _decode_varints(uint p, bytes memory bs) internal pure returns (int, uint) {
    (uint u, uint sz) = _decode_varint(p, bs);
    int s;
    assembly {
      s := xor(div(u, 2), add(not(and(u, 1)), 1))
    }
    return (s, sz);
  }

  function _decode_uintf(uint p, bytes memory bs, uint sz) internal pure returns (uint, uint) {
    uint x = 0;
    assembly {
      let i := 0
      p     := add(bs, p)
      for {} lt(i, sz) {} {
        x := or(x, mul(byte(0, mload(p)), exp(2, mul(8, i))))
        p := add(p, 0x01)
        i := add(i, 1)
      }
    }
    return (x, sz);
  }

  function _decode_fixed32(uint p, bytes memory bs) internal pure returns (uint32, uint) {
    (uint x, uint sz) = _decode_uintf(p, bs, 4);
    return (uint32(x), sz);
  }

  function _decode_fixed64(uint p, bytes memory bs) internal pure returns (uint64, uint) {
    (uint x, uint sz) = _decode_uintf(p, bs, 8);
    return (uint64(x), sz);
  }

  function _decode_sfixed32(uint p, bytes memory bs) internal pure returns (int32, uint) {
    (uint x, uint sz) = _decode_uintf(p, bs, 4);
    int r; assembly { r := x }
    return (int32(r), sz);
  }

  function _decode_sfixed64(uint p, bytes memory bs) internal pure returns (int64, uint) {
    (uint x, uint sz) = _decode_uintf(p, bs, 8);
    int r; assembly { r := x }
    return (int64(r), sz);
  }

  function _decode_lendelim(uint p, bytes memory bs) internal pure returns (bytes memory, uint) {
    (uint len, uint sz) = _decode_varint(p, bs);
    bytes memory b = new bytes(len);
    assembly {
      let bptr  := add(b, 32)
      let count := 0
      p         := add(add(bs, p),sz)
      for {} lt(count, len) {} {
        mstore8(bptr, byte(0, mload(p)))
        p     := add(p, 1)
        bptr  := add(bptr, 1)
        count := add(count, 1)
      }
    }
    return (b, sz+len);
  }

  // Encoders

  function _encode_key(uint x, WireType wt, uint p, bytes memory bs) internal pure returns (uint) {
    uint i;
    assembly {
      i := or(mul(x, 8), mod(wt, 8))
    }
    return _encode_varint(i, p, bs);
  }

  function _encode_varint(uint x, uint p, bytes memory bs) internal pure returns (uint) {
    uint sz = 0;
    assembly {
      let bsptr := add(bs, p)
      /*
      let byt := 0
      let pbyt := 0
      loop:
      byt := and(div(x, exp(2, mul(7, sz))), 0x7f)
      pbyt := and(div(x, exp(2, mul(7, add(sz, 1)))), 0x7f)
      jumpi(end, eq(pbyt, 0))
      mstore8(bsptr, or(0x80, byt))
      bsptr := add(bsptr, 1)
      sz := add(sz, 1)
      jump(loop)
      end:

      */
      let byt := and(x, 0x7f)
      let pbyt := and(div(x, exp(2, 7)), 0x7f)
      for {} eq(eq(pbyt, 0), 0) {} {
        mstore8(bsptr, or(0x80, byt))
        bsptr := add(bsptr, 1)
        sz := add(sz, 1)
        byt := and(div(x, exp(2, mul(7, sz))), 0x7f)
        pbyt := and(div(x, exp(2, mul(7, add(sz, 1)))), 0x7f)
      }
      mstore8(bsptr, byt)
      sz := add(sz, 1)
    }
    return sz;
  }

  function _encode_varints(int x, uint p, bytes memory bs) internal pure returns (uint) {
    uint encodedInt = _encode_zigzag(x);
    return _encode_varint(encodedInt, p, bs);
  }

  function _encode_bytes(bytes memory xs, uint p, bytes memory bs) internal pure returns (uint) {
    uint xsLength = xs.length;
    uint sz = _encode_varint(xsLength, p, bs);
    uint count = 0;
    assembly {
      let bsptr := add(bs, add(p, sz))
      let xsptr := add(xs, 32)
      for {} lt(count, xsLength) {} {
        mstore8(bsptr, byte(0, mload(xsptr)))
        bsptr := add(bsptr, 1)
        xsptr := add(xsptr, 1)
        count := add(count, 1)
      }
    }
    return sz+count;
  }

  function _encode_uint32(uint32 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_varint(x, p, bs);
  }

  function _encode_uint64(uint64 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_varint(x, p, bs);
  }

  function _encode_int32(int32 x, uint p, bytes memory bs) internal pure returns (uint) {
    uint64 twosComplement; // use signextend here?
    assembly { twosComplement := signextend(64, x) }
    return _encode_varint(twosComplement, p, bs);
  }

  function _encode_int64(int64 x, uint p, bytes memory bs) internal pure returns (uint) {
    uint64 twosComplement;
    assembly { twosComplement := x }
    return _encode_varint(twosComplement, p, bs);
  }

  function _encode_enum(int64 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_int64(x, p, bs);
  }

  function _encode_sint32(int32 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_varints(x, p, bs);
  }

  function _encode_sint64(int64 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_varints(x, p, bs);
  }

  function _encode_string(string memory xs, uint p, bytes memory bs) internal pure returns (uint) {
    return  _encode_bytes(bytes(xs), p, bs);
  }

  function _encode_bool(bool x, uint p, bytes memory bs) internal pure returns (uint) {
    if (x) return _encode_varint(1, p, bs);
    else return _encode_varint(0, p, bs);
  }

  function _encode_fixed32(uint32 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_uintf(x, p, bs, 4);
  }

  function _encode_fixed64(uint64 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_uintf(x, p, bs, 8);
  }

  function _encode_sfixed32(int32 x, uint p, bytes memory bs) internal pure returns (uint) {
    uint32 twosComplement;
    assembly { twosComplement := x }
    return _encode_uintf(twosComplement, p, bs, 4);
  }

  function _encode_sfixed64(int64 x, uint p, bytes memory bs) internal pure returns (uint) {
    uint64 twosComplement;
    assembly { twosComplement := x }
    return _encode_uintf(twosComplement, p, bs, 8);
  }

  function _encode_uintf(uint x, uint p, bytes memory bs, uint sz) internal pure returns (uint) {
    assembly {
      let bsptr := add(sz,add(bs, p))
      let count := sz
      for {} gt(count, 0) {} {
        bsptr := sub(bsptr, 1)
        mstore8(bsptr, byte(sub(32, count), x))
        count := sub(count, 1)
      }
    }
    return sz;
  }

  function _encode_zigzag(int i) internal pure returns (uint) {
    if(i >= 0) return uint(i) * 2;
    else return uint(i * -2) - 1;
  }

  // Estimators

  function _sz_lendelim(uint i) internal pure returns (uint) {
    return i + _sz_varint(i);
  }

  function _sz_key(uint i) internal pure returns (uint) {
    if(i < 16) return 1;
    else if(i < 2048) return 2;
    else if(i < 262144) return 3;
    else revert();
  }

  function _sz_varint(uint i) internal pure returns (uint) {
    uint count = 1;
    assembly {
      for {} eq(lt(i, exp(2, mul(7, count))), 0) {} {
        count := add(count, 1)
      }
    }
    return count;
  }

  function _sz_uint32(uint32 i) internal pure returns (uint) {
    return _sz_varint(i);
  }

  function _sz_uint64(uint64 i) internal pure returns (uint) {
    return _sz_varint(i);
  }

  function _sz_int32(int32 i) internal pure returns (uint) {
    if (i < 0) return 10;
    else return _sz_varint(uint32(i));
  }

  function _sz_int64(int64 i) internal pure returns (uint) {
    if (i < 0) return 10;
    else return _sz_varint(uint64(i));
  }

  function _sz_enum(int64 i) internal pure returns (uint) {
    if (i < 0) return 10;
    else return _sz_varint(uint64(i));
  }

  function _sz_sint32(int32 i) internal pure returns (uint) {
    return _sz_varint(_encode_zigzag(i));
  }

  function _sz_sint64(int64 i) internal pure returns (uint) {
    return _sz_varint(_encode_zigzag(i));
  }

  // Soltype extensions

  function _decode_sol_bytesN_lower(uint8 n, uint p, bytes memory bs) internal pure returns (bytes32, uint) {
    uint r;
    (uint len, uint sz) = _decode_varint(p, bs);
    if (len + sz != n + 3) revert();
    p += 3;
    assembly { r := mload(add(p,bs)) }
    for (uint i=n; i<32; i++)
    r /= 256;
    return (bytes32(r), n + 3);
  }
  function _decode_sol_bytesN(uint8 n, uint p, bytes memory bs) internal pure returns (bytes32, uint) {
    (uint len, uint sz) = _decode_varint(p, bs);
    if (len + sz != n + 3) revert();
    p += 3;
    bytes32 acc;
    assembly {
      acc := mload(add(p, bs))
    }
    return (acc, n + 3);
  }

  function _decode_sol_address(uint p, bytes memory bs) internal pure returns (address, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN_lower(20, p, bs);
    bytes20 _result;
    assembly {
      _result := mload(add(r, 0x20))
    }
    return (address(_result), sz);
  }

  function _decode_sol_bool(uint p, bytes memory bs) internal pure returns (bool, uint) {
    (uint r, uint sz) = _decode_sol_uintN(1, p, bs);
    if (r == 0) return (false, sz);
    return (true, sz);
  }

  function _decode_sol_uint(uint p, bytes memory bs) internal pure returns (uint, uint) {
    return _decode_sol_uint256(p, bs);
  }

  function _decode_sol_uintN(uint8 n, uint p, bytes memory bs) internal pure returns (uint, uint) {
    (bytes32 u, uint sz) = _decode_sol_bytesN_lower(n, p, bs);
    uint r; assembly { r := u }
    return (r, sz);
  }

  function _decode_sol_uint8(uint p, bytes memory bs) internal pure returns (uint8, uint) {
    (uint r, uint sz) = _decode_sol_uintN(1, p, bs);
    return (uint8(r), sz);
  }

  function _decode_sol_uint16(uint p, bytes memory bs) internal pure returns (uint16, uint) {
    (uint r, uint sz) = _decode_sol_uintN(2, p, bs);
    return (uint16(r), sz);
  }

  function _decode_sol_uint24(uint p, bytes memory bs) internal pure returns (uint24, uint) {
    (uint r, uint sz) = _decode_sol_uintN(3, p, bs);
    return (uint24(r), sz);
  }

  function _decode_sol_uint32(uint p, bytes memory bs) internal pure returns (uint32, uint) {
    (uint r, uint sz) = _decode_sol_uintN(4, p, bs);
    return (uint32(r), sz);
  }

  function _decode_sol_uint40(uint p, bytes memory bs) internal pure returns (uint40, uint) {
    (uint r, uint sz) = _decode_sol_uintN(5, p, bs);
    return (uint40(r), sz);
  }

  function _decode_sol_uint48(uint p, bytes memory bs) internal pure returns (uint48, uint) {
    (uint r, uint sz) = _decode_sol_uintN(6, p, bs);
    return (uint48(r), sz);
  }

  function _decode_sol_uint56(uint p, bytes memory bs) internal pure returns (uint56, uint) {
    (uint r, uint sz) = _decode_sol_uintN(7, p, bs);
    return (uint56(r), sz);
  }

  function _decode_sol_uint64(uint p, bytes memory bs) internal pure returns (uint64, uint) {
    (uint r, uint sz) = _decode_sol_uintN(8, p, bs);
    return (uint64(r), sz);
  }

  function _decode_sol_uint72(uint p, bytes memory bs) internal pure returns (uint72, uint) {
    (uint r, uint sz) = _decode_sol_uintN(9, p, bs);
    return (uint72(r), sz);
  }

  function _decode_sol_uint80(uint p, bytes memory bs) internal pure returns (uint80, uint) {
    (uint r, uint sz) = _decode_sol_uintN(10, p, bs);
    return (uint80(r), sz);
  }

  function _decode_sol_uint88(uint p, bytes memory bs) internal pure returns (uint88, uint) {
    (uint r, uint sz) = _decode_sol_uintN(11, p, bs);
    return (uint88(r), sz);
  }

  function _decode_sol_uint96(uint p, bytes memory bs) internal pure returns (uint96, uint) {
    (uint r, uint sz) = _decode_sol_uintN(12, p, bs);
    return (uint96(r), sz);
  }

  function _decode_sol_uint104(uint p, bytes memory bs) internal pure returns (uint104, uint) {
    (uint r, uint sz) = _decode_sol_uintN(13, p, bs);
    return (uint104(r), sz);
  }

  function _decode_sol_uint112(uint p, bytes memory bs) internal pure returns (uint112, uint) {
    (uint r, uint sz) = _decode_sol_uintN(14, p, bs);
    return (uint112(r), sz);
  }

  function _decode_sol_uint120(uint p, bytes memory bs) internal pure returns (uint120, uint) {
    (uint r, uint sz) = _decode_sol_uintN(15, p, bs);
    return (uint120(r), sz);
  }

  function _decode_sol_uint128(uint p, bytes memory bs) internal pure returns (uint128, uint) {
    (uint r, uint sz) = _decode_sol_uintN(16, p, bs);
    return (uint128(r), sz);
  }

  function _decode_sol_uint136(uint p, bytes memory bs) internal pure returns (uint136, uint) {
    (uint r, uint sz) = _decode_sol_uintN(17, p, bs);
    return (uint136(r), sz);
  }

  function _decode_sol_uint144(uint p, bytes memory bs) internal pure returns (uint144, uint) {
    (uint r, uint sz) = _decode_sol_uintN(18, p, bs);
    return (uint144(r), sz);
  }

  function _decode_sol_uint152(uint p, bytes memory bs) internal pure returns (uint152, uint) {
    (uint r, uint sz) = _decode_sol_uintN(19, p, bs);
    return (uint152(r), sz);
  }

  function _decode_sol_uint160(uint p, bytes memory bs) internal pure returns (uint160, uint) {
    (uint r, uint sz) = _decode_sol_uintN(20, p, bs);
    return (uint160(r), sz);
  }

  function _decode_sol_uint168(uint p, bytes memory bs) internal pure returns (uint168, uint) {
    (uint r, uint sz) = _decode_sol_uintN(21, p, bs);
    return (uint168(r), sz);
  }

  function _decode_sol_uint176(uint p, bytes memory bs) internal pure returns (uint176, uint) {
    (uint r, uint sz) = _decode_sol_uintN(22, p, bs);
    return (uint176(r), sz);
  }

  function _decode_sol_uint184(uint p, bytes memory bs) internal pure returns (uint184, uint) {
    (uint r, uint sz) = _decode_sol_uintN(23, p, bs);
    return (uint184(r), sz);
  }

  function _decode_sol_uint192(uint p, bytes memory bs) internal pure returns (uint192, uint) {
    (uint r, uint sz) = _decode_sol_uintN(24, p, bs);
    return (uint192(r), sz);
  }

  function _decode_sol_uint200(uint p, bytes memory bs) internal pure returns (uint200, uint) {
    (uint r, uint sz) = _decode_sol_uintN(25, p, bs);
    return (uint200(r), sz);
  }

  function _decode_sol_uint208(uint p, bytes memory bs) internal pure returns (uint208, uint) {
    (uint r, uint sz) = _decode_sol_uintN(26, p, bs);
    return (uint208(r), sz);
  }

  function _decode_sol_uint216(uint p, bytes memory bs) internal pure returns (uint216, uint) {
    (uint r, uint sz) = _decode_sol_uintN(27, p, bs);
    return (uint216(r), sz);
  }

  function _decode_sol_uint224(uint p, bytes memory bs) internal pure returns (uint224, uint) {
    (uint r, uint sz) = _decode_sol_uintN(28, p, bs);
    return (uint224(r), sz);
  }

  function _decode_sol_uint232(uint p, bytes memory bs) internal pure returns (uint232, uint) {
    (uint r, uint sz) = _decode_sol_uintN(29, p, bs);
    return (uint232(r), sz);
  }

  function _decode_sol_uint240(uint p, bytes memory bs) internal pure returns (uint240, uint) {
    (uint r, uint sz) = _decode_sol_uintN(30, p, bs);
    return (uint240(r), sz);
  }

  function _decode_sol_uint248(uint p, bytes memory bs) internal pure returns (uint248, uint) {
    (uint r, uint sz) = _decode_sol_uintN(31, p, bs);
    return (uint248(r), sz);
  }

  function _decode_sol_uint256(uint p, bytes memory bs) internal pure returns (uint256, uint) {
    (uint r, uint sz) = _decode_sol_uintN(32, p, bs);
    return (uint256(r), sz);
  }

  function _decode_sol_int(uint p, bytes memory bs) internal pure returns (int, uint) {
    return _decode_sol_int256(p, bs);
  }

  function _decode_sol_intN(uint8 n, uint p, bytes memory bs) internal pure returns (int, uint) {
    (bytes32 u, uint sz) = _decode_sol_bytesN_lower(n, p, bs);
    int r; assembly { r := u }
    return (r, sz);
  }

  function _decode_sol_int8(uint p, bytes memory bs) internal pure returns (int8, uint) {
    (int r, uint sz) = _decode_sol_intN(1, p, bs);
    return (int8(r), sz);
  }

  function _decode_sol_int16(uint p, bytes memory bs) internal pure returns (int16, uint) {
    (int r, uint sz) = _decode_sol_intN(2, p, bs);
    return (int16(r), sz);
  }

  function _decode_sol_int24(uint p, bytes memory bs) internal pure returns (int24, uint) {
    (int r, uint sz) = _decode_sol_intN(3, p, bs);
    return (int24(r), sz);
  }

  function _decode_sol_int32(uint p, bytes memory bs) internal pure returns (int32, uint) {
    (int r, uint sz) = _decode_sol_intN(4, p, bs);
    return (int32(r), sz);
  }

  function _decode_sol_int40(uint p, bytes memory bs) internal pure returns (int40, uint) {
    (int r, uint sz) = _decode_sol_intN(5, p, bs);
    return (int40(r), sz);
  }

  function _decode_sol_int48(uint p, bytes memory bs) internal pure returns (int48, uint) {
    (int r, uint sz) = _decode_sol_intN(6, p, bs);
    return (int48(r), sz);
  }

  function _decode_sol_int56(uint p, bytes memory bs) internal pure returns (int56, uint) {
    (int r, uint sz) = _decode_sol_intN(7, p, bs);
    return (int56(r), sz);
  }

  function _decode_sol_int64(uint p, bytes memory bs) internal pure returns (int64, uint) {
    (int r, uint sz) = _decode_sol_intN(8, p, bs);
    return (int64(r), sz);
  }

  function _decode_sol_int72(uint p, bytes memory bs) internal pure returns (int72, uint) {
    (int r, uint sz) = _decode_sol_intN(9, p, bs);
    return (int72(r), sz);
  }

  function _decode_sol_int80(uint p, bytes memory bs) internal pure returns (int80, uint) {
    (int r, uint sz) = _decode_sol_intN(10, p, bs);
    return (int80(r), sz);
  }

  function _decode_sol_int88(uint p, bytes memory bs) internal pure returns (int88, uint) {
    (int r, uint sz) = _decode_sol_intN(11, p, bs);
    return (int88(r), sz);
  }

  function _decode_sol_int96(uint p, bytes memory bs) internal pure returns (int96, uint) {
    (int r, uint sz) = _decode_sol_intN(12, p, bs);
    return (int96(r), sz);
  }

  function _decode_sol_int104(uint p, bytes memory bs) internal pure returns (int104, uint) {
    (int r, uint sz) = _decode_sol_intN(13, p, bs);
    return (int104(r), sz);
  }

  function _decode_sol_int112(uint p, bytes memory bs) internal pure returns (int112, uint) {
    (int r, uint sz) = _decode_sol_intN(14, p, bs);
    return (int112(r), sz);
  }

  function _decode_sol_int120(uint p, bytes memory bs) internal pure returns (int120, uint) {
    (int r, uint sz) = _decode_sol_intN(15, p, bs);
    return (int120(r), sz);
  }

  function _decode_sol_int128(uint p, bytes memory bs) internal pure returns (int128, uint) {
    (int r, uint sz) = _decode_sol_intN(16, p, bs);
    return (int128(r), sz);
  }

  function _decode_sol_int136(uint p, bytes memory bs) internal pure returns (int136, uint) {
    (int r, uint sz) = _decode_sol_intN(17, p, bs);
    return (int136(r), sz);
  }

  function _decode_sol_int144(uint p, bytes memory bs) internal pure returns (int144, uint) {
    (int r, uint sz) = _decode_sol_intN(18, p, bs);
    return (int144(r), sz);
  }

  function _decode_sol_int152(uint p, bytes memory bs) internal pure returns (int152, uint) {
    (int r, uint sz) = _decode_sol_intN(19, p, bs);
    return (int152(r), sz);
  }

  function _decode_sol_int160(uint p, bytes memory bs) internal pure returns (int160, uint) {
    (int r, uint sz) = _decode_sol_intN(20, p, bs);
    return (int160(r), sz);
  }

  function _decode_sol_int168(uint p, bytes memory bs) internal pure returns (int168, uint) {
    (int r, uint sz) = _decode_sol_intN(21, p, bs);
    return (int168(r), sz);
  }

  function _decode_sol_int176(uint p, bytes memory bs) internal pure returns (int176, uint) {
    (int r, uint sz) = _decode_sol_intN(22, p, bs);
    return (int176(r), sz);
  }

  function _decode_sol_int184(uint p, bytes memory bs) internal pure returns (int184, uint) {
    (int r, uint sz) = _decode_sol_intN(23, p, bs);
    return (int184(r), sz);
  }

  function _decode_sol_int192(uint p, bytes memory bs) internal pure returns (int192, uint) {
    (int r, uint sz) = _decode_sol_intN(24, p, bs);
    return (int192(r), sz);
  }

  function _decode_sol_int200(uint p, bytes memory bs) internal pure returns (int200, uint) {
    (int r, uint sz) = _decode_sol_intN(25, p, bs);
    return (int200(r), sz);
  }

  function _decode_sol_int208(uint p, bytes memory bs) internal pure returns (int208, uint) {
    (int r, uint sz) = _decode_sol_intN(26, p, bs);
    return (int208(r), sz);
  }

  function _decode_sol_int216(uint p, bytes memory bs) internal pure returns (int216, uint) {
    (int r, uint sz) = _decode_sol_intN(27, p, bs);
    return (int216(r), sz);
  }

  function _decode_sol_int224(uint p, bytes memory bs) internal pure returns (int224, uint) {
    (int r, uint sz) = _decode_sol_intN(28, p, bs);
    return (int224(r), sz);
  }

  function _decode_sol_int232(uint p, bytes memory bs) internal pure returns (int232, uint) {
    (int r, uint sz) = _decode_sol_intN(29, p, bs);
    return (int232(r), sz);
  }

  function _decode_sol_int240(uint p, bytes memory bs) internal pure returns (int240, uint) {
    (int r, uint sz) = _decode_sol_intN(30, p, bs);
    return (int240(r), sz);
  }

  function _decode_sol_int248(uint p, bytes memory bs) internal pure returns (int248, uint) {
    (int r, uint sz) = _decode_sol_intN(31, p, bs);
    return (int248(r), sz);
  }

  function _decode_sol_int256(uint p, bytes memory bs) internal pure returns (int256, uint) {
    (int r, uint sz) = _decode_sol_intN(32, p, bs);
    return (int256(r), sz);
  }

  function _decode_sol_bytes1(uint p, bytes memory bs) internal pure returns (bytes1, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(1, p, bs);
    return (bytes1(r), sz);
  }

  function _decode_sol_bytes2(uint p, bytes memory bs) internal pure returns (bytes2, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(2, p, bs);
    return (bytes2(r), sz);
  }

  function _decode_sol_bytes3(uint p, bytes memory bs) internal pure returns (bytes3, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(3, p, bs);
    return (bytes3(r), sz);
  }

  function _decode_sol_bytes4(uint p, bytes memory bs) internal pure returns (bytes4, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(4, p, bs);
    return (bytes4(r), sz);
  }

  function _decode_sol_bytes5(uint p, bytes memory bs) internal pure returns (bytes5, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(5, p, bs);
    return (bytes5(r), sz);
  }

  function _decode_sol_bytes6(uint p, bytes memory bs) internal pure returns (bytes6, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(6, p, bs);
    return (bytes6(r), sz);
  }

  function _decode_sol_bytes7(uint p, bytes memory bs) internal pure returns (bytes7, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(7, p, bs);
    return (bytes7(r), sz);
  }

  function _decode_sol_bytes8(uint p, bytes memory bs) internal pure returns (bytes8, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(8, p, bs);
    return (bytes8(r), sz);
  }

  function _decode_sol_bytes9(uint p, bytes memory bs) internal pure returns (bytes9, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(9, p, bs);
    return (bytes9(r), sz);
  }

  function _decode_sol_bytes10(uint p, bytes memory bs) internal pure returns (bytes10, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(10, p, bs);
    return (bytes10(r), sz);
  }

  function _decode_sol_bytes11(uint p, bytes memory bs) internal pure returns (bytes11, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(11, p, bs);
    return (bytes11(r), sz);
  }

  function _decode_sol_bytes12(uint p, bytes memory bs) internal pure returns (bytes12, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(12, p, bs);
    return (bytes12(r), sz);
  }

  function _decode_sol_bytes13(uint p, bytes memory bs) internal pure returns (bytes13, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(13, p, bs);
    return (bytes13(r), sz);
  }

  function _decode_sol_bytes14(uint p, bytes memory bs) internal pure returns (bytes14, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(14, p, bs);
    return (bytes14(r), sz);
  }

  function _decode_sol_bytes15(uint p, bytes memory bs) internal pure returns (bytes15, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(15, p, bs);
    return (bytes15(r), sz);
  }

  function _decode_sol_bytes16(uint p, bytes memory bs) internal pure returns (bytes16, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(16, p, bs);
    return (bytes16(r), sz);
  }

  function _decode_sol_bytes17(uint p, bytes memory bs) internal pure returns (bytes17, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(17, p, bs);
    return (bytes17(r), sz);
  }

  function _decode_sol_bytes18(uint p, bytes memory bs) internal pure returns (bytes18, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(18, p, bs);
    return (bytes18(r), sz);
  }

  function _decode_sol_bytes19(uint p, bytes memory bs) internal pure returns (bytes19, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(19, p, bs);
    return (bytes19(r), sz);
  }

  function _decode_sol_bytes20(uint p, bytes memory bs) internal pure returns (bytes20, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(20, p, bs);
    return (bytes20(r), sz);
  }

  function _decode_sol_bytes21(uint p, bytes memory bs) internal pure returns (bytes21, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(21, p, bs);
    return (bytes21(r), sz);
  }

  function _decode_sol_bytes22(uint p, bytes memory bs) internal pure returns (bytes22, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(22, p, bs);
    return (bytes22(r), sz);
  }

  function _decode_sol_bytes23(uint p, bytes memory bs) internal pure returns (bytes23, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(23, p, bs);
    return (bytes23(r), sz);
  }

  function _decode_sol_bytes24(uint p, bytes memory bs) internal pure returns (bytes24, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(24, p, bs);
    return (bytes24(r), sz);
  }

  function _decode_sol_bytes25(uint p, bytes memory bs) internal pure returns (bytes25, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(25, p, bs);
    return (bytes25(r), sz);
  }

  function _decode_sol_bytes26(uint p, bytes memory bs) internal pure returns (bytes26, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(26, p, bs);
    return (bytes26(r), sz);
  }

  function _decode_sol_bytes27(uint p, bytes memory bs) internal pure returns (bytes27, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(27, p, bs);
    return (bytes27(r), sz);
  }

  function _decode_sol_bytes28(uint p, bytes memory bs) internal pure returns (bytes28, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(28, p, bs);
    return (bytes28(r), sz);
  }

  function _decode_sol_bytes29(uint p, bytes memory bs) internal pure returns (bytes29, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(29, p, bs);
    return (bytes29(r), sz);
  }

  function _decode_sol_bytes30(uint p, bytes memory bs) internal pure returns (bytes30, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(30, p, bs);
    return (bytes30(r), sz);
  }

  function _decode_sol_bytes31(uint p, bytes memory bs) internal pure returns (bytes31, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(31, p, bs);
    return (bytes31(r), sz);
  }

  function _decode_sol_bytes32(uint p, bytes memory bs) internal pure returns (bytes32, uint) {
    return _decode_sol_bytesN(32, p, bs);
  }

  function _encode_sol_address(address x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 20, p, bs);
  }
  function _encode_sol_uint(uint x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 32, p, bs);
  }
  function _encode_sol_uint8(uint8 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 1, p, bs);
  }

  function _encode_sol_uint16(uint16 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 2, p, bs);
  }

  function _encode_sol_uint24(uint24 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 3, p, bs);
  }

  function _encode_sol_uint32(uint32 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 4, p, bs);
  }

  function _encode_sol_uint40(uint40 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 5, p, bs);
  }

  function _encode_sol_uint48(uint48 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 6, p, bs);
  }

  function _encode_sol_uint56(uint56 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 7, p, bs);
  }

  function _encode_sol_uint64(uint64 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 8, p, bs);
  }

  function _encode_sol_uint72(uint72 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 9, p, bs);
  }

  function _encode_sol_uint80(uint80 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 10, p, bs);
  }

  function _encode_sol_uint88(uint88 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 11, p, bs);
  }

  function _encode_sol_uint96(uint96 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 12, p, bs);
  }

  function _encode_sol_uint104(uint104 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 13, p, bs);
  }

  function _encode_sol_uint112(uint112 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 14, p, bs);
  }

  function _encode_sol_uint120(uint120 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 15, p, bs);
  }

  function _encode_sol_uint128(uint128 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 16, p, bs);
  }

  function _encode_sol_uint136(uint136 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 17, p, bs);
  }

  function _encode_sol_uint144(uint144 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 18, p, bs);
  }

  function _encode_sol_uint152(uint152 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 19, p, bs);
  }

  function _encode_sol_uint160(uint160 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 20, p, bs);
  }

  function _encode_sol_uint168(uint168 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 21, p, bs);
  }

  function _encode_sol_uint176(uint176 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 22, p, bs);
  }

  function _encode_sol_uint184(uint184 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 23, p, bs);
  }

  function _encode_sol_uint192(uint192 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 24, p, bs);
  }

  function _encode_sol_uint200(uint200 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 25, p, bs);
  }

  function _encode_sol_uint208(uint208 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 26, p, bs);
  }

  function _encode_sol_uint216(uint216 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 27, p, bs);
  }

  function _encode_sol_uint224(uint224 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 28, p, bs);
  }

  function _encode_sol_uint232(uint232 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 29, p, bs);
  }

  function _encode_sol_uint240(uint240 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 30, p, bs);
  }

  function _encode_sol_uint248(uint248 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 31, p, bs);
  }

  function _encode_sol_uint256(uint256 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 32, p, bs);
  }
  function _encode_sol_int(int x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_256(x), 32, p, bs);
  }
  function _encode_sol_int8(int8 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_8(x), 1, p, bs);
  }

  function _encode_sol_int16(int16 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_16(x), 2, p, bs);
  }

  function _encode_sol_int24(int24 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_24(x), 3, p, bs);
  }

  function _encode_sol_int32(int32 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_32(x), 4, p, bs);
  }

  function _encode_sol_int40(int40 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_40(x), 5, p, bs);
  }

  function _encode_sol_int48(int48 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_48(x), 6, p, bs);
  }

  function _encode_sol_int56(int56 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_56(x), 7, p, bs);
  }

  function _encode_sol_int64(int64 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_64(x), 8, p, bs);
  }

  function _encode_sol_int72(int72 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_72(x), 9, p, bs);
  }

  function _encode_sol_int80(int80 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_80(x), 10, p, bs);
  }

  function _encode_sol_int88(int88 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_88(x), 11, p, bs);
  }

  function _encode_sol_int96(int96 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_96(x), 12, p, bs);
  }

  function _encode_sol_int104(int104 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_104(x), 13, p, bs);
  }

  function _encode_sol_int112(int112 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_112(x), 14, p, bs);
  }

  function _encode_sol_int120(int120 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_120(x), 15, p, bs);
  }

  function _encode_sol_int128(int128 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_128(x), 16, p, bs);
  }

  function _encode_sol_int136(int136 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_136(x), 17, p, bs);
  }

  function _encode_sol_int144(int144 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_144(x), 18, p, bs);
  }

  function _encode_sol_int152(int152 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_152(x), 19, p, bs);
  }

  function _encode_sol_int160(int160 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_160(x), 20, p, bs);
  }

  function _encode_sol_int168(int168 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_168(x), 21, p, bs);
  }

  function _encode_sol_int176(int176 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_176(x), 22, p, bs);
  }

  function _encode_sol_int184(int184 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_184(x), 23, p, bs);
  }

  function _encode_sol_int192(int192 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_192(x), 24, p, bs);
  }

  function _encode_sol_int200(int200 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_200(x), 25, p, bs);
  }

  function _encode_sol_int208(int208 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_208(x), 26, p, bs);
  }

  function _encode_sol_int216(int216 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_216(x), 27, p, bs);
  }

  function _encode_sol_int224(int224 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_224(x), 28, p, bs);
  }

  function _encode_sol_int232(int232 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_232(x), 29, p, bs);
  }

  function _encode_sol_int240(int240 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_240(x), 30, p, bs);
  }

  function _encode_sol_int248(int248 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_248(x), 31, p, bs);
  }

  function _encode_sol_int256(int256 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(_twos_complement_256(x), 32, p, bs);
  }

  function _encode_sol_bytes1(bytes1 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 1, p, bs, true);
  }
  function _encode_sol_bytes2(bytes2 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 2, p, bs, true);
  }
  function _encode_sol_bytes3(bytes3 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 3, p, bs, true);
  }
  function _encode_sol_bytes4(bytes4 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 4, p, bs, true);
  }
  function _encode_sol_bytes5(bytes5 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 5, p, bs, true);
  }
  function _encode_sol_bytes6(bytes6 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 6, p, bs, true);
  }
  function _encode_sol_bytes7(bytes7 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 7, p, bs, true);
  }
  function _encode_sol_bytes8(bytes8 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 8, p, bs, true);
  }
  function _encode_sol_bytes9(bytes9 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 9, p, bs, true);
  }
  function _encode_sol_bytes10(bytes10 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 10, p, bs, true);
  }
  function _encode_sol_bytes11(bytes11 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 11, p, bs, true);
  }
  function _encode_sol_bytes12(bytes12 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 12, p, bs, true);
  }
  function _encode_sol_bytes13(bytes13 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 13, p, bs, true);
  }
  function _encode_sol_bytes14(bytes14 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 14, p, bs, true);
  }
  function _encode_sol_bytes15(bytes15 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 15, p, bs, true);
  }
  function _encode_sol_bytes16(bytes16 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 16, p, bs, true);
  }
  function _encode_sol_bytes17(bytes17 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 17, p, bs, true);
  }
  function _encode_sol_bytes18(bytes18 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 18, p, bs, true);
  }
  function _encode_sol_bytes19(bytes19 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 19, p, bs, true);
  }
  function _encode_sol_bytes20(bytes20 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 20, p, bs, true);
  }
  function _encode_sol_bytes21(bytes21 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 21, p, bs, true);
  }
  function _encode_sol_bytes22(bytes22 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 22, p, bs, true);
  }
  function _encode_sol_bytes23(bytes23 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 23, p, bs, true);
  }
  function _encode_sol_bytes24(bytes24 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 24, p, bs, true);
  }
  function _encode_sol_bytes25(bytes25 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 25, p, bs, true);
  }
  function _encode_sol_bytes26(bytes26 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 26, p, bs, true);
  }
  function _encode_sol_bytes27(bytes27 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 27, p, bs, true);
  }
  function _encode_sol_bytes28(bytes28 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 28, p, bs, true);
  }
  function _encode_sol_bytes29(bytes29 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 29, p, bs, true);
  }
  function _encode_sol_bytes30(bytes30 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 30, p, bs, true);
  }
  function _encode_sol_bytes31(bytes31 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(bytes32(x)), 31, p, bs, true);
  }
  function _encode_sol_bytes32(bytes32 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 32, p, bs, true);
  }
  function _encode_sol_header(uint sz, uint p, bytes memory bs) internal pure returns (uint) {
    uint offset = p;
    p += _encode_varint(sz + 2, p, bs); // length of (payload + 1b key + 1b inner length)
    p += _encode_key(1, WireType.LengthDelim, p, bs);
    p += _encode_varint(sz, p, bs);
    return p - offset;
  }
  function _encode_sol(uint x, uint sz, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, sz, p, bs, false);
  }
  function _encode_sol(uint x, uint sz, uint p, bytes memory bs, bool is_bytes) internal pure returns (uint) {
    uint offset = p;
    p += _encode_sol_header(sz, p, bs);
    if (!is_bytes) {
      p += _encode_sol_raw_other(x, p, bs, sz);
    } else {
      p += _encode_sol_raw_bytes_array(x, p, bs, sz);
    }

    return p - offset;
  }
  function _encode_sol_raw_other(uint x, uint p, bytes memory bs, uint sz) internal pure returns (uint) {
    assembly {
      let bsptr := add(bs, p)
      let count := sz
      for {} gt(count, 0) {} {
        mstore8(bsptr, byte(sub(32, count), x))
        bsptr := add(bsptr, 1)
        count := sub(count, 1)
      }
    }
    return sz;
  }
  function _encode_sol_raw_bytes_array(uint x, uint p, bytes memory bs, uint sz) internal pure returns (uint) {
    assembly {
      let bsptr := add(bs, p)
      mstore(bsptr, x)
    }
    return sz;
  }
  function _twos_complement_8(int8 x) internal pure returns (uint8) {
    uint8 r; assembly { r := x }
    return r;
  }

  function _twos_complement_16(int16 x) internal pure returns (uint16) {
    uint16 r; assembly { r := x }
    return r;
  }

  function _twos_complement_24(int24 x) internal pure returns (uint24) {
    uint24 r; assembly { r := x }
    return r;
  }

  function _twos_complement_32(int32 x) internal pure returns (uint32) {
    uint32 r; assembly { r := x }
    return r;
  }

  function _twos_complement_40(int40 x) internal pure returns (uint40) {
    uint40 r; assembly { r := x }
    return r;
  }

  function _twos_complement_48(int48 x) internal pure returns (uint48) {
    uint48 r; assembly { r := x }
    return r;
  }

  function _twos_complement_56(int56 x) internal pure returns (uint56) {
    uint56 r; assembly { r := x }
    return r;
  }

  function _twos_complement_64(int64 x) internal pure returns (uint64) {
    uint64 r; assembly { r := x }
    return r;
  }

  function _twos_complement_72(int72 x) internal pure returns (uint72) {
    uint72 r; assembly { r := x }
    return r;
  }

  function _twos_complement_80(int80 x) internal pure returns (uint80) {
    uint80 r; assembly { r := x }
    return r;
  }

  function _twos_complement_88(int88 x) internal pure returns (uint88) {
    uint88 r; assembly { r := x }
    return r;
  }

  function _twos_complement_96(int96 x) internal pure returns (uint96) {
    uint96 r; assembly { r := x }
    return r;
  }

  function _twos_complement_104(int104 x) internal pure returns (uint104) {
    uint104 r; assembly { r := x }
    return r;
  }

  function _twos_complement_112(int112 x) internal pure returns (uint112) {
    uint112 r; assembly { r := x }
    return r;
  }

  function _twos_complement_120(int120 x) internal pure returns (uint120) {
    uint120 r; assembly { r := x }
    return r;
  }

  function _twos_complement_128(int128 x) internal pure returns (uint128) {
    uint128 r; assembly { r := x }
    return r;
  }

  function _twos_complement_136(int136 x) internal pure returns (uint136) {
    uint136 r; assembly { r := x }
    return r;
  }

  function _twos_complement_144(int144 x) internal pure returns (uint144) {
    uint144 r; assembly { r := x }
    return r;
  }

  function _twos_complement_152(int152 x) internal pure returns (uint152) {
    uint152 r; assembly { r := x }
    return r;
  }

  function _twos_complement_160(int160 x) internal pure returns (uint160) {
    uint160 r; assembly { r := x }
    return r;
  }

  function _twos_complement_168(int168 x) internal pure returns (uint168) {
    uint168 r; assembly { r := x }
    return r;
  }

  function _twos_complement_176(int176 x) internal pure returns (uint176) {
    uint176 r; assembly { r := x }
    return r;
  }

  function _twos_complement_184(int184 x) internal pure returns (uint184) {
    uint184 r; assembly { r := x }
    return r;
  }

  function _twos_complement_192(int192 x) internal pure returns (uint192) {
    uint192 r; assembly { r := x }
    return r;
  }

  function _twos_complement_200(int200 x) internal pure returns (uint200) {
    uint200 r; assembly { r := x }
    return r;
  }

  function _twos_complement_208(int208 x) internal pure returns (uint208) {
    uint208 r; assembly { r := x }
    return r;
  }

  function _twos_complement_216(int216 x) internal pure returns (uint216) {
    uint216 r; assembly { r := x }
    return r;
  }

  function _twos_complement_224(int224 x) internal pure returns (uint224) {
    uint224 r; assembly { r := x }
    return r;
  }

  function _twos_complement_232(int232 x) internal pure returns (uint232) {
    uint232 r; assembly { r := x }
    return r;
  }

  function _twos_complement_240(int240 x) internal pure returns (uint240) {
    uint240 r; assembly { r := x }
    return r;
  }

  function _twos_complement_248(int248 x) internal pure returns (uint248) {
    uint248 r; assembly { r := x }
    return r;
  }

  function _twos_complement_256(int256 x) internal pure returns (uint256) {
    uint256 r; assembly { r := x }
    return r;
  }
}
