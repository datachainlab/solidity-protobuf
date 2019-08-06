STRUCT_DEFINITION = """
  //struct definition
  struct Data {{
{fields}{map_fields}
  }}"""

ENUMS_DEFINITION = """
  //enum definition{enums}"""

MAP_FIELD_DEFINITION = """
    uint _size_{name};"""

UTILITY_FUNCTION = """
  //utility functions
  function nil() internal pure returns ({name} memory r) {{
    assembly {{
      r := 0
    }}
  }}

  function isNil({name} memory x) internal pure returns (bool r) {{
    assembly {{
      r := iszero(x)
    }}
  }}"""

STORE_REPEATED = """
    output.{field}.length = input.{field}.length;
    for(uint i{i} = 0; i{i} < input.{field}.length; i{i}++) {{
      {lib}.store(input.{field}[i{i}], output.{field}[i{i}]);
    }}
    {map_insert_code}
"""

STORE_MESSAGE = "    {lib}.store(input.{field}, output.{field});\n"

STORE_OTHER = "    output.{field} = input.{field};\n"

STORE_FUNCTION = """
  //store function
  function store({name} memory input, {name} storage output) internal {{
{store_codes}
  }}"""

MAP_HELPER_CODE = """
  //map helpers for {name}
  function get{name}(Data memory self, {key_type} {key_storage_type} key) internal pure returns ({value_type} {value_storage_type}) {{
    {value_type} {value_storage_type} defaultValue;
    for (uint i = 0; i < {map_name}; i++) {{
      {field_type} memory data = {val_name}[i];
      if (keccak256(abi.encodePacked((key))) == keccak256(abi.encodePacked((data.key)))) {{
        return data.value;
      }}
    }}
    return defaultValue;
  }}

  function search{name}(Data memory self, {key_type} {key_storage_type} key) internal pure returns (bool, {value_type} {value_storage_type}) {{
    {value_type} {value_storage_type} defaultValue;
    for (uint i = 0; i < {map_name}; i++) {{
      {field_type} memory data = {val_name}[i];
      if (keccak256(abi.encodePacked((key))) == keccak256(abi.encodePacked((data.key)))) {{
        return (true, data.value);
      }}
    }}
    return (false, defaultValue);
  }}

  function add{name}(Data memory self, {key_type} {key_storage_type} key, {value_type} {value_storage_type} value) internal pure {{
    for (uint i = 0; i < {map_name}; i++) {{
      {field_type} memory data = {val_name}[i];
      if (keccak256(abi.encodePacked((key))) == keccak256(abi.encodePacked((data.key)))) {{
        {val_name}[i].value = value;
        return;
      }}
    }}
    if ({val_name}.length == 0) {{
      {val_name} = new {field_type}[](10);
    }}
    if ({map_name} == {val_name}.length) {{
      {field_type}[] memory tmp = new {field_type}[]({val_name}.length * 2);
      for (uint i = 0; i < {map_name}; i++) {{
        tmp[i] = {val_name}[i];
      }}
      {val_name} = tmp;
    }}
    {field_type} memory entry;
    entry.key = key;
    entry.value = value;
    {val_name}[{map_name}++] = entry;
  }}

  function rm{name}(Data memory self, {key_type} {key_storage_type} key) internal pure {{
    uint pos;
    for (uint i = 0; i < {map_name}; i++) {{
      {field_type} memory data = {val_name}[i];
      if (keccak256(abi.encodePacked((key))) == keccak256(abi.encodePacked((data.key)))) {{
        pos = i + 1;
        break;
      }}
    }}
    if (pos == 0) {{
      return;
    }}
    pos -= 1;
    {val_name}[pos] = {val_name}[--{map_name}];
  }}"""

ARRAY_HELPER_CODE = """
  //array helpers for {name}
  function add{name}(Data memory self, {field_type} {field_storage_type} value) internal pure {{
    {field_type}[] memory tmp = new {field_type}[]({val_name}.length + 1);
    for (uint i = 0; i < {val_name}.length; i++) {{
      tmp[i] = {val_name}[i];
    }}
    tmp[{val_name}.length] = value;
    {val_name} = tmp;
  }}
"""

CODECS = """
library {delegate_lib_name} {{
{enum_definition}
{struct_definition}
{decoder_section}
{encoder_section}
{store_function}
{map_helper}
{array_helper}
{utility_functions}
}}
//library {delegate_lib_name}"""
