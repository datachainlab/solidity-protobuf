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
