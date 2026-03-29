import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

class PasskeyAvailabilityResult {
  const PasskeyAvailabilityResult({
    required this.isSupported,
    this.reason,
  });

  const PasskeyAvailabilityResult.supported()
      : isSupported = true,
        reason = null;

  const PasskeyAvailabilityResult.unsupported(this.reason)
      : isSupported = false;

  final bool isSupported;
  final String? reason;
}

class PasskeyService {
  PasskeyService({PasskeyAuthenticator? authenticator})
      : _authenticator = authenticator ?? PasskeyAuthenticator();

  final PasskeyAuthenticator _authenticator;

  Future<PasskeyAvailabilityResult> getAvailability() async {
    if (defaultTargetPlatform == TargetPlatform.linux) {
      return const PasskeyAvailabilityResult.unsupported('Linux 仅提供占位提示');
    }

    try {
      if (kIsWeb) {
        final availability = await _authenticator.getAvailability().web();
        if (availability.hasPasskeySupport) {
          return const PasskeyAvailabilityResult.supported();
        }
        return const PasskeyAvailabilityResult.unsupported('当前浏览器不支持 Passkey');
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final availability = await _authenticator.getAvailability().android();
          if (availability.hasPasskeySupport) {
            return const PasskeyAvailabilityResult.supported();
          }
          return const PasskeyAvailabilityResult.unsupported('当前设备不支持 Passkey');
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          final availability = await _authenticator.getAvailability().iOS();
          if (availability.hasPasskeySupport) {
            return const PasskeyAvailabilityResult.supported();
          }
          return const PasskeyAvailabilityResult.unsupported(
              '当前 Apple 设备不支持 Passkey');
        case TargetPlatform.windows:
          final availability = await _authenticator.getAvailability().windows();
          if (availability.hasPasskeySupport) {
            return const PasskeyAvailabilityResult.supported();
          }
          return const PasskeyAvailabilityResult.unsupported(
              '当前 Windows 设备不支持 Passkey');
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          return const PasskeyAvailabilityResult.unsupported(
              '当前平台暂不支持 Passkey');
      }
    } catch (e, stackTrace) {
      appLogger.wWithPackage(
        'core.services.passkey_service',
        'getAvailability failed',
        error: e,
        stackTrace: stackTrace,
      );
      return PasskeyAvailabilityResult.unsupported(toUserMessage(e));
    }
  }

  Future<Map<String, dynamic>> registerCredential(
    Map<String, dynamic> publicKey,
  ) async {
    final request = RegisterRequestType.fromJson(publicKey);
    final response = await _authenticator.register(request);
    return response.toJson();
  }

  Future<Map<String, dynamic>> authenticateCredential(
    Map<String, dynamic> publicKey,
  ) async {
    final request = AuthenticateRequestType.fromJson(publicKey);
    final response = await _authenticator.authenticate(request);
    return response.toJson();
  }

  String toUserMessage(Object error) {
    if (error is PasskeyAuthCancelledException) {
      return '已取消 Passkey 验证';
    }
    if (error is DomainNotAssociatedException) {
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
      return '域名关联校验失败，请检查平台配置';
    }
    if (error is NoCredentialsAvailableException) {
      return '未找到可用 Passkey';
    }
    if (error is DeviceNotSupportedException ||
        error is PasskeyUnsupportedException) {
      return '当前设备不支持 Passkey';
    }
    if (error is TimeoutException) {
      return 'Passkey 操作超时，请重试';
    }
    if (error is MissingGoogleSignInException) {
      return '请先在设备上登录 Google 账户';
    }
    if (error is NoCreateOptionException) {
      final text = error.message?.trim();
      return (text == null || text.isEmpty) ? '无法创建 Passkey' : text;
    }
    final text = error.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
    return 'Passkey 操作失败';
  }
}
