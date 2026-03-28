import 'package:equatable/equatable.dart';

class FileMountInfo extends Equatable {
  final String device;
  final String mountPoint;
  final String fsType;
  final int total;
  final int used;
  final int available;

  const FileMountInfo({
    required this.device,
    required this.mountPoint,
    required this.fsType,
    required this.total,
    required this.used,
    required this.available,
  });

  factory FileMountInfo.fromJson(Map<String, dynamic> json) {
    return FileMountInfo(
      device: json['device'] as String? ?? '',
      mountPoint: json['mountPoint'] as String? ?? '',
      fsType: json['fsType'] as String? ?? '',
      total: json['total'] as int? ?? 0,
      used: json['used'] as int? ?? 0,
      available: json['available'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device': device,
      'mountPoint': mountPoint,
      'fsType': fsType,
      'total': total,
      'used': used,
      'available': available,
    };
  }

  @override
  List<Object?> get props =>
      [device, mountPoint, fsType, total, used, available];
}
