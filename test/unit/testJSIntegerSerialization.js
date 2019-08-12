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
    let payload = {
      "uint64Field": {
      },
      "addressField": {
      }
    };
    let message = TestInteger.fromObject(payload);
    message.uint64Field.saveAsBytes(513);
    message.addressField.saveAsBytes(BigNumber(accounts[0].toString().toLowerCase()));
    let buffer = TestInteger.encode(message).finish();
    let result = await contractInstance.getTestIntegerUint64("0x" + buffer.toString('hex'));
    let address = await contractInstance.getTestAddress("0x" + buffer.toString('hex'));
    console.log(result);
    console.log(address);
    assert.equal(513, result.toNumber());
    assert.equal(accounts[0], address);
  })
});
