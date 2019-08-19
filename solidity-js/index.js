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

module.exports = {
  importTypes: function (proto) {
    proto.solidity['address'].prototype.saveAsBytes = function(data) {
      let result = saveAsBytes(data, "biguint");
      this.setData(result);
    }

    proto.solidity['address'].prototype.toAddress = function() {
      let result = this.getData();
      return "0x" + Buffer.from(result).toString('hex');
    }

    for (let i = 8; i <= 256; i += 8) {
      proto.solidity['uint' + i].prototype.saveAsBytes = function(data) {
        let result = saveAsBytes(data, "biguint");
        this.setData(result);
      }

      proto.solidity['uint' + i].prototype.toBigInt = function() {
        let result = this.getData();
        return toBigInt(result, "biguint");
      }

      proto.solidity['uint' + i].prototype.toNumber = function() {
        let result = this.getData();
        return toBigInt(result, "biguint").toNumber();
      }

      proto.solidity['int' + i].prototype.saveAsBytes = function(data) {
        let result = saveAsBytes(data, "bigint");
        this.setData(result);
      }

      proto.solidity['int' + i].prototype.toBigInt = function() {
        let result = this.getData();
        return toBigInt(result, "bigint");
      }

      proto.solidity['int' + i].prototype.toNumber = function() {
        let result = this.getData();
        return toBigInt(result, "bigint").toNumber();
      }
    }

    for (let i = 1; i <= 32; i++) {
      proto.solidity['bytes' + i].prototype.toHex = function() {
        let result = this.getData();
        return "0x" + Buffer.from(result).toString('hex');
      }
    }
    return proto;
  }
}
