ENUM_TYPE = """
  int64 public constant _{type}_{name} = {value};
  function {type}_{name}() internal pure returns (int64) {{
    return _{type}_{name};
  }}
"""

ENUM_FUNCTION = """
enum {enum_name} {{
    {enum_values}
  }}
"""
