const SimpleContract = artifacts.require('SimpleContract.sol');
const assert = require('assert');

let contractInstance;

contract('SimpleContractV2', (accounts) => {
    beforeEach(async () => {
        contractInstance = await SimpleContract.new();
    }),
    it('should return same address', async () => {
        // console.log(escrowInstance.address);
        // console.log(tokenInstance.address);
        await contractInstance.storeSimpleContract(accounts[0], 123, -12812, 12700);
        let result = await contractInstance.getSimpleContract(accounts[0]);
        assert.equal(12700, result);
        console.log(result);
        // let size = await contractInstance.getByteLength(125, 32);
        // console.log(size);
        //
        // let size_2 = await contractInstance.getInt32(-2147483646);
        // console.log(size_2);
    })
 });
