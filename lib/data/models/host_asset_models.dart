import 'package:equatable/equatable.dart';

class HostOperate extends Equatable {
  const HostOperate({
    this.id,
    required this.name,
    this.groupID,
    required this.addr,
    required this.port,
    required this.user,
    required this.authMode,
    this.password,
    this.privateKey,
    this.passPhrase,
    this.rememberPassword = false,
    this.description,
  });

  final int? id;
  final String name;
  final int? groupID;
  final String addr;
  final int port;
  final String user;
  final String authMode;
  final String? password;
  final String? privateKey;
  final String? passPhrase;
  final bool rememberPassword;
  final String? description;

  HostOperate copyWith({
    int? id,
    String? name,
    int? groupID,
    String? addr,
    int? port,
    String? user,
    String? authMode,
    String? password,
    String? privateKey,
    String? passPhrase,
    bool? rememberPassword,
    String? description,
  }) {
    return HostOperate(
      id: id ?? this.id,
      name: name ?? this.name,
      groupID: groupID ?? this.groupID,
      addr: addr ?? this.addr,
      port: port ?? this.port,
      user: user ?? this.user,
      authMode: authMode ?? this.authMode,
      password: password ?? this.password,
      privateKey: privateKey ?? this.privateKey,
      passPhrase: passPhrase ?? this.passPhrase,
      rememberPassword: rememberPassword ?? this.rememberPassword,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'name': name,
      'groupID': groupID,
      'addr': addr,
      'port': port,
      'user': user,
      'authMode': authMode,
      'password': password,
      'privateKey': privateKey,
      'passPhrase': passPhrase,
      'rememberPassword': rememberPassword,
      'description': description,
    };
  }

  factory HostOperate.fromJson(Map<String, dynamic> json) {
    return HostOperate(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      groupID: json['groupID'] as int?,
      addr: json['addr'] as String? ?? '',
      port: json['port'] as int? ?? 22,
      user: json['user'] as String? ?? '',
      authMode: json['authMode'] as String? ?? 'password',
      password: json['password'] as String?,
      privateKey: json['privateKey'] as String?,
      passPhrase: json['passPhrase'] as String?,
      rememberPassword: json['rememberPassword'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        groupID,
        addr,
        port,
        user,
        authMode,
        password,
        privateKey,
        passPhrase,
        rememberPassword,
        description,
      ];
}

class HostConnTest extends Equatable {
  const HostConnTest({
    required this.addr,
    required this.port,
    required this.user,
    required this.authMode,
    this.password,
    this.privateKey,
    this.passPhrase,
  });

  final String addr;
  final int port;
  final String user;
  final String authMode;
  final String? password;
  final String? privateKey;
  final String? passPhrase;

  HostConnTest copyWith({
    String? addr,
    int? port,
    String? user,
    String? authMode,
    String? password,
    String? privateKey,
    String? passPhrase,
  }) {
    return HostConnTest(
      addr: addr ?? this.addr,
      port: port ?? this.port,
      user: user ?? this.user,
      authMode: authMode ?? this.authMode,
      password: password ?? this.password,
      privateKey: privateKey ?? this.privateKey,
      passPhrase: passPhrase ?? this.passPhrase,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'addr': addr,
      'port': port,
      'user': user,
      'authMode': authMode,
      'password': password,
      'privateKey': privateKey,
      'passPhrase': passPhrase,
    };
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
      ];
}

class HostSearchRequest extends Equatable {
  const HostSearchRequest({
    this.page = 1,
    this.pageSize = 20,
    this.groupID,
    this.info,
  });

  final int page;
  final int pageSize;
  final int? groupID;
  final String? info;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'groupID': groupID ?? 0,
      'info': info,
    };
  }

  @override
  List<Object?> get props => <Object?>[page, pageSize, groupID, info];
}

class HostGroupChange extends Equatable {
  const HostGroupChange({required this.id, required this.groupID});

  final int id;
  final int groupID;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'groupID': groupID,
    };
  }

  @override
  List<Object?> get props => <Object?>[id, groupID];
}
