const TestMapPB = artifacts.require('TestMapPB.sol');
const assert = require('assert');

let contractInstance;
contract('TestMapPB', (accounts) => {
  beforeEach(async () => {
    contractInstance = await TestMapPB.new();
  }),
  it('should return same values', async () => {
    await contractInstance.storeTestMap(accounts[0], "abc", "def");
    let result = await contractInstance.getTestMap(accounts[0], "abc");
    console.log("result: " + result);
    assert.equal("def", result);
  }),
  it('should have valid test state', async () => {
    await contractInstance.createTestState(accounts[0]);
    let result = await contractInstance.getTestMap(accounts[0], "one");
    console.log("result: " + result);
    assert.equal("one_value", result);

    result = await contractInstance.getTestMap(accounts[0], "two");
    console.log("result: " + result);
    assert.equal("two_value", result);

    result = await contractInstance.getTestMap(accounts[0], "three");
    console.log("result: " + result);
    assert.equal("three_value_new", result);

    result = await contractInstance.getTestMap(accounts[0], "four");
    console.log("result: " + result);
    assert.equal("four_value", result);

    result = await contractInstance.getTestMap(accounts[0], "zero");
    console.log("result: " + result);
    assert.equal("", result);

    result = await contractInstance.getTestMapSize(accounts[0]);
    console.log("result: " + result);
    assert.equal(4, result);
  })
});
