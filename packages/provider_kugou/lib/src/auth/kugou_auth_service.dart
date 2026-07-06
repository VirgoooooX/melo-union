import '../api/kugou_api_client.dart';
import 'kugou_qr_login_service.dart';
import 'kugou_session.dart';
import 'kugou_session_manager.dart';

final class KugouAuthService {
  KugouAuthService({
    required KugouSessionManager sessionManager,
    required KugouQrLoginService qrLoginService,
    KugouApiClient? apiClient,
  })  : _sessionManager = sessionManager,
        _qrLoginService = qrLoginService,
        _apiClient = apiClient;

  final KugouSessionManager _sessionManager;
  final KugouQrLoginService _qrLoginService;
  final KugouApiClient? _apiClient;

  Future<bool> get isAuthenticated async {
    final session = await _sessionManager.getSession();
    return session != null;
  }

  bool get isAuthenticatedSync => _sessionManager.isAuthenticated;

  Future<KugouSession?> get currentSession async {
    return _sessionManager.getSession();
  }

  Future<KugouQrLoginSession> createQrLoginSession() {
    return _qrLoginService.createQrLoginSession();
  }

  Future<KugouQrLoginResult> checkQrLoginSession(
      KugouQrLoginSession session) async {
    final result = await _qrLoginService.checkQrLoginSession(session);
    if (result.status == KugouQrLoginStatus.authorized &&
        result.session != null) {
      // The QR login service may generate synthetic device identifiers.
      // Override with stable device details from the session manager
      // so the Android gateway doesn't reject requests.
      final details = await _sessionManager.getOrCreateDeviceDetails();
      final stableSession = KugouSession(
        userId: result.session!.userId,
        token: result.session!.token,
        deviceId: details.deviceId,
        mid: details.mid,
        deviceFingerprint: details.fingerprint,
        installGuid: details.installGuid,
        installMac: details.installMac,
        installDev: details.installDev,
        vipToken: result.session!.vipToken,
        vipType: result.session!.vipType,
        refreshMetadata: result.session!.refreshMetadata,
        updatedAt: result.session!.updatedAt,
      );
      await _sessionManager.updateSession(stableSession);

      // Post-login device registration.  This registers the device identity
      // with the Kugou risk service so the Android gateway accepts our
      // subsequent requests.  Failure is non-fatal — the QR login result is
      // still returned as authorized.
      if (_apiClient != null) {
        try {
          await _apiClient.registerWebDevice();
        } catch (_) {
          // Device registration failures are non-fatal; the session can still
          // use the login device cookie and gateway fallback paths.
        }
      }
      final currentSession = await _sessionManager.getSession();
      return KugouQrLoginResult(
        status: result.status,
        session: currentSession ?? stableSession,
        message: result.message,
      );
    }
    return result;
  }

  Future<void> logout() async {
    await _sessionManager.clearSession();
  }
}
