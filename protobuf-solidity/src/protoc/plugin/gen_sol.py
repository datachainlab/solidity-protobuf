#!/usr/bin/env python

import os, sys
from typing import Union, List, Tuple

import pprint
pp = pprint.PrettyPrinter(indent=4, stream=sys.stderr)

from google.protobuf.compiler import plugin_pb2 as plugin
from google.protobuf.descriptor_pool import DescriptorPool
from google.protobuf.descriptor import Descriptor, FieldDescriptor, FileDescriptor

from gen_decoder import gen_decoder_section
from gen_encoder import gen_encoder_section
import gen_util as util
import gen_sol_constants as sol_constants
import solidity_protobuf_extensions_pb2 as solpbext


def gen_fields(msg: Descriptor) -> str:
  return '\n'.join(map((lambda f: ("    {type} {name};").format(type = util.gen_fieldtype(f), name = f.name)), msg.fields))

def gen_map_fields_decl_for_field(f: FieldDescriptor) -> str:
  return (sol_constants.MAP_FIELD_DEFINITION).format(
    name = f.name,
    key_type = util.gen_global_type_name_from_field(f.message_type.fields[0]),
    container_type = util.gen_global_type_name_from_field(f)
  )

def gen_map_fields(msg: Descriptor) -> str:
  map_fields = list(filter(lambda f: f.message_type and f.message_type.GetOptions().map_entry, msg.fields))
  return '\n'.join(map(gen_map_fields_decl_for_field, map_fields))

# below gen_* codes for generating external library
def gen_struct_definition(msg: Descriptor) -> str:
  """Generates the following part.

  struct Data {
      ...
  }
  """
  map_fields = gen_map_fields(msg)
  if map_fields.strip():
    map_fields = "\n    //non serialized fields" + map_fields
  else:
    map_fields = ""
  fields = gen_fields(msg)
  if (fields or map_fields):
    return (sol_constants.STRUCT_DEFINITION).format(
      fields = fields,
      map_fields = map_fields
    )
  else:
    return (sol_constants.STRUCT_DEFINITION).format(
      fields = "    bool x;",
      map_fields = map_fields
    )

def gen_enums(msg: Union[Descriptor, FileDescriptor]) -> str:
  return '\n'.join(map(util.gen_enumtype, msg.enum_types_by_name.values()))

# below gen_* codes for generating internal library
def gen_enum_definition(msg: Union[Descriptor, FileDescriptor]) -> str:
  """Generates the following parts.

  enum Foo { ... }
  function encode_Foo(...) { ... }
  function decode_Foo(...) { ... }

  enum Bar { ... }
  function encode_Bar(...) { ... }
  function decode_Bar(...) { ... }

  ...
  """
  enums = gen_enums(msg)
  if enums.strip():
    return (sol_constants.ENUMS_DEFINITION).format(
      enums = gen_enums(msg)
    )
  else:
    return ""

# below gen_* codes for generating internal library
def gen_utility_functions(msg: Descriptor) -> str:
  return (sol_constants.UTILITY_FUNCTION).format(
    name = util.gen_internal_struct_name(msg)
  )

def gen_map_insert_on_store(f: FieldDescriptor, parent_msg: Descriptor) -> str:
  for nt in parent_msg.nested_types:
    if nt.GetOptions().map_entry:
      if f.message_type and f.message_type is nt:
        return ('output._size_{name} = input._size_{name};\n').format(name = f.name)
  return ''

def gen_store_code_for_field(f: FieldDescriptor, msg: Descriptor) -> str:
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
    map_insert_code = gen_map_insert_on_store(f, msg)
  )

def gen_store_codes(msg: Descriptor) -> str:
  return ''.join(map((lambda f: gen_store_code_for_field(f, msg)), msg.fields))

def gen_store_function(msg: Descriptor) -> str:
  """Generates the following.

  function store(Data memory input, Data storage output) internal {
      ...
  }
  """
  return (sol_constants.STORE_FUNCTION).format(
    name = util.gen_internal_struct_name(msg),
    store_codes = gen_store_codes(msg)
  )

def gen_value_copy_code(value_field, dst_flagment):
  if util.field_is_message(value_field):
    return ("{struct_name}.store(value, {dst}.value);").format(
      struct_name = util.gen_struct_codec_lib_name_from_field(value_field),
      dst = dst_flagment
    )
  else:
    return ("{dst}.value = value;").format(dst = dst_flagment)

def gen_map_helper_codes_for_field(f: FieldDescriptor, nested_type: Descriptor) -> str:
  kf = nested_type.fields[0]
  vf = nested_type.fields[1]
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

def gen_array_helper_codes_for_field(f: FieldDescriptor) -> str:
  field_type = util.gen_global_type_name_from_field(f)
  return (sol_constants.ARRAY_HELPER_CODE).format(
    name = util.to_camel_case(f.name),
    val_name = "self.{0}".format(f.name),
    field_type = field_type,
    field_storage_type = "memory" if util.is_complex_type(field_type) else ""
  )

def gen_map_helper(nested_type: Descriptor, parent_msg: Descriptor, all_map_fields: List[FieldDescriptor]) -> str:
  if nested_type.GetOptions().map_entry:
    map_fields = list(filter(
      lambda f: f.message_type and f.message_type is nested_type,
      parent_msg.fields))
    all_map_fields.extend(map_fields)
    return ''.join(map(lambda f: gen_map_helper_codes_for_field(f, nested_type), map_fields))
  else:
    return ''

def gen_map_helpers(msg: Descriptor, all_map_fields: List[FieldDescriptor]) -> str:
  return ''.join(map((lambda nt: gen_map_helper(nt, msg, all_map_fields)), msg.nested_types))

def gen_array_helpers(msg: Descriptor, all_map_fields: List[FieldDescriptor]) -> str:
  array_fields = filter(lambda t: util.field_is_repeated(t) and t not in all_map_fields, msg.fields)
  return ''.join(map(lambda f: gen_array_helper_codes_for_field(f), array_fields))

def gen_codec(msg: Descriptor, delegate_codecs: List[str]):
  delegate_lib_name = util.gen_delegate_lib_name(msg)
  all_map_fields = []
  # delegate codec
  delegate_codecs.append(sol_constants.CODECS.format(
    delegate_lib_name = delegate_lib_name,
    enum_definition = gen_enum_definition(msg),
    struct_definition = gen_struct_definition(msg),
    decoder_section = gen_decoder_section(msg),
    encoder_section = gen_encoder_section(msg),
    store_function = gen_store_function(msg),
    map_helper = gen_map_helpers(msg, all_map_fields),
    array_helper = gen_array_helpers(msg, all_map_fields),
    utility_functions = gen_utility_functions(msg)
  ))
  for nested in msg.nested_types:
    nested = nested if not util.ALLOW_RESERVED_KEYWORDS else util.MessageWrapper(nested)
    gen_codec(nested, delegate_codecs)

def gen_global_enum(file: FileDescriptor, delegate_codecs: List[str]):
  """Generates the following parts.

  library FILE_NAME_GLOBAL_ENUMS {
      enum Foo { ... }
      function encode_Foo(...) { ... }
      function decode_Foo(...) { ... }

      enum Bar { ... }
      function encode_Bar(...) { ... }
      function decode_Bar(...) { ... }

      ...
  }
  """
  delegate_codecs.append(sol_constants.GLOBAL_ENUM_CODECS.format(
    delegate_lib_name = util.gen_global_enum_name(file),
    enum_definition = gen_enum_definition(file),
  ))

RUNTIME_FILE_NAME = "ProtoBufRuntime.sol"
PROTOBUF_ANY_FILE_NAME = "GoogleProtobufAny.sol"
GEN_RUNTIME = False
COMPILE_META_SCHEMA = False
def apply_options(params_string):
  global GEN_RUNTIME
  params = util.parse_urllike_parameter(params_string)
  if 'gen_runtime' in params and 'use_runtime' in params:
    raise ValueError('"gen_runtime" and "use_runtime" cannot be used together')
  if "gen_runtime" in params:
    GEN_RUNTIME = True
    change_runtime_file_names(params["gen_runtime"])
  if "use_runtime" in params:
    GEN_RUNTIME = False
    change_runtime_file_names(params["use_runtime"])
  if "ignore_protos" in params:
    util.set_ignored_protos(params["ignore_protos"])
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
  if "allow_reserved_keywords" in params:
    util.set_allow_reserved_keywords(True)

def change_runtime_file_names(name: str):
  if not name.endswith(".sol"):
    raise ValueError('Only *.sol file is acceptable, but {0} is specified'.format(name))
  global RUNTIME_FILE_NAME, PROTOBUF_ANY_FILE_NAME
  RUNTIME_FILE_NAME = name
  # GoogleProtobufAny.sol and ProtoBufRuntime.sol must be put together in the same directory
  PROTOBUF_ANY_FILE_NAME = os.path.join(
      os.path.dirname(RUNTIME_FILE_NAME),
      os.path.basename(PROTOBUF_ANY_FILE_NAME))

def get_location_option(f: FileDescriptor) -> str:
  if not f.GetOptions().HasExtension(solpbext.file_options):
    return ""
  opts = f.GetOptions().Extensions[solpbext.file_options]
  return opts.location

def extract_npm_package_name_and_directory_path(location: str) -> Tuple[str, str]:
  parts = location.split('/')
  if location.startswith('@'):
    return '/'.join(parts[:2]), '/'.join(parts[2:])
  else:
    return parts[0], '/'.join(parts[1:])

def to_sol(path: str) -> str:
  return os.path.splitext(path)[0] + '.sol'

# parse a string like "@scope/package/a/b/c/d.sol" into ("@scope/package", "a/b/c", "d.sol")
def path_to_output_triple(path: str) -> Tuple[str, str, str]:
  location, s = os.path.split(path)
  p, d = extract_npm_package_name_and_directory_path(location)
  return p, d, s

# generate an output triple from FileDescriptor
def desc_to_output_triple(f: FileDescriptor) -> Tuple[str, str, str]:
  location = get_location_option(f)
  if location:
    p, d = extract_npm_package_name_and_directory_path(location)
    s = to_sol(os.path.basename(f.name))
    return p, d, s
  else:
    d, b = os.path.split(f.name)
    s = to_sol(b)
    return "", d, s

def gen_output_path(f: FileDescriptor) -> str:
  p, d, s = desc_to_output_triple(f)
  return os.path.join(p, d, s)

def calc_relpath(path: str, start: str) -> str:
  path = os.path.join('root', path)
  start = os.path.join('root', start)
  return os.path.relpath(path, start)

def gen_import_path(importee: Union[str, FileDescriptor], importer: FileDescriptor) -> str:
  importee_triple = desc_to_output_triple(importee) if isinstance(importee, FileDescriptor) else path_to_output_triple(importee)
  importer_triple = desc_to_output_triple(importer)
  if importee_triple[0] == importer_triple[0]:
    # relative import path
    relpath = calc_relpath(importee_triple[1], importer_triple[1])
    return os.path.join(relpath, importee_triple[2])
  else:
    # absolute import path
    return os.path.join(*importee_triple)

def generate_code(request, response):
  pool = DescriptorPool()
  for f in request.proto_file:
    pool.Add(f)

  generated = 0

  apply_options(request.parameter)

  for proto_file in map(lambda f: pool.FindFileByName(f.name), request.proto_file):
    # skip google.protobuf namespace
    if (proto_file.package == "google.protobuf") and (not COMPILE_META_SCHEMA):
      continue
    # skip native solidity type definition
    if proto_file.package == "solidity":
      continue
    # skip descriptors listed by ignored_protos
    if util.ignores_proto(proto_file.name):
      continue
    # main output
    output = []
    output_path = gen_output_path(proto_file)

    # generate sol library
    # prologue
    output.append('// SPDX-License-Identifier: Apache-2.0\npragma solidity ^{0};'.format(util.SOLIDITY_VERSION))
    for pragma in util.SOLIDITY_PRAGMAS:
      output.append('{0};'.format(pragma))
    output.append('import "{0}";'.format(gen_import_path(RUNTIME_FILE_NAME, proto_file)))
    output.append('import "{0}";'.format(gen_import_path(PROTOBUF_ANY_FILE_NAME, proto_file)))
    for dep in proto_file.dependencies:
      if dep.package == "solidity":
        continue
      if (dep.package == "google.protobuf") and (not COMPILE_META_SCHEMA):
        continue
      if util.ignores_proto(dep.name):
        continue
      output.append('import "{0}";'.format(gen_import_path(dep, proto_file)))

    # generate per message codes
    delegate_codecs = []
    for msg in proto_file.message_types_by_name.values():
      msg = msg if not util.ALLOW_RESERVED_KEYWORDS else util.MessageWrapper(msg)
      gen_codec(msg, delegate_codecs)
    if len(proto_file.enum_types_by_name):
      gen_global_enum(proto_file, delegate_codecs)

    # epilogue
    output = output + delegate_codecs


    if len(delegate_codecs) > 0: # if it has any contents, output pb.sol file
      # Fill response
      f = response.file.add()
      f.name = output_path
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
