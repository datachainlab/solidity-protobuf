import gen_util as util
import gen_decoder_constants as decoder_constants
from google.protobuf.descriptor import Descriptor, FieldDescriptor

def gen_main_decoder(msg: Descriptor) -> str:
  return (decoder_constants.MAIN_DECODER).format(
    visibility = util.gen_visibility(True),
    name = util.gen_internal_struct_name(msg)
  )

"""
Generate decoder for a field. If it is a repeated field, a second pass is required,
and the first pass is to determine the number of elements.
"""
def gen_inner_field_decoder(field: FieldDescriptor, first_pass: bool, index: int) -> str:
  args = ""
  repeated = util.field_is_repeated(field)
  if repeated:
    if first_pass:
      args = decoder_constants.INNER_FIELD_DECODER_NIL
    else:
      args = decoder_constants.INNER_FIELD_DECODER_REGULAR
  else:
    if first_pass:
      args = decoder_constants.INNER_FIELD_DECODER_REGULAR
    else:
      args = decoder_constants.INNER_FIELD_DECODER_NIL
  return (decoder_constants.INNER_FIELD_DECODER).format(
    control = ("else " if index > 0 else ""),
    id = field.number,
    field = field.name,
    args = args
  )

def gen_inner_fields_decoder(msg: Descriptor, first_pass: bool) -> str:
  transformed = [gen_inner_field_decoder(field, first_pass, index) for index, field in enumerate(msg.fields)]
  return (''.join(transformed))


def gen_inner_array_allocator(f: FieldDescriptor, is_repeated: bool) -> str:
  """Generates the following.

  r.{field} = new {t}(counters[{i}]);
  """
  if not is_repeated:
    return ""
  return (decoder_constants.INNER_ARRAY_ALLOCATOR).format(
    t = util.gen_global_type_from_field(f),
    field = f.name,
    i = f.number
  )

def gen_inner_map_size(f: FieldDescriptor) -> str:
  if not util.is_map_type(f):
    return ""
  return (decoder_constants.INNER_MAP_SIZE).format(
    field = f.name,
    i = f.number
  )

def gen_inner_array_allocators(msg: Descriptor) -> str:
  return ''.join(map(lambda f: gen_inner_array_allocator(f, util.field_is_repeated(f)), msg.fields))

def gen_inner_maps_size(msg: Descriptor) -> str:
  return ''.join(map(lambda f: gen_inner_map_size(f), msg.fields))

def gen_inner_decoder(msg: Descriptor) -> str:
  """
    If there are not repeated fields, the second pass is not generated.
  """
  allocators = gen_inner_array_allocators(msg) + "\n" + gen_inner_maps_size(msg)
  if allocators.strip():
    second_pass = decoder_constants.INNER_DECODER_SECOND_PASS.format(
      allocators = allocators,
      second_pass = gen_inner_fields_decoder(msg, False)
    )
  else:
    second_pass = ""
  first_pass = gen_inner_fields_decoder(msg, True)
  return (decoder_constants.INNER_DECODER).format(
    struct = util.gen_internal_struct_name(msg),
    n = util.max_field_number(msg) + 1,
    first_pass = first_pass,
    else_statement = decoder_constants.INNER_DECODER_ELSE.format() if first_pass else "",
    second_pass = second_pass
  )

def gen_field_reader(f: FieldDescriptor, msg: Descriptor) -> str:
  suffix = ("[r.{field}.length - counters[{i}]]").format(field = f.name, i = f.number) if util.field_is_repeated(f) else ""
  if f.type == FieldDescriptor.TYPE_ENUM:
    type_name = util.gen_enum_name_from_field(f)
    library_name = "" if msg.name == type_name.split(".")[0] else (type_name.split(".")[0] + ".")
    assert library_name != "."
    decode_type = util.gen_global_type_decl_from_field(f)
    assert decode_type[0] != "."
    reader = (decoder_constants.ENUM_FIELD_READER).format(
      field = f.name,
      decoder = util.gen_decoder_name(f),
      decode_type = decode_type,
      t = util.gen_internal_struct_name(msg),
      i = f.number,
      n = util.max_field_number(msg) + 1,
      suffix = suffix,
      enum_name = type_name.split(".")[-1],
      library_name = library_name
    )
    if not suffix:
      return reader
    reader += (decoder_constants.PACKED_REPEATED_ENUM_FIELD_READER).format(
      field = f.name,
      decoder = util.gen_decoder_name(f),
      decode_type = decode_type,
      t = util.gen_internal_struct_name(msg),
      i = f.number,
      n = util.max_field_number(msg) + 1,
      enum_name = type_name.split(".")[-1],
      library_name = library_name
    )
    return reader
  reader = (decoder_constants.FIELD_READER).format(
    field = f.name,
    decoder = util.gen_decoder_name(f),
    decode_type = util.gen_global_type_decl_from_field(f),
    t = util.gen_internal_struct_name(msg),
    i = f.number,
    n = util.max_field_number(msg) + 1,
    suffix = suffix
  )
  if util.gen_wire_type(f) not in ['Varint', 'Fixed32', 'Fixed64'] or not suffix:
    return reader
  reader += (decoder_constants.PACKED_REPEATED_FIELD_READER).format(
    field = f.name,
    decoder = util.gen_decoder_name(f),
    decode_type = util.gen_global_type_decl_from_field(f),
    t = util.gen_internal_struct_name(msg),
    i = f.number,
    n = util.max_field_number(msg) + 1
  )
  return reader


def gen_field_readers(msg: Descriptor) -> str:
  return ''.join(map(lambda f: gen_field_reader(f, msg), msg.fields))

def gen_struct_decoder(f: FieldDescriptor) -> str:
  """Generates the following parts.

  function _decode_FieldTypeName(...) {
      ...
  }
  """
  assert f.message_type
  return (decoder_constants.STRUCT_DECORDER).format(
    struct = util.gen_global_type_name_from_field(f),
    decode_type = util.gen_global_type_decl_from_field(f),
    name = util.gen_struct_decoder_name_from_field(f),
    lib = util.gen_struct_codec_lib_name_from_field(f)
  )

def gen_struct_decoders(msg: Descriptor) -> str:
  decoders = list(map((lambda f: gen_struct_decoder(f) if util.field_is_message(f) else ""), msg.fields))
  return ''.join(sorted(set(decoders), key=decoders.index))


def gen_decoder_section(msg: Descriptor) -> str:
  struct_decoders = gen_struct_decoders(msg)
  if struct_decoders.strip():
    struct_decoders = "\n  // struct decoder" + struct_decoders
  else:
    struct_decoders = ""
  return (decoder_constants.DECODER_SECTION).format(
    main_decoder = gen_main_decoder(msg),
    inner_decoder = gen_inner_decoder(msg),
    field_readers = gen_field_readers(msg),
    struct_decoders = struct_decoders
  )
