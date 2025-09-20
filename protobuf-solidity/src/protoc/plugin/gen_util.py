import sys
import pprint
import wrapt
import gen_util_constants as util_constants
from google.protobuf.descriptor import Descriptor, EnumDescriptor, EnumValueDescriptor, FieldDescriptor, FileDescriptor
from typing import Tuple

pp = pprint.PrettyPrinter(indent=4, stream=sys.stderr)



Num2Type = {
  1: "bytes8",  # double -> 8-byte representation
  2: "bytes4",  # float -> 4-byte representation
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

SOL_RESERVED_KEYWORDS = set([
  # global variables
  "abi", "block", "gasleft",
  "msg", "now", "tx",
  "assert", "require", "revert",
  "blockhash", "keccak256", "sha256",
  "ripemd160", "ecrecover", "addmod",
  "mulmod", "this", "super", "selfdestruct",
  "type", "address", "bytes",

  # units
  "wei", "gwei", "ether",
  "seconds", "minutes", "hours",
  "days", "weeks"
])

INTERNAL_TYPE_CATEGORY_BUILTIN = 1
INTERNAL_TYPE_CATEGORY_ENUM = 2
INTERNAL_TYPE_CATEGORY_USERTYPE = 3

PB_LIB_NAME_PREFIX = ""
LIBRARY_LINKING_MODE = False
ENUM_AS_CONSTANT = False
ALLOW_RESERVED_KEYWORDS = False
SOLIDITY_VERSION = "0.8.10"
SOLIDITY_PRAGMAS = []
IGNORED_PROTOS = []

# utils
def is_map_type(f: FieldDescriptor) -> bool:
  return f.message_type and f.message_type.GetOptions().map_entry

def to_camel_case(name: str) -> str:
  if "_" in name:
    return name.replace("_", " ").title().replace(" ", "")
  return name[:1].upper() + name[1:]

def parse_urllike_parameter(s):
  ret = {} #hash
  if s:
    for e in s.split('&'):
      kv = e.split('=')
      if len(kv) == 1:
        ret[kv[0]] = True  # Boolean flag parameters
      else:
        ret[kv[0]] = kv[1]
  return ret

def field_is_message(f: FieldDescriptor) -> bool:
  return f.message_type and (f.message_type.file.package != "solidity")

def field_is_repeated(f: FieldDescriptor) -> bool:
  return f.label == FieldDescriptor.LABEL_REPEATED

def field_is_scalar_numeric(f: FieldDescriptor) -> bool:
  return gen_wire_type(f) in ['Varint', 'Fixed32', 'Fixed64']

def field_is_packed(f: FieldDescriptor) -> bool:
  opt = f.GetOptions()
  return opt.packed or field_is_scalar_numeric(f) and not opt.HasField("packed")

def field_has_dyn_size(f: FieldDescriptor) -> bool:
  # if string or bytes, dynamic
  if f.type == FieldDescriptor.TYPE_STRING or f.type == FieldDescriptor.TYPE_BYTES:
    return True
  elif f.type == FieldDescriptor.TYPE_MESSAGE:
    # if non struct, message should be translate struct, which may have dynamic size
    # otherwise solidity native type, which should not have dynamic size
    return field_sol_type(f) == None
  else:
    return False

def field_pb_type(f: FieldDescriptor) -> str:
  if f.type == FieldDescriptor.TYPE_MESSAGE:
    return "message"
  return Num2PbType.get(f.type, None)

def field_sol_type(f: FieldDescriptor) -> str:
  if f.type != FieldDescriptor.TYPE_MESSAGE:
    return None
  elif f.message_type.file.package == "solidity":
    return f.message_type.name
  else:
    return None

def prefix_lib(name: str) -> str:
  return PB_LIB_NAME_PREFIX + name

def gen_delegate_lib_name(msg: Descriptor) -> str:
  """Generate a library name as follows.

  PackageNameContainingTypeNameSelfTypeName
  """
  name = "".join(map(lambda word: word[:1].upper() + word[1:], msg.full_name.split(".")))
  return prefix_lib(name)

def gen_global_type_name_from_field(field: FieldDescriptor) -> str:
  ftid, type_category = gen_field_type_id(field)
  if type_category == INTERNAL_TYPE_CATEGORY_BUILTIN:
    return ftid
  elif type_category == INTERNAL_TYPE_CATEGORY_ENUM:
    global ENUM_AS_CONSTANT
    return "int64" if ENUM_AS_CONSTANT else prefix_lib(ftid)
  else:
    assert type_category == INTERNAL_TYPE_CATEGORY_USERTYPE
    return prefix_lib(ftid) + ".Data"

def is_complex_type(field: str) -> bool:
  return "string" == field or "bytes" == field or ".Data" in field or "[]" in field

def gen_global_type_decl_from_field(field: FieldDescriptor) -> str:
  tp = gen_global_type_name_from_field(field)
  if field_has_dyn_size(field):
    return tp + " memory"
  else:
    return tp

def gen_global_type_from_field(field: FieldDescriptor) -> str:
  t = gen_global_type_name_from_field(field)
  if t is None:
    pp.pprint(field)
    pp.pprint("will die ======================================= ")
  if field_is_repeated(field):
    return t + "[]"
  else:
    return t

def gen_internal_struct_name(_: Descriptor) -> str:
  return "Data"

def max_field_number(msg: Descriptor) -> int:
  num = 0
  for f in msg.fields:
    if num < f.number:
      num = f.number
  return num

def str_contains(s, token):
  try:
    return s.index(token) >= 0
  except Exception as e:
    return False

def gen_struct_name(msg: Descriptor) -> str:
  """Generates PackageNameContainingTypeNameSelfTypeName"""
  return "".join(map(lambda word: word[:1].upper() + word[1:], msg.full_name.split('.')))

def gen_struct_name_from_field(f: FieldDescriptor) -> str:
  assert f.message_type
  return gen_struct_name(f.message_type)

def gen_enum_name(e: EnumDescriptor) -> str:
  """Generates the following.

  - PackageNameContainingTypeName.EnumName if the enum is nested
  - EnumName if the enum is global
  """
  if e.containing_type:
    return gen_struct_name(e.containing_type) + '.' + e.name
  else:
    return gen_global_enum_name(e.file) + '.' + e.name

def gen_enum_name_from_field(f: FieldDescriptor) -> str:
  assert f.enum_type
  return gen_enum_name(f.enum_type)

def gen_field_type_id(field: FieldDescriptor) -> Tuple[str, int]:
  val = Num2Type.get(field.type, None)
  if val != None:
    if val == "enum":
      return (gen_enum_name_from_field(field), INTERNAL_TYPE_CATEGORY_ENUM)
    return (val, INTERNAL_TYPE_CATEGORY_BUILTIN)
  val = field_sol_type(field)
  if val != None:
    return (val, INTERNAL_TYPE_CATEGORY_BUILTIN)
  return (gen_struct_name_from_field(field), INTERNAL_TYPE_CATEGORY_USERTYPE)

def gen_fieldtype(field: FieldDescriptor) -> str:
  t = gen_global_type_name_from_field(field)
  assert t[0] != "."
  if field_is_repeated(field):
    return t + "[]"
  else:
    return t

def gen_enumvalue_entry(v: Tuple[int, EnumValueDescriptor]):
  if v[0] == 0:
    return "{name}".format(
      name = v[1].name,
    )
  else:
    return ",\n    {name}".format(
      name = v[1].name,
    )

def gen_enumencoder_entry(v: EnumValueDescriptor) -> str:
  return util_constants.ENUM_ENCODE_FUNCTION_INNER.format(
    name = v.name,
    value = v.number,
    enum_name = v.type.name
  )

def gen_enumdecoder_entry(v: EnumValueDescriptor) -> str:
  return util_constants.ENUM_DECODE_FUNCTION_INNER.format(
    name = v.name,
    value = v.number,
    enum_name = v.type.name
  )

def gen_enumvalues(e: EnumDescriptor) -> str:
  return ''.join(
    map(gen_enumvalue_entry, enumerate(e.values))
  )

def gen_enum_encoders(e: EnumDescriptor) -> str:
  return '\n'.join(
    map(gen_enumencoder_entry, e.values)
  )

def gen_enum_decoders(e: EnumDescriptor) -> str:
  return '\n'.join(
    map(gen_enumdecoder_entry, e.values)
  )

def gen_enumtype(e: EnumDescriptor) -> str:
  """Generate the following parts.

  enum Foo {
     ...
  }

  function encode_Foo(Foo x) internal pure returns (int32) {
     ...
  }

  function decode_Foo(int64 x) internal pure returns (Foo) {
     ...
  }
  """
  global ENUM_AS_CONSTANT
  if ENUM_AS_CONSTANT:
    return '\n'.join(
      map(lambda v: util_constants.ENUM_TYPE.format(
          type = e.name,
          name = v.name,
          value = v.number
        ),
      e.values)
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
    estimator = util_constants.ENUM_ESTIMATE_FUNCTION.format(
      enum_name = e.name
    )
    return definition + "\n" + encoder + "\n" + decoder + "\n" + estimator

def gen_struct_decoder_name_from_field(field: FieldDescriptor) -> str:
  ftid, _ = gen_field_type_id(field)
  return "_decode_" + ftid

def gen_struct_codec_lib_name_from_field(field: FieldDescriptor) -> str:
  ftid, type_category = gen_field_type_id(field)
  assert type_category == INTERNAL_TYPE_CATEGORY_USERTYPE
  return prefix_lib(ftid)

def gen_decoder_name(field: FieldDescriptor) -> str:
  val = Num2PbType.get(field.type, None)
  if val != None:
    return "ProtoBufRuntime._decode_" + val
  else:
    val = field_sol_type(field)
    if val != None:
      return "ProtoBufRuntime._decode_sol_" + val
    return "_decode_" + gen_struct_name_from_field(field)

def gen_encoder_name(field: FieldDescriptor) -> str:
  val = Num2PbType.get(field.type, None)
  if val != None:
    return "ProtoBufRuntime._encode_" + val
  else:
    val = field_sol_type(field)
    if val != None:
      return "ProtoBufRuntime._encode_sol_" + val
    return gen_struct_codec_lib_name_from_field(field) + "._encode_nested"


def gen_empty_checker_block(msg: Descriptor, field: FieldDescriptor) -> str:
  blk = EmptyCheckBlock(field)
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

def is_struct_type(field: FieldDescriptor) -> bool:
  val = Num2PbType.get(field.type, None)
  if val != None:
    return False
  else:
    return True

def gen_wire_type(field: FieldDescriptor) -> str:
  return Num2WireType.get(field.type, None)

def gen_soltype_estimate_len(sol_type: str) -> int:
  val = SolType2BodyLen.get(sol_type, 0)
  return val + 3

def gen_global_enum_name(file: FileDescriptor) -> str:
  """Generate the name of a library containing global enums as follows.

  FILE_NAME_GLOBAL_ENUMS
  """
  return file.name.replace(".", "_").replace("/", "_").upper() + "_" + "GLOBAL_ENUMS"

# Solidity reserved keywords that need mangling
SOLIDITY_RESERVED_KEYWORDS = {
  'address', 'bool', 'string', 'bytes', 'byte', 'int', 'int8', 'int16', 'int24',
  'int32', 'int40', 'int48', 'int56', 'int64', 'int72', 'int80', 'int88', 'int96',
  'int104', 'int112', 'int120', 'int128', 'int136', 'int144', 'int152', 'int160',
  'int168', 'int176', 'int184', 'int192', 'int200', 'int208', 'int216', 'int224',
  'int232', 'int240', 'int248', 'int256', 'uint', 'uint8', 'uint16', 'uint24',
  'uint32', 'uint40', 'uint48', 'uint56', 'uint64', 'uint72', 'uint80', 'uint88',
  'uint96', 'uint104', 'uint112', 'uint120', 'uint128', 'uint136', 'uint144',
  'uint152', 'uint160', 'uint168', 'uint176', 'uint184', 'uint192', 'uint200',
  'uint208', 'uint216', 'uint224', 'uint232', 'uint240', 'uint248', 'uint256',
  'bytes1', 'bytes2', 'bytes3', 'bytes4', 'bytes5', 'bytes6', 'bytes7', 'bytes8',
  'bytes9', 'bytes10', 'bytes11', 'bytes12', 'bytes13', 'bytes14', 'bytes15',
  'bytes16', 'bytes17', 'bytes18', 'bytes19', 'bytes20', 'bytes21', 'bytes22',
  'bytes23', 'bytes24', 'bytes25', 'bytes26', 'bytes27', 'bytes28', 'bytes29',
  'bytes30', 'bytes31', 'bytes32', 'fixed', 'ufixed', 'abstract', 'after',
  'alias', 'apply', 'auto', 'case', 'catch', 'copyof', 'default', 'define',
  'final', 'immutable', 'implements', 'in', 'inline', 'let', 'macro', 'match',
  'mutable', 'null', 'of', 'override', 'partial', 'promise', 'reference',
  'relocatable', 'sealed', 'sizeof', 'static', 'supports', 'switch', 'typedef',
  'typeof', 'var', 'assembly', 'break', 'continue', 'contract', 'do', 'else',
  'enum', 'event', 'for', 'function', 'if', 'import', 'library', 'mapping',
  'modifier', 'pragma', 'return', 'struct', 'using', 'while', 'constant',
  'anonymous', 'indexed', 'internal', 'external', 'private', 'public', 'pure',
  'view', 'payable', 'storage', 'memory', 'calldata', 'constructor', 'fallback',
  'receive', 'virtual', 'double', 'float', 'const'
}

def mangle_solidity_field_name(field_name: str) -> str:
  """Mangle field names that conflict with Solidity reserved keywords."""
  if field_name in SOLIDITY_RESERVED_KEYWORDS:
    return field_name + "_field"
  return field_name

def change_pb_libname_prefix(new_name: str):
  global PB_LIB_NAME_PREFIX
  PB_LIB_NAME_PREFIX = new_name

def is_lib_linking_mode() -> bool:
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

def set_solc_version(version: str):
  global SOLIDITY_VERSION
  SOLIDITY_VERSION = version

def set_allow_reserved_keywords(on: bool):
  global ALLOW_RESERVED_KEYWORDS
  ALLOW_RESERVED_KEYWORDS = on

def set_enum_as_constant(on: bool):
  global ENUM_AS_CONSTANT
  ENUM_AS_CONSTANT = on

def set_ignored_protos(opt: str):
  global IGNORED_PROTOS
  IGNORED_PROTOS = opt.split(',')

def ignores_proto(name: str) -> bool:
  global IGNORED_PROTOS
  return (name in IGNORED_PROTOS)

def gen_visibility(is_decoder) -> str:
  if not LIBRARY_LINKING_MODE:
    return "internal"
  return "public" #"internal" if is_decoder else ""

def simple_term(field: FieldDescriptor) -> str:
  return "r.{name}".format(name=mangle_solidity_field_name(field.name))

def string_term(field: FieldDescriptor) -> str:
  return "bytes(r.{name}).length".format(name=mangle_solidity_field_name(field.name))

def bytes_term(field: FieldDescriptor) -> str:
  return "r.{name}.length".format(name=mangle_solidity_field_name(field.name))

def message_term(field: FieldDescriptor) -> str:
  child = gen_struct_name_from_field(field)
  return "{child}._empty(r.{name})".format(child=child, name=mangle_solidity_field_name(field.name))

def enum_term(field: FieldDescriptor) -> str:
  return "uint(r.{name})".format(name=mangle_solidity_field_name(field.name))

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
  "float": {"cond": "!= 0", "f": simple_term},
  "double": {"cond": "!= 0", "f": simple_term},
  "enum": {"cond": "!= 0", "f": enum_term},
  "message": {"cond": "!= true", "f": message_term}
}

class EmptyCheckBlock:
  def __init__(self, field: FieldDescriptor):
    self.field = field
    self.val = Num2PbType.get(self.field.type, None)

  def begin(self):
    if field_is_repeated(self.field):
      return "if ({term} != 0) {{".format(term="r." + mangle_solidity_field_name(self.field.name) + ".length")
    elif self.val in default_values:
      dv = default_values[self.val]
      params = dict(
        term=dv['f'](self.field),
        op=dv['cond'],
      )
      return "if ({term} {op}) ".format(**params) + "{"
    elif is_struct_type(self.field):
      return ""
    else:
      raise Exception('Unsupported type: {} in field: {} from message: {}'.format(self.field.type, self.field.name, self.field.containing_type.name))

  def end(self):
    if is_struct_type(self.field) and not field_is_repeated(self.field):
      return ""
    else:
      return "}"

class MessageFieldWrapper(wrapt.ObjectProxy):
  @property
  def name(self):
    if self.__wrapped__.name in SOL_RESERVED_KEYWORDS:
      return self.__wrapped__.name.capitalize()
    return self.__wrapped__.name

class MessageFieldsWrapper(wrapt.ObjectProxy):
  def __init__(self, wrapped):
    super(MessageFieldsWrapper, self).__init__(wrapped)
    self._self_fields = None

  def __iter__(self):
    if self._self_fields is None:
       self._self_fields = [MessageFieldWrapper(f) for f in self.__wrapped__]

    for f in self._self_fields:
      yield f

class MessageWrapper(wrapt.ObjectProxy):
  def __init__(self, wrapped):
    super(MessageWrapper, self).__init__(wrapped)
    self._self_fields = MessageFieldsWrapper(wrapped.fields)

  @property
  def fields(self):
    return self._self_fields

# Circular dependency handling for buf/validate types
CIRCULAR_DEPENDENCY_MAP = {
  # FieldRules has circular references to MapRules and RepeatedRules
  "FieldRules": {
    "map": "MapRules",
    "repeated": "RepeatedRules"
  },
  # MapRules has circular references back to FieldRules
  "MapRules": {
    "keys": "FieldRules",
    "values": "FieldRules"
  },
  # RepeatedRules has circular reference back to FieldRules
  "RepeatedRules": {
    "items": "FieldRules"
  }
}

def is_circular_dependency(msg: Descriptor, field: FieldDescriptor) -> bool:
  """
  Detects if a message field creates a circular dependency.

  Args:
    msg: The containing message descriptor
    field: The field descriptor to check

  Returns:
    True if the field creates a circular dependency
  """
  msg_name = msg.name
  field_name = mangle_solidity_field_name(field.name)


  # Check if this message has known circular dependencies
  if msg_name in CIRCULAR_DEPENDENCY_MAP:
    circular_fields = CIRCULAR_DEPENDENCY_MAP[msg_name]
    if field_name in circular_fields:
      # Check if the field type matches the expected circular target
      if field.message_type:
        target_type = field.message_type.name
        expected_target = circular_fields[field_name]
        return target_type == expected_target

  return False

def should_use_bytes_for_field(msg: Descriptor, field: FieldDescriptor) -> bool:
  """
  Determines if a field should use bytes instead of its natural type
  to break circular dependencies.

  Args:
    msg: The containing message descriptor
    field: The field descriptor to check

  Returns:
    True if the field should use bytes instead of its natural type
  """
  return is_circular_dependency(msg, field)
