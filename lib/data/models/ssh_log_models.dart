import 'package:equatable/equatable.dart';

enum SshLogStatus {
  all('All'),
  success('Success'),
  failed('Failed');

  const SshLogStatus(this.value);

  final String value;
}

class SshLogSearchRequest extends Equatable {
  const SshLogSearchRequest({
    this.page = 1,
    this.pageSize = 20,
    this.info,
    this.status = SshLogStatus.all,
  });

  final int page;
  final int pageSize;
  final String? info;
  final SshLogStatus status;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        'info': info,
        'status': status.value,
      };

  @override
  List<Object?> get props => <Object?>[page, pageSize, info, status];
}

class SshLogEntry extends Equatable {
  const SshLogEntry({
    required this.date,
    required this.area,
    required this.user,
    required this.authMode,
    required this.address,
    required this.port,
    required this.status,
    required this.message,
  });

  final DateTime? date;
  final String area;
  final String user;
  final String authMode;
  final String address;
  final String port;
  final String status;
  final String message;

  factory SshLogEntry.fromJson(Map<String, dynamic> json) {
    return SshLogEntry(
      date: json['date'] == null
          ? null
          : DateTime.tryParse(json['date'].toString()),
      area: json['area'] as String? ?? '',
      user: json['user'] as String? ?? '',
      authMode: json['authMode'] as String? ?? '',
      address: json['address'] as String? ?? '',
      port: json['port']?.toString() ?? '',
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[date, area, user, authMode, address, port, status, message];
}
