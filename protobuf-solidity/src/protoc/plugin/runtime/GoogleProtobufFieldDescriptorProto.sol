// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;
import "./ProtoBufRuntime.sol";

library GoogleProtobufFieldDescriptorProto {

  enum Type {
    TYPE_DOUBLE,
    TYPE_FLOAT,
    TYPE_INT64,
    TYPE_UINT64,
    TYPE_INT32,
    TYPE_FIXED64,
    TYPE_FIXED32,
    TYPE_BOOL,
    TYPE_STRING,
    TYPE_GROUP,
    TYPE_MESSAGE,
    TYPE_BYTES,
    TYPE_UINT32,
    TYPE_ENUM,
    TYPE_SFIXED32,
    TYPE_SFIXED64,
    TYPE_SINT32,
    TYPE_SINT64
  }

  function decode_Type(int64 x) internal pure returns (Type) {
    return Type(uint256(uint64(x)));
  }

  function encode_Type(Type x) internal pure returns (int32) {
    return int32(uint32(x));
  }
}