const SimpleContract = artifacts.require('../SimpleContract.sol');
const assert = require('assert');

let contractInstance;
const DIFF = 1000000000000000000;       // The transaction cost should be less then 1 Ether

contract('SimpleContractV2', (accounts) => {
    beforeEach(async () => {
        contractInstance = await SimpleContract.new();
    }),
    it('should return same address', async () => {
        // console.log(escrowInstance.address);
        // console.log(tokenInstance.address);
        await contractInstance.storeSimpleContract(accounts[0], 12800, -12900);
        // let current = await contractInstance.getSimpleContractUint232(accounts[0]);
        // console.log(current);
        // assert.equal(12800, current);

        current = await contractInstance.getSimpleContractInt232(accounts[0]);
        target = 12800;
        console.log(current);
        assert.equal(-12900, current);
    })
 });
