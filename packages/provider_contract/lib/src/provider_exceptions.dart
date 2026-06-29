import 'provider_capability.dart';
import 'provider_id.dart';
import 'provider_models.dart';

class ProviderException implements Exception {
  const ProviderException({
    required this.providerId,
    required this.message,
  });

  final ProviderId providerId;
  final String message;

  @override
  String toString() => '$runtimeType(${providerId.value}): $message';
}

final class CapabilityUnavailableException extends ProviderException {
  const CapabilityUnavailableException({
    required super.providerId,
    required this.capability,
    required super.message,
  });

  final ProviderCapability capability;
}

final class AuthenticationRequiredException extends ProviderException {
  const AuthenticationRequiredException({
    required super.providerId,
    required super.message,
  });
}

final class ProviderDisabledException extends ProviderException {
  const ProviderDisabledException({
    required super.providerId,
    required super.message,
  });
}

final class ProviderTrackNotFoundException extends ProviderException {
  const ProviderTrackNotFoundException({
    required super.providerId,
    required this.track,
    required super.message,
  });

  final ProviderTrackRef track;
}
