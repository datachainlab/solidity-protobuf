const TestSize = artifacts.require('TestSize.sol');
const assert = require('assert');

let contractInstance;

contract('TestSize', (accounts) => {
    beforeEach(async () => {
        contractInstance = await TestSize.new();
    }),
    it('should return same size', async () => {
        let result = await contractInstance.getSignedSize(-1);
        console.log(result);
        assert.equal(1, result);

        result = await contractInstance.getSignedSize(-128);
        console.log(result);
        assert.equal(1, result);

        result = await contractInstance.getSignedSize(-256);
        console.log(result);
        assert.equal(2, result);

        result = await contractInstance.getSignedSize(255);
        console.log(result);
        assert.equal(2, result);

        result = await contractInstance.getUnsingedSize(0);
        console.log(result);
        assert.equal(1, result);

        result = await contractInstance.getUnsingedSize(255);
        console.log(result);
        assert.equal(1, result);

        result = await contractInstance.getUnsingedSize(256);
        console.log(result);
        assert.equal(2, result);

    })
 });
