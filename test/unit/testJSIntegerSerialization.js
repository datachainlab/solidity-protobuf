const TestIntegerDeserialization = artifacts.require('TestIntegerDeserialization.sol');
const soltype = require(__dirname + "../../../solidity-js");
const protobufjs = soltype.importProtoFile(require("protobufjs"));
const assert = require('assert');
const BigNumber = require('bignumber.js');

let contractInstance;

contract('TestIntegerDeserialization', (accounts) => {
  beforeEach(async () => {
    contractInstance = await TestIntegerDeserialization.new();
  }),
  it('should return same integer', async () => {
    let TestInteger = await new Promise(function(resolve, reject) {
      protobufjs.load(__dirname + "../../../proto/test_integer.proto", function(err, root) {
        if (err) {
          reject(err);
        }
        soltype.importTypes(root);
        let TestInteger = root.lookupType("TestInteger");
        resolve(TestInteger);
      });
    });
    let testNumber = BigNumber(513);
    let convertedNumber = testNumber.toString(16);
    if (convertedNumber.length % 2 != 0) {
      convertedNumber = "0" + convertedNumber;
    }
    let data = Uint8Array.from(Buffer.from(convertedNumber, 'hex'));
    let payload = {
      "uint64Field": {
        "data": data
      }
    };
    let message = TestInteger.fromObject(payload);
    let buffer = TestInteger.encode(message).finish();
    let result = await contractInstance.getTestIntegerUint64("0x" + buffer.toString('hex'));
    console.log(result);
    assert.equal(513, result.toNumber());
  })
});
