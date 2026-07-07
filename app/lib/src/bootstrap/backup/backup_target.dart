import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

final class BackupRemoteEntry {
  const BackupRemoteEntry({
    required this.name,
    required this.path,
    this.size,
    this.modifiedAt,
  });

  final String name;
  final String path;
  final int? size;
  final DateTime? modifiedAt;
}

abstract interface class BackupTarget {
  Future<void> testConnection();

  Future<List<BackupRemoteEntry>> listBackups();

  Future<void> uploadBackup(String name, Uint8List bytes);

  Future<Uint8List> downloadBackup(String path);

  Future<void> deleteBackup(String path);
}

final class LocalBackupTarget implements BackupTarget {
  const LocalBackupTarget({required this.directory});

  final Directory directory;

  @override
  Future<void> testConnection() async {
    await directory.create(recursive: true);
  }

  @override
  Future<List<BackupRemoteEntry>> listBackups() async {
    if (!await directory.exists()) return const [];
    final files = await directory
        .list()
        .where((entity) => entity is File && _isBackupFile(entity.path))
        .cast<File>()
        .toList();
    final entries = <BackupRemoteEntry>[];
    for (final file in files) {
      final stat = await file.stat();
      entries.add(
        BackupRemoteEntry(
          name: file.uri.pathSegments.last,
          path: file.path,
          size: stat.size,
          modifiedAt: stat.modified,
        ),
      );
    }
    entries.sort((a, b) => (b.modifiedAt ?? DateTime(1900))
        .compareTo(a.modifiedAt ?? DateTime(1900)));
    return entries;
  }

  @override
  Future<void> uploadBackup(String name, Uint8List bytes) async {
    await directory.create(recursive: true);
    await File('${directory.path}${Platform.pathSeparator}$name')
        .writeAsBytes(bytes);
  }

  @override
  Future<Uint8List> downloadBackup(String path) async {
    return File(path).readAsBytes();
  }

  @override
  Future<void> deleteBackup(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

final class WebDavConfig {
  const WebDavConfig({
    required this.baseUri,
    required this.username,
    required this.password,
    this.remoteDirectory = '/MeloUnion/backups/',
  });

  final Uri baseUri;
  final String username;
  final String password;
  final String remoteDirectory;

  Uri resolve(String path) {
    final normalizedDir =
        remoteDirectory.endsWith('/') ? remoteDirectory : '$remoteDirectory/';
    final root = baseUri.replace(
      path: _joinPath(baseUri.path, normalizedDir),
    );
    if (path.isEmpty) return root;
    return root.replace(path: _joinPath(root.path, path));
  }

  static String _joinPath(String left, String right) {
    final l = left.endsWith('/') ? left.substring(0, left.length - 1) : left;
    final r = right.startsWith('/') ? right.substring(1) : right;
    return '$l/$r';
  }
}

final class WebDavBackupTarget implements BackupTarget {
  WebDavBackupTarget({
    required this.config,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final WebDavConfig config;
  final http.Client _client;

  @override
  Future<void> testConnection() async {
    await _ensureDirectory();
  }

  @override
  Future<List<BackupRemoteEntry>> listBackups() async {
    await _ensureDirectory();
    final request = http.Request('PROPFIND', config.resolve(''))
      ..headers.addAll(_headers(depth: '1'));
    final response =
        await http.Response.fromStream(await _client.send(request));
    _throwIfFailed(response, 'Failed to list WebDAV backups.');
    final entries = _parsePropfind(response.body)
        .where((entry) => _isBackupFile(entry.name))
        .toList();
    entries.sort((a, b) => (b.modifiedAt ?? DateTime(1900))
        .compareTo(a.modifiedAt ?? DateTime(1900)));
    return entries;
  }

  @override
  Future<void> uploadBackup(String name, Uint8List bytes) async {
    await _ensureDirectory();
    final response = await _client.put(
      config.resolve(Uri.encodeComponent(name)),
      headers: _headers(),
      body: bytes,
    );
    _throwIfFailed(response, 'Failed to upload WebDAV backup.');
  }

  @override
  Future<Uint8List> downloadBackup(String path) async {
    final response =
        await _client.get(config.resolve(path), headers: _headers());
    _throwIfFailed(response, 'Failed to download WebDAV backup.');
    return response.bodyBytes;
  }

  @override
  Future<void> deleteBackup(String path) async {
    final response =
        await _client.delete(config.resolve(path), headers: _headers());
    _throwIfFailed(response, 'Failed to delete WebDAV backup.');
  }

  Future<void> _ensureDirectory() async {
    final response =
        await _client.request('MKCOL', config.resolve(''), headers: _headers());
    if (response.statusCode == 201 ||
        response.statusCode == 405 ||
        response.statusCode == 200) {
      return;
    }
    if (response.statusCode == 409) {
      throw const HttpException('WebDAV parent directory does not exist.');
    }
    _throwIfFailed(response, 'Failed to prepare WebDAV directory.');
  }

  Map<String, String> _headers({String? depth}) {
    return {
      'Authorization':
          'Basic ${base64Encode(utf8.encode('${config.username}:${config.password}'))}',
      if (depth != null) 'Depth': depth,
    };
  }

  List<BackupRemoteEntry> _parsePropfind(String body) {
    final matches = RegExp(
      r'<[^:>]*:?response[\s\S]*?<[^:>]*:?href>(.*?)</[^:>]*:?href>[\s\S]*?</[^:>]*:?response>',
      caseSensitive: false,
    ).allMatches(body);
    return [
      for (final match in matches)
        _entryFromResponse(
          Uri.decodeFull(match.group(1) ?? ''),
          match.group(0) ?? '',
        ),
    ].whereType<BackupRemoteEntry>().toList();
  }

  BackupRemoteEntry? _entryFromResponse(String href, String responseXml) {
    final parts = href.split('/').where((part) => part.isNotEmpty).toList();
    final name = parts.isEmpty ? null : parts.last;
    if (name == null || name.isEmpty || !_isBackupFile(name)) {
      return null;
    }
    return BackupRemoteEntry(
      name: name,
      path: name,
      size: _intTag(responseXml, 'getcontentlength'),
      modifiedAt: _dateTag(responseXml, 'getlastmodified'),
    );
  }

  int? _intTag(String xml, String tagName) {
    final value = _tagText(xml, tagName);
    if (value == null) return null;
    return int.tryParse(value.trim());
  }

  DateTime? _dateTag(String xml, String tagName) {
    final value = _tagText(xml, tagName);
    if (value == null) return null;
    try {
      return HttpDate.parse(value.trim());
    } on FormatException {
      return null;
    }
  }

  String? _tagText(String xml, String tagName) {
    final match = RegExp(
      '<[^:>]*:?' '$tagName' r'>(.*?)</[^:>]*:?' '$tagName' '>',
      caseSensitive: false,
    ).firstMatch(xml);
    return match?.group(1);
  }

  void _throwIfFailed(http.Response response, String message) {
    if ((response.statusCode >= 200 && response.statusCode < 300) ||
        response.statusCode == 207) {
      return;
    }
    throw HttpException('$message (${response.statusCode})');
  }
}

bool _isBackupFile(String name) {
  final lower = name.toLowerCase();
  return lower.endsWith('.zip') || lower.endsWith('.melobak');
}

extension on http.Client {
  Future<http.Response> request(
    String method,
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final request = http.Request(method, uri);
    if (headers != null) request.headers.addAll(headers);
    return http.Response.fromStream(await send(request));
  }
}
