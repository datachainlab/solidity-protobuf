const TestOtherPB = artifacts.require('TestOtherPB.sol');
const assert = require('assert');

let contractInstance;
contract('TestOtherPB', (accounts) => {
  beforeEach(async () => {
    contractInstance = await TestOtherPB.new();
  }),
  it('should return same values', async () => {
    let string_field_expected = "abc";
    let bool_field_expected = false;
    let enum_field_expected = 1;

    await contractInstance.storeTestOther(accounts[0], [0x01, 0x02],
      string_field_expected, bool_field_expected,
      enum_field_expected);

    let bytes_field = await contractInstance.getTestOtherBytes(accounts[0]);
    let string_field = await contractInstance.getTestOtherString(accounts[0]);
    let bool_field = await contractInstance.getTestOtherBool(accounts[0]);
    let enum_field = await contractInstance.getTestOtherEnum(accounts[0]);

    assert.equal(0x0102, bytes_field);
    assert.equal(string_field_expected, string_field);
    assert.equal(bool_field_expected, bool_field);
    assert.equal(enum_field_expected, enum_field);

  })
});
