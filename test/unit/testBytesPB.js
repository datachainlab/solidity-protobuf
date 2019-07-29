const TestBytesPB = artifacts.require('TestBytesPB.sol');
const assert = require('assert');

let contractInstance;
contract('TestBytesPB', (accounts) => {
  beforeEach(async () => {
    contractInstance = await TestBytesPB.new();
  }),
  it('should return same bytes values', async () => {
    let bytes2_number = 2;
    let bytes10_number = 64880;
    let bytes17_number = 214748364;
    let bytes31_number = 332147483647;

    await contractInstance.storeTestBytes(accounts[0], bytes2_number,
      bytes10_number, bytes17_number,
      bytes31_number);

    let bytes2_field = await contractInstance.getTestBytesBytes2(accounts[0]);
    let bytes10_field = await contractInstance.getTestBytesBytes10(accounts[0]);
    let bytes17_field = await contractInstance.getTestBytesBytes17(accounts[0]);
    let bytes31_field = await contractInstance.getTestBytesBytes31(accounts[0]);

    let bytes2_field_expected = await contractInstance.getBytes2FromInteger(bytes2_number);
    let bytes10_field_expected = await contractInstance.getBytes10FromInteger(bytes10_number);
    let bytes17_field_expected = await contractInstance.getBytes17FromInteger(bytes17_number);
    let bytes31_field_expected = await contractInstance.getBytes31FromInteger(bytes31_number);

    assert.equal(bytes2_field_expected, bytes2_field);
    assert.equal(bytes10_field_expected, bytes10_field);
    assert.equal(bytes17_field_expected, bytes17_field);
    assert.equal(bytes31_field_expected, bytes31_field);

    let size = await contractInstance.sizeTestBytes(accounts[0], bytes2_number,
      bytes10_number, bytes17_number,
      bytes31_number);
    console.log(size);

  })
});
