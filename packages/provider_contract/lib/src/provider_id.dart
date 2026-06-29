final class ProviderId {
  ProviderId(String value) : value = _validate(value);

  final String value;

  static final RegExp _pattern = RegExp(r'^[a-z]+(?:_[a-z]+)*$');

  static String _validate(String value) {
    if (!_pattern.hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'ProviderId must use lowercase ASCII segments joined by underscores.',
      );
    }
    return value;
  }

  @override
  bool operator ==(Object other) => other is ProviderId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
