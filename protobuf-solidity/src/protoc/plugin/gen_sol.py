#!/usr/bin/env python

import os, sys

import pprint
pp = pprint.PrettyPrinter(indent=4, stream=sys.stderr)

from google.protobuf.compiler import plugin_pb2 as plugin
from google.protobuf.descriptor_pb2 import DescriptorProto, EnumDescriptorProto

from gen_decoder import gen_decoder_section
from gen_encoder import gen_encoder_section
import gen_util as util
import gen_sol_constants as sol_constants
import sol_dirpath_pb2


def gen_fields(msg, file):
  return '\n'.join(list(map((lambda f: ("    {type} {name};").format(type = util.gen_fieldtype(f, file), name = f.name)), msg.field)))


def gen_map_fields_decl_for_field(f, nested_type):
  return (sol_constants.MAP_FIELD_DEFINITION).format(
    name = f.name,
    key_type = util.gen_global_type_name_from_field(nested_type.field[0]),
    container_type = util.gen_global_type_name_from_field(f)
  )

def gen_nested_struct_name(nested_type, parent_msg, parent_struct_name):
  flagments = [util.current_package_name(), parent_struct_name, parent_msg.name, nested_type.name] if parent_struct_name else [util.current_package_name(), parent_msg.name, nested_type.name]
  pb_nested_struct_name = "".join(flagments)
  return pb_nested_struct_name

def gen_map_fields_helper(nested_type, parent_msg, parent_struct_name):
  if nested_type.options and nested_type.options.map_entry:
    pb_nested_struct_name = gen_nested_struct_name(nested_type, parent_msg, parent_struct_name)
    map_fields = list(filter(
      lambda f: util.gen_struct_name_from_field(f) == pb_nested_struct_name,
      parent_msg.field))
    return '\n'.join(list(map(lambda f: gen_map_fields_decl_for_field(f, nested_type), map_fields)))
  else:
    return ''

def gen_map_fields(msg, parent_struct_name):
  return '\n'.join(list(map((lambda nt: gen_map_fields_helper(nt, msg, parent_struct_name)), msg.nested_type)))

# below gen_* codes for generating external library
def gen_struct_definition(msg, parent_struct_name, file):
  map_fields = gen_map_fields(msg, parent_struct_name)
  if map_fields.strip():
    map_fields = "\n    //non serialized fields" + map_fields
  else:
    map_fields = ""
  fields = gen_fields(msg, file)
  if (fields or map_fields):
    return (sol_constants.STRUCT_DEFINITION).format(
      fields = gen_fields(msg, file),
      map_fields = map_fields
    )
  else:
    return (sol_constants.STRUCT_DEFINITION).format(
      fields = "    bool x;",
      map_fields = map_fields
    )

def gen_enums(msg):
  return '\n'.join(list(map(util.gen_enumtype, msg.enum_type)))

# below gen_* codes for generating internal library
def gen_enum_definition(msg, parent_struct_name):
  enums = gen_enums(msg)
  if enums.strip():
    return (sol_constants.ENUMS_DEFINITION).format(
      enums = gen_enums(msg)
    )
  else:
    return ""

# below gen_* codes for generating internal library
def gen_utility_functions(msg, parent_struct_name):
  return (sol_constants.UTILITY_FUNCTION).format(
    name = util.gen_internal_struct_name(msg, parent_struct_name)
  )

def gen_map_insert_on_store(f, parent_msg, parent_struct_name):
  for nt in parent_msg.nested_type:
    if nt.options and nt.options.map_entry:
      pb_nested_struct_name = gen_nested_struct_name(nt, parent_msg, parent_struct_name)
      if util.gen_struct_name_from_field(f) == pb_nested_struct_name:
        return ('output._size_{name} = input._size_{name};\n').format(
          name = f.name,
          i = f.number
        )
  return ''

def gen_store_code_for_field(f, msg, parent_struct_name):
  tmpl = ""
  if util.field_is_message(f) and util.field_is_repeated(f):
    tmpl = sol_constants.STORE_REPEATED
  elif util.field_is_message(f):
    tmpl = sol_constants.STORE_MESSAGE
  else:
    return (sol_constants.STORE_OTHER).format(
      field = f.name
    )

  libname = util.gen_struct_codec_lib_name_from_field(f)

  return tmpl.format(
    i = f.number,
    field = f.name,
    lib = libname,
    map_insert_code = gen_map_insert_on_store(f, msg, parent_struct_name)
  )

def gen_store_codes(msg, parent_struct_name):
  return ''.join(list(map((lambda f: gen_store_code_for_field(f, msg, parent_struct_name)), msg.field)))

def gen_store_function(msg, parent_struct_name):
  return (sol_constants.STORE_FUNCTION).format(
    name = util.gen_internal_struct_name(msg, parent_struct_name),
    store_codes = gen_store_codes(msg, parent_struct_name)
  )

def gen_value_copy_code(value_field, dst_flagment):
  if util.field_is_message(value_field):
    return ("{struct_name}.store(value, {dst}.value);").format(
      struct_name = util.gen_struct_codec_lib_name_from_field(value_field),
      dst = dst_flagment
    )
  else:
    return ("{dst}.value = value;").format(dst = dst_flagment)

def gen_map_helper_codes_for_field(f, nested_type):
  kf = nested_type.field[0]
  vf = nested_type.field[1]
  key_type = util.gen_global_type_name_from_field(kf)
  value_type = util.gen_global_type_name_from_field(vf)
  field_type = util.gen_global_type_name_from_field(f)
  if util.is_complex_type(value_type):
    value_storage_type = "memory"
  else:
    value_storage_type = ""
  return (sol_constants.MAP_HELPER_CODE).format(
    name = util.to_camel_case(f.name),
    val_name = "self.{0}".format(f.name),
    map_name = "self._size_{0}".format(f.name),
    key_type = key_type,
    value_type = value_type,
    field_type = field_type,
    value_storage_type = value_storage_type,
    key_storage_type = "memory" if util.is_complex_type(key_type) else "",
    container_type = util.gen_global_type_name_from_field(f)
  )

def gen_array_helper_codes_for_field(f):
  field_type = util.gen_global_type_name_from_field(f)
  return (sol_constants.ARRAY_HELPER_CODE).format(
    name = util.to_camel_case(f.name),
    val_name = "self.{0}".format(f.name),
    field_type = field_type,
    field_storage_type = "memory" if util.is_complex_type(field_type) else ""
  )

def gen_map_helper(nested_type, parent_msg, parent_struct_name, all_map_fields):
  if nested_type.options and nested_type.options.map_entry:
    pb_nested_struct_name = gen_nested_struct_name(nested_type, parent_msg, parent_struct_name)
    map_fields = list(filter(
      lambda f: util.gen_struct_name_from_field(f) == pb_nested_struct_name,
      parent_msg.field))
    all_map_fields.extend(map_fields)
    return ''.join(list(map(lambda f: gen_map_helper_codes_for_field(f, nested_type), map_fields)))
  else:
    return ''

def gen_map_helpers(msg, parent_struct_name, all_map_fields):
  return ''.join(list(map((lambda nt: gen_map_helper(nt, msg, parent_struct_name, all_map_fields)), msg.nested_type)))

def gen_array_helpers(msg, parent_struct_name, all_map_fields):
  array_fields = filter(lambda t: util.field_is_repeated(t) and t not in all_map_fields, msg.field)
  return ''.join(map(lambda f: gen_array_helper_codes_for_field(f),array_fields))

def gen_codec(msg, main_codecs, delegate_codecs, parent_struct_name = None, file = None):
  delegate_lib_name = util.gen_delegate_lib_name(msg, parent_struct_name)
  all_map_fields = []
  # delegate codec
  delegate_codecs.append(sol_constants.CODECS.format(
    delegate_lib_name = delegate_lib_name,
    enum_definition = gen_enum_definition(msg, parent_struct_name),
    struct_definition = gen_struct_definition(msg, parent_struct_name, file),
    decoder_section = gen_decoder_section(msg, parent_struct_name, file),
    encoder_section = gen_encoder_section(msg, parent_struct_name, file),
    store_function = gen_store_function(msg, parent_struct_name),
    map_helper = gen_map_helpers(msg, parent_struct_name, all_map_fields),
    array_helper = gen_array_helpers(msg, parent_struct_name, all_map_fields),
    utility_functions = gen_utility_functions(msg, parent_struct_name)
  ))
  for nested in msg.nested_type:
    gen_codec(nested, main_codecs, delegate_codecs, util.add_prefix(parent_struct_name, msg.name), file)

def gen_global_enum(msg, main_codecs, delegate_codecs, parent_struct_name = None):
  delegate_codecs.append(sol_constants.GLOBAL_ENUM_CODECS.format(
    delegate_lib_name = util.gen_global_enum_name(msg),
    enum_definition = gen_enum_definition(msg, parent_struct_name),
  ))

RUNTIME_FILE_NAME = "ProtoBufRuntime.sol"
PROTOBUF_ANY_FILE_NAME = "GoogleProtobufAny.sol"
GEN_RUNTIME = False
COMPILE_META_SCHEMA = False
def apply_options(params_string):
  params = util.parse_urllike_parameter(params_string)
  if "gen_runtime" in params:
    global GEN_RUNTIME
    GEN_RUNTIME = True
    name = params["gen_runtime"]
    if name.endswith(".sol"):
      global RUNTIME_FILE_NAME
      RUNTIME_FILE_NAME = name
  if "pb_libname" in params:
    util.change_pb_libname_prefix(params["pb_libname"])
  if "for_linking" in params:
    sys.stderr.write("warning: for_linking option is still under experiment due to slow-pace of solidity development\n")
    util.set_library_linking_mode()
  if "gen_internal_lib" in params:
    util.set_internal_linking_mode()
  if "use_builtin_enum" in params:
    sys.stderr.write("warning: use_builtin_enum option is still under experiment because we cannot set value to solidity's enum\n")
    util.set_enum_as_constant(True)
  if "compile_meta_schema" in params:
    global COMPILE_META_SCHEMA
    COMPILE_META_SCHEMA = True
  if "solc_version" in params:
    util.set_solc_version(params["solc_version"])

def get_dependencies(proto_file, request):
  proto_files = {f.name:f for f in request.proto_file}
  return [proto_files[d] for d in proto_file.dependency]

def gen_import_path(dependency):
  # I don't know whether `os.path` module works well for import paths on Windows ...
  import os
  dirname = os.path.dirname(dependency.name)
  basename = os.path.basename(dependency.name).replace('.proto', '.sol')
  if sol_dirpath_pb2.sol_dirpath in dependency.options.Extensions:
    dirname = dependency.options.Extensions[sol_dirpath_pb2.sol_dirpath]
  if dirname == "":
    return './{0}'.format(basename)
  else:
    return './{0}/{1}'.format(dirname, basename)

def generate_code(request, response):
  generated = 0

  apply_options(request.parameter)

  for proto_file in request.proto_file:
    # skip google.protobuf namespace
    if (proto_file.package == "google.protobuf") and (not COMPILE_META_SCHEMA):
      continue
    # skip native solidity type definition
    if proto_file.package == "solidity":
      continue
    # main output
    output = []

    # set package name if any
    util.change_package_name(proto_file.package)

    # generate sol library
    # prologue
    output.append('// SPDX-License-Identifier: Apache-2.0\npragma solidity ^{0};'.format(util.SOLIDITY_VERSION))
    for pragma in util.SOLIDITY_PRAGMAS:
      output.append('{0};'.format(pragma))
    output.append('import "./{0}";'.format(RUNTIME_FILE_NAME))
    output.append('import "./{0}";'.format(PROTOBUF_ANY_FILE_NAME))
    for dep in get_dependencies(proto_file, request):
      if dep.package == "solidity":
        continue
      if (dep.package == "google.protobuf") and (not COMPILE_META_SCHEMA):
        continue
      output.append('import "{0}";'.format(gen_import_path(dep)))

    # generate per message codes
    main_codecs = []
    delegate_codecs = []
    for msg in proto_file.message_type:
      gen_codec(msg, main_codecs, delegate_codecs, None, proto_file)
    if proto_file.enum_type:
      gen_global_enum(proto_file, main_codecs, delegate_codecs, None)

    # epilogue
    output = output + delegate_codecs


    if len(delegate_codecs) > 0: # if it has any contents, output pb.sol file
      # Fill response
      basepath = os.path.basename(proto_file.name)
      f = response.file.add()
      f.name = basepath.replace('.proto', '.sol')
      f.content = '\n'.join(output)
      # increase generated file count
      generated = generated + 1

  if generated > 0 and GEN_RUNTIME:
    try:
      with open(os.path.dirname(os.path.realpath(__file__)) + '/runtime/ProtoBufRuntime.sol', 'r') as runtime:
        rf = response.file.add()
        rf.name = RUNTIME_FILE_NAME
        rf.content = '// SPDX-License-Identifier: Apache-2.0\npragma solidity ^{0};\n'.format(util.SOLIDITY_VERSION) + runtime.read()
    except Exception as e:
      sys.stderr.write(
        "required to generate solidity runtime at {} but cannot open runtime with error {}\n".format(
          RUNTIME_FILE_NAME, e
        )
      )
    try:
      with open(os.path.dirname(os.path.realpath(__file__)) + '/runtime/GoogleProtobufAny.sol', 'r') as runtime:
        rf = response.file.add()
        rf.name = PROTOBUF_ANY_FILE_NAME
        rf.content = '// SPDX-License-Identifier: Apache-2.0\npragma solidity ^{0};\n'.format(util.SOLIDITY_VERSION) + runtime.read()
    except Exception as e:
      sys.stderr.write(
        "required to generate solidity runtime at {} but cannot open runtime with error {}\n".format(
          PROTOBUF_ANY_FILE_NAME, e
        )
      )

if __name__ == '__main__':
  # Read request message from stdin
  if hasattr(sys.stdin, 'buffer'):
    data = sys.stdin.buffer.read()
  else:
    data = sys.stdin.read()

  # Parse request
  request = plugin.CodeGeneratorRequest()
  request.ParseFromString(data)

  # pp.pprint(request)

  # Create response
  response = plugin.CodeGeneratorResponse()

  # Generate code
  generate_code(request, response)

  # Serialise response message
  output = response.SerializeToString()

  # Write to stdout
  if hasattr(sys.stdin, 'buffer'):
    sys.stdout.buffer.write(output)
  else:
    sys.stdout.write(output)
