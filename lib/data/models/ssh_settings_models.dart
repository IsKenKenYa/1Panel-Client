import 'package:equatable/equatable.dart';

class SshInfo extends Equatable {
  const SshInfo({
    required this.autoStart,
    required this.isExist,
    required this.isActive,
    required this.message,
    required this.port,
    required this.listenAddress,
    required this.passwordAuthentication,
    required this.pubkeyAuthentication,
    required this.permitRootLogin,
    required this.useDNS,
    required this.currentUser,
  });

  final bool autoStart;
  final bool isExist;
  final bool isActive;
  final String message;
  final String port;
  final String listenAddress;
  final String passwordAuthentication;
  final String pubkeyAuthentication;
  final String permitRootLogin;
  final String useDNS;
  final String currentUser;

  factory SshInfo.fromJson(Map<String, dynamic> json) {
    return SshInfo(
      autoStart: json['autoStart'] as bool? ?? false,
      isExist: json['isExist'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      port: json['port']?.toString() ?? '',
      listenAddress: json['listenAddress'] as String? ?? '',
      passwordAuthentication:
          json['passwordAuthentication'] as String? ?? 'yes',
      pubkeyAuthentication: json['pubkeyAuthentication'] as String? ?? 'yes',
      permitRootLogin: json['permitRootLogin'] as String? ?? 'yes',
      useDNS: json['useDNS'] as String? ?? 'no',
      currentUser: json['currentUser'] as String? ?? 'root',
    );
  }

  @override
  List<Object?> get props => <Object?>[
        autoStart,
        isExist,
        isActive,
        message,
        port,
        listenAddress,
        passwordAuthentication,
        pubkeyAuthentication,
        permitRootLogin,
        useDNS,
        currentUser,
      ];
}

class SshOperateRequest extends Equatable {
  const SshOperateRequest({required this.operation});

  final String operation;

  Map<String, dynamic> toJson() => <String, dynamic>{'operation': operation};

  @override
  List<Object?> get props => <Object?>[operation];
}

class SshUpdateRequest extends Equatable {
  const SshUpdateRequest({
    required this.key,
    required this.newValue,
    this.oldValue = '',
  });

  final String key;
  final String oldValue;
  final String newValue;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'key': key,
        'oldValue': oldValue,
        'newValue': newValue,
      };

  @override
  List<Object?> get props => <Object?>[key, oldValue, newValue];
}

class SshFileLoadRequest extends Equatable {
  const SshFileLoadRequest({this.name = 'sshdConf'});

  final String name;

  Map<String, dynamic> toJson() => <String, dynamic>{'name': name};

  @override
  List<Object?> get props => <Object?>[name];
}

class SshFileUpdateRequest extends Equatable {
  const SshFileUpdateRequest({
    this.key = 'sshdConf',
    required this.value,
  });

  final String key;
  final String value;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'key': key,
        'value': value,
      };

  @override
  List<Object?> get props => <Object?>[key, value];
}

class SshLocalConnectionInfo extends Equatable {
  const SshLocalConnectionInfo({
    this.addr = '',
    this.port = 22,
    this.user = '',
    this.authMode = 'password',
    this.password,
    this.privateKey,
    this.passPhrase,
    this.localSSHConnShow = 'Disable',
  });

  final String addr;
  final int port;
  final String user;
  final String authMode;
  final String? password;
  final String? privateKey;
  final String? passPhrase;
  final String localSSHConnShow;

  bool get isVisibleByDefault => localSSHConnShow.toLowerCase() == 'enable';
  bool get isConfigured => addr.trim().isNotEmpty && user.trim().isNotEmpty;

  String get summary {
    if (!isConfigured) {
      return '-';
    }
    return '$user@$addr:$port';
  }

  factory SshLocalConnectionInfo.fromJson(Map<String, dynamic> json) {
    return SshLocalConnectionInfo(
      addr: json['addr'] as String? ?? '',
      port: json['port'] as int? ?? 22,
      user: json['user'] as String? ?? '',
      authMode: json['authMode'] as String? ?? 'password',
      password: json['password'] as String?,
      privateKey: json['privateKey'] as String?,
      passPhrase: json['passPhrase'] as String?,
      localSSHConnShow: json['localSSHConnShow'] as String? ?? 'Disable',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'addr': addr,
        'port': port,
        'user': user,
        'authMode': authMode,
        'password': password,
        'privateKey': privateKey,
        'passPhrase': passPhrase,
        'localSSHConnShow': localSSHConnShow,
      };

  SshLocalConnectionInfo copyWith({
    String? addr,
    int? port,
    String? user,
    String? authMode,
    String? password,
    String? privateKey,
    String? passPhrase,
    String? localSSHConnShow,
  }) {
    return SshLocalConnectionInfo(
      addr: addr ?? this.addr,
      port: port ?? this.port,
      user: user ?? this.user,
      authMode: authMode ?? this.authMode,
      password: password ?? this.password,
      privateKey: privateKey ?? this.privateKey,
      passPhrase: passPhrase ?? this.passPhrase,
      localSSHConnShow: localSSHConnShow ?? this.localSSHConnShow,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        addr,
        port,
        user,
        authMode,
        password,
        privateKey,
        passPhrase,
        localSSHConnShow,
      ];
}

class SshDefaultConnectionVisibilityUpdate extends Equatable {
  const SshDefaultConnectionVisibilityUpdate({
    required this.withReset,
    required this.defaultConn,
  });

  final bool withReset;
  final String defaultConn;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'withReset': withReset,
        'defaultConn': defaultConn,
      };

  @override
  List<Object?> get props => <Object?>[withReset, defaultConn];
}
