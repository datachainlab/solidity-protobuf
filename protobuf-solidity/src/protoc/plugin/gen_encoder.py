import gen_util as util
import gen_encoder_constants as encoder_constants
from google.protobuf.descriptor import Descriptor, FieldDescriptor
from typing import List

def gen_main_encoder(msg: Descriptor) -> str:
  return (encoder_constants.MAIN_ENCODER).format(
    visibility = util.gen_visibility(False),
    struct = util.gen_internal_struct_name(msg),
  )

def has_repeated_field(fields: List[FieldDescriptor]) -> bool:
  for f in fields:
    if util.field_is_repeated(f):
      return True
  return False

def gen_inner_field_encoder(f: FieldDescriptor, msg: Descriptor) -> str:
  """Generates a code snippet that encodes a field (a part of _encode)"""
  if util.field_is_repeated(f):
    if util.is_map_type(f):
      template = encoder_constants.INNER_FIELD_ENCODER_REPEATED_MAP
    elif f.type == FieldDescriptor.TYPE_ENUM:
      template = encoder_constants.INNER_FIELD_ENCODER_REPEATED_ENUM
    else:
      template = encoder_constants.INNER_FIELD_ENCODER_REPEATED
  elif f.type == FieldDescriptor.TYPE_ENUM:
    template = encoder_constants.INNER_FIELD_ENCODER_NOT_REPEATED_ENUM
  else:
    template = encoder_constants.INNER_FIELD_ENCODER_NOT_REPEATED
  type_name = ""
  library_name = ""
  if f.type == FieldDescriptor.TYPE_ENUM:
    type_name = util.gen_enum_name_from_field(f)
    library_name = "" if msg.name == type_name.split(".")[0] else (type_name.split(".")[0] + ".")
    assert library_name != "."
  ecblk = util.EmptyCheckBlock(f)
  return template.format(
    block_begin=ecblk.begin(),
    field = f.name,
    key = f.number,
    wiretype = util.gen_wire_type(f),
    encoder = util.gen_encoder_name(f),
    enum_name = type_name.split(".")[-1],
    library_name = library_name,
    block_end=ecblk.end(),
  )

def gen_inner_field_encoders(msg: Descriptor) -> str:
  return ''.join(map((lambda f: gen_inner_field_encoder(f, msg)), msg.fields))

def gen_inner_encoder(msg: Descriptor) -> str:
  """Generates the following part.

  function _encode(Data memory r, uint256 p, bytes memory bs) {
      ...
  }
  """
  return (encoder_constants.INNER_ENCODER).format(
    struct = util.gen_internal_struct_name(msg),
    counter = "uint256 i;" if has_repeated_field(msg.fields) else "",
    encoders = gen_inner_field_encoders(msg)
  )

def gen_nested_encoder(msg: Descriptor) -> str:
  return (encoder_constants.NESTED_ENCODER).format(
    struct = util.gen_internal_struct_name(msg)
  )

"""
  Determine the estimated size given the field type
"""
def gen_field_scalar_size(f: FieldDescriptor, msg: Descriptor) -> str:
  wt = util.gen_wire_type(f)
  vt = util.field_pb_type(f)
  fname = f.name + ("[i]" if util.field_is_repeated(f) else "")
  if wt == "Varint":
    if vt == "bool":
      return "1"
    if vt == "enum":
      type_name = util.gen_enum_name_from_field(f)
      library_name = "" if msg.name == type_name.split(".")[0] else (type_name.split(".")[0] + ".")
      assert library_name != "."
      return ("ProtoBufRuntime._sz_{valtype}({library_name}encode_{enum_name}(r.{field}))").format(
        valtype = vt,
        field = fname,
        enum_name = type_name.split(".")[-1],
        library_name = library_name
      )
    else:
      return ("ProtoBufRuntime._sz_{valtype}(r.{field})").format(
        valtype = vt,
        field = fname,
      )
  elif wt == "Fixed64":
    return "8"
  elif wt == "Fixed32":
    return "4"
  elif wt == "LengthDelim":
    if vt == "bytes":
      return ("ProtoBufRuntime._sz_lendelim(r.{field}.length)").format(
        field = fname
      )
    elif vt == "string":
      return ("ProtoBufRuntime._sz_lendelim(bytes(r.{field}).length)").format(
        field = fname
      )
    elif vt == "message":
      st = util.field_sol_type(f)
      if st is None:
        return ("ProtoBufRuntime._sz_lendelim({lib}._estimate(r.{field}))").format(
          lib = util.gen_struct_codec_lib_name_from_field(f),
          field = fname,
        )
      else:
        return "{}".format(util.gen_soltype_estimate_len(st))
    else:
      return ("__does not support pb type {t}__").format(t = vt)
  else:
    return ("__does not support wire type {t}__").format(t = wt)

def gen_field_estimator(f: FieldDescriptor, msg: Descriptor) -> str:
  if util.field_is_repeated(f):
    if util.is_map_type(f):
      template = encoder_constants.FIELD_ESTIMATOR_REPEATED_MAP
    elif util.field_is_packed(f):
      template = encoder_constants.FIELD_ESTIMATOR_PACKED_REPEATED
    else:
      template = encoder_constants.FIELD_ESTIMATOR_UNPACKED_REPEATED
  else:
    template = encoder_constants.FIELD_ESTIMATOR_NOT_REPEATED
  return template.format(
    field = f.name,
    szKey = (1 if f.number < 16 else 2),
    szItem = gen_field_scalar_size(f, msg)
  )

def gen_field_estimators(msg: Descriptor) -> str:
  return ''.join(map((lambda f: gen_field_estimator(f, msg)), msg.fields))

def gen_estimator(msg: Descriptor) -> str:
  est = gen_field_estimators(msg)
  not_pure = util.str_contains(est, "r.")
  return (encoder_constants.ESTIMATOR).format(
    struct = util.gen_internal_struct_name(msg),
    varname = "r" if not_pure else "/* r */",
    param = "\n   * @param r The struct to be encoded" if not_pure else "",
    mutability = "pure",
    counter = "uint256 i;" if has_repeated_field(msg.fields) else "",
    estimators = est
  )

def gen_empty_field_checkers(msg: Descriptor) -> str:
  return ''.join(map((lambda f: util.gen_empty_checker_block(msg, f)), msg.fields))

def gen_empty_checker(msg: Descriptor) -> str:
  return (encoder_constants.EMPTY_CHECKER).format(
    struct = util.gen_internal_struct_name(msg),
    checkers = gen_empty_field_checkers(msg)
  )

def gen_encoder_section(msg: Descriptor) -> str:
  return (encoder_constants.ENCODER_SECTION).format(
    main_encoder = gen_main_encoder(msg),
    inner_encoder = gen_inner_encoder(msg),
    nested_encoder = gen_nested_encoder(msg),
    estimator = gen_estimator(msg),
    empty_checker = gen_empty_checker(msg)
  )
