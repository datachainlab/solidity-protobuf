import re, sys
import pprint
import gen_util_constants as util_constants

pp = pprint.PrettyPrinter(indent=4, stream=sys.stderr)


Label2Value = {
  "LABEL_OPTIONAL": 1,
  "LABEL_REQUIRED": 2,
  "LABEL_REPEATED": 3,
}

Num2Type = {
  1: "double",
  2: "float",
  3: "int64",    # not zigzag (proto3 compiler does not seem to use it)
  4: "uint64",
  5: "int32",    # not zigzag (proto3 compiler does not seem to use it)
  6: "uint64",
  7: "uint32",
  8: "bool",
  9: "string",
  10: None, #"group",   # group (deprecated in proto3)
  11: None, #"message", # another messsage
  12: "bytes",   # bytes
  13: "uint32",
  14: "enum",
  15: "int32",
  16: "int64",
  17: "int32", # Uses ZigZag encoding.
  18: "int64", # Uses ZigZag encoding.
}

Num2PbType = {
  1: "double",
  2: "float",
  3: "int64",    # not zigzag (proto3 compiler does not seem to use it)
  4: "uint64",
  5: "int32",    # not zigzag (proto3 compiler does not seem to use it)
  6: "fixed64",
  7: "fixed32",
  8: "bool",
  9: "string",
  10: None, #"group",   # group (deprecated in proto3)
  11: None, #"message", # another messsage
  12: "bytes",   # bytes
  13: "uint32",
  14: "enum",
  15: "sfixed32",
  16: "sfixed64",
  17: "sint32", # Uses ZigZag encoding.
  18: "sint64", # Uses ZigZag encoding.
}

Num2WireType = {
  1: "Fixed64",
  2: "Fixed32",
  3: "Varint",
  4: "Varint",
  5: "Varint",
  6: "Fixed64",
  7: "Fixed32",
  8: "Varint",
  9: "LengthDelim",
  10: None,
  11: "LengthDelim",
  12: "LengthDelim",
  13: "Varint",
  14: "Varint",
  15: "Fixed32",
  16: "Fixed64",
  17: "Varint",
  18: "Varint",
}

SolType2BodyLen = {
  "address": 20,
  "uint"   : 32,
    "uint8" : 1,
  "uint16" : 2,
  "uint24" : 3,
  "uint32" : 4,
  "uint40" : 5,
  "uint48" : 6,
  "uint56" : 7,
  "uint64" : 8,
  "uint72" : 9,
  "uint80" : 10,
  "uint88" : 11,
  "uint96" : 12,
  "uint104" : 13,
  "uint112" : 14,
  "uint120" : 15,
  "uint128" : 16,
  "uint136" : 17,
  "uint144" : 18,
  "uint152" : 19,
  "uint160" : 20,
  "uint168" : 21,
  "uint176" : 22,
  "uint184" : 23,
  "uint192" : 24,
  "uint200" : 25,
  "uint208" : 26,
  "uint216" : 27,
  "uint224" : 28,
  "uint232" : 29,
  "uint240" : 30,
  "uint248" : 31,
  "uint256" : 32,
  "int"    : 32,
  "int8" : 1,
  "int16" : 2,
  "int24" : 3,
  "int32" : 4,
  "int40" : 5,
  "int48" : 6,
  "int56" : 7,
  "int64" : 8,
  "int72" : 9,
  "int80" : 10,
  "int88" : 11,
  "int96" : 12,
  "int104" : 13,
  "int112" : 14,
  "int120" : 15,
  "int128" : 16,
  "int136" : 17,
  "int144" : 18,
  "int152" : 19,
  "int160" : 20,
  "int168" : 21,
  "int176" : 22,
  "int184" : 23,
  "int192" : 24,
  "int200" : 25,
  "int208" : 26,
  "int216" : 27,
  "int224" : 28,
  "int232" : 29,
  "int240" : 30,
  "int248" : 31,
  "int256" : 32,
  "bytes1" : 1,
  "bytes2" : 2,
  "bytes3" : 3,
  "bytes4" : 4,
  "bytes5" : 5,
  "bytes6" : 6,
  "bytes7" : 7,
  "bytes8" : 8,
  "bytes9" : 9,
  "bytes10": 10,
  "bytes11": 11,
  "bytes12": 12,
  "bytes13": 13,
  "bytes14": 14,
  "bytes15": 15,
  "bytes16": 16,
  "bytes17": 17,
  "bytes18": 18,
  "bytes19": 19,
  "bytes20": 20,
  "bytes21": 21,
  "bytes22": 22,
  "bytes23": 23,
  "bytes24": 24,
  "bytes25": 25,
  "bytes26": 26,
  "bytes27": 27,
  "bytes28": 28,
  "bytes29": 29,
  "bytes30": 30,
  "bytes31": 31,
  "bytes32": 32,
}

INTERNAL_TYPE_CATEGORY_BUILTIN = 1
INTERNAL_TYPE_CATEGORY_ENUM = 2
INTERNAL_TYPE_CATEGORY_USERTYPE = 3

TYPE_MESSAGE = 11
PB_LIB_NAME_PREFIX = ""
PB_CURRENT_PACKAGE = ""
LIBRARY_LINKING_MODE = False
ENUM_AS_CONSTANT = False
SOLIDITY_VERSION = "0.6.8"
SOLIDITY_PRAGMAS = []

# utils
def is_map_type(f, nested_type):
  if f.type_name.endswith("MapFieldEntry") and field_is_repeated(f):
    return len(list(filter(lambda t: t.name == "MapFieldEntry" and t.options and t.options.map_entry ,nested_type))) > 0
  return False

def to_camel_case(name):
  if "_" in name:
    return name.replace("_", " ").title().replace(" ", "")
  return name[:1].upper() + name[1:]

def add_prefix(prefix, name, sep = ""):
  return ("" if (prefix is None) else (prefix + sep)) + name

def parse_urllike_parameter(s):
  ret = {} #hash
  if s:
    for e in s.split('&'):
      kv = e.split('=')
      ret[kv[0]] = kv[1]
  return ret


def camel2snake(name):
  s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
  return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

def field_is_message(f):
  return f.type == TYPE_MESSAGE and (not f.type_name.startswith(".solidity."))

def field_is_repeated(f):
  return f.label == Label2Value["LABEL_REPEATED"]

def field_has_dyn_size(f):
  # if string or bytes, dynamic
  if f.type == 9 or f.type == 12:
    return True
  elif f.type == TYPE_MESSAGE:
    # if non struct, message should be translate struct, which may have dynamic size
    # otherwise solidity native type, which should not have dynamic size
    return field_sol_type(f) == None
  else:
    return False

def field_pb_type(f):
  if f.type == TYPE_MESSAGE:
    return "message"
  return Num2PbType.get(f.type, None)

def field_sol_type(f):
  if f.type != TYPE_MESSAGE:
    return None
  elif f.type_name.startswith(".solidity."):
    return f.type_name.replace(".solidity.", "")
  else:
    return None

def prefix_lib_and_package(name):
  return PB_LIB_NAME_PREFIX + PB_CURRENT_PACKAGE + name

def prefix_lib(name):
  return PB_LIB_NAME_PREFIX + name

def gen_delegate_lib_name(msg, parent_struct_name):
  return prefix_lib_and_package(add_prefix(parent_struct_name, msg.name))

def gen_global_type_name_from_field(field):
  ftid, type_category = gen_field_type_id(field)
  if type_category == INTERNAL_TYPE_CATEGORY_BUILTIN:
    return ftid
  elif type_category == INTERNAL_TYPE_CATEGORY_ENUM:
    global ENUM_AS_CONSTANT
    return "int64" if ENUM_AS_CONSTANT else prefix_lib(ftid)
  elif type_category == INTERNAL_TYPE_CATEGORY_USERTYPE:
    return prefix_lib(ftid) + ".Data"

def is_complex_type(field):
  return "string" == field or "bytes" == field or ".Data" in field or "[]" in field

def gen_global_type_decl_from_field(field):
  tp = gen_global_type_name_from_field(field)
  if field_has_dyn_size(field):
    return tp + " memory"
  else:
    return tp

def gen_global_type_from_field(field):
  t = gen_global_type_name_from_field(field)
  if t is None:
    pp.pprint(field)
    pp.pprint("will die ======================================= ")
  if field_is_repeated(field):
    return t + "[]"
  else:
    return t

def gen_internal_struct_name(msg, parent_struct_name):
  return "Data"

def max_field_number(msg):
  num = 0
  for f in msg.field:
    if num < f.number:
      num = f.number
  return num

def str_contains(s, token):
  try:
    return s.index(token) >= 0
  except Exception as e:
    return False

def gen_struct_name_from_field(f):
  return "".join(map(lambda t: t[:1].upper() + t[1:], f.type_name[1:].split(".")))

def gen_enum_name_from_field(f):
  seps = f.type_name.split('.')
  return ('_'.join(seps[1:-1])) + "." + seps[-1]

def gen_field_type_id(field):
  val = Num2Type.get(field.type, None)
  if val != None:
    if val == "enum":
      return (gen_enum_name_from_field(field), INTERNAL_TYPE_CATEGORY_ENUM)
    return (val, INTERNAL_TYPE_CATEGORY_BUILTIN)
  val = field_sol_type(field)
  if val != None:
    return (val, INTERNAL_TYPE_CATEGORY_BUILTIN)
  return (gen_struct_name_from_field(field), INTERNAL_TYPE_CATEGORY_USERTYPE)

def gen_fieldtype(field, file):
  t = gen_global_type_name_from_field(field)
  if t[0] == ".":
    t = gen_global_enum_name(file) + t
  if field_is_repeated(field):
    return t + "[]"
  else:
    return t

def gen_enumvalue_entry(v):
  if v[0] == 0:
    return "{name}".format(
      name = v[1].name,
    )
  else:
    return ",\n    {name}".format(
      name = v[1].name,
    )

def gen_enumencoder_entry(v, name):
  return util_constants.ENUM_ENCODE_FUNCTION_INNER.format(
    name = v.name,
    value = v.number,
    enum_name = name
  )

def gen_enumdecoder_entry(v, name):
  return util_constants.ENUM_DECODE_FUNCTION_INNER.format(
    name = v.name,
    value = v.number,
    enum_name = name
  )

def gen_enumvalues(e):
  return ''.join(
    list(map(gen_enumvalue_entry, enumerate(e.value)))
  )

def gen_enum_encoders(e):
  return '\n'.join(
    list(map(lambda t: gen_enumencoder_entry(t, e.name), e.value))
  )

def gen_enum_decoders(e):
  return '\n'.join(
    list(map(lambda t: gen_enumdecoder_entry(t, e.name), e.value))
  )

def gen_enumtype(e):
  global ENUM_AS_CONSTANT
  if ENUM_AS_CONSTANT:
    return '\n'.join(
      list(map(lambda v: util_constants.ENUM_TYPE.format(
          type = e.name,
          name = v.name,
          value = v.number
        ),
      e.value))
    )
  else:
    definition = util_constants.ENUM_FUNCTION.format(
      enum_name = e.name,
      enum_values = gen_enumvalues(e)
    )
    encoder = util_constants.ENUM_ENCODE_FUNCTION.format(
      enum_name = e.name,
      enum_values = gen_enum_encoders(e)
    )
    decoder = util_constants.ENUM_DECODE_FUNCTION.format(
      enum_name = e.name,
      enum_values = gen_enum_decoders(e)
    )
    return definition + "\n" + encoder + "\n" + decoder

def gen_struct_decoder_name_from_field(field):
  ftid, _ = gen_field_type_id(field)
  return "_decode_" + ftid

def gen_struct_codec_lib_name_from_field(field):
  ftid, type_category = gen_field_type_id(field)
  if type_category != INTERNAL_TYPE_CATEGORY_USERTYPE:
    "___{} is not user type ({})___".format(field.name, ftid)
  return prefix_lib(ftid)

def gen_decoder_name(field):
  val = Num2PbType.get(field.type, None)
  if val != None:
    return "ProtoBufRuntime._decode_" + val
  else:
    val = field_sol_type(field)
    if val != None:
      return "ProtoBufRuntime._decode_sol_" + val
    return "_decode_" + "".join(map(lambda t: t[:1].upper() + t[1:], field.type_name.split(".")))

def gen_encoder_name(field):
  val = Num2PbType.get(field.type, None)
  if val != None:
    return "ProtoBufRuntime._encode_" + val
  else:
    val = field_sol_type(field)
    if val != None:
      return "ProtoBufRuntime._encode_sol_" + val
    return gen_struct_codec_lib_name_from_field(field) + "._encode_nested"


def gen_empty_checker_block(msg, field):
  blk = EmptyCheckBlock(msg, field)
  begin = blk.begin()
  if begin == '':
    return ''
  return """
  {block_begin}
    return false;
  {block_end}
""".format(
    block_begin=begin,
    block_end=blk.end()
  )

def is_struct_type(field):
  val = Num2PbType.get(field.type, None)
  if val != None:
    return False
  else:
    val = field_sol_type(field)
    if val != None:
      return False
    return True

def gen_wire_type(field):
  return Num2WireType.get(field.type, None)

def gen_soltype_estimate_len(sol_type):
  val = SolType2BodyLen.get(sol_type, 0)
  return val + 3

def gen_global_enum_name(msg):
  return msg.name.replace(".", "_").upper() + "_" + "GLOBAL_ENUMS"

def change_pb_libname_prefix(new_name):
  global PB_LIB_NAME_PREFIX
  PB_LIB_NAME_PREFIX = new_name

def change_package_name(new_name):
  global PB_CURRENT_PACKAGE
  if new_name:
    PB_CURRENT_PACKAGE = "".join(map(lambda t: t[:1].upper() + t[1:], new_name.split(".")))
  else:
    PB_CURRENT_PACKAGE = ""

def current_package_name():
  global PB_CURRENT_PACKAGE
  return PB_CURRENT_PACKAGE

def is_lib_linking_mode():
  global LIBRARY_LINKING_MODE
  return LIBRARY_LINKING_MODE

def set_library_linking_mode():
  global LIBRARY_LINKING_MODE
  LIBRARY_LINKING_MODE = True
  global SOLIDITY_PRAGMAS
  SOLIDITY_PRAGMAS = ["pragma experimental ABIEncoderV2"]

def set_internal_linking_mode():
  global LIBRARY_LINKING_MODE
  LIBRARY_LINKING_MODE = False
  global SOLIDITY_PRAGMAS
  SOLIDITY_PRAGMAS = []

def set_solc_version(version):
  global SOLIDITY_VERSION
  SOLIDITY_VERSION = version

def set_enum_as_constant(on):
  global ENUM_AS_CONSTANT
  ENUM_AS_CONSTANT = on

def gen_visibility(is_decoder):
  if not LIBRARY_LINKING_MODE:
    return "internal"
  return "public" #"internal" if is_decoder else ""

def simple_term(msg, field, name):
  return "r.{name}".format(name=name)

def string_term(msg, field, name):
  return "bytes(r.{name}).length".format(name=name)

def bytes_term(msg, field, name):
  return "r.{name}.length".format(name=name)

def message_term(msg, field, name):
  child = gen_struct_name_from_field(field)
  return "{child}._empty(r.{name})".format(child=child, name=name)

def enum_term(msg, field, name):
  return "uint(r.{name})".format(name=name)

default_values = {
  "bytes": {"cond": "!= 0", "f": bytes_term},
  "string": {"cond": "!= 0", "f": string_term},
  "bool": {"cond": "!= false", "f": simple_term},
  "int32": {"cond": "!= 0", "f": simple_term},
  "int64": {"cond": "!= 0", "f": simple_term},
  "uint32": {"cond": "!= 0", "f": simple_term},
  "uint64": {"cond": "!= 0", "f": simple_term},
  "sint32": {"cond": "!= 0", "f": simple_term},
  "sint64": {"cond": "!= 0", "f": simple_term},
  "fixed32": {"cond": "!= 0", "f": simple_term},
  "fixed64": {"cond": "!= 0", "f": simple_term},
  "sfixed32": {"cond": "!= 0", "f": simple_term},
  "sfixed64": {"cond": "!= 0", "f": simple_term},
  "enum": {"cond": "!= 0", "f": enum_term},
  "message": {"cond": "!= true", "f": message_term}
}

class EmptyCheckBlock:
  def __init__(self, msg, field):
    self.msg = msg
    self.field = field
    self.is_repeated = field_is_repeated(field)
    self.val = Num2PbType.get(self.field.type, None)

  def begin(self):
    if self.is_repeated:
      return "if ({term} != 0) {{".format(term="r." + self.field.name + ".length")
    elif self.val in default_values:
      dv = default_values[self.val]
      params = dict(
        term=dv['f'](self.msg, self.field, self.field.name),
        op=dv['cond'],
      )
      return "if ({term} {op}) ".format(**params) + "{"
    elif is_struct_type(self.field):
      return ""
    else:
      raise Exception('Unsupported type: {}', self.field.type)

  def end(self):
    if is_struct_type(self.field) and not self.is_repeated:
      return ""
    else:
      return "}"
