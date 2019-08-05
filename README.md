<h1 align="center">ProtoSolGen</h1>

ProtoSolGen is a protocol buffer client generator for Solidity. Its main purpose is to allow Ethereum developers to define custom data structure using protocol buffer, and generates Solidity stubs for data serialization and deserialization.

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

<h2 align="center">Concept</h2>

Solidity has much more basic types than protocol buffer. For example, in Solidity there are 32 signed integer types, from int8 to int256. In order to address this type mismatch, we provide a custom type defintion for each Solidity types. For example, uint128 is defined as below:

```
message uint128 {bytes data = 1;}
```

The data, which is of type bytes, contains the minimum number of bytes needed to hold the value. For example, if the uint128 variable has a value of 20,000, 2 bytes are sufficient to hold this number. Currently we only support length-delimited encoding for value data.

<h2 align="center">How to Use It</h2>

Users can use the custom type definition to define their data structure. Below is an example:

```
syntax = "proto3";

import "Solidity.proto";

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

ProtoSolGen generates a Solidity struct definition for this message as well as serialization/deserialization methods. Users can use the generated Solidity stub in their smart contracts.
