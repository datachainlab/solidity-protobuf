const TestRepeatedAddPB = artifacts.require('TestRepeatedAddPB.sol');
const assert = require('assert');
const BN = require('bn.js');

let contractInstance;
contract('TestRepeatedAddPB', (accounts) => {
  beforeEach(async () => {
    contractInstance = await TestRepeatedAddPB.new();
  }),
  it('should return same values', async () => {
    let uint256s_expected = [1, 2, 3, 12800];

    await contractInstance.storeTestRepeated(accounts[0], [1, 2, 3]);

    let uint256s = await contractInstance.getTestRepeatedUint256(accounts[0]);
    assert.equal(JSON.stringify(uint256s_expected), JSON.stringify(uint256s.map(x => x.toNumber())));
  })
});
