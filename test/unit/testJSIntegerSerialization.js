const TestIntegerDeserialization = artifacts.require('TestIntegerDeserialization.sol');
const { BN, constants, expectEvent, shouldFail, time } = require('@openzeppelin/test-helpers');
const soltype = require(__dirname + "../../../solidity-js");
const proto = soltype.importTypes(require(__dirname + '/../../js/test_integer_pb.js'));
const assert = require('assert');
const BigNumber = require('bignumber.js');

let contractInstance;

contract('TestIntegerDeserialization', (accounts) => {
  beforeEach(async () => {
    contractInstance = await TestIntegerDeserialization.new();
  }),
  it('should return same integer', async () => {
    let message = new proto.TestInteger();
    let uint64Field = new proto.solidity.uint64();
    uint64Field.saveAsBytes(513);
    let addressField = new proto.solidity.address();
    addressField.saveAsBytes(BigNumber(accounts[0].toString().toLowerCase()));
    message.setUint64Field(uint64Field);
    message.setAddressField(addressField);
    let buffer = message.serializeBinary();
    let encodedString = Buffer.from(buffer).toString('hex')
    let result = await contractInstance.getTestIntegerUint64("0x" + encodedString);
    let address = await contractInstance.getTestAddress("0x" + encodedString);
    console.log(result);
    console.log(address);
    assert.equal(513, result.toNumber());
    assert.equal(accounts[0], address);
  }),
  it('should fail to decode', async () => {
    let message = new proto.TestInteger();
    let uint64Field = new proto.solidity.uint64();
    uint64Field.saveAsBytes(513);
    let addressField = new proto.solidity.address();
    addressField.saveAsBytes(BigNumber(accounts[0].toString().toLowerCase()));
    message.setUint64Field(uint64Field);
    message.setAddressField(addressField);
    let buffer = message.serializeBinary();
    buffer[0] = 129;
    let encodedString = Buffer.from(buffer).toString('hex')
    await shouldFail.reverting.withMessage(contractInstance.getTestIntegerUint64("0x" + encodedString), "length overflow");
  })
});
