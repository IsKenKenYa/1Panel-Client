import 'package:equatable/equatable.dart';

/// LDAP configuration model
class LDAPConfig extends Equatable {
  final String? server;
  final int? port;
  final String? bindDn;
  final String? baseDn;
  final String? userFilter;
  final String? userAttribute;
  final bool? sslEnabled;
  final bool? startTls;
  final bool? enabled;

  const LDAPConfig({
    this.server,
    this.port,
    this.bindDn,
    this.baseDn,
    this.userFilter,
    this.userAttribute,
    this.sslEnabled,
    this.startTls,
    this.enabled,
  });

  factory LDAPConfig.fromJson(Map<String, dynamic> json) {
    return LDAPConfig(
      server: json['server'] as String?,
      port: json['port'] as int?,
      bindDn: json['bindDn'] as String?,
      baseDn: json['baseDn'] as String?,
      userFilter: json['userFilter'] as String?,
      userAttribute: json['userAttribute'] as String?,
      sslEnabled: json['sslEnabled'] as bool?,
      startTls: json['startTls'] as bool?,
      enabled: json['enabled'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'server': server,
      'port': port,
      'bindDn': bindDn,
      'baseDn': baseDn,
      'userFilter': userFilter,
      'userAttribute': userAttribute,
      'sslEnabled': sslEnabled,
      'startTls': startTls,
      'enabled': enabled,
    };
  }

  @override
  List<Object?> get props => [
        server,
        port,
        bindDn,
        baseDn,
        userFilter,
        userAttribute,
        sslEnabled,
        startTls,
        enabled
      ];
}
