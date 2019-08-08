const TestBytesNative = artifacts.require('TestBytesNative.sol');
const assert = require('assert');

let contractInstance;
contract('TestBytesNative', (accounts) => {
  beforeEach(async () => {
    contractInstance = await TestBytesNative.new();
  }),
  it('should return same bytes values', async () => {
    let random_hex = '0xb10fb5381f400334c7baae705e3fe509712e38b66c3479c21b5c66a9f306877b';

    await contractInstance.storeTestBytes(accounts[0], random_hex);

    let bytes2_field = await contractInstance.getTestBytesBytes2(accounts[0]);
    let bytes10_field = await contractInstance.getTestBytesBytes10(accounts[0]);
    let bytes17_field = await contractInstance.getTestBytesBytes17(accounts[0]);
    let bytes31_field = await contractInstance.getTestBytesBytes31(accounts[0]);

    let bytes2_field_expected = await contractInstance.getBytes2FromBytes32(random_hex);
    let bytes10_field_expected = await contractInstance.getBytes10FromBytes32(random_hex);
    let bytes17_field_expected = await contractInstance.getBytes17FromBytes32(random_hex);
    let bytes31_field_expected = await contractInstance.getBytes31FromBytes32(random_hex);

    assert.equal(bytes2_field_expected, bytes2_field);
    assert.equal(bytes10_field_expected, bytes10_field);
    assert.equal(bytes17_field_expected, bytes17_field);
    assert.equal(bytes31_field_expected, bytes31_field);

  })
});
