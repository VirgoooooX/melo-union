import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

const _part1Indexes = [23, 14, 6, 36, 16, 7, 19];
const _part2Indexes = [16, 1, 32, 12, 19, 27, 8, 5];
const _scrambleValues = [
  89,
  39,
  179,
  150,
  218,
  82,
  58,
  252,
  177,
  52,
  186,
  123,
  120,
  64,
  242,
  133,
  143,
  161,
  121,
  179,
];

const _ag1RequestKey = [
  0xbd,
  0x30,
  0x5f,
  0x10,
  0xd0,
  0xff,
  0x74,
  0xb6,
  0xef,
  0x54,
  0xda,
  0xb8,
  0x35,
  0xb5,
  0xe1,
  0xcf,
];

const _ag1ResponseKey = [
  0x7a,
  0x3f,
  0x8c,
  0x1d,
  0x5e,
  0x9b,
  0x2f,
  0x0a,
  0x6c,
  0x4d,
  0x7e,
  0x8b,
  0x1f,
  0x3a,
  0x5c,
  0x9d,
  0x0e,
  0x2b,
  0x6f,
  0x4a,
  0x81,
];

final _secureRandom = Random.secure();
final _ag1RequestCipher = AesGcm.with128bits();

String qqMusicZzcSign(String payload) {
  final hash =
      crypto.sha1.convert(utf8.encode(payload)).toString().toUpperCase();
  final part1 = _part1Indexes.map((index) => hash[index]).join();
  final part2 = _part2Indexes.map((index) => hash[index]).join();
  final scrambled = <int>[
    for (var i = 0; i < _scrambleValues.length; i++)
      _scrambleValues[i] ^
          int.parse(hash.substring(i * 2, i * 2 + 2), radix: 16),
  ];
  final part3 = base64Encode(scrambled).replaceAll(RegExp(r'[\\/+=]'), '');
  return 'zzc$part1$part3$part2'.toLowerCase();
}

Future<String> encodeQqMusicAg1Request(
  String payload, {
  List<int>? nonce,
}) async {
  final requestNonce =
      nonce ?? List<int>.generate(12, (_) => _secureRandom.nextInt(256));
  if (requestNonce.length != 12) {
    throw ArgumentError.value(nonce, 'nonce', 'AG1 nonce must be 12 bytes.');
  }
  final box = await _ag1RequestCipher.encrypt(
    utf8.encode(payload),
    secretKey: SecretKey(_ag1RequestKey),
    nonce: requestNonce,
  );
  return base64Encode([
    ...requestNonce,
    ...box.cipherText,
    ...box.mac.bytes,
  ]);
}

String decodeQqMusicAg1Response(List<int> data) {
  final decoded = <int>[
    for (var i = 0; i < data.length; i++)
      data[i] ^ _ag1ResponseKey[i % _ag1ResponseKey.length],
  ];
  return utf8.decode(decoded);
}

List<int> encodeQqMusicAg1Response(String payload) {
  final encoded = utf8.encode(payload);
  return [
    for (var i = 0; i < encoded.length; i++)
      encoded[i] ^ _ag1ResponseKey[i % _ag1ResponseKey.length],
  ];
}
