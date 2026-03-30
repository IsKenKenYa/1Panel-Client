import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';

const String _appLocalAuthPackage = 'core.security.app_local_auth_service';

class LocalAuthAvailability {
  const LocalAuthAvailability({
    required this.isSupported,
    required this.canCheckBiometrics,
    required this.isDeviceSupported,
    required this.availableBiometrics,
    this.reason,
  });

  const LocalAuthAvailability.unknown()
      : isSupported = false,
        canCheckBiometrics = false,
        isDeviceSupported = false,
        availableBiometrics = const <BiometricType>[],
        reason = null;

  final bool isSupported;
  final bool canCheckBiometrics;
  final bool isDeviceSupported;
  final List<BiometricType> availableBiometrics;
  final String? reason;
}

class LocalAuthResult {
  const LocalAuthResult({
    required this.success,
    this.message,
  });

  final bool success;
  final String? message;
}

abstract class LocalAuthGateway {
  Future<bool> canCheckBiometrics();
  Future<bool> isDeviceSupported();
  Future<List<BiometricType>> getAvailableBiometrics();
  Future<bool> authenticate({
    required String localizedReason,
    required AuthenticationOptions options,
  });
}

class FlutterLocalAuthGateway implements LocalAuthGateway {
  FlutterLocalAuthGateway({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  @override
  Future<bool> canCheckBiometrics() {
    return _localAuth.canCheckBiometrics;
  }

  @override
  Future<bool> isDeviceSupported() {
    return _localAuth.isDeviceSupported();
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() {
    return _localAuth.getAvailableBiometrics();
  }

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required AuthenticationOptions options,
  }) {
    return _localAuth.authenticate(
      localizedReason: localizedReason,
      options: options,
    );
  }
}

class AppLocalAuthService {
  AppLocalAuthService({LocalAuthGateway? gateway})
      : _gateway = gateway ?? FlutterLocalAuthGateway();

  final LocalAuthGateway _gateway;

  Future<LocalAuthAvailability> checkAvailability() async {
    try {
      final canCheckBiometrics = await _gateway.canCheckBiometrics();
      final isDeviceSupported = await _gateway.isDeviceSupported();
      final biometrics = canCheckBiometrics
          ? await _gateway.getAvailableBiometrics()
          : const <BiometricType>[];
      final isSupported = canCheckBiometrics || isDeviceSupported;

      return LocalAuthAvailability(
        isSupported: isSupported,
        canCheckBiometrics: canCheckBiometrics,
        isDeviceSupported: isDeviceSupported,
        availableBiometrics: biometrics,
        reason: isSupported ? null : '当前设备不支持本地认证',
      );
    } on PlatformException catch (e, stackTrace) {
      appLogger.wWithPackage(
        _appLocalAuthPackage,
        'checkAvailability failed',
        error: e,
        stackTrace: stackTrace,
      );
      return LocalAuthAvailability(
        isSupported: false,
        canCheckBiometrics: false,
        isDeviceSupported: false,
        availableBiometrics: const <BiometricType>[],
        reason: toUserMessage(e),
      );
    } catch (e, stackTrace) {
      appLogger.wWithPackage(
        _appLocalAuthPackage,
        'checkAvailability failed',
        error: e,
        stackTrace: stackTrace,
      );
      return LocalAuthAvailability(
        isSupported: false,
        canCheckBiometrics: false,
        isDeviceSupported: false,
        availableBiometrics: const <BiometricType>[],
        reason: e.toString(),
      );
    }
  }

  Future<LocalAuthResult> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
  }) async {
    try {
      final success = await _gateway.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
      if (success) {
        return const LocalAuthResult(success: true);
      }
      return const LocalAuthResult(
        success: false,
        message: '已取消本地认证',
      );
    } on PlatformException catch (e, stackTrace) {
      appLogger.wWithPackage(
        _appLocalAuthPackage,
        'authenticate failed',
        error: e,
        stackTrace: stackTrace,
      );
      return LocalAuthResult(
        success: false,
        message: toUserMessage(e),
      );
    } catch (e, stackTrace) {
      appLogger.wWithPackage(
        _appLocalAuthPackage,
        'authenticate failed',
        error: e,
        stackTrace: stackTrace,
      );
      return LocalAuthResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  String toUserMessage(Object error) {
    if (error is! PlatformException) {
      return error.toString();
    }

    final code = error.code.toLowerCase();
    if (code.contains('notavailable')) {
      return '设备当前不可用本地认证';
    }
    if (code.contains('notenrolled')) {
      return '设备未录入生物信息';
    }
    if (code.contains('passcodenotset')) {
      return '设备未设置系统密码或PIN';
    }
    if (code.contains('lockedout') && !code.contains('permanent')) {
      return '认证尝试次数过多，请稍后再试';
    }
    if (code.contains('permanentlylockedout')) {
      return '本地认证已被系统锁定，请使用系统解锁后重试';
    }
    if (code.contains('otheroperatingsystem')) {
      return '当前平台不支持此认证方式';
    }

    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return '本地认证失败';
  }
}
