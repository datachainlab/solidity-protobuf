pragma solidity ^0.5.0;
/**
 * @title Runtime library for ProtoBuf serialization and/or deserialization.
 * All ProtoBuf generated code will use this library.
 */
library ProtoBufRuntime {
  // Types defined in ProtoBuf
  enum WireType { Varint, Fixed64, LengthDelim, StartGroup, EndGroup, Fixed32 }
  // Constants for bytes calculation
  uint constant WORD_LENGTH = 32;
  uint constant HEADER_SIZE_LENGTH_IN_BYTES = 4;
  uint constant BYTE_SIZE = 8;
  uint constant REMAINING_LENGTH = WORD_LENGTH - HEADER_SIZE_LENGTH_IN_BYTES;
  string constant OVERFLOW_MESSAGE = "length overflow";
  uint32 constant ERROR_FUNCTION_SELECTOR = 0x08c379a0;
  uint constant ERROR_DATA_OFFSET = 32;

  //Storages
  /**
   * @dev Encode to storage location using assembly to save storage space.
   * @param location The location of storage
   * @param encoded The encoded ProtoBuf bytes
   */
  function encodeStorage(bytes storage location, bytes memory encoded) internal {
    /**
     * This code use the first four bytes as size,
     * and then put the rest of `encoded` bytes.
     */
    uint length = encoded.length;
    uint firstWord;
    uint wordLength = WORD_LENGTH;
    uint remainingLength = REMAINING_LENGTH;

    assembly {
      firstWord := mload(add(encoded, wordLength))
    }
    firstWord = firstWord >> (BYTE_SIZE * HEADER_SIZE_LENGTH_IN_BYTES) | (length << BYTE_SIZE * REMAINING_LENGTH);

    assembly {
      sstore(location_slot, firstWord)
    }

    if (length > REMAINING_LENGTH) {
      length -= REMAINING_LENGTH;
      for (uint i = 0; i < ceil(length, WORD_LENGTH); i++) {
        assembly {
          let offset := add(mul(i, wordLength), remainingLength)
          let slotIndex := add(i, 1)
          sstore(add(location_slot, slotIndex), mload(add(add(encoded, wordLength), offset)))
        }
      }
    }
  }

  /**
   * @dev Decode storage location using assembly using the format in `encodeStorage`.
   * @param location The location of storage
   * @return The encoded bytes
   */
  function decodeStorage(bytes storage location) internal view returns (bytes memory) {
    /**
     * This code is to decode the first four bytes as size,
     * and then decode the rest using the decoded size.
     */
    uint firstWord;
    uint remainingLength = REMAINING_LENGTH;
    uint wordLength = WORD_LENGTH;

    assembly {
      firstWord := sload(location_slot)
    }

    uint length = firstWord >> (BYTE_SIZE * REMAINING_LENGTH);
    bytes memory encoded = new bytes(length);

    assembly {
      mstore(add(encoded, remainingLength), firstWord)
    }

    if (length > REMAINING_LENGTH) {
      length -= REMAINING_LENGTH;
      for (uint i = 0; i < ceil(length, WORD_LENGTH); i++) {
        assembly {
          let offset := add(mul(i, wordLength), remainingLength)
          let slotIndex := add(i, 1)
          mstore(add(add(encoded, wordLength), offset), sload(add(location_slot, slotIndex)))
        }
      }
    }
    return encoded;
  }

  /**
   * @dev Fast memory copy of bytes using assembly.
   * @param src The source memory address
   * @param dest The destination memory address
   * @param len The length of bytes to copy
   */
  function copyBytes(uint src, uint dest, uint len) internal pure {
    // Copy word-length chunks while possible
    for (; len >= WORD_LENGTH; len -= WORD_LENGTH) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += WORD_LENGTH;
      src += WORD_LENGTH;
    }

    // Copy remaining bytes
    uint mask = 256 ** (WORD_LENGTH - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }
  }

  /**
   * @dev Use assembly to get memory address.
   * @param r The in-memory bytes array
   * @return The memory address of `r`
   */
  function getMemoryAddress(bytes memory r) internal pure returns (uint) {
    uint addr;
    assembly {
      addr := r
    }
    return addr;
  }

  /**
   * @dev Implement Math function of ceil
   * @param a The denominator
   * @param m The numerator
   * @return r The result of ceil(a/m)
   */
  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m;
  }

  // Decoders
  /**
   * This section of code `_decode_(u)int(32|64)`, `_decode_enum` and `_decode_bool`
   * is to decode ProtoBuf native integers,
   * using the `varint` encoding.
   */

  /**
   * @dev Decode integers
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_uint32(uint p, bytes memory bs) internal pure returns (uint32, uint) {
    (uint varint, uint sz) = _decode_varint(p, bs);
    return (uint32(varint), sz);
  }

  /**
   * @dev Decode integers
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_uint64(uint p, bytes memory bs) internal pure returns (uint64, uint) {
    (uint varint, uint sz) = _decode_varint(p, bs);
    return (uint64(varint), sz);
  }

  /**
   * @dev Decode integers
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_int32(uint p, bytes memory bs) internal pure returns (int32, uint) {
    (uint varint, uint sz) = _decode_varint(p, bs);
    int32 r;
    assembly {
      r := varint
    }
    return (r, sz);
  }

  /**
   * @dev Decode integers
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_int64(uint p, bytes memory bs) internal pure returns (int64, uint) {
    (uint varint, uint sz) = _decode_varint(p, bs);
    int64 r;
    assembly {
      r := varint
    }
    return (r, sz);
  }

  /**
   * @dev Decode enum
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded enum's integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_enum(uint p, bytes memory bs) internal pure returns (int64, uint) {
    return _decode_int64(p, bs);
  }

  /**
   * @dev Decode enum
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded boolean
   * @return The length of `bs` used to get decoded
   */
  function _decode_bool(uint p, bytes memory bs) internal pure returns (bool, uint) {
    (uint varint, uint sz) = _decode_varint(p, bs);
    if (varint == 0) {
      return (false, sz);
    }
    return (true, sz);
  }

  /**
   * This section of code `_decode_sint(32|64)`
   * is to decode ProtoBuf native signed integers,
   * using the `zig-zag` encoding.
   */

  /**
   * @dev Decode signed integers
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_sint32(uint p, bytes memory bs) internal pure returns (int32, uint) {
    (int varint, uint sz) = _decode_varints(p, bs);
    return (int32(varint), sz);
  }

  /**
   * @dev Decode signed integers
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_sint64(uint p, bytes memory bs) internal pure returns (int64, uint) {
    (int varint, uint sz) = _decode_varints(p, bs);
    return (int64(varint), sz);
  }

  /**
   * @dev Decode string
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded string
   * @return The length of `bs` used to get decoded
   */
  function _decode_string(uint p, bytes memory bs) internal pure returns (string memory, uint) {
    (bytes memory x, uint sz) = _decode_lendelim(p, bs);
    return (string(x), sz);
  }

  /**
   * @dev Decode bytes array
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded bytes array
   * @return The length of `bs` used to get decoded
   */
  function _decode_bytes(uint p, bytes memory bs) internal pure returns (bytes memory, uint) {
    return _decode_lendelim(p, bs);
  }

  /**
   * @dev Decode ProtoBuf key
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded field ID
   * @return The decoded WireType specified in ProtoBuf
   * @return The length of `bs` used to get decoded
   */
  function _decode_key(uint p, bytes memory bs) internal pure returns (uint, WireType, uint) {
    (uint x, uint n) = _decode_varint(p, bs);
    WireType typeId  = WireType(x & 7);
    uint fieldId = x / 8;
    return (fieldId, typeId, n);
  }

  /**
   * @dev Decode ProtoBuf varint
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded unsigned integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_varint(uint p, bytes memory bs) internal pure returns (uint, uint) {
    /**
     * Read a byte.
     * Use the lower 7 bits and shift it to the left,
     * until the most significant bit is 0.
     * Refer to https://developers.google.com/protocol-buffers/docs/encoding
     */
    uint x = 0;
    uint sz = 0;
    uint length = bs.length + WORD_LENGTH;
    assembly {
      let b := 0x80
      p := add(bs, p)
      for {} eq(0x80, and(b, 0x80)) {} {
        if eq(lt(sub(p, bs), length), 0) {
          mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000) //error function selector
          mstore(4, 32)
          mstore(36, 15)
          mstore(68, 0x6c656e677468206f766572666c6f770000000000000000000000000000000000) // length overflow in hex
          revert(0, 83)
        }
        b := byte(0, mload(p))
        x := or(x, shl(mul(7, sz), and(0x7f, b)))
        sz := add(sz, 1)
        p := add(p, 0x01)
      }
    }
    return (x, sz);
  }

  /**
   * @dev Decode ProtoBuf zig-zag encoding
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded signed integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_varints(uint p, bytes memory bs) internal pure returns (int, uint) {
    /**
     * Refer to https://developers.google.com/protocol-buffers/docs/encoding
     */
    (uint u, uint sz) = _decode_varint(p, bs);
    int s;
    assembly {
      s := xor(shr(1, u), add(not(and(u, 1)), 1))
    }
    return (s, sz);
  }

  /**
   * @dev Decode ProtoBuf fixed-length encoding
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded unsigned integer
   * @return The length of `bs` used to get decoded
   */
  function _decode_uintf(uint p, bytes memory bs, uint sz) internal pure returns (uint, uint) {
    /**
     * Refer to https://developers.google.com/protocol-buffers/docs/encoding
     */
    uint x = 0;
    uint length = bs.length + WORD_LENGTH;
    assembly {
      let i := 0
      p := add(bs, p)
      for {} lt(i, sz) {} {
        if eq(lt(sub(p, bs), length), 0) {
          mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000) //error function selector
          mstore(4, 32)
          mstore(36, 15)
          mstore(68, 0x6c656e677468206f766572666c6f770000000000000000000000000000000000) // length overflow in hex
          revert(0, 83)
        }
        x := or(x, shl(mul(8, i), byte(0, mload(p))))
        p := add(p, 0x01)
        i := add(i, 1)
      }
    }
    return (x, sz);
  }

  /**
   * `_decode_(s)fixed(32|64)` is the concrete implementation of `_decode_uintf`
   */
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
    int r;
    assembly {
      r := x
    }
    return (int32(r), sz);
  }

  function _decode_sfixed64(uint p, bytes memory bs) internal pure returns (int64, uint) {
    (uint x, uint sz) = _decode_uintf(p, bs, 8);
    int r;
    assembly {
      r := x
    }
    return (int64(r), sz);
  }

  /**
   * @dev Decode bytes array
   * @param p The memory offset of `bs`
   * @param bs The bytes array to be decoded
   * @return The decoded bytes array
   * @return The length of `bs` used to get decoded
   */
  function _decode_lendelim(uint p, bytes memory bs) internal pure returns (bytes memory, uint) {
    /**
     * First read the size encoded in `varint`, then use the size to read bytes.
     */
    (uint len, uint sz) = _decode_varint(p, bs);
    bytes memory b = new bytes(len);
    uint length = bs.length + WORD_LENGTH;
    assembly {
      let bptr  := add(b, 32)
      let count := 0
      p := add(add(bs, p), sz)
      for {} lt(count, len) {} {
        if eq(lt(sub(p, bs), length), 0) {
          mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000) //error function selector
          mstore(4, 32)
          mstore(36, 15)
          mstore(68, 0x6c656e677468206f766572666c6f770000000000000000000000000000000000) // length overflow in hex
          revert(0, 83)
        }
        mstore8(bptr, byte(0, mload(p)))
        p := add(p, 1)
        bptr := add(bptr, 1)
        count := add(count, 1)
      }
    }
    return (b, sz + len);
  }

  // Encoders
  /**
   * @dev Encode ProtoBuf key
   * @param x The field ID
   * @param wt The WireType specified in ProtoBuf
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The length of encoded bytes
   */
  function _encode_key(uint x, WireType wt, uint p, bytes memory bs) internal pure returns (uint) {
    uint i;
    assembly {
      i := or(mul(x, 8), mod(wt, 8))
    }
    return _encode_varint(i, p, bs);
  }

  /**
   * @dev Encode ProtoBuf varint
   * @param x The unsigned integer to be encoded
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The length of encoded bytes
   */
  function _encode_varint(uint x, uint p, bytes memory bs) internal pure returns (uint) {
    /**
     * Refer to https://developers.google.com/protocol-buffers/docs/encoding
     */
    uint sz = 0;
    assembly {
      let bsptr := add(bs, p)
      let byt := and(x, 0x7f)
      for {} gt(shr(7, x), 0) {} {
        mstore8(bsptr, or(0x80, byt))
        bsptr := add(bsptr, 1)
        sz := add(sz, 1)
        x := shr(7, x)
        byt := and(x, 0x7f)
      }
      mstore8(bsptr, byt)
      sz := add(sz, 1)
    }
    return sz;
  }

  /**
   * @dev Encode ProtoBuf zig-zag encoding
   * @param x The signed integer to be encoded
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The length of encoded bytes
   */
  function _encode_varints(int x, uint p, bytes memory bs) internal pure returns (uint) {
    /**
     * Refer to https://developers.google.com/protocol-buffers/docs/encoding
     */
    uint encodedInt = _encode_zigzag(x);
    return _encode_varint(encodedInt, p, bs);
  }

  /**
   * @dev Encode ProtoBuf bytes
   * @param xs The bytes array to be encoded
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The length of encoded bytes
   */
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
    return sz + count;
  }

  /**
   * @dev Encode ProtoBuf string
   * @param xs The string to be encoded
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The length of encoded bytes
   */
  function _encode_string(string memory xs, uint p, bytes memory bs) internal pure returns (uint) {
    return  _encode_bytes(bytes(xs), p, bs);
  }

  /**
   * `_encode_(u)int(32|64)`, `_encode_enum` and `_encode_bool`
   * are concrete implementation of `_encode_varint`
   */
  function _encode_uint32(uint32 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_varint(x, p, bs);
  }

  function _encode_uint64(uint64 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_varint(x, p, bs);
  }

  function _encode_int32(int32 x, uint p, bytes memory bs) internal pure returns (uint) {
    uint64 twosComplement;
    assembly {
      twosComplement := x
    }
    return _encode_varint(twosComplement, p, bs);
  }

  function _encode_int64(int64 x, uint p, bytes memory bs) internal pure returns (uint) {
    uint64 twosComplement;
    assembly {
      twosComplement := x
    }
    return _encode_varint(twosComplement, p, bs);
  }

  function _encode_enum(int64 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_int64(x, p, bs);
  }

  function _encode_bool(bool x, uint p, bytes memory bs) internal pure returns (uint) {
    if (x) {
      return _encode_varint(1, p, bs);
    }
    else return _encode_varint(0, p, bs);
  }

  /**
   * `_encode_sint(32|64)`, `_encode_enum` and `_encode_bool`
   * are the concrete implementation of `_encode_varints`
   */
  function _encode_sint32(int32 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_varints(x, p, bs);
  }

  function _encode_sint64(int64 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_varints(x, p, bs);
  }

  /**
   * `_encode_(s)fixed(32|64)` is the concrete implementation of `_encode_uintf`
   */
  function _encode_fixed32(uint32 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_uintf(x, p, bs, 4);
  }

  function _encode_fixed64(uint64 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_uintf(x, p, bs, 8);
  }

  function _encode_sfixed32(int32 x, uint p, bytes memory bs) internal pure returns (uint) {
    uint32 twosComplement;
    assembly {
      twosComplement := x
    }
    return _encode_uintf(twosComplement, p, bs, 4);
  }

  function _encode_sfixed64(int64 x, uint p, bytes memory bs) internal pure returns (uint) {
    uint64 twosComplement;
    assembly {
      twosComplement := x
    }
    return _encode_uintf(twosComplement, p, bs, 8);
  }

  /**
   * @dev Encode ProtoBuf fixed-length integer
   * @param x The unsigned integer to be encoded
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The length of encoded bytes
   */
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

  /**
   * @dev Encode ProtoBuf zig-zag signed integer
   * @param i The unsigned integer to be encoded
   * @return The encoded unsigned integer
   */
  function _encode_zigzag(int i) internal pure returns (uint) {
    if (i >= 0) {
      return uint(i) * 2;
    }
    else return uint(i * -2) - 1;
  }

  // Estimators
  /**
   * @dev Estimate the length of encoded LengthDelim
   * @param i The length of LengthDelim
   * @return The estimated encoded length
   */
  function _sz_lendelim(uint i) internal pure returns (uint) {
    return i + _sz_varint(i);
  }

  /**
   * @dev Estimate the length of encoded ProtoBuf field ID
   * @param i The field ID
   * @return The estimated encoded length
   */
  function _sz_key(uint i) internal pure returns (uint) {
    if (i < 16) {
      return 1;
    }
    else if (i < 2048) {
      return 2;
    }
    else if (i < 262144) {
      return 3;
    }
    else {
      revert("not supported");
    }
  }

  /**
   * @dev Estimate the length of encoded ProtoBuf varint
   * @param i The unsigned integer
   * @return The estimated encoded length
   */
  function _sz_varint(uint i) internal pure returns (uint) {
    uint count = 1;
    assembly {
      i := shr(7, i)
      for {} gt(i, 0) {} {
        i := shr(7, i)
        count := add(count, 1)
      }
    }
    return count;
  }

  /**
   * `_sz_(u)int(32|64)` and `_sz_enum` are the concrete implementation of `_sz_varint`
   */
  function _sz_uint32(uint32 i) internal pure returns (uint) {
    return _sz_varint(i);
  }

  function _sz_uint64(uint64 i) internal pure returns (uint) {
    return _sz_varint(i);
  }

  function _sz_int32(int32 i) internal pure returns (uint) {
    if (i < 0) {
      return 10;
    }
    else return _sz_varint(uint32(i));
  }

  function _sz_int64(int64 i) internal pure returns (uint) {
    if (i < 0) {
      return 10;
    }
    else return _sz_varint(uint64(i));
  }

  function _sz_enum(int64 i) internal pure returns (uint) {
    if (i < 0) {
      return 10;
    }
    else return _sz_varint(uint64(i));
  }

  /**
   * `_sz_sint(32|64)` and `_sz_enum` are the concrete implementation of zig-zag encoding
   */
  function _sz_sint32(int32 i) internal pure returns (uint) {
    return _sz_varint(_encode_zigzag(i));
  }

  function _sz_sint64(int64 i) internal pure returns (uint) {
    return _sz_varint(_encode_zigzag(i));
  }

  // Soltype extensions
  /**
   * @dev Decode Solidity integer and/or fixed-size bytes array, filling from lowest bit.
   * @param n The maximum number of bytes to read
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The bytes32 representation
   * @return The number of bytes used to decode
   */
  function _decode_sol_bytesN_lower(uint8 n, uint p, bytes memory bs) internal pure returns (bytes32, uint) {
    uint r;
    (uint len, uint sz) = _decode_varint(p, bs);
    if (len + sz > n + 3) {
      revert(OVERFLOW_MESSAGE);
    }
    p += 3;
    require(p < bs.length + WORD_LENGTH, OVERFLOW_MESSAGE);
    assembly {
      r := mload(add(p, bs))
    }
    for (uint i = len - 2; i < WORD_LENGTH; i++) {
      r /= 256;
    }
    return (bytes32(r), len + sz);
  }

  /**
   * @dev Decode Solidity integer and/or fixed-size bytes array, filling from highest bit.
   * @param n The maximum number of bytes to read
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The bytes32 representation
   * @return The number of bytes used to decode
   */
  function _decode_sol_bytesN(uint8 n, uint p, bytes memory bs) internal pure returns (bytes32, uint) {
    (uint len, uint sz) = _decode_varint(p, bs);
    uint wordLength = WORD_LENGTH;
    uint byteSize = BYTE_SIZE;
    if (len + sz > n + 3) {
      revert(OVERFLOW_MESSAGE);
    }
    p += 3;
    bytes32 acc;
    require(p < bs.length + WORD_LENGTH, OVERFLOW_MESSAGE);
    assembly {
      acc := mload(add(p, bs))
      let difference := sub(wordLength, sub(len, 2))
      let bits := mul(byteSize, difference)
      acc := shl(bits, shr(bits, acc))
    }
    return (acc, len + sz);
  }

  /*
   * `_decode_sol*` are the concrete implementation of decoding Solidity types
   */
  function _decode_sol_address(uint p, bytes memory bs) internal pure returns (address, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytesN(20, p, bs);
    return (address(bytes20(r)), sz);
  }

  function _decode_sol_bool(uint p, bytes memory bs) internal pure returns (bool, uint) {
    (uint r, uint sz) = _decode_sol_uintN(1, p, bs);
    if (r == 0) {
      return (false, sz);
    }
    return (true, sz);
  }

  function _decode_sol_uint(uint p, bytes memory bs) internal pure returns (uint, uint) {
    return _decode_sol_uint256(p, bs);
  }

  function _decode_sol_uintN(uint8 n, uint p, bytes memory bs) internal pure returns (uint, uint) {
    (bytes32 u, uint sz) = _decode_sol_bytesN_lower(n, p, bs);
    uint r;
    assembly {
      r := u
    }
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
    int r;
    assembly {
      r := u
      r := signextend(sub(sz, 4), r)
    }
    return (r, sz);
  }

  function _decode_sol_bytes(uint8 n, uint p, bytes memory bs) internal pure returns (bytes32, uint) {
    (bytes32 u, uint sz) = _decode_sol_bytesN(n, p, bs);
    return (u, sz);
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
    (bytes32 r, uint sz) = _decode_sol_bytes(1, p, bs);
    return (bytes1(r), sz);
  }

  function _decode_sol_bytes2(uint p, bytes memory bs) internal pure returns (bytes2, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(2, p, bs);
    return (bytes2(r), sz);
  }

  function _decode_sol_bytes3(uint p, bytes memory bs) internal pure returns (bytes3, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(3, p, bs);
    return (bytes3(r), sz);
  }

  function _decode_sol_bytes4(uint p, bytes memory bs) internal pure returns (bytes4, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(4, p, bs);
    return (bytes4(r), sz);
  }

  function _decode_sol_bytes5(uint p, bytes memory bs) internal pure returns (bytes5, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(5, p, bs);
    return (bytes5(r), sz);
  }

  function _decode_sol_bytes6(uint p, bytes memory bs) internal pure returns (bytes6, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(6, p, bs);
    return (bytes6(r), sz);
  }

  function _decode_sol_bytes7(uint p, bytes memory bs) internal pure returns (bytes7, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(7, p, bs);
    return (bytes7(r), sz);
  }

  function _decode_sol_bytes8(uint p, bytes memory bs) internal pure returns (bytes8, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(8, p, bs);
    return (bytes8(r), sz);
  }

  function _decode_sol_bytes9(uint p, bytes memory bs) internal pure returns (bytes9, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(9, p, bs);
    return (bytes9(r), sz);
  }

  function _decode_sol_bytes10(uint p, bytes memory bs) internal pure returns (bytes10, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(10, p, bs);
    return (bytes10(r), sz);
  }

  function _decode_sol_bytes11(uint p, bytes memory bs) internal pure returns (bytes11, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(11, p, bs);
    return (bytes11(r), sz);
  }

  function _decode_sol_bytes12(uint p, bytes memory bs) internal pure returns (bytes12, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(12, p, bs);
    return (bytes12(r), sz);
  }

  function _decode_sol_bytes13(uint p, bytes memory bs) internal pure returns (bytes13, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(13, p, bs);
    return (bytes13(r), sz);
  }

  function _decode_sol_bytes14(uint p, bytes memory bs) internal pure returns (bytes14, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(14, p, bs);
    return (bytes14(r), sz);
  }

  function _decode_sol_bytes15(uint p, bytes memory bs) internal pure returns (bytes15, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(15, p, bs);
    return (bytes15(r), sz);
  }

  function _decode_sol_bytes16(uint p, bytes memory bs) internal pure returns (bytes16, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(16, p, bs);
    return (bytes16(r), sz);
  }

  function _decode_sol_bytes17(uint p, bytes memory bs) internal pure returns (bytes17, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(17, p, bs);
    return (bytes17(r), sz);
  }

  function _decode_sol_bytes18(uint p, bytes memory bs) internal pure returns (bytes18, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(18, p, bs);
    return (bytes18(r), sz);
  }

  function _decode_sol_bytes19(uint p, bytes memory bs) internal pure returns (bytes19, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(19, p, bs);
    return (bytes19(r), sz);
  }

  function _decode_sol_bytes20(uint p, bytes memory bs) internal pure returns (bytes20, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(20, p, bs);
    return (bytes20(r), sz);
  }

  function _decode_sol_bytes21(uint p, bytes memory bs) internal pure returns (bytes21, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(21, p, bs);
    return (bytes21(r), sz);
  }

  function _decode_sol_bytes22(uint p, bytes memory bs) internal pure returns (bytes22, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(22, p, bs);
    return (bytes22(r), sz);
  }

  function _decode_sol_bytes23(uint p, bytes memory bs) internal pure returns (bytes23, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(23, p, bs);
    return (bytes23(r), sz);
  }

  function _decode_sol_bytes24(uint p, bytes memory bs) internal pure returns (bytes24, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(24, p, bs);
    return (bytes24(r), sz);
  }

  function _decode_sol_bytes25(uint p, bytes memory bs) internal pure returns (bytes25, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(25, p, bs);
    return (bytes25(r), sz);
  }

  function _decode_sol_bytes26(uint p, bytes memory bs) internal pure returns (bytes26, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(26, p, bs);
    return (bytes26(r), sz);
  }

  function _decode_sol_bytes27(uint p, bytes memory bs) internal pure returns (bytes27, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(27, p, bs);
    return (bytes27(r), sz);
  }

  function _decode_sol_bytes28(uint p, bytes memory bs) internal pure returns (bytes28, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(28, p, bs);
    return (bytes28(r), sz);
  }

  function _decode_sol_bytes29(uint p, bytes memory bs) internal pure returns (bytes29, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(29, p, bs);
    return (bytes29(r), sz);
  }

  function _decode_sol_bytes30(uint p, bytes memory bs) internal pure returns (bytes30, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(30, p, bs);
    return (bytes30(r), sz);
  }

  function _decode_sol_bytes31(uint p, bytes memory bs) internal pure returns (bytes31, uint) {
    (bytes32 r, uint sz) = _decode_sol_bytes(31, p, bs);
    return (bytes31(r), sz);
  }

  function _decode_sol_bytes32(uint p, bytes memory bs) internal pure returns (bytes32, uint) {
    return _decode_sol_bytes(32, p, bs);
  }

  /*
   * `_encode_sol*` are the concrete implementation of encoding Solidity types
   */
  function _encode_sol_address(address x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 20, p, bs);
  }
  function _encode_sol_uint(uint x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 32, p, bs);
  }
  function _encode_sol_uint8(uint8 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 1, p, bs);
  }

  function _encode_sol_uint16(uint16 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 2, p, bs);
  }

  function _encode_sol_uint24(uint24 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 3, p, bs);
  }

  function _encode_sol_uint32(uint32 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 4, p, bs);
  }

  function _encode_sol_uint40(uint40 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 5, p, bs);
  }

  function _encode_sol_uint48(uint48 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 6, p, bs);
  }

  function _encode_sol_uint56(uint56 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 7, p, bs);
  }

  function _encode_sol_uint64(uint64 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 8, p, bs);
  }

  function _encode_sol_uint72(uint72 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 9, p, bs);
  }

  function _encode_sol_uint80(uint80 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 10, p, bs);
  }

  function _encode_sol_uint88(uint88 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 11, p, bs);
  }

  function _encode_sol_uint96(uint96 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 12, p, bs);
  }

  function _encode_sol_uint104(uint104 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 13, p, bs);
  }

  function _encode_sol_uint112(uint112 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 14, p, bs);
  }

  function _encode_sol_uint120(uint120 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 15, p, bs);
  }

  function _encode_sol_uint128(uint128 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 16, p, bs);
  }

  function _encode_sol_uint136(uint136 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 17, p, bs);
  }

  function _encode_sol_uint144(uint144 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 18, p, bs);
  }

  function _encode_sol_uint152(uint152 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 19, p, bs);
  }

  function _encode_sol_uint160(uint160 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 20, p, bs);
  }

  function _encode_sol_uint168(uint168 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 21, p, bs);
  }

  function _encode_sol_uint176(uint176 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 22, p, bs);
  }

  function _encode_sol_uint184(uint184 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 23, p, bs);
  }

  function _encode_sol_uint192(uint192 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 24, p, bs);
  }

  function _encode_sol_uint200(uint200 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 25, p, bs);
  }

  function _encode_sol_uint208(uint208 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 26, p, bs);
  }

  function _encode_sol_uint216(uint216 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 27, p, bs);
  }

  function _encode_sol_uint224(uint224 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 28, p, bs);
  }

  function _encode_sol_uint232(uint232 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 29, p, bs);
  }

  function _encode_sol_uint240(uint240 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 30, p, bs);
  }

  function _encode_sol_uint248(uint248 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 31, p, bs);
  }

  function _encode_sol_uint256(uint256 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(uint(x), 32, p, bs);
  }
  function _encode_sol_int(int x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 32, p, bs);
  }
  function _encode_sol_int8(int8 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 1, p, bs);
  }

  function _encode_sol_int16(int16 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 2, p, bs);
  }

  function _encode_sol_int24(int24 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 3, p, bs);
  }

  function _encode_sol_int32(int32 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 4, p, bs);
  }

  function _encode_sol_int40(int40 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 5, p, bs);
  }

  function _encode_sol_int48(int48 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 6, p, bs);
  }

  function _encode_sol_int56(int56 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 7, p, bs);
  }

  function _encode_sol_int64(int64 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 8, p, bs);
  }

  function _encode_sol_int72(int72 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 9, p, bs);
  }

  function _encode_sol_int80(int80 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 10, p, bs);
  }

  function _encode_sol_int88(int88 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 11, p, bs);
  }

  function _encode_sol_int96(int96 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 12, p, bs);
  }

  function _encode_sol_int104(int104 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 13, p, bs);
  }

  function _encode_sol_int112(int112 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 14, p, bs);
  }

  function _encode_sol_int120(int120 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 15, p, bs);
  }

  function _encode_sol_int128(int128 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 16, p, bs);
  }

  function _encode_sol_int136(int136 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 17, p, bs);
  }

  function _encode_sol_int144(int144 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 18, p, bs);
  }

  function _encode_sol_int152(int152 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 19, p, bs);
  }

  function _encode_sol_int160(int160 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 20, p, bs);
  }

  function _encode_sol_int168(int168 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 21, p, bs);
  }

  function _encode_sol_int176(int176 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 22, p, bs);
  }

  function _encode_sol_int184(int184 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 23, p, bs);
  }

  function _encode_sol_int192(int192 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 24, p, bs);
  }

  function _encode_sol_int200(int200 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 25, p, bs);
  }

  function _encode_sol_int208(int208 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 26, p, bs);
  }

  function _encode_sol_int216(int216 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 27, p, bs);
  }

  function _encode_sol_int224(int224 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 28, p, bs);
  }

  function _encode_sol_int232(int232 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 29, p, bs);
  }

  function _encode_sol_int240(int240 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 30, p, bs);
  }

  function _encode_sol_int248(int248 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(int(x), 31, p, bs);
  }

  function _encode_sol_int256(int256 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol(x, 32, p, bs);
  }

  function _encode_sol_bytes1(bytes1 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 1, p, bs);
  }

  function _encode_sol_bytes2(bytes2 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 2, p, bs);
  }

  function _encode_sol_bytes3(bytes3 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 3, p, bs);
  }

  function _encode_sol_bytes4(bytes4 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 4, p, bs);
  }

  function _encode_sol_bytes5(bytes5 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 5, p, bs);
  }

  function _encode_sol_bytes6(bytes6 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 6, p, bs);
  }

  function _encode_sol_bytes7(bytes7 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 7, p, bs);
  }

  function _encode_sol_bytes8(bytes8 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 8, p, bs);
  }

  function _encode_sol_bytes9(bytes9 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 9, p, bs);
  }

  function _encode_sol_bytes10(bytes10 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 10, p, bs);
  }

  function _encode_sol_bytes11(bytes11 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 11, p, bs);
  }

  function _encode_sol_bytes12(bytes12 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 12, p, bs);
  }

  function _encode_sol_bytes13(bytes13 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 13, p, bs);
  }

  function _encode_sol_bytes14(bytes14 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 14, p, bs);
  }

  function _encode_sol_bytes15(bytes15 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 15, p, bs);
  }

  function _encode_sol_bytes16(bytes16 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 16, p, bs);
  }

  function _encode_sol_bytes17(bytes17 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 17, p, bs);
  }

  function _encode_sol_bytes18(bytes18 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 18, p, bs);
  }

  function _encode_sol_bytes19(bytes19 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 19, p, bs);
  }

  function _encode_sol_bytes20(bytes20 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 20, p, bs);
  }

  function _encode_sol_bytes21(bytes21 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 21, p, bs);
  }

  function _encode_sol_bytes22(bytes22 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 22, p, bs);
  }

  function _encode_sol_bytes23(bytes23 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 23, p, bs);
  }

  function _encode_sol_bytes24(bytes24 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 24, p, bs);
  }

  function _encode_sol_bytes25(bytes25 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 25, p, bs);
  }

  function _encode_sol_bytes26(bytes26 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 26, p, bs);
  }

  function _encode_sol_bytes27(bytes27 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 27, p, bs);
  }

  function _encode_sol_bytes28(bytes28 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 28, p, bs);
  }

  function _encode_sol_bytes29(bytes29 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 29, p, bs);
  }

  function _encode_sol_bytes30(bytes30 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 30, p, bs);
  }

  function _encode_sol_bytes31(bytes31 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(bytes32(x), 31, p, bs);
  }

  function _encode_sol_bytes32(bytes32 x, uint p, bytes memory bs) internal pure returns (uint) {
    return _encode_sol_bytes(x, 32, p, bs);
  }

  /**
   * @dev Encode the key of Solidity integer and/or fixed-size bytes array.
   * @param sz The number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes used to encode
   */
  function _encode_sol_header(uint sz, uint p, bytes memory bs) internal pure returns (uint) {
    uint offset = p;
    p += _encode_varint(sz + 2, p, bs);
    p += _encode_key(1, WireType.LengthDelim, p, bs);
    p += _encode_varint(sz, p, bs);
    return p - offset;
  }

  /**
   * @dev Encode Solidity type
   * @param x The unsinged integer to be encoded
   * @param sz The number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes used to encode
   */
  function _encode_sol(uint x, uint sz, uint p, bytes memory bs) internal pure returns (uint) {
    uint offset = p;
    uint size;
    p += 3;
    size = _encode_sol_raw_other(x, p, bs, sz);
    p += size;
    _encode_sol_header(size, offset, bs);
    return p - offset;
  }

  /**
   * @dev Encode Solidity type
   * @param x The signed integer to be encoded
   * @param sz The number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes used to encode
   */
  function _encode_sol(int x, uint sz, uint p, bytes memory bs) internal pure returns (uint) {
    uint offset = p;
    uint size;
    p += 3;
    size = _encode_sol_raw_other(x, p, bs, sz);
    p += size;
    _encode_sol_header(size, offset, bs);
    return p - offset;
  }

  /**
   * @dev Encode Solidity type
   * @param x The fixed-size byte array to be encoded
   * @param sz The number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes used to encode
   */
  function _encode_sol_bytes(bytes32 x, uint sz, uint p, bytes memory bs) internal pure returns (uint) {
    uint offset = p;
    uint size;
    p += 3;
    size = _encode_sol_raw_bytes_array(x, p, bs, sz);
    p += size;
    _encode_sol_header(size, offset, bs);
    return p - offset;
  }

  /**
   * @dev Get the actual size needed to encoding an unsigned integer
   * @param x The unsigned integer to be encoded
   * @param sz The maximum number of bytes used to encode Solidity types
   * @return The number of bytes needed for encoding `x`
   */
  function _get_real_size(uint x, uint sz) internal pure returns (uint) {
    uint base = 0xff;
    uint realSize = sz;
    while (x & (base << (realSize * BYTE_SIZE - BYTE_SIZE)) == 0 && realSize > 0) {
      realSize -= 1;
    }
    if (realSize == 0) {
      realSize = 1;
    }
    return realSize;
  }

  /**
   * @dev Get the actual size needed to encoding an signed integer
   * @param x The signed integer to be encoded
   * @param sz The maximum number of bytes used to encode Solidity types
   * @return The number of bytes needed for encoding `x`
   */
  function _get_real_size(int x, uint sz) internal pure returns (uint) {
    int base = 0xff;
    if (x >= 0) {
      uint tmp = _get_real_size(uint(x), sz);
      int remainder = (x & (base << (tmp * BYTE_SIZE - BYTE_SIZE))) >> (tmp * BYTE_SIZE - BYTE_SIZE);
      if (remainder >= 128) {
        tmp += 1;
      }
      return tmp;
    }

    uint realSize = sz;
    while (x & (base << (realSize * BYTE_SIZE - BYTE_SIZE)) == (base << (realSize * BYTE_SIZE - BYTE_SIZE)) && realSize > 0) {
      realSize -= 1;
    }
    int remainder = (x & (base << (realSize * BYTE_SIZE - BYTE_SIZE))) >> (realSize * BYTE_SIZE - BYTE_SIZE);
    if (remainder < 128) {
      realSize += 1;
    }
    return realSize;
  }

  /**
   * @dev Encode the fixed-bytes array
   * @param x The fixed-size byte array to be encoded
   * @param sz The maximum number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes needed for encoding `x`
   */
  function _encode_sol_raw_bytes_array(bytes32 x, uint p, bytes memory bs, uint sz) internal pure returns (uint) {
    /**
     * The idea is to not encode the leading bytes of zero.
     */
    uint actualSize = sz;
    for (uint i = 0; i < sz; i++) {
      uint8 current = uint8(x[sz - 1 - i]);
      if (current == 0 && actualSize > 1) {
        actualSize--;
      } else {
        break;
      }
    }
    assembly {
      let bsptr := add(bs, p)
      let count := actualSize
      for {} gt(count, 0) {} {
        mstore8(bsptr, byte(sub(actualSize, count), x))
        bsptr := add(bsptr, 1)
        count := sub(count, 1)
      }
    }
    return actualSize;
  }

  /**
   * @dev Encode the signed integer
   * @param x The signed integer to be encoded
   * @param sz The maximum number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes needed for encoding `x`
   */
  function _encode_sol_raw_other(int x, uint p, bytes memory bs, uint sz) internal pure returns (uint) {
    /**
     * The idea is to not encode the leading bytes of zero.or one,
     * depending on whether it is positive.
     */
    uint realSize = _get_real_size(x, sz);
    assembly {
      let bsptr := add(bs, p)
      let count := realSize
      for {} gt(count, 0) {} {
        mstore8(bsptr, byte(sub(32, count), x))
        bsptr := add(bsptr, 1)
        count := sub(count, 1)
      }
    }
    return realSize;
  }

  /**
   * @dev Encode the unsigned integer
   * @param x The unsigned integer to be encoded
   * @param sz The maximum number of bytes used to encode Solidity types
   * @param p The offset of bytes array `bs`
   * @param bs The bytes array to encode
   * @return The number of bytes needed for encoding `x`
   */
  function _encode_sol_raw_other(uint x, uint p, bytes memory bs, uint sz) internal pure returns (uint) {
    uint realSize = _get_real_size(x, sz);
    assembly {
      let bsptr := add(bs, p)
      let count := realSize
      for {} gt(count, 0) {} {
        mstore8(bsptr, byte(sub(32, count), x))
        bsptr := add(bsptr, 1)
        count := sub(count, 1)
      }
    }
    return realSize;
  }
}
