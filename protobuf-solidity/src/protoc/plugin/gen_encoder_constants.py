MAIN_ENCODER = """
  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
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
  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode({struct} memory r, uint p, bytes memory bs)
      internal pure returns (uint) {{
    uint offset = p;
    uint pointer = p;
    {counter}{encoders}
    return pointer - offset;
  }}"""

NESTED_ENCODER = """
  /**
   * @dev The encoder for inner struct
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode_nested({struct} memory r, uint p, bytes memory bs)
      internal pure returns (uint) {{
    /**
     * First encoded `r` into a temporary array, and encode the actual size used. 
     * Then copy the temporary array into `bs`. 
     */    
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
  /**
   * @dev The estimator for a struct{param}
   * @return The number of bytes encoded in estimation
   */
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
