import 'package:equatable/equatable.dart';

class SshSessionQuery extends Equatable {
  const SshSessionQuery({
    this.loginUser = '',
    this.loginIP = '',
  });

  final String loginUser;
  final String loginIP;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'ssh',
        'loginUser': loginUser,
        'loginIP': loginIP,
      };

  @override
  List<Object?> get props => <Object?>[loginUser, loginIP];
}

class SshSessionInfo extends Equatable {
  const SshSessionInfo({
    required this.username,
    required this.pid,
    required this.terminal,
    required this.host,
    required this.loginTime,
  });

  final String username;
  final int pid;
  final String terminal;
  final String host;
  final String loginTime;

  factory SshSessionInfo.fromJson(Map<String, dynamic> json) {
    return SshSessionInfo(
      username: json['username'] as String? ?? '',
      pid: json['PID'] as int? ?? 0,
      terminal: json['terminal'] as String? ?? '',
      host: json['host'] as String? ?? '',
      loginTime: json['loginTime'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => <Object?>[username, pid, terminal, host, loginTime];
}
