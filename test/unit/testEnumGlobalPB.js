const TestEnumGlobalPB = artifacts.require('TestEnumGlobalPB.sol');
const assert = require('assert');

let contractInstance;
contract('TestEnumGlobalPB', (accounts) => {
  beforeEach(async () => {
    contractInstance = await TestEnumGlobalPB.new();
  }),
  it('should return same values', async () => {
    let string_field_expected = "abc";
    let bool_field_expected = false;
    let enum_field_expected = 1;

    await contractInstance.storeTestOther(accounts[0], [0x01, 0x02],
      string_field_expected, bool_field_expected,
      enum_field_expected);

    let enum_field = await contractInstance.getTestOtherEnum(accounts[0]);
    assert.equal(enum_field_expected, enum_field);

  })
});
