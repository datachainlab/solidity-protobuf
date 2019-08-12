MAIN_ENCODER = """
  function encode({struct} memory r) {visibility} pure returns (bytes memory) {{
    bytes memory bs = new bytes(_estimate(r));
    uint sz = _encode(r, 32, bs);
    assembly {{
      mstore(bs, sz)
    }}
    return bs;
  }}"""

INNER_FIELD_ENCODER_REPEATED = """
    for(i = 0; i < r.{field}.length; i++) {{
      pointer += ProtoBufRuntime._encode_key({key}, ProtoBufRuntime.WireType.{wiretype}, pointer, bs);
      pointer += {encoder}(r.{field}[i], pointer, bs);
    }}"""

INNER_FIELD_ENCODER_REPEATED_MAP = """
    for(i = 0; i < r._size_{field}; i++) {{
      pointer += ProtoBufRuntime._encode_key({key}, ProtoBufRuntime.WireType.{wiretype}, pointer, bs);
      pointer += {encoder}(r.{field}[i], pointer, bs);
    }}"""

INNER_FIELD_ENCODER_NOT_REPEATED = """
    pointer += ProtoBufRuntime._encode_key({key}, ProtoBufRuntime.WireType.{wiretype}, pointer, bs);
    pointer += {encoder}(r.{field}, pointer, bs);"""

INNER_ENCODER = """
  function _encode({struct} memory r, uint p, bytes memory bs)
      internal pure returns (uint) {{
    uint offset = p;
    uint pointer = p;
    {counter}{encoders}
    return pointer - offset;
  }}"""

NESTED_ENCODER = """
  function _encode_nested({struct} memory r, uint p, bytes memory bs)
      internal pure returns (uint) {{
    uint offset = p;
    uint pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint size = _encode(r, 32, tmp);
    pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
    ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
    pointer += size;
    delete tmp;
    return pointer - offset;
  }}"""

FIELD_ESTIMATOR_REPEATED = """
    for(i = 0; i < r.{field}.length; i++) {{
      e += {szKey} + {szItem};
    }}"""

FIELD_ESTIMATOR_REPEATED_MAP = """
    for(i = 0; i < r._size_{field}; i++) {{
      e += {szKey} + {szItem};
    }}"""

FIELD_ESTIMATOR_NOT_REPEATED = """
    e += {szKey} + {szItem};"""

ESTIMATOR = """
  function _estimate({struct} memory {varname}) internal {mutability} returns (uint) {{
    uint e;{counter}{estimators}
    return e;
  }}"""

ENCODER_SECTION = """
  // Encoder section
{main_encoder}
  // inner encoder
{inner_encoder}
  // nested encoder
{nested_encoder}
  // estimator
{estimator}"""
