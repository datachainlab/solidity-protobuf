import gen_util as util

INNER_FIELD_DECODER_REGULAR = "p, bs, r, counters"
INNER_FIELD_DECODER_NIL = "p, bs, nil(), counters"

MAIN_DECODER = """
  function decode(bytes memory bs) {visibility} pure returns ({name} memory) {{
    (Data memory x,) = _decode(32, bs, bs.length);
    return x;
  }}

  function decode({name} storage self, bytes memory bs) {visibility} {{
    (Data memory x,) = _decode(32, bs, bs.length);
    store(x, self);
  }}"""

INNER_FIELD_DECODER = """
      {control}if(fieldId == {id}) {{
        p += _read_{field}({args});
      }}"""

INNER_ARRAY_ALLOCATOR = """
    r.{field} = new {t}(counters[{i}]);"""

INNER_MAP_SIZE = """
    r._size_{field} = counters[{i}];"""

INNER_DECODER = """
  function _decode(uint p, bytes memory bs, uint sz)
      internal pure returns ({struct} memory, uint) {{
    {struct} memory r;
    uint[{n}] memory counters;
    uint fieldId;
    ProtoBufParser.WireType wireType;
    uint bytesRead;
    uint offset = p;
    while(p < offset+sz) {{
      (fieldId, wireType, bytesRead) = ProtoBufParser._decode_key(p, bs);
      p += bytesRead;
      {first_pass}
    }}
    {second_pass}
    return (r, sz);
  }}
"""

INNER_DECODER_SECOND_PASS = """
    p = offset;
    {allocators}
    while(p < offset+sz) {{
      (fieldId, wireType, bytesRead) = ProtoBufParser._decode_key(p, bs);
      p += bytesRead;
      {second_pass}
    }}"""

FIELD_READER = """
  function _read_{field}(uint p, bytes memory bs, {t} memory r, uint[{n}] memory counters) internal pure returns (uint) {{
    ({decode_type} x, uint sz) = {decoder}(p, bs);
    if(isNil(r)) {{
      counters[{i}] += 1;
    }} else {{
      r.{field}{suffix} = x;
      if(counters[{i}] > 0) counters[{i}] -= 1;
    }}
    return sz;
  }}"""

STRUCT_DECORDER = """
  function {name}(uint p, bytes memory bs)
      internal pure returns ({struct} memory, uint) {{
    (uint sz, uint bytesRead) = ProtoBufParser._decode_varint(p, bs);
    p += bytesRead;
    ({decode_type} r,) = {lib}._decode(p, bs, sz);
    return (r, sz + bytesRead);
  }}"""

DECODER_SECTION = """
  // Decoder section
{main_decoder}
  // innter decoder
{inner_decoder}
  // field readers
{field_readers}
  // struct decoder
{struct_decoders}"""
