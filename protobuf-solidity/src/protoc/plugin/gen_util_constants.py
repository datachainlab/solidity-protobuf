ENUM_TYPE = """
  // Define enum constants
  int64 public constant _{type}_{name} = {value};
  function {type}_{name}() internal pure returns (int64) {{
    return _{type}_{name};
  }}
"""

ENUM_FUNCTION = """
// Solidity enum definitions
enum {enum_name} {{
    {enum_values}
  }}
"""

ENUM_ENCODE_FUNCTION = """
// Solidity enum encoder
function encode_{enum_name}({enum_name} x) internal pure returns (int64) {{
    {enum_values}
  revert();
}}
"""

ENUM_ENCODE_FUNCTION_INNER = """
  if (x == {enum_name}.{name}) {{
    return {value};
  }}"""

ENUM_DECODE_FUNCTION = """
// Solidity enum decoder
function decode_{enum_name}(int64 x) internal pure returns ({enum_name}) {{
    {enum_values}
  revert();
}}
"""

ENUM_DECODE_FUNCTION_INNER = """
  if (x == {value}) {{
    return {enum_name}.{name};
  }}"""
