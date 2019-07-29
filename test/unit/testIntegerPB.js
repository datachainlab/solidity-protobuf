const TestIntegerPB = artifacts.require('TestIntegerPB.sol');
const assert = require('assert');

let contractInstance;
contract('TestIntegerPB', (accounts) => {
  beforeEach(async () => {
    contractInstance = await TestIntegerPB.new();
  }),
  it('should return same positive values', async () => {
    await contractInstance.storeTestInteger(accounts[0], 1, 2, 3, 4, 5, 6, accounts[1], 8, 9);
    let sint32_field = await contractInstance.getTestIntegerSint32(accounts[0]);
    let int32_field = await contractInstance.getTestIntegerInt32(accounts[0]);
    let fixed32_field = await contractInstance.getTestIntegerFixed32(accounts[0]);
    let fixed64_field = await contractInstance.getTestIntegerFixed64(accounts[0]);
    let int256_field = await contractInstance.getTestIntegerInt256(accounts[0]);
    let uint256_field = await contractInstance.getTestIntegerUint256(accounts[0]);
    let address_field = await contractInstance.getTestIntegerAddress(accounts[0]);
    let int64_field = await contractInstance.getTestIntegerInt64(accounts[0]);
    let uint64_field = await contractInstance.getTestIntegerUint64(accounts[0]);

    assert.equal(1, sint32_field);
    assert.equal(2, int32_field);
    assert.equal(3, fixed32_field);
    assert.equal(4, fixed64_field);
    assert.equal(5, int256_field);
    assert.equal(6, uint256_field);
    assert.equal(accounts[1], address_field);
    assert.equal(8, int64_field);
    assert.equal(9, uint64_field);

  }),
  it('should return same negative values', async () => {
    await contractInstance.storeTestInteger(accounts[0], -2147483646, -2147483643, 3, 4, -2147483639, 6, accounts[1], -2147483640, 9);
    let sint32_field = await contractInstance.getTestIntegerSint32(accounts[0]);
    let int32_field = await contractInstance.getTestIntegerInt32(accounts[0]);
    let fixed32_field = await contractInstance.getTestIntegerFixed32(accounts[0]);
    let fixed64_field = await contractInstance.getTestIntegerFixed64(accounts[0]);
    let int256_field = await contractInstance.getTestIntegerInt256(accounts[0]);
    let uint256_field = await contractInstance.getTestIntegerUint256(accounts[0]);
    let address_field = await contractInstance.getTestIntegerAddress(accounts[0]);
    let int64_field = await contractInstance.getTestIntegerInt64(accounts[0]);
    let uint64_field = await contractInstance.getTestIntegerUint64(accounts[0]);

    assert.equal(-2147483646, sint32_field);
    assert.equal(-2147483643, int32_field);
    assert.equal(3, fixed32_field);
    assert.equal(4, fixed64_field);
    assert.equal(-2147483639, int256_field);
    assert.equal(6, uint256_field);
    assert.equal(accounts[1], address_field);
    assert.equal(-2147483640, int64_field);
    assert.equal(9, uint64_field);

  })
});
