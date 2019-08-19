const TestBytesDeserialization = artifacts.require('TestBytesDeserialization.sol');
const assert = require('assert');
const soltype = require(__dirname + "../../../solidity-js");
const proto = soltype.importTypes(require(__dirname + '/../../js/test_bytes_pb.js'));

let contractInstance;

contract('TestBytesDeserialization', (accounts) => {
  beforeEach(async () => {
    contractInstance = await TestBytesDeserialization.new();
  }),
  it('should return same bytes', async () => {
    let data = new Uint8Array(2);
    data[0] = 2;
    data[1] = 1;
    let message = new proto.TestBytes();
    let bytes2Field = new proto.solidity.bytes2();
    bytes2Field.setData(data);
    message.setBytes2Field(bytes2Field);
    let buffer = message.serializeBinary();
    let encodedString = Buffer.from(buffer).toString('hex')
    let result = await contractInstance.getTestBytesBytes2("0x" + encodedString);
    console.log(result);
    assert.equal('0x0201', result);
  })
});
