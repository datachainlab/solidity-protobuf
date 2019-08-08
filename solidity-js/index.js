const BigNumber = require('bignumber.js');

function toBigInt(data, type) {
  let hex = "0x" + data.toString('hex');
  if (data instanceof Uint8Array) {
    hex = "0x" + Buffer.from(data).toString('hex');
  }
  let unsigned = BigNumber(hex);
  let firstByte = data[0];
  if (type == "biguint" || firstByte < 0x80) {
    return unsigned;
  } else {
    return BigNumber(2).pow(data.length * 8).minus(unsigned).negated();
  }
}

function saveAsBytes(number, type) {
  let bigNumber = number;
  if (Number.isInteger(number)) {
    bigNumber = BigNumber(number);
  }
  let isNegative = bigNumber.isNegative();
  if (isNegative) {
    let positive = bigNumber.negated();
    let digits = Math.ceil(positive.toString(16).length / 2.0);
    bigNumber = BigNumber(2).pow(digits * 8).minus(positive);
  }
  let convertedNumber = bigNumber.toString(16);
  if (convertedNumber.length % 2 != 0) {
    convertedNumber = "0" + convertedNumber;
  }
  if (type == "bigint" && !isNegative && convertedNumber[0] >= "8") {
    convertedNumber = "00" + convertedNumber;
  }
  let data = Uint8Array.from(Buffer.from(convertedNumber, 'hex'));
  return data;
}

var SolidityPrototypeExtension = {
  isAddress: function() {
    return this.type == "address";
  },
  toAddress: function () {
    return "0x" + this.data.toString('hex');
  },
  toNumber: function () {
    return toBigInt(this.data, this.type).toNumber();
  },
  toBigInt: function () {
    return toBigInt(this.data, this.type);
  },
  isBytes: function() {
    return this.type == "bytes";
  },
  toBytes: function () {
    return this.data;
  },
  saveAsBytes: function (number) {
    this.data = saveAsBytes(number, this.type);
  }
}
function Soliditize(proto, typename) {
  function SolidityType(properties) {
    this.type = typename;
  }
  Object.assign(SolidityType.prototype, SolidityPrototypeExtension);
  proto.ctor = SolidityType;
}
module.exports = {
  importTypes: function (proto) {
    Soliditize(proto.lookup("solidity.address"), "address");
    for (let i = 8; i <= 256; i += 8) {
      Soliditize(proto.lookup("solidity.uint" + i.toString()), "biguint");
      Soliditize(proto.lookup("solidity.int" + i.toString()), "bigint");
    }
    for (let i = 1; i <= 32; i++) {
      Soliditize(proto.lookup("solidity.bytes" + i), "bytes");
    }
  },
  importProtoFile: function (protobufjs) {
    let origResolvePath = protobufjs.Root.prototype.resolvePath;
    protobufjs.Root.prototype.resolvePath = function (filename, path) {
      if (path.endsWith("SolidityTypes.proto")) {
        return origResolvePath(filename, __dirname + "/../protobuf-solidity/src/protoc/include/SolidityTypes.proto");
      }
      return origResolvePath(filename, path);
    }
    return protobufjs;
  }
}
