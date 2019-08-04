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
      p += ProtoBufParser._encode_key({key}, ProtoBufParser.WireType.{wiretype}, p, bs);
      p += {encoder}(r.{field}[i], p, bs);
    }}"""

INNER_FIELD_ENCODER_REPEATED_MAP = """
    for(i = 0; i < r._size_{field}; i++) {{
      p += ProtoBufParser._encode_key({key}, ProtoBufParser.WireType.{wiretype}, p, bs);
      p += {encoder}(r.{field}[i], p, bs);
    }}"""

INNER_FIELD_ENCODER_NOT_REPEATED = """
    p += ProtoBufParser._encode_key({key}, ProtoBufParser.WireType.{wiretype}, p, bs);
    p += {encoder}(r.{field}, p, bs);"""

INNER_ENCODER = """
  function _encode({struct} memory r, uint p, bytes memory bs)
      internal pure returns (uint) {{
    uint offset = p;
    {counter}
    {encoders}
    return p - offset;
  }}"""

NESTED_ENCODER = """
  function _encode_nested({struct} memory r, uint p, bytes memory bs)
      internal pure returns (uint) {{
    uint offset = p;
    p += ProtoBufParser._encode_varint(_estimate(r), p, bs);
    p += _encode(r, p, bs);
    return p - offset;
  }}"""

FIELD_ESTIMATOR_REPEATED = """
    for(i = 0; i < r.{field}.length; i++) {{
      e+= {szKey} + {szItem};
    }}"""

FIELD_ESTIMATOR_REPEATED_MAP = """
    for(i = 0; i < r._size_{field}; i++) {{
      e+= {szKey} + {szItem};
    }}"""

FIELD_ESTIMATOR_NOT_REPEATED = """
    e += {szKey} + {szItem};"""

ESTIMATOR = """
  function _estimate({struct} memory {varname}) internal {mutability} returns (uint) {{
    uint e;
    {counter}
    {estimators}
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
