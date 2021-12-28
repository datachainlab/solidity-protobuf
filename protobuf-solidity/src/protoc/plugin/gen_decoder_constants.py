import gen_util as util

MAIN_DECODER = """
  /**
   * @dev The main decoder for memory
   * @param bs The bytes array to be decoded
   * @return The decoded struct
   */
  function decode(bytes memory bs) {visibility} pure returns ({name} memory) {{
    (Data memory x, ) = _decode(32, bs, bs.length);
    return x;
  }}

  /**
   * @dev The main decoder for storage
   * @param self The in-storage struct
   * @param bs The bytes array to be decoded
   */
  function decode({name} storage self, bytes memory bs) {visibility} {{
    (Data memory x, ) = _decode(32, bs, bs.length);
    store(x, self);
  }}"""

INNER_FIELD_DECODER = """
      if (fieldId == {id}) {{
        pointer += _read_{field}(pointer, bs, r);
      }} else"""

INNER_REPEATED_SCALAR_NUMERIC_FIELD_DECODER_FIRST_PASS = """
      if (fieldId == {id}) {{
        if (wireType == ProtoBufRuntime.WireType.LengthDelim) {{
          pointer += _read_packed_repeated_{field}(pointer, bs, r);
        }} else {{
          pointer += _read_unpacked_repeated_{field}(pointer, bs, nil(), counters);
        }}
      }} else"""

INNER_REPEATED_SCALAR_NUMERIC_FIELD_DECODER_SECOND_PASS = """
      if (fieldId == {id} && wireType != ProtoBufRuntime.WireType.LengthDelim) {{
        pointer += _read_unpacked_repeated_{field}(pointer, bs, r, counters);
      }} else"""

INNER_REPEATED_NON_SCALAR_NUMERIC_FIELD_DECODER_FIRST_PASS = """
      if (fieldId == {id}) {{
        pointer += _read_unpacked_repeated_{field}(pointer, bs, nil(), counters);
      }} else"""

INNER_REPEATED_NON_SCALAR_NUMERIC_FIELD_DECODER_SECOND_PASS = """
      if (fieldId == {id}) {{
        pointer += _read_unpacked_repeated_{field}(pointer, bs, r, counters);
      }} else"""

INNER_ARRAY_ALLOCATOR = """
    if (counters[{i}] > 0) {{
      require(r.{field}.length == 0);
      r.{field} = new {t}(counters[{i}]);
    }}"""

INNER_MAP_SIZE = """
    r._size_{field} = counters[{i}];"""

INNER_COUNTERS = """
    uint[{n}] memory counters;"""

INNER_DECODER = """
  /**
   * @dev The decoder for internal usage
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param sz The number of bytes expected
   * @return The decoded struct
   * @return The number of bytes decoded
   */
  function _decode(uint256 p, bytes memory bs, uint256 sz)
    internal
    pure
    returns ({struct} memory, uint)
  {{
    {struct} memory r;{counters}
    uint256 fieldId;
    ProtoBufRuntime.WireType wireType;
    uint256 bytesRead;
    uint256 offset = p;
    uint256 pointer = p;
    while (pointer < offset + sz) {{
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;{first_pass}{else_statement}
    }}{second_pass}
    return (r, sz);
  }}
"""

INNER_DECODER_ELSE = """
      {{
        pointer += ProtoBufRuntime._skip_field(wireType, pointer, bs);
      }}
"""
INNER_DECODER_SECOND_PASS = """
    pointer = offset;{allocators}
    while (pointer < offset + sz) {{
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;{second_pass}
      {{
        pointer += ProtoBufRuntime._skip_field(wireType, pointer, bs);
      }}
    }}"""

FIELD_READER = """
  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_{field}(
    uint256 p,
    bytes memory bs,
    {t} memory r
  ) internal pure returns (uint) {{
    ({decode_type} x, uint256 sz) = {decoder}(p, bs);
    r.{field} = x;
    return sz;
  }}
"""

UNPACKED_REPEATED_FIELD_READER = """
  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_unpacked_repeated_{field}(
    uint256 p,
    bytes memory bs,
    {t} memory r,
    uint[{n}] memory counters
  ) internal pure returns (uint) {{
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    ({decode_type} x, uint256 sz) = {decoder}(p, bs);
    if (isNil(r)) {{
      counters[{i}] += 1;
    }} else {{
      r.{field}[r.{field}.length - counters[{i}]] = x;
      counters[{i}] -= 1;
    }}
    return sz;
  }}
"""

PACKED_REPEATED_FIXED32_FIELD_READER = """
  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_packed_repeated_{field}(
    uint256 p,
    bytes memory bs,
    {t} memory r
  ) internal pure returns (uint) {{
    (uint256 len, uint256 size) = ProtoBufRuntime._decode_varint(p, bs);
    p += size;
    uint256 count = len / 4;
    r.{field} = new {decode_type}[](count);
    for (uint256 i = 0; i < count; i++) {{
      ({decode_type} x, uint256 sz) = {decoder}(p, bs);
      p += sz;
      r.{field}[i] = x;
    }}
    return size + len;
  }}
"""

PACKED_REPEATED_FIXED64_FIELD_READER = """
  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_packed_repeated_{field}(
    uint256 p,
    bytes memory bs,
    {t} memory r
  ) internal pure returns (uint) {{
    (uint256 len, uint256 size) = ProtoBufRuntime._decode_varint(p, bs);
    p += size;
    uint256 count = len / 8;
    r.{field} = new {decode_type}[](count);
    for (uint256 i = 0; i < count; i++) {{
      ({decode_type} x, uint256 sz) = {decoder}(p, bs);
      p += sz;
      r.{field}[i] = x;
    }}
    return size + len;
  }}
"""

PACKED_REPEATED_VARINT_FIELD_READER = """
  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_packed_repeated_{field}(
    uint256 p,
    bytes memory bs,
    {t} memory r
  ) internal pure returns (uint) {{
    (uint256 len, uint256 size) = ProtoBufRuntime._decode_varint(p, bs);
    p += size;
    uint256 count = ProtoBufRuntime._count_packed_repeated_varint(p, len, bs);
    r.{field} = new {decode_type}[](count);
    for (uint256 i = 0; i < count; i++) {{
      ({decode_type} x, uint256 sz) = {decoder}(p, bs);
      p += sz;
      r.{field}[i] = x;
    }}
    return size + len;
  }}
"""

ENUM_FIELD_READER = """
  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_{field}(
    uint256 p,
    bytes memory bs,
    {t} memory r
  ) internal pure returns (uint) {{
    (int64 tmp, uint256 sz) = {decoder}(p, bs);
    {decode_type} x = {library_name}decode_{enum_name}(tmp);
    r.{field} = x;
    return sz;
  }}
"""

UNPACKED_REPEATED_ENUM_FIELD_READER = """
  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @param counters The counters for repeated fields
   * @return The number of bytes decoded
   */
  function _read_unpacked_repeated_{field}(
    uint256 p,
    bytes memory bs,
    {t} memory r,
    uint[{n}] memory counters
  ) internal pure returns (uint) {{
    /**
     * if `r` is NULL, then only counting the number of fields.
     */
    (int64 tmp, uint256 sz) = {decoder}(p, bs);
    {decode_type} x = {library_name}decode_{enum_name}(tmp);
    if (isNil(r)) {{
      counters[{i}] += 1;
    }} else {{
      r.{field}[r.{field}.length - counters[{i}]] = x;
      counters[{i}] -= 1;
    }}
    return sz;
  }}
"""

PACKED_REPEATED_ENUM_FIELD_READER = """
  /**
   * @dev The decoder for reading a field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @param r The in-memory struct
   * @return The number of bytes decoded
   */
  function _read_packed_repeated_{field}(
    uint256 p,
    bytes memory bs,
    {t} memory r
  ) internal pure returns (uint) {{
    (uint256 len, uint256 size) = ProtoBufRuntime._decode_varint(p, bs);
    p += size;
    uint256 count = ProtoBufRuntime._count_packed_repeated_varint(p, len, bs);
    r.{field} = new {decode_type}[](count);
    for (uint256 i = 0; i < count; i++) {{
      (int64 tmp, uint256 sz) = {decoder}(p, bs);
      {decode_type} x = {library_name}decode_{enum_name}(tmp);
      p += sz;
      r.{field}[i] = x;
    }}
    return size + len;
  }}
"""

STRUCT_DECORDER = """
  /**
   * @dev The decoder for reading a inner struct field
   * @param p The offset of bytes array to start decode
   * @param bs The bytes array to be decoded
   * @return The decoded inner-struct
   * @return The number of bytes used to decode
   */
  function {name}(uint256 p, bytes memory bs)
    internal
    pure
    returns ({struct} memory, uint)
  {{
    uint256 pointer = p;
    (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    ({decode_type} r, ) = {lib}._decode(pointer, bs, sz);
    return (r, sz + bytesRead);
  }}
"""

DECODER_SECTION = """
  // Decoder section
{main_decoder}
  // inner decoder
{inner_decoder}
  // field readers
{field_readers}{struct_decoders}"""
