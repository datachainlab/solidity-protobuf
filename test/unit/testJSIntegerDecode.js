const soltype = require(__dirname + "../../../solidity-js");
const protobufjs = soltype.importProtoFile(require("protobufjs"));
const assert = require('assert');
const BigNumber = require('bignumber.js');

let contractInstance;

contract('TestIntegerDeserialization', (accounts) => {
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
      "int64Field": {
        "data": new Uint8Array(2)
      }
    };
    let message = TestInteger.fromObject(payload);
    message.int64Field.saveAsBytes(128);
    assert.equal(128, message.int64Field.toBigInt());
  })
});
