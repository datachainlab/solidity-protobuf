const TestBytesDeserialization = artifacts.require('TestBytesDeserialization.sol');
const protobufjs = require("protobufjs");
const assert = require('assert');

let contractInstance;

contract('TestBytesDeserialization', (accounts) => {
  beforeEach(async () => {
    let origResolvePath = protobufjs.Root.prototype.resolvePath;
    protobufjs.Root.prototype.resolvePath = function (filename, path) {
      if (path.endsWith("SolidityTypes.proto")) {
        return origResolvePath(filename, __dirname + "../../../protobuf-solidity/src/protoc/include/SolidityTypes.proto");
      }
      return origResolvePath(filename, path);
    }
    contractInstance = await TestBytesDeserialization.new();
  }),
  it('should return same bytes', async () => {
    let TestBytes = await new Promise(function(resolve, reject) {
      protobufjs.load(__dirname + "../../../proto/test_bytes.proto", function(err, root) {
        if (err) {
          reject(err);
        }
        let TestBytes = root.lookupType("TestBytes");
        resolve(TestBytes);
      });
    });
    let data = new Uint8Array(2);
    data[0] = 2;
    data[1] = 1;
    let payload = {
      "bytes2Field": {
        "data": data
      }
    };
    let message = TestBytes.create(payload);
    let buffer = TestBytes.encode(message).finish();
    let result = await contractInstance.getTestBytesBytes2("0x" + buffer.toString('hex'));
    console.log(result);
    assert.equal('0x0201', result);
  })
});
