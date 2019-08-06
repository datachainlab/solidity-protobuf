import gen_util as util
import gen_decoder_constants as decoder_constants

def gen_main_decoder(msg, parent_struct_name):
  return (decoder_constants.MAIN_DECODER).format(
    visibility = util.gen_visibility(True),
    name = util.gen_internal_struct_name(msg, parent_struct_name)
  )

def gen_inner_field_decoder(field, parent_struct_name, first_pass, index):
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

def gen_inner_fields_decoder(msg, parent_struct_name, first_pass):
  transformed = [gen_inner_field_decoder(field, parent_struct_name, first_pass, index) for index, field in enumerate(msg.field)]
  return (''.join(transformed))


def gen_inner_array_allocator(f, parent_struct_name, is_repeated):
  if not is_repeated:
    return ""
  return (decoder_constants.INNER_ARRAY_ALLOCATOR).format(
    t = util.gen_global_type_from_field(f),
    field = f.name,
    i = f.number
  )

def gen_inner_map_size(f, nested_type):
  if not util.is_map_type(f, nested_type):
    return ""
  return (decoder_constants.INNER_MAP_SIZE).format(
    field = f.name,
    i = f.number
  )

def gen_inner_array_allocators(msg, parent_struct_name):
  return ''.join(map(lambda f: gen_inner_array_allocator(f, parent_struct_name, util.field_is_repeated(f)), msg.field))

def gen_inner_maps_size(msg, parent_struct_name):
  return ''.join(map(lambda f: gen_inner_map_size(f, msg.nested_type), msg.field))

def gen_inner_decoder(msg, parent_struct_name):
  allocators = gen_inner_array_allocators(msg, parent_struct_name) + "\n" + gen_inner_maps_size(msg, parent_struct_name)
  if allocators.strip():
    second_pass = decoder_constants.INNER_DECODER_SECOND_PASS.format(
      allocators = allocators,
      second_pass = gen_inner_fields_decoder(msg, parent_struct_name, False)
    )
  else:
    second_pass = ""
  return (decoder_constants.INNER_DECODER).format(
    struct = util.gen_internal_struct_name(msg, parent_struct_name),
    n = util.max_field_number(msg) + 1,
    first_pass = gen_inner_fields_decoder(msg, parent_struct_name, True),
    second_pass = second_pass
  )

def gen_field_reader(f, parent_struct_name, msg):
  suffix = ("[r.{field}.length - counters[{i}]]").format(field = f.name, i = f.number) if util.field_is_repeated(f) else ""
  return (decoder_constants.FIELD_READER).format(
    field = f.name,
    decoder = util.gen_decoder_name(f),
    decode_type = util.gen_global_type_decl_from_field(f),
    t = util.gen_internal_struct_name(msg, parent_struct_name),
    i = f.number,
    n = util.max_field_number(msg) + 1,
    suffix = suffix
  )


def gen_field_readers(msg, parent_struct_name):
  return ''.join(list(map(lambda f: gen_field_reader(f, parent_struct_name, msg), msg.field)))

def gen_struct_decoder(f, msg, parent_struct_name):
  return (decoder_constants.STRUCT_DECORDER).format(
    struct = util.gen_global_type_name_from_field(f),
    decode_type = util.gen_global_type_decl_from_field(f),
    name = util.gen_struct_decoder_name_from_field(f),
    lib = util.gen_struct_codec_lib_name_from_field(f)
  )

def gen_struct_decoders(msg, parent_struct_name):
  return ''.join(list(map(
    (lambda f: gen_struct_decoder(f, msg, parent_struct_name) if util.field_is_message(f) else ""), msg.field)))


def gen_decoder_section(msg, parent_struct_name):
  struct_decoders = gen_struct_decoders(msg, parent_struct_name)
  if struct_decoders.strip():
    struct_decoders = "\n  // struct decoder" + struct_decoders
  else:
    struct_decoders = ""
  return (decoder_constants.DECODER_SECTION).format(
    main_decoder = gen_main_decoder(msg, parent_struct_name),
    inner_decoder = gen_inner_decoder(msg, parent_struct_name),
    field_readers = gen_field_readers(msg, parent_struct_name),
    struct_decoders = struct_decoders
  )
