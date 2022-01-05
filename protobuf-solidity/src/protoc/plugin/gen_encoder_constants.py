MAIN_ENCODER = """
  /**
   * @dev The main encoder for memory
   * @param r The struct to be encoded
   * @return The encoded byte array
   */
  function encode({struct} memory r) {visibility} pure returns (bytes memory) {{
    bytes memory bs = new bytes(_estimate(r));
    uint256 sz = _encode(r, 32, bs);
    assembly {{
      mstore(bs, sz)
    }}
    return bs;
  }}"""

INNER_FIELD_ENCODER_UNPACKED_REPEATED = """
    {block_begin}
    for(i = 0; i < r.{field}.length; i++) {{
      pointer += ProtoBufRuntime._encode_key(
        {key},
        ProtoBufRuntime.WireType.{wiretype},
        pointer,
        bs)
      ;
      pointer += {encoder}(r.{field}[i], pointer, bs);
    }}
    {block_end}"""

INNER_FIELD_ENCODER_UNPACKED_REPEATED_ENUM = """
    {block_begin}
    int32 _enum_{field};
    for(i = 0; i < r.{field}.length; i++) {{
      pointer += ProtoBufRuntime._encode_key(
        {key},
        ProtoBufRuntime.WireType.{wiretype},
        pointer,
        bs
      );
      _enum_{field} = {library_name}encode_{enum_name}(r.{field}[i]);
      pointer += {encoder}(_enum_{field}, pointer, bs);
    }}
    {block_end}"""

INNER_FIELD_ENCODER_REPEATED_MAP = """
    {block_begin}
    for(i = 0; i < r._size_{field}; i++) {{
      pointer += ProtoBufRuntime._encode_key(
        {key},
        ProtoBufRuntime.WireType.{wiretype},
        pointer,
        bs
      );
      pointer += {encoder}(r.{field}[i], pointer, bs);
    }}
    {block_end}"""

INNER_FIELD_ENCODER_PACKED_REPEATED = """
    {block_begin}
    pointer += ProtoBufRuntime._encode_key(
      {key},
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_varint(
      {size},
      pointer,
      bs
    );
    for(i = 0; i < r.{field}.length; i++) {{
      pointer += {encoder}(r.{field}[i], pointer, bs);
    }}
    {block_end}"""

INNER_FIELD_ENCODER_PACKED_REPEATED_ENUM = """
    {block_begin}
    pointer += ProtoBufRuntime._encode_key(
      {key},
      ProtoBufRuntime.WireType.LengthDelim,
      pointer,
      bs
    );
    pointer += ProtoBufRuntime._encode_varint(
      {size},
      pointer,
      bs
    );
    for(i = 0; i < r.{field}.length; i++) {{
      int32 _enum_{field} = {library_name}encode_{enum_name}(r.{field}[i]);
      pointer += {encoder}(_enum_{field}, pointer, bs);
    }}
    {block_end}"""

INNER_FIELD_ENCODER_NOT_REPEATED = """
    {block_begin}
    pointer += ProtoBufRuntime._encode_key(
      {key},
      ProtoBufRuntime.WireType.{wiretype},
      pointer,
      bs
    );
    pointer += {encoder}(r.{field}, pointer, bs);
    {block_end}"""

INNER_FIELD_ENCODER_NOT_REPEATED_ENUM = """
    {block_begin}
    pointer += ProtoBufRuntime._encode_key(
      {key},
      ProtoBufRuntime.WireType.{wiretype},
      pointer,
      bs
    );
    int32 _enum_{field} = {library_name}encode_{enum_name}(r.{field});
    pointer += {encoder}(_enum_{field}, pointer, bs);
    {block_end}"""

INNER_ENCODER = """
  /**
   * @dev The encoder for internal usage
   * @param r The struct to be encoded
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The number of bytes encoded
   */
  function _encode({struct} memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {{
    uint256 offset = p;
    uint256 pointer = p;
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
  function _encode_nested({struct} memory r, uint256 p, bytes memory bs)
    internal
    pure
    returns (uint)
  {{
    /**
     * First encoded `r` into a temporary array, and encode the actual size used.
     * Then copy the temporary array into `bs`.
     */
    uint256 offset = p;
    uint256 pointer = p;
    bytes memory tmp = new bytes(_estimate(r));
    uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
    uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
    uint256 size = _encode(r, 32, tmp);
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
  function _estimate(
    {struct} memory {varname}
  ) internal {mutability} returns (uint) {{
    uint256 e;{counter}{estimators}
    return e;
  }}"""

EMPTY_CHECKER = """
  function _empty(
    {struct} memory r
  ) internal pure returns (bool) {{
    {checkers}
    return true;
  }}
"""

ENCODER_SECTION = """
  // Encoder section
{main_encoder}
  // inner encoder
{inner_encoder}
  // nested encoder
{nested_encoder}
  // estimator
{estimator}
  // empty checker
{empty_checker}"""
