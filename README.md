<h1 align="center">ProtoSolGen</h1>

ProtoSolGen is a protocol buffer client generator for Solidity. Its main purpose is to allow Ethereum developers to define custom data structure using protocol buffer, and generates Solidity stubs for data serialization and deserialization.

<h2 align="center">Introduction</h2>

Protocol buffer is a language-neutral, platform-neutral, extensible way of serializing structured data for use in communications protocols, data storage, and more. It's widely adopted as in various platforms, and it has several characteristics to make it particularly beneficial to Ethereum development.

### Optimized Storage

The storage cost is significantly higher in Ethereum than compute. For example, an SSTORE operation costs 20,000 gas while a normal ADD costs only 3. It's more reasonable to trade storage cost with computation in Ethereum.

However, Solidity in Ethereum is not storage-efficient. A single storage variable of type uint8 also takes the space of a whole word, identical to variables of type uint256. For a variable of type uint256, even if its value is relative small, (e.g it consumes only 4 bytes), it's still stored as 32 bytes.

<h2 align="center">Concept</h2>

<h2 align="center">How to Use It</h2>
