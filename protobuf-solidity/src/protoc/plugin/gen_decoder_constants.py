import gen_util as util

INNER_FIELD_DECODER_REGULAR = "pointer, bs, r, counters"
INNER_FIELD_DECODER_NIL = "pointer, bs, nil(), counters"

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
        pointer += _read_{field}({args});
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
    ProtoBufRuntime.WireType wireType;
    uint bytesRead;
    uint offset = p;
    uint pointer = p;
    while(pointer < offset+sz) {{
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;{first_pass}
    }}{second_pass}
    return (r, sz);
  }}
"""

INNER_DECODER_SECOND_PASS = """
    pointer = offset;{allocators}
    while(pointer < offset+sz) {{
      (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
      pointer += bytesRead;{second_pass}
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
    uint pointer = p;
    (uint sz, uint bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
    pointer += bytesRead;
    ({decode_type} r,) = {lib}._decode(pointer, bs, sz);
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
