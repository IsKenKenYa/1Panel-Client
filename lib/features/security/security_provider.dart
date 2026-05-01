import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/features/security/security_repository.dart';

class SecurityProvider extends ChangeNotifier with SafeChangeNotifier {
  SecurityProvider({SecurityVerificationRepository? repository})
      : _repository = repository ?? ApiSecurityVerificationRepository();

  final SecurityVerificationRepository _repository;
  bool _loading = false;
  String? _error;
  MfaOtpInfo? _mfaInfo;

  bool get loading => _loading;
  String? get error => _error;
  MfaOtpInfo? get mfaInfo => _mfaInfo;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _mfaInfo = await _repository.loadMfaInfo();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> bind({required String code}) async {
    final mfaInfo = _mfaInfo;
    if (mfaInfo == null) {
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.bindMfa(
        code: code,
        interval: '30',
        secret: mfaInfo.secret,
      );
      _mfaInfo = MfaOtpInfo(
        secret: mfaInfo.secret,
        qrImage: mfaInfo.qrImage,
        enabled: true,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
