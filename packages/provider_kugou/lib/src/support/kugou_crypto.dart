import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/export.dart' as pc;

const String kugouLitePublicKey = '''
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDECi0Np2UR87scwrvTr72L6oO01rBbbBPriSDFPxr3Z5syug0O24QyQO8bg27+0+4kBzTBTBOZ/WWU0WryL1JSXRTXLgFVxtzIY41Pe7lPOgsfTCn5kZcvKhYKJesKnnJDNr5/abvTGf+rHG3YRwsCHcQ08/q6ifSioBszvb3QiwIDAQAB
-----END PUBLIC KEY-----
''';

final class KugouEncryptedPayload {
  const KugouEncryptedPayload({
    required this.base64Body,
    required this.aesSeed,
    required this.key,
    required this.iv,
  });

  final String base64Body;
  final String aesSeed;
  final Uint8List key;
  final Uint8List iv;
}

KugouEncryptedPayload kugouEncryptRegisterPayload(Object payload) {
  final aesSeed = _randomLowerString(6);
  final digest = crypto.md5.convert(utf8.encode(aesSeed)).toString();
  final key = Uint8List.fromList(utf8.encode(digest.substring(0, 16)));
  final iv = Uint8List.fromList(utf8.encode(digest.substring(16, 32)));
  final jsonText = jsonEncode(payload);
  final encrypted =
      kugouAesCbcEncrypt(Uint8List.fromList(utf8.encode(jsonText)), key, iv);
  return KugouEncryptedPayload(
    base64Body: base64Encode(encrypted),
    aesSeed: aesSeed,
    key: key,
    iv: iv,
  );
}

Map<String, dynamic> kugouDecryptRegisterResponse(
  List<int> responseBytes,
  Uint8List key,
  Uint8List iv,
) {
  final trimmed = utf8.decode(responseBytes, allowMalformed: true).trim();
  if (trimmed.startsWith('{')) {
    return jsonDecode(trimmed) as Map<String, dynamic>;
  }

  Uint8List encrypted;
  try {
    encrypted = Uint8List.fromList(base64Decode(trimmed));
  } catch (_) {
    encrypted = Uint8List.fromList(responseBytes);
  }
  final decrypted = kugouAesCbcDecrypt(encrypted, key, iv);
  return jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;
}

Uint8List kugouAesCbcEncrypt(Uint8List plain, Uint8List key, Uint8List iv) {
  final padded = _pkcs7Pad(plain, 16);
  final cipher = pc.CBCBlockCipher(pc.AESEngine())
    ..init(true, pc.ParametersWithIV(pc.KeyParameter(key), iv));
  return _processBlocks(cipher, padded);
}

Uint8List kugouAesCbcDecrypt(Uint8List encrypted, Uint8List key, Uint8List iv) {
  final cipher = pc.CBCBlockCipher(pc.AESEngine())
    ..init(false, pc.ParametersWithIV(pc.KeyParameter(key), iv));
  final plain = _processBlocks(cipher, encrypted);
  return _pkcs7Unpad(plain);
}

String kugouRsaPkcs1Hex(Object payload) {
  final publicKey = _parsePublicKey(kugouLitePublicKey);
  final cipher = pc.PKCS1Encoding(pc.RSAEngine())
    ..init(true, pc.PublicKeyParameter<pc.RSAPublicKey>(publicKey));
  final input = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  return _hex(cipher.process(input)).toUpperCase();
}

String kugouRsaNoPaddingHex(Object payload) {
  final publicKey = _parsePublicKey(kugouLitePublicKey);
  final input = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  final padded = Uint8List(128);
  padded.setRange(0, input.length, input);
  final message = _bigIntFromBytes(padded);
  final encrypted = message.modPow(publicKey.exponent!, publicKey.modulus!);
  return _bigIntToFixedHex(encrypted, 128).toLowerCase();
}

Uint8List _processBlocks(pc.BlockCipher cipher, Uint8List input) {
  if (input.length % cipher.blockSize != 0) {
    throw ArgumentError('AES-CBC input length must be block aligned.');
  }
  final out = Uint8List(input.length);
  for (var offset = 0; offset < input.length; offset += cipher.blockSize) {
    cipher.processBlock(input, offset, out, offset);
  }
  return out;
}

Uint8List _pkcs7Pad(Uint8List input, int blockSize) {
  final pad = blockSize - input.length % blockSize;
  return Uint8List.fromList([...input, ...List<int>.filled(pad, pad)]);
}

Uint8List _pkcs7Unpad(Uint8List input) {
  if (input.isEmpty) throw FormatException('Empty PKCS7 payload.');
  final pad = input.last;
  if (pad <= 0 || pad > input.length) {
    throw FormatException('Invalid PKCS7 padding.');
  }
  return Uint8List.sublistView(input, 0, input.length - pad);
}

pc.RSAPublicKey _parsePublicKey(String pem) {
  final base64Text = pem
      .replaceAll('-----BEGIN PUBLIC KEY-----', '')
      .replaceAll('-----END PUBLIC KEY-----', '')
      .replaceAll(RegExp(r'\s+'), '');
  final bytes = Uint8List.fromList(base64Decode(base64Text));
  final reader = _DerReader(bytes);
  final spki = _DerReader(reader.readSequence());
  spki.readSequence(); // algorithm identifier
  final bitString = spki.readBitString();
  final rsaReader = _DerReader(bitString);
  final rsaSeq = _DerReader(rsaReader.readSequence());
  final modulus = _bigIntFromBytes(rsaSeq.readInteger());
  final exponent = _bigIntFromBytes(rsaSeq.readInteger());
  return pc.RSAPublicKey(modulus, exponent);
}

BigInt _bigIntFromBytes(Uint8List bytes) {
  var result = BigInt.zero;
  for (final byte in bytes) {
    result = (result << 8) | BigInt.from(byte);
  }
  return result;
}

String _hex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

String _bigIntToFixedHex(BigInt value, int length) {
  var hex = value.toRadixString(16);
  if (hex.length.isOdd) hex = '0$hex';
  final targetLength = length * 2;
  if (hex.length > targetLength) {
    hex = hex.substring(hex.length - targetLength);
  }
  return hex.padLeft(targetLength, '0');
}

String _randomLowerString(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyz';
  final random = Random.secure();
  return List.generate(length, (_) => chars[random.nextInt(chars.length)])
      .join();
}

final class _DerReader {
  _DerReader(this._bytes);

  final Uint8List _bytes;
  int _offset = 0;

  Uint8List readSequence() => _readValue(0x30);

  Uint8List readInteger() => _readValue(0x02);

  Uint8List readBitString() {
    final value = _readValue(0x03);
    if (value.isEmpty || value.first != 0) {
      throw FormatException('Unsupported DER bit string.');
    }
    return Uint8List.sublistView(value, 1);
  }

  Uint8List _readValue(int expectedTag) {
    if (_offset >= _bytes.length || _bytes[_offset++] != expectedTag) {
      throw FormatException('Unexpected DER tag.');
    }
    final length = _readLength();
    final start = _offset;
    _offset += length;
    if (_offset > _bytes.length) {
      throw FormatException('Invalid DER length.');
    }
    return Uint8List.sublistView(_bytes, start, start + length);
  }

  int _readLength() {
    final first = _bytes[_offset++];
    if (first < 0x80) return first;
    final count = first & 0x7f;
    var length = 0;
    for (var i = 0; i < count; i++) {
      length = (length << 8) | _bytes[_offset++];
    }
    return length;
  }
}
