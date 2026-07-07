import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:music_data/music_data.dart';

import '../app_version.dart';

final class BackupManifest {
  const BackupManifest({
    required this.backupVersion,
    required this.createdAt,
    required this.appVersion,
    required this.deviceName,
    required this.platform,
    required this.includesAccountVault,
    required this.snapshotSchemaVersion,
  });

  final int backupVersion;
  final DateTime createdAt;
  final String appVersion;
  final String deviceName;
  final String platform;
  final bool includesAccountVault;
  final int snapshotSchemaVersion;

  Map<String, Object?> toJson() {
    return {
      'backupVersion': backupVersion,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'appVersion': appVersion,
      'deviceName': deviceName,
      'platform': platform,
      'includesAccountVault': includesAccountVault,
      'snapshotSchemaVersion': snapshotSchemaVersion,
    };
  }

  factory BackupManifest.fromJson(Map<String, Object?> json) {
    return BackupManifest(
      backupVersion: json['backupVersion'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
      appVersion: json['appVersion']?.toString() ?? 'unknown',
      deviceName: json['deviceName']?.toString() ?? 'unknown',
      platform: json['platform']?.toString() ?? 'unknown',
      includesAccountVault: json['includesAccountVault'] as bool? ?? false,
      snapshotSchemaVersion: json['snapshotSchemaVersion'] as int? ?? 0,
    );
  }
}

final class BackupArchivePayload {
  const BackupArchivePayload({
    required this.manifest,
    required this.snapshot,
    this.accountVaultBytes,
  });

  final BackupManifest manifest;
  final MeloDataSnapshot snapshot;
  final Uint8List? accountVaultBytes;
}

final class BackupArchiveService {
  const BackupArchiveService({
    MeloJsonCodec codec = const MeloJsonCodec(),
  }) : _codec = codec;

  static const currentBackupVersion = 1;

  final MeloJsonCodec _codec;

  Uint8List createArchive({
    required MeloDataSnapshot snapshot,
    required String deviceName,
    required String platform,
    Uint8List? accountVaultBytes,
    DateTime? now,
  }) {
    final createdAt = (now ?? DateTime.now()).toUtc();
    final manifest = BackupManifest(
      backupVersion: currentBackupVersion,
      createdAt: createdAt,
      appVersion: '$appDisplayVersion ($appVersion)',
      deviceName: deviceName,
      platform: platform,
      includesAccountVault: accountVaultBytes != null,
      snapshotSchemaVersion: MeloJsonCodec.schemaVersion,
    );
    final archive = Archive()
      ..addFile(_jsonFile('manifest.json', manifest.toJson()))
      ..addFile(_jsonFile('snapshot.json', _codec.encodeSnapshot(snapshot)));
    if (accountVaultBytes != null) {
      archive.addFile(
        ArchiveFile(
          'account_vault.enc',
          accountVaultBytes.length,
          accountVaultBytes,
        ),
      );
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  BackupArchivePayload readArchive(List<int> bytes) {
    return _readArchive(bytes, allowWrappedBackup: true);
  }

  BackupArchivePayload _readArchive(
    List<int> bytes, {
    required bool allowWrappedBackup,
  }) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final manifestFile = archive.findFile('manifest.json');
    final snapshotFile = archive.findFile('snapshot.json');
    if (manifestFile == null || snapshotFile == null) {
      if (allowWrappedBackup) {
        final wrappedPayload = _tryReadWrappedBackup(archive);
        if (wrappedPayload != null) {
          return wrappedPayload;
        }
      }
      if (manifestFile == null) {
        throw const FormatException('Backup archive is missing manifest.json.');
      }
      throw const FormatException('Backup archive is missing snapshot.json.');
    }
    final manifest = BackupManifest.fromJson(_jsonMap(manifestFile.content));
    if (manifest.backupVersion != currentBackupVersion) {
      throw FormatException(
        'Unsupported backup version: ${manifest.backupVersion}.',
      );
    }
    if (manifest.snapshotSchemaVersion != MeloJsonCodec.schemaVersion) {
      throw FormatException(
        'Unsupported snapshot schema: ${manifest.snapshotSchemaVersion}.',
      );
    }
    final snapshot = _codec.decodeSnapshot(_jsonMap(snapshotFile.content));
    final accountFile = archive.findFile('account_vault.enc');
    return BackupArchivePayload(
      manifest: manifest,
      snapshot: snapshot,
      accountVaultBytes:
          accountFile == null ? null : _contentBytes(accountFile.content),
    );
  }

  BackupArchivePayload? _tryReadWrappedBackup(Archive archive) {
    final candidates = archive.files.where((file) => file.isFile).where((file) {
      final name = file.name.toLowerCase();
      return name.endsWith('.melobak') || name.endsWith('.zip');
    }).toList(growable: false);
    for (final candidate in candidates) {
      try {
        return _readArchive(
          _contentBytes(candidate.content),
          allowWrappedBackup: false,
        );
      } catch (_) {
        // Keep trying other archive entries; if none match, the outer archive
        // will surface the original missing-manifest error.
      }
    }
    return null;
  }

  ArchiveFile _jsonFile(String name, Map<String, Object?> json) {
    const encoder = JsonEncoder.withIndent('  ');
    final bytes = utf8.encode('${encoder.convert(json)}\n');
    return ArchiveFile(name, bytes.length, bytes);
  }

  Map<String, Object?> _jsonMap(Object? content) {
    final bytes = _contentBytes(content);
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const FormatException('Backup JSON file must be an object.');
    }
    return Map<String, Object?>.from(decoded);
  }

  Uint8List _contentBytes(Object? content) {
    if (content is Uint8List) {
      return content;
    }
    if (content is List<int>) {
      return Uint8List.fromList(content);
    }
    throw const FormatException('Backup archive file is not bytes.');
  }
}
