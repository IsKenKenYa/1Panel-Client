import 'package:equatable/equatable.dart';

/// License information model
class LicenseInfo extends Equatable {
  final String? key;
  final String? type;
  final String? status;
  final String? expireTime;
  final String? features;
  final String? user;
  final int? maxDevices;

  const LicenseInfo({
    this.key,
    this.type,
    this.status,
    this.expireTime,
    this.features,
    this.user,
    this.maxDevices,
  });

  factory LicenseInfo.fromJson(Map<String, dynamic> json) {
    return LicenseInfo(
      key: json['key'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
      expireTime: json['expireTime'] as String?,
      features: json['features'] as String?,
      user: json['user'] as String?,
      maxDevices: json['maxDevices'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'type': type,
      'status': status,
      'expireTime': expireTime,
      'features': features,
      'user': user,
      'maxDevices': maxDevices,
    };
  }

  @override
  List<Object?> get props =>
      [key, type, status, expireTime, features, user, maxDevices];
}
