const TestRepeatedNative = artifacts.require('TestRepeatedNative.sol');
const assert = require('assert');
const BN = require('bn.js');

let contractInstance;
contract('TestRepeatedNative', (accounts) => {
  beforeEach(async () => {
    contractInstance = await TestRepeatedNative.new();
  }),
  it('should return same values', async () => {
    let string_field_expected = "abc";
    let uint256s_expected = [1, 2, 3];
    let sint64s_expected = [-1, 2, -3];
    let bool_field_expected = true;
    let unpacked_int32s_expected = [3, -2, 1, 0, -1000, 1000000, -1000000000];
    let packed_int32s_expected = [-3, 2, -1, 0, 1000, -1000000, 1000000000];

    await contractInstance.storeTestRepeated(
      accounts[0],
      string_field_expected,
      uint256s_expected,
      sint64s_expected,
      bool_field_expected,
      unpacked_int32s_expected,
      packed_int32s_expected
    );

    let string_field = await contractInstance.getTestRepeatedString(accounts[0]);
    let uint256s = await contractInstance.getTestRepeatedUint256(accounts[0]);
    let sint64s = await contractInstance.getTestRepeatedInt64(accounts[0]);
    let bool_field = await contractInstance.getTestRepeatedBool(accounts[0]);
    let unpacked_int32s = await contractInstance.getTestRepeatedUnpackedInt32(accounts[0]);
    let packed_int32s = await contractInstance.getTestRepeatedPackedInt32(accounts[0]);

    assert.equal(string_field_expected, string_field);
    assert.equal(JSON.stringify(uint256s_expected), JSON.stringify(uint256s.map(x => x.toNumber())));
    assert.equal(JSON.stringify(sint64s_expected), JSON.stringify(sint64s.map(x => x.toNumber())));
    assert.equal(bool_field_expected, bool_field);
    assert.equal(JSON.stringify(unpacked_int32s_expected), JSON.stringify(unpacked_int32s.map(x => x.toNumber())));
    assert.equal(JSON.stringify(packed_int32s_expected), JSON.stringify(packed_int32s.map(x => x.toNumber())));

  })
});
