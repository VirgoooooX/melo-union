final class KugouApiFailure {
  const KugouApiFailure({
    required this.code,
    required this.message,
  });

  final int code;
  final String message;

  @override
  String toString() => 'KugouApiFailure(code: $code, message: $message)';
}
