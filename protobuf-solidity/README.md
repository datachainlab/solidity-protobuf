# protobuf-solidity

A Protocol Buffers compiler plugin for generating Solidity code from `.proto` files.

## Features

### Message Generation
- Generates Solidity structs for Protocol Buffer messages
- Includes encoder/decoder functions for each message type
- Supports nested messages and repeated fields
- Handles all standard protobuf types (strings, integers, booleans, bytes)

### Contract Interface Generation
- Generates Solidity interfaces from Protocol Buffer service definitions
- Maps proto RPC methods to Solidity function signatures
- Maintains type safety between proto definitions and Solidity contracts
- Enables contract-first development with proto as single source of truth

## Usage

### Installation

Link the plugin for use with `protoc`:

```bash
ln -s src/protoc/plugin/gen_sol.py protoc-gen-solidity
chmod +x protoc-gen-solidity
```

### Basic Usage

Generate Solidity files from proto definitions:

```bash
protoc --solidity_out=./generated *.proto
```

### Proto Service to Contract Interface

Define a service in your `.proto` file:

```protobuf
service ContractInterface {
  rpc RegisterIdentity(RegisterIdentityRequest) returns (RegisterIdentityResponse);
  rpc GetIdentities(GetIdentitiesRequest) returns (GetIdentitiesResponse);
}
```

The plugin generates a corresponding Solidity interface:

```solidity
interface IContractInterface {
    function registerIdentity(string memory domain, string memory identifier)
        external returns (bool success, string memory error, string memory transaction_hash);
    function getIdentities()
        external returns (StandaloneAttestorStandaloneIdentity.Data[] memory identities);
}
```

### Contract Implementation

Implement the generated interface in your contract:

```solidity
contract MyContract is IContractInterface {
    function registerIdentity(string memory domain, string memory identifier)
        external override returns (bool success, string memory error, string memory transaction_hash) {
        // Implementation
    }
}
```

## Type Mapping

| Proto Type | Solidity Type |
|------------|---------------|
| `string` | `string memory` |
| `int32` | `int32` |
| `int64` | `int64` |
| `uint32` | `uint32` |
| `uint64` | `uint64` |
| `bool` | `bool` |
| `bytes` | `bytes memory` |
| `repeated T` | `T[] memory` |
| Message type | `LibraryName.Data memory` |

## Architecture

- **Message Types**: Generated as libraries with `Data` structs and encode/decode functions
- **Service Interfaces**: Generated as Solidity interfaces with function signatures matching RPC methods
- **Type Safety**: Compile-time verification that contracts match proto definitions
- **Modularity**: Each proto file generates corresponding Solidity libraries and interfaces

## Benefits

- **Single Source of Truth**: Proto files define both backend contracts and frontend types
- **Type Safety**: Compile-time checking ensures implementation matches specification
- **Consistency**: Same data structures across different parts of the application
- **Maintainability**: Changes to proto files automatically propagate to generated code