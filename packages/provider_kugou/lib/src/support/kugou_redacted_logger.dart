final class KugouRedactedLogger {
  const KugouRedactedLogger();

  void logRequest(String method, Uri uri, Map<String, String>? headers) {
    // Redacted logs for security. In production this would write to a logger stream.
  }

  void logResponse(int statusCode, String body) {
    // print('[KugouAPI] Response: HTTP $statusCode');
  }

  Uri redactUri(Uri uri) {
    if (!uri.hasQuery) return uri;
    final queryParams = Map<String, String>.from(uri.queryParameters);
    for (final key in queryParams.keys) {
      if (_isSensitiveKey(key)) {
        queryParams[key] = '***';
      }
    }
    return uri.replace(queryParameters: queryParams);
  }

  String redactValue(String key, String value) {
    if (_isSensitiveKey(key)) {
      return '***';
    }
    return value;
  }

  bool _isSensitiveKey(String key) {
    final lower = key.toLowerCase();
    return lower.contains('token') ||
        lower.contains('cookie') ||
        lower.contains('password') ||
        lower.contains('session') ||
        lower.contains('userid') ||
        lower.contains('mid') ||
        lower.contains('uuid') ||
        lower.contains('device') ||
        lower.contains('sign') ||
        lower.contains('signature');
  }
}
