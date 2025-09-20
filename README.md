<h1 align="center">ProtoSolGenerator</h1>

ProtoSolGenerator is a protocol buffer client generator for Solidity. Its main purpose is to allow Ethereum developers to define custom data structure using protocol buffer, and generates Solidity stubs for data serialization and deserialization.

ProtoSolGenerator is inspired by [pb3sol](https://raw.githubusercontent.com/umegaya/pb3sol) with optimization on performance, flexibility and usability. We initial testing shows that the gas cost is reduced by 2/3 compared to the original Solidity implementation.

<h2 align="center">Introduction</h2>

Protocol buffer is a language-neutral, platform-neutral, extensible way of serializing structured data for use in communications protocols, data storage, and more. It's widely adopted as in various platforms, and it has several characteristics to make it particularly beneficial to Ethereum development.

### Optimized Storage

The storage cost is significantly higher in Ethereum than compute. For example, an SSTORE operation costs 20,000 gas while a normal ADD costs only 3. It's more reasonable to trade storage cost with computation in Ethereum.

However, Solidity in Ethereum is not storage-efficient. A single storage variable of type uint8 also takes the space of a whole word, identical to variables of type uint256. For a variable of type uint256, even if its value is relative small, (e.g it consumes only 4 bytes), it's still stored as 32 bytes. Protocol buffer defines an encoding format which is highly optimized in storage.

### Flexibility

Once a smart contract is deployed to Ethereum network, it's not updatable. Even though it can be "upgraded" using proxies, it comes with constraints and is not easy to use. For example, the upgraded contract might need to use the same field declaration order as the old contract.

Such inflexibility in logic can be mitigated with flexibility in data definition, which is a core feature of protocol buffer. When implemented with separation of logic and data, the upgraded contracts can work with data from the old ones.

### Cross-platform Support

Protocol buffer has rich support in languages including Java, JavaScript, Python and C++, so the function parameters and return values can be defined using the protocol buffer encoded strings. With this approach, users of smart contracts can use languages like JavaScript to construct function parameters to invoke Solidity functions.

### Security

The binary of protocol buffer data pertains the data type definition as well as field number. This ensures type-safety of data either on-chain or passed-in externally.

Moreover, Protocol Buffer simplifies the usage of complex data structure in the paramters and return values of external functions. There might be still hidden risk in using ABIEncoderV2, especially with the known bug identified in March 2019. ProtoSolGen allows auto-serialization of the complex data types so that we could use string as paramter/return value types instead of relying on ABIEncoderV2.

<h2 align="center">Concept</h2>

Solidity has much more basic types than protocol buffer. For example, in Solidity there are 32 signed integer types, from int8 to int256. In order to address this type mismatch, we provide a custom type defintion for each Solidity types. For example, uint128 is defined as below:

```
message uint128 {bytes data = 1;}
```

The data, which is of type bytes, contains the minimum number of bytes needed to hold the value. For example, if the uint128 variable has a value of 20,000, 2 bytes are sufficient to hold this number. Currently we only support length-delimited encoding for value data.

<h2 align="center">How to Use It</h2>

### Installation

To install ProtoSolGenerator, first install [protobuf compiler](https://github.com/protocolbuffers/protobuf#protocol-compiler-installation).

Then install python requirements. Python >= 3.5 is required.

```pip install -r requirements.txt```

### Runtime Enhancements

ProtoSolGenerator includes enhanced runtime support for additional protobuf types and Google well-known types:

#### Float and Double Support

The runtime includes native support for protobuf `float` (32-bit) and `double` (64-bit) types:

- `_decode_float(uint256 p, bytes memory bs)` - Decodes protobuf float to bytes4
- `_encode_float(bytes4 x, uint256 p, bytes memory bs)` - Encodes bytes4 to protobuf float
- `_decode_double(uint256 p, bytes memory bs)` - Decodes protobuf double to bytes8
- `_encode_double(bytes8 x, uint256 p, bytes memory bs)` - Encodes bytes8 to protobuf double

These functions enable proper handling of floating-point validation constraints from buf/validate and other protobuf schemas.

#### Google Well-Known Types

Runtime libraries are provided for common Google protobuf types:

- **GoogleProtobufAny.sol** - Support for `google.protobuf.Any` messages
- **GoogleProtobufDuration.sol** - Support for `google.protobuf.Duration` messages
- **GoogleProtobufTimestamp.sol** - Support for `google.protobuf.Timestamp` messages
- **GoogleProtobufFieldDescriptorProto.sol** - Support for `google.protobuf.FieldDescriptorProto` messages

These libraries are automatically included when generating contracts that use the corresponding Google protobuf types.

### Solidity Compatibility

ProtoSolGenerator includes comprehensive compatibility features for Solidity development:

#### Reserved Keyword Handling

The generator automatically mangles protobuf field names that conflict with Solidity reserved keywords:

- **Automatic detection**: Comprehensive list of Solidity reserved keywords including types (uint256, bytes32, etc.), control flow (if, while, etc.), and language features (contract, library, etc.)
- **Safe mangling**: Conflicting field names are automatically suffixed with `_field` (e.g., `uint32` → `uint32_field`)
- **No manual intervention**: Field name conflicts are resolved transparently during code generation

#### Enhanced Parameter Processing

The plugin supports both value-based and boolean flag parameters:

```bash
# Boolean flags (automatically detected)
--sol_opt=gen_runtime
--sol_opt=use_builtin_enum

# Value-based parameters
--sol_opt=gen_runtime=MyRuntime.sol
--sol_opt=solc_version=0.8.19
```

This enables more flexible plugin configuration and better integration with build tools like buf.

### Circular Dependency Resolution

ProtoSolGenerator includes advanced handling for circular dependencies commonly found in validation schemas:

#### Automatic Detection

The generator automatically detects circular references in message structures, particularly in buf/validate types:

- **FieldRules** ↔ **MapRules**: Field rules can reference map validation rules
- **FieldRules** ↔ **RepeatedRules**: Field rules can reference repeated field validation rules
- **MapRules** → **FieldRules**: Map rules reference field rules for key/value validation

#### Bytes Field Solution

Circular dependencies are resolved by using `bytes` fields with encode/decode helpers:

```solidity
struct BufValidateFieldRules {
    bytes map_field;        // Circular reference: use encode/decode helpers
    bytes repeated_field;   // Circular reference: use encode/decode helpers
    // ... other fields
}
```

The circular fields are marked with descriptive comments and can be serialized/deserialized using the standard protobuf encoding functions, maintaining full compatibility while avoiding Solidity compilation errors.

#### No Manual Intervention

Circular dependency resolution is automatic and transparent:
- Detected at generation time based on message and field type analysis
- Fields are automatically converted to `bytes` representation where needed
- Original protobuf semantics are preserved through encode/decode operations

### BSR Plugin Configuration

ProtoSolGenerator can be configured for distribution via the Buf Schema Registry (BSR):

#### Plugin Metadata

The included `buf.plugin.yaml` defines the plugin configuration:

```yaml
version: v1
name: buf.build/datachainlab/protoc-gen-solidity
plugin_version: v1.0.0
description: "Generate Solidity contracts from protobuf with validation support"
source_url: "https://github.com/datachainlab/solidity-protobuf"
deps:
  - buf.build/protocolbuffers/protobuf
  - buf.build/bufbuild/protovalidate
runtime:
  python:
    requirements:
      - protobuf>=4.25.1
      - wrapt
spdx_license_id: Apache-2.0
license_url: "https://github.com/datachainlab/solidity-protobuf/blob/master/LICENSE"
```

#### Local buf.gen.yaml Usage

For local development with the plugin:

```yaml
version: v2
plugins:
  - local: ["python", "protobuf-solidity/src/protoc/plugin/gen_sol.py"]
    out: contracts/generated
    opt: gen_runtime=true
```

#### Plugin Options

The plugin supports various configuration options:

- `gen_runtime=true`: Generate runtime libraries (ProtoBufRuntime.sol, etc.)
- `gen_runtime=CustomRuntime.sol`: Generate with custom runtime filename
- `solc_version=0.8.19`: Target specific Solidity compiler version
- `for_linking`: Enable library linking mode for larger projects
- `pb_libname=Custom`: Set custom library name prefix

### Data Definition

Users can use the custom type definition to define their data structure. Below is an example:

```
syntax = "proto3";

import "SolidityTypes.proto";

package finance.nuts;

message SellerParameter {
    .solidity.address seller_address = 1;
    .solidity.uint256 start_date = 2;
    .solidity.address collateral_token_address = 3;
    .solidity.uint256 collateral_token_amount = 4;
    .solidity.uint256 borrow_amount = 5;
    .solidity.uint16 collateral_due_days = 6;
    .solidity.uint16 engagement_due_days = 7;
    .solidity.uint16 tenor_days = 8;
    .solidity.uint16 interest_rate = 9;
    .solidity.uint16 grace_period = 10;
}
```

ProtoSolGenerator generates a Solidity struct definition for this message as well as serialization/deserialization methods. Users can use the generated Solidity stub in their smart contracts.

### Client Generation

Use `run.sh` with input proto files (`--input`) and output Solidity location(`--output`)

```
./run.sh --input <proto file path> --output <output directory>
```
