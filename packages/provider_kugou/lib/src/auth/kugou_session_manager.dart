import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'kugou_session.dart';
import 'kugou_secure_session_store.dart';

final class KugouSessionManager {
  KugouSessionManager({
    required KugouSecureSessionStore secureStore,
    KugouSession? initialSession,
    String Function()? generateUuid,
  })  : _secureStore = secureStore,
        _currentSession = initialSession,
        _initialized = initialSession != null,
        _generateUuid = generateUuid ?? _defaultUuidGenerator;

  final KugouSecureSessionStore _secureStore;
  final String Function() _generateUuid;

  KugouSession? _currentSession;
  bool _initialized = false;
  Future<void>? _refreshFuture;

  bool get isAuthenticated => _currentSession != null;

  static String _defaultUuidGenerator() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _randomKugouString([int length = 16]) {
    const chars = '1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Generates a Kugou-compatible device MID.
  ///
  /// Matches music-lib's calculateKugouMID:
  ///   1. Generate a UUID-format GUID (with hyphens, version 4)
  ///   2. MD5-hash the GUID string
  ///   3. Convert MD5 bytes to a decimal big-number string
  static String calculateKugouMid(String seed) {
    final hash = md5.convert(utf8.encode(seed));
    final bigInt = hash.bytes.fold<BigInt>(
        BigInt.zero, (prev, byte) => (prev << 8) | BigInt.from(byte));
    return bigInt.toString();
  }

  static String calculateKugouUuid(String dfid, String mid) {
    return md5.convert(utf8.encode('$dfid$mid')).toString();
  }

  Future<KugouSession?> getSession() async {
    if (!_initialized) {
      await _init();
    }
    return _currentSession;
  }

  Future<void> _init() async {
    _currentSession = await _secureStore.read();
    _initialized = true;
  }

  Future<void> updateSession(KugouSession session) async {
    _currentSession = session;
    _cachedDeviceId = session.deviceId;
    _cachedMid = session.mid;
    _cachedFingerprint = session.deviceFingerprint;
    _cachedInstallGuid = session.installGuid ?? session.deviceId;
    _cachedInstallMac = session.installMac;
    _cachedInstallDev = session.installDev;
    await _secureStore.write(session);
  }

  /// Updates the stored device fingerprint (dfid), e.g. after server-side
  /// device registration returns a real dfid.
  Future<void> updateDeviceFingerprint(String fingerprint) async {
    final normalized = fingerprint.trim().isEmpty ? '-' : fingerprint.trim();
    _cachedFingerprint = normalized;
    final session = _currentSession;
    if (session != null) {
      final installGuid =
          session.installGuid ?? _cachedInstallGuid ?? session.deviceId;
      final dfidMid = normalized == '-' ? null : calculateKugouMid(normalized);
      final sessionMid = session.mid.trim();
      final nextMid =
          sessionMid.isEmpty || (dfidMid != null && sessionMid == dfidMid)
              ? calculateKugouMid(installGuid)
              : session.mid;
      final updated = KugouSession(
        userId: session.userId,
        token: session.token,
        deviceId: session.deviceId.trim().isEmpty ? '-' : session.deviceId,
        mid: nextMid,
        deviceFingerprint: normalized,
        installGuid: installGuid,
        installMac: session.installMac ?? _cachedInstallMac,
        installDev: session.installDev ?? _cachedInstallDev,
        vipToken: session.vipToken,
        vipType: session.vipType,
        refreshMetadata: session.refreshMetadata,
        updatedAt: session.updatedAt,
      );
      await _secureStore.write(updated);
      _currentSession = updated;
    }
  }

  Future<void> clearSession() async {
    _currentSession = null;
    await _secureStore.clear();
  }

  Future<KugouSession?> getOrRefreshSession() async {
    final session = await getSession();
    if (session == null) return null;

    if (_isNearExpiry(session)) {
      await refreshSession();
    }
    return _currentSession;
  }

  bool _isNearExpiry(KugouSession session) {
    if (session.updatedAt == null) return true;
    final age = DateTime.now().difference(session.updatedAt!);
    return age.inDays >= 6;
  }

  Future<void> refreshSession() async {
    if (_refreshFuture != null) {
      await _refreshFuture;
      return;
    }

    final completer = Future<void>(() async {
      final session = _currentSession;
      if (session == null) return;

      // In a real client refresh metadata is used to fetch a new token.
      // Here we update the updatedAt timestamp to represent session activity.
      final updated = KugouSession(
        userId: session.userId,
        token: session.token,
        deviceId: session.deviceId,
        mid: session.mid,
        deviceFingerprint: session.deviceFingerprint,
        installGuid: session.installGuid,
        installMac: session.installMac,
        installDev: session.installDev,
        vipToken: session.vipToken,
        vipType: session.vipType,
        refreshMetadata: session.refreshMetadata,
        updatedAt: DateTime.now(),
      );
      await updateSession(updated);
    });

    _refreshFuture = completer;
    try {
      await completer;
    } finally {
      _refreshFuture = null;
    }
  }

  String? _cachedDeviceId;
  String? _cachedMid;
  String? _cachedFingerprint;
  String? _cachedInstallGuid;
  String? _cachedInstallMac;
  String? _cachedInstallDev;

  Future<
      ({
        String deviceId,
        String mid,
        String fingerprint,
        String installGuid,
        String installMac,
        String installDev,
        String uuid,
      })> getOrCreateDeviceDetails() async {
    final session = await getSession();
    if (session != null) {
      final installGuid = session.installGuid ?? session.deviceId;
      final installMac = session.installMac ?? _randomKugouString(32);
      final installDev = session.installDev ?? _randomKugouString();
      final fingerprint = session.deviceFingerprint.trim().isEmpty
          ? '-'
          : session.deviceFingerprint;
      final mid = session.mid.trim().isEmpty
          ? calculateKugouMid(installGuid)
          : session.mid;
      _cachedDeviceId = session.deviceId;
      _cachedMid = mid;
      _cachedFingerprint = fingerprint;
      _cachedInstallGuid = installGuid;
      _cachedInstallMac = installMac;
      _cachedInstallDev = installDev;
      return (
        deviceId: session.deviceId,
        mid: mid,
        fingerprint: fingerprint,
        installGuid: installGuid,
        installMac: installMac,
        installDev: installDev,
        uuid: '-',
      );
    }

    if (_cachedDeviceId != null) {
      final fingerprint = _cachedFingerprint ?? '-';
      final mid = _cachedMid ?? calculateKugouMid(_cachedInstallGuid!);
      return (
        deviceId: _cachedDeviceId!,
        mid: mid,
        fingerprint: fingerprint,
        installGuid: _cachedInstallGuid!,
        installMac: _cachedInstallMac!,
        installDev: _cachedInstallDev!,
        uuid: '-',
      );
    }

    _cachedInstallGuid = _generateUuid();
    _cachedInstallMac = _generateUuid();
    _cachedInstallDev = _randomKugouString();
    _cachedFingerprint = '-';
    _cachedMid = calculateKugouMid(_cachedInstallGuid!);
    _cachedDeviceId = '-';
    return (
      deviceId: _cachedDeviceId!,
      mid: _cachedMid!,
      fingerprint: _cachedFingerprint!,
      installGuid: _cachedInstallGuid!,
      installMac: _cachedInstallMac!,
      installDev: _cachedInstallDev!,
      uuid: '-',
    );
  }
}
