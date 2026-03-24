import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/api/v2/setting_v2.dart';
import 'package:onepanel_client/data/models/setting_models.dart';

abstract class SecurityVerificationRepository {
  Future<MfaOtpInfo> loadMfaInfo();

  Future<void> bindMfa({
    required String code,
    required String interval,
    required String secret,
  });
}

class MfaOtpInfo {
  const MfaOtpInfo({
    required this.secret,
    required this.qrImage,
    required this.enabled,
  });

  final String secret;
  final String qrImage;
  final bool enabled;
}

class ApiSecurityVerificationRepository
    implements SecurityVerificationRepository {
  ApiSecurityVerificationRepository({SettingV2Api? api}) : _api = api;

  SettingV2Api? _api;

  Future<void> _ensureApiClient() async {
    if (_api != null) {
      return;
    }
    final manager = ApiClientManager.instance;
    _api = await manager.getSettingApi();
  }

  @override
  Future<MfaOtpInfo> loadMfaInfo() async {
    await _ensureApiClient();
    final statusResponse = await _api!.getMfaStatus();
    final otpResponse = await _api!.loadMfaInfo(
      const MfaCredential(code: '', interval: '30', secret: ''),
    );
    final status = statusResponse.data;
    final otp = otpResponse.data;
    return MfaOtpInfo(
      secret: otp?.secret ?? status?.secret ?? '',
      qrImage: otp?.qrImage ?? '',
      enabled: status?.enabled ?? false,
    );
  }

  @override
  Future<void> bindMfa({
    required String code,
    required String interval,
    required String secret,
  }) async {
    await _ensureApiClient();
    await _api!.bindMfa(
      MfaBindRequest(
        code: code,
        interval: interval,
        secret: secret,
      ),
    );
  }
}
