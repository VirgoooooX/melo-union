import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:provider_kugou/provider_kugou.dart';
import 'package:provider_netease/provider_netease.dart';
import 'package:provider_qq/provider_qq.dart';

import '../kugou_session_store.dart';
import '../netease_session_store.dart';
import '../qq_music_session_store.dart';

final class AccountVaultService {
  AccountVaultService({
    required this.neteaseSessionStore,
    required this.qqMusicSessionStore,
    required this.kugouSessionStore,
    Pbkdf2? kdf,
    AesGcm? cipher,
    Random? random,
  })  : _kdf = kdf ??
            Pbkdf2(
              macAlgorithm: Hmac.sha256(),
              iterations: 210000,
              bits: 256,
            ),
        _cipher = cipher ?? AesGcm.with256bits(),
        _random = random ?? Random.secure();

  final NeteaseSessionStore neteaseSessionStore;
  final QqMusicSessionStore qqMusicSessionStore;
  final KugouSessionStore kugouSessionStore;
  final Pbkdf2 _kdf;
  final AesGcm _cipher;
  final Random _random;

  Future<Uint8List?> exportEncrypted(String password) async {
    final payload = <String, Object?>{
      'schemaVersion': 1,
      'accounts': await _readAccounts(),
    };
    final accounts = payload['accounts']! as Map<String, Object?>;
    if (accounts.isEmpty) return null;
    return _encrypt(utf8.encode(jsonEncode(payload)), password);
  }

  Future<void> importEncrypted(Uint8List encrypted, String password) async {
    final decrypted = await _decrypt(encrypted, password);
    final decoded = jsonDecode(utf8.decode(decrypted));
    if (decoded is! Map) {
      throw const FormatException('Account vault must be a JSON object.');
    }
    final schemaVersion = decoded['schemaVersion'] as int? ?? 0;
    if (schemaVersion != 1) {
      throw FormatException(
          'Unsupported account vault schema: $schemaVersion.');
    }
    final accounts = Map<String, Object?>.from(decoded['accounts'] as Map);
    final netease = Map<String, Object?>.from(
        accounts['netease_cloud_music'] as Map? ?? {});
    final qq = Map<String, Object?>.from(accounts['qq_music'] as Map? ?? {});
    final kugou = Map<String, Object?>.from(accounts['kugou'] as Map? ?? {});

    final neteaseCookie = netease['cookie']?.toString();
    if (neteaseCookie != null && neteaseCookie.trim().isNotEmpty) {
      await neteaseSessionStore.write(
        NeteaseCredentials(
          cookie: neteaseCookie,
          userId: _blankToNull(netease['userId']?.toString()),
        ),
      );
    }

    final qqCookie = qq['cookie']?.toString();
    if (qqCookie != null && qqCookie.trim().isNotEmpty) {
      await qqMusicSessionStore.write(QqMusicCredentials(cookie: qqCookie));
    }

    final sessionJson = kugou['session'];
    if (sessionJson is Map) {
      await kugouSessionStore.write(
        KugouSession.fromJson(Map<String, dynamic>.from(sessionJson)),
      );
    }
  }

  Future<Map<String, Object?>> _readAccounts() async {
    final accounts = <String, Object?>{};
    final netease = await neteaseSessionStore.read();
    if (netease?.hasCookie ?? false) {
      accounts['netease_cloud_music'] = {
        'cookie': netease!.cookie,
        if (netease.userId != null) 'userId': netease.userId,
      };
    }
    final qq = await qqMusicSessionStore.read();
    if (qq?.hasCookie ?? false) {
      accounts['qq_music'] = {'cookie': qq!.cookie};
    }
    final kugou = await kugouSessionStore.read();
    if (kugou != null) {
      accounts['kugou'] = {'session': kugou.toJson()};
    }
    return accounts;
  }

  Future<Uint8List> _encrypt(List<int> plainBytes, String password) async {
    _requirePassword(password);
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final key = await _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final box = await _cipher.encrypt(plainBytes, secretKey: key, nonce: nonce);
    final envelope = {
      'schemaVersion': 1,
      'kdf': 'pbkdf2-hmac-sha256',
      'cipher': 'aes-gcm',
      'iterations': 210000,
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'mac': base64Encode(box.mac.bytes),
      'ciphertext': base64Encode(box.cipherText),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  Future<Uint8List> _decrypt(Uint8List encrypted, String password) async {
    _requirePassword(password);
    final decoded = jsonDecode(utf8.decode(encrypted));
    if (decoded is! Map) {
      throw const FormatException('Account vault envelope must be an object.');
    }
    final envelope = Map<String, Object?>.from(decoded);
    if (envelope['schemaVersion'] != 1 ||
        envelope['kdf'] != 'pbkdf2-hmac-sha256' ||
        envelope['cipher'] != 'aes-gcm') {
      throw const FormatException('Unsupported account vault envelope.');
    }
    final key = await _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: base64Decode(envelope['salt']! as String),
    );
    final box = SecretBox(
      base64Decode(envelope['ciphertext']! as String),
      nonce: base64Decode(envelope['nonce']! as String),
      mac: Mac(base64Decode(envelope['mac']! as String)),
    );
    return Uint8List.fromList(
      await _cipher.decrypt(box, secretKey: key),
    );
  }

  Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _random.nextInt(256)),
    );
  }

  void _requirePassword(String password) {
    if (password.trim().isEmpty) {
      throw ArgumentError.value(password, 'password', 'Password is required.');
    }
  }

  String? _blankToNull(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }
}
