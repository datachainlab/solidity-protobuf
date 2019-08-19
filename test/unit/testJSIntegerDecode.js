const soltype = require(__dirname + "../../../solidity-js");
const proto = soltype.importTypes(require(__dirname + '/../../js/test_integer_pb.js'));
const assert = require('assert');
const BigNumber = require('bignumber.js');

let contractInstance;

contract('TestIntegerDeserialization', (accounts) => {
  it('should return same integer', async () => {
    let message = new proto.TestInteger();
    let int64Field = new proto.solidity.int64();
    int64Field.saveAsBytes(128);
    message.setInt64Field(int64Field);
    assert.equal(128, message.getInt64Field().toBigInt());
  })
});
