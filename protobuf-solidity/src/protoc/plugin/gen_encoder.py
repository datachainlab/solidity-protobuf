import sys
import gen_util as util
import gen_encoder_constants as encoder_constants
def gen_main_encoder(msg, parent_struct_name):
  return (encoder_constants.MAIN_ENCODER).format(
    visibility = util.gen_visibility(False),
    struct = util.gen_internal_struct_name(msg, parent_struct_name),
  )

def has_repeated_field(fields):
  for f in fields:
    if util.field_is_repeated(f):
      return True
  return False

def gen_inner_field_encoder(f, nested_type):
  # sys.stderr.write(str(f))
  # sys.stderr.write(str(nested_type))
  if util.field_is_repeated(f):
    if util.is_map_type(f, nested_type):
      template = encoder_constants.INNER_FIELD_ENCODER_REPEATED_MAP
    else:
      template = encoder_constants.INNER_FIELD_ENCODER_REPEATED
  else:
    template = encoder_constants.INNER_FIELD_ENCODER_NOT_REPEATED
  return template.format(
    field = f.name,
    key = f.number,
    wiretype = util.gen_wire_type(f),
    encoder = util.gen_encoder_name(f)
  )

def gen_inner_field_encoders(msg, parent_struct_name):
  return ''.join(list(map((lambda f: gen_inner_field_encoder(f, msg.nested_type)), msg.field)))

def gen_inner_encoder(msg, parent_struct_name):
  return (encoder_constants.INNER_ENCODER).format(
    struct = util.gen_internal_struct_name(msg, parent_struct_name),
    counter = "uint i;" if has_repeated_field(msg.field) else "",
    encoders = gen_inner_field_encoders(msg, parent_struct_name)
  )

def gen_nested_encoder(msg, parent_struct_name):
  return (encoder_constants.NESTED_ENCODER).format(
    struct = util.gen_internal_struct_name(msg, parent_struct_name)
  )

"""
  Determine the estimated size given the field type
"""
def gen_field_scalar_size(f):
  wt = util.gen_wire_type(f)
  vt = util.field_pb_type(f)
  fname = f.name + ("[i]" if util.field_is_repeated(f) else "")
  if wt == "Varint":
    if vt == "bool":
      return "1"
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

def gen_field_estimator(f, nested_type):
  if util.field_is_repeated(f):
    if util.is_map_type(f, nested_type):
      template = encoder_constants.FIELD_ESTIMATOR_REPEATED_MAP
    else:
      template = encoder_constants.FIELD_ESTIMATOR_REPEATED
  else:
    template = encoder_constants.FIELD_ESTIMATOR_NOT_REPEATED
  return template.format(
    field = f.name,
    szKey = (1 if f.number < 16 else 2),
    szItem = gen_field_scalar_size(f)
  )

def gen_field_estimators(msg, parent_struct_name):
  return ''.join(list(map((lambda f: gen_field_estimator(f, msg.nested_type)), msg.field)))

def gen_estimator(msg, parent_struct_name):
  est = gen_field_estimators(msg, parent_struct_name)
  not_pure = util.str_contains(est, "r.")
  return (encoder_constants.ESTIMATOR).format(
    struct = util.gen_internal_struct_name(msg, parent_struct_name),
    varname = "r" if not_pure else "/* r */",
    param = "\n   * @param r The struct to be encoded" if not_pure else "",
    mutability = "pure",
    counter = "uint i;" if has_repeated_field(msg.field) else "",
    estimators = est
  )

def gen_encoder_section(msg, parent_struct_name):
  return (encoder_constants.ENCODER_SECTION).format(
    main_encoder = gen_main_encoder(msg, parent_struct_name),
    inner_encoder = gen_inner_encoder(msg, parent_struct_name),
    nested_encoder = gen_nested_encoder(msg, parent_struct_name),
    estimator = gen_estimator(msg, parent_struct_name)
  )
