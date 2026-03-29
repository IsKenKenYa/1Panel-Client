import 'package:equatable/equatable.dart';

class LoginRequest extends Equatable {
  final String username;
  final String password;
  final String language;
  final String? entranceCode;
  final String? captcha;
  final String? captchaId;

  const LoginRequest({
    required this.username,
    required this.password,
    this.language = 'en',
    this.entranceCode,
    this.captcha,
    this.captchaId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': username,
      'password': password,
      'language': language,
      if (captcha != null) 'captcha': captcha,
      if (captchaId != null) 'captchaID': captchaId,
    };
  }

  @override
  List<Object?> get props => [
        username,
        password,
        language,
        entranceCode,
        captcha,
        captchaId,
      ];
}

class LoginResponse extends Equatable {
  final String? token;
  final String? name;
  final bool? mfaStatus;
  final String? message;
  final String? entranceCode;

  const LoginResponse({
    this.token,
    this.name,
    this.mfaStatus,
    this.message,
    this.entranceCode,
  });

  static bool? _parseMfaStatus(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) return null;
      return normalized == 'enable' ||
          normalized == 'enabled' ||
          normalized == 'true' ||
          normalized == '1';
    }
    return null;
  }

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String?,
      name: json['name'] as String?,
      mfaStatus: _parseMfaStatus(json['mfaStatus']),
      message: json['message'] as String?,
    );
  }

  LoginResponse copyWith({
    String? token,
    String? name,
    bool? mfaStatus,
    String? message,
    String? entranceCode,
  }) {
    return LoginResponse(
      token: token ?? this.token,
      name: name ?? this.name,
      mfaStatus: mfaStatus ?? this.mfaStatus,
      message: message ?? this.message,
      entranceCode: entranceCode ?? this.entranceCode,
    );
  }

  @override
  List<Object?> get props => [token, name, mfaStatus, message, entranceCode];
}

class MfaLoginRequest extends Equatable {
  final String code;
  final String name;
  final String password;
  final String? entranceCode;

  const MfaLoginRequest({
    required this.code,
    required this.name,
    required this.password,
    this.entranceCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'password': password,
    };
  }

  @override
  List<Object?> get props => [code, name, password, entranceCode];
}

class PasskeyBeginResponse extends Equatable {
  final String? sessionId;
  final dynamic publicKey;

  const PasskeyBeginResponse({
    this.sessionId,
    this.publicKey,
  });

  factory PasskeyBeginResponse.fromJson(Map<String, dynamic> json) {
    return PasskeyBeginResponse(
      sessionId: json['sessionId'] as String?,
      publicKey: json['publicKey'],
    );
  }

  @override
  List<Object?> get props => [sessionId, publicKey];
}

class CaptchaData extends Equatable {
  final String? captchaId;
  final String? imagePath;
  final String? base64;

  const CaptchaData({
    this.captchaId,
    this.imagePath,
    this.base64,
  });

  factory CaptchaData.fromJson(Map<String, dynamic> json) {
    return CaptchaData(
      captchaId: json['captchaId'] as String? ?? json['id'] as String?,
      imagePath: json['imagePath'] as String? ?? json['path'] as String?,
      base64: json['image'] as String? ?? json['base64'] as String?,
    );
  }

  @override
  List<Object?> get props => [captchaId, imagePath, base64];
}

class LoginSettings extends Equatable {
  final bool? captcha;
  final bool? mfa;
  final String? demo;
  final String? title;
  final String? logo;

  const LoginSettings({
    this.captcha,
    this.mfa,
    this.demo,
    this.title,
    this.logo,
  });

  factory LoginSettings.fromJson(Map<String, dynamic> json) {
    return LoginSettings(
      captcha: json['captcha'] as bool?,
      mfa: json['mfa'] as bool?,
      demo: json['demo'] as String?,
      title: json['title'] as String?,
      logo: json['logo'] as String?,
    );
  }

  @override
  List<Object?> get props => [captcha, mfa, demo, title, logo];
}

class SafetyStatus extends Equatable {
  final bool? isSafety;
  final String? message;

  const SafetyStatus({
    this.isSafety,
    this.message,
  });

  factory SafetyStatus.fromJson(Map<String, dynamic> json) {
    return SafetyStatus(
      isSafety: json['issafety'] as bool? ?? json['isSafety'] as bool?,
      message: json['message'] as String?,
    );
  }

  @override
  List<Object?> get props => [isSafety, message];
}

class DemoModeStatus extends Equatable {
  final bool? isDemo;
  final String? message;

  const DemoModeStatus({
    this.isDemo,
    this.message,
  });

  factory DemoModeStatus.fromJson(Map<String, dynamic> json) {
    return DemoModeStatus(
      isDemo: json['demo'] as bool? ?? json['isDemo'] as bool?,
      message: json['message'] as String?,
    );
  }

  @override
  List<Object?> get props => [isDemo, message];
}
