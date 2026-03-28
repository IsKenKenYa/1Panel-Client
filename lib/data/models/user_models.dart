import 'package:equatable/equatable.dart';

/// User status enumeration
enum UserStatus {
  active('active'),
  disabled('disabled'),
  locked('locked'),
  pending('pending');

  const UserStatus(this.value);
  final String value;

  static UserStatus fromString(String value) {
    return UserStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => UserStatus.disabled,
    );
  }
}

/// User role enumeration
enum UserRole {
  admin('admin'),
  user('user'),
  guest('guest'),
  operator('operator');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.guest,
    );
  }
}

/// User creation request model
class UserCreate extends Equatable {
  final String username;
  final String password;
  final String email;
  final String? nickname;
  final String? role;
  final String? phone;
  final String? description;
  final bool? enable;

  const UserCreate({
    required this.username,
    required this.password,
    required this.email,
    this.nickname,
    this.role,
    this.phone,
    this.description,
    this.enable,
  });

  factory UserCreate.fromJson(Map<String, dynamic> json) {
    return UserCreate(
      username: json['username'] as String,
      password: json['password'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String?,
      role: json['role'] as String?,
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      enable: json['enable'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'email': email,
      'nickname': nickname,
      'role': role,
      'phone': phone,
      'description': description,
      'enable': enable,
    };
  }

  @override
  List<Object?> get props =>
      [username, password, email, nickname, role, phone, description, enable];
}

/// User information model
class UserInfo extends Equatable {
  final int? id;
  final String? username;
  final String? email;
  final String? nickname;
  final String? role;
  final String? phone;
  final String? avatar;
  final String? description;
  final UserStatus? status;
  final String? lastLoginTime;
  final String? lastLoginIp;
  final int? loginCount;
  final String? createTime;
  final String? updateTime;

  const UserInfo({
    this.id,
    this.username,
    this.email,
    this.nickname,
    this.role,
    this.phone,
    this.avatar,
    this.description,
    this.status,
    this.lastLoginTime,
    this.lastLoginIp,
    this.loginCount,
    this.createTime,
    this.updateTime,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      nickname: json['nickname'] as String?,
      role: json['role'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      description: json['description'] as String?,
      status: json['status'] != null
          ? UserStatus.fromString(json['status'] as String)
          : null,
      lastLoginTime: json['lastLoginTime'] as String?,
      lastLoginIp: json['lastLoginIp'] as String?,
      loginCount: json['loginCount'] as int?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'nickname': nickname,
      'role': role,
      'phone': phone,
      'avatar': avatar,
      'description': description,
      'status': status?.value,
      'lastLoginTime': lastLoginTime,
      'lastLoginIp': lastLoginIp,
      'loginCount': loginCount,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        nickname,
        role,
        phone,
        avatar,
        description,
        status,
        lastLoginTime,
        lastLoginIp,
        loginCount,
        createTime,
        updateTime
      ];
}

/// User search request model
class UserSearch extends Equatable {
  final int? page;
  final int? pageSize;
  final String? search;
  final String? role;
  final UserStatus? status;

  const UserSearch({
    this.page,
    this.pageSize,
    this.search,
    this.role,
    this.status,
  });

  factory UserSearch.fromJson(Map<String, dynamic> json) {
    return UserSearch(
      page: json['page'] as int?,
      pageSize: json['pageSize'] as int?,
      search: json['search'] as String?,
      role: json['role'] as String?,
      status: json['status'] != null
          ? UserStatus.fromString(json['status'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      'search': search,
      'role': role,
      'status': status?.value,
    };
  }

  @override
  List<Object?> get props => [page, pageSize, search, role, status];
}

/// User update request model
class UserUpdate extends Equatable {
  final int id;
  final String? email;
  final String? nickname;
  final String? role;
  final String? phone;
  final String? avatar;
  final String? description;
  final bool? enable;
  final String? password;

  const UserUpdate({
    required this.id,
    this.email,
    this.nickname,
    this.role,
    this.phone,
    this.avatar,
    this.description,
    this.enable,
    this.password,
  });

  factory UserUpdate.fromJson(Map<String, dynamic> json) {
    return UserUpdate(
      id: json['id'] as int,
      email: json['email'] as String?,
      nickname: json['nickname'] as String?,
      role: json['role'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      description: json['description'] as String?,
      enable: json['enable'] as bool?,
      password: json['password'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'role': role,
      'phone': phone,
      'avatar': avatar,
      'description': description,
      'enable': enable,
      'password': password,
    };
  }

  @override
  List<Object?> get props =>
      [id, email, nickname, role, phone, avatar, description, enable, password];
}

/// User operation model
class UserOperate extends Equatable {
  final List<int> ids;
  final String operation;

  const UserOperate({
    required this.ids,
    required this.operation,
  });

  factory UserOperate.fromJson(Map<String, dynamic> json) {
    return UserOperate(
      ids: (json['ids'] as List?)?.map((e) => e as int).toList() ?? [],
      operation: json['operation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ids': ids,
      'operation': operation,
    };
  }

  @override
  List<Object?> get props => [ids, operation];
}

/// User login request model
class UserLogin extends Equatable {
  final String username;
  final String password;
  final String? captcha;
  final String? rememberMe;

  const UserLogin({
    required this.username,
    required this.password,
    this.captcha,
    this.rememberMe,
  });

  factory UserLogin.fromJson(Map<String, dynamic> json) {
    return UserLogin(
      username: json['username'] as String,
      password: json['password'] as String,
      captcha: json['captcha'] as String?,
      rememberMe: json['rememberMe'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'captcha': captcha,
      'rememberMe': rememberMe,
    };
  }

  @override
  List<Object?> get props => [username, password, captcha, rememberMe];
}

/// User login response model
class UserLoginResponse extends Equatable {
  final String? token;
  final String? refreshToken;
  final UserInfo? user;
  final int? expiresIn;

  const UserLoginResponse({
    this.token,
    this.refreshToken,
    this.user,
    this.expiresIn,
  });

  factory UserLoginResponse.fromJson(Map<String, dynamic> json) {
    return UserLoginResponse(
      token: json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
      user: json['user'] != null
          ? UserInfo.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      expiresIn: json['expiresIn'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'user': user?.toJson(),
      'expiresIn': expiresIn,
    };
  }

  @override
  List<Object?> get props => [token, refreshToken, user, expiresIn];
}

/// Permission model
class Permission extends Equatable {
  final String? id;
  final String? name;
  final String? resource;
  final String? action;
  final String? description;

  const Permission({
    this.id,
    this.name,
    this.resource,
    this.action,
    this.description,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'] as String?,
      name: json['name'] as String?,
      resource: json['resource'] as String?,
      action: json['action'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'resource': resource,
      'action': action,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [id, name, resource, action, description];
}

/// Role model
class Role extends Equatable {
  final int? id;
  final String? name;
  final String? code;
  final String? description;
  final List<Permission>? permissions;
  final String? createTime;

  const Role({
    this.id,
    this.name,
    this.code,
    this.description,
    this.permissions,
    this.createTime,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int?,
      name: json['name'] as String?,
      code: json['code'] as String?,
      description: json['description'] as String?,
      permissions: (json['permissions'] as List?)
          ?.map((item) => Permission.fromJson(item as Map<String, dynamic>))
          .toList(),
      createTime: json['createTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'permissions':
          permissions?.map((permission) => permission.toJson()).toList(),
      'createTime': createTime,
    };
  }

  @override
  List<Object?> get props =>
      [id, name, code, description, permissions, createTime];
}

/// User session model
class UserSession extends Equatable {
  final String? sessionId;
  final int? userId;
  final String? username;
  final String? ipAddress;
  final String? userAgent;
  final String? loginTime;
  final String? lastActivity;
  final bool? active;

  const UserSession({
    this.sessionId,
    this.userId,
    this.username,
    this.ipAddress,
    this.userAgent,
    this.loginTime,
    this.lastActivity,
    this.active,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      sessionId: json['sessionId'] as String?,
      userId: json['userId'] as int?,
      username: json['username'] as String?,
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      loginTime: json['loginTime'] as String?,
      lastActivity: json['lastActivity'] as String?,
      active: json['active'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'username': username,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'loginTime': loginTime,
      'lastActivity': lastActivity,
      'active': active,
    };
  }

  @override
  List<Object?> get props => [
        sessionId,
        userId,
        username,
        ipAddress,
        userAgent,
        loginTime,
        lastActivity,
        active
      ];
}

/// MFA login request model
class UserMFALogin extends Equatable {
  final String username;
  final String password;
  final String? captcha;
  final String? rememberMe;
  final String? mfaCode;
  final String? mfaToken;

  const UserMFALogin({
    required this.username,
    required this.password,
    this.captcha,
    this.rememberMe,
    this.mfaCode,
    this.mfaToken,
  });

  factory UserMFALogin.fromJson(Map<String, dynamic> json) {
    return UserMFALogin(
      username: json['username'] as String,
      password: json['password'] as String,
      captcha: json['captcha'] as String?,
      rememberMe: json['rememberMe'] as String?,
      mfaCode: json['mfaCode'] as String?,
      mfaToken: json['mfaToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'captcha': captcha,
      'rememberMe': rememberMe,
      'mfaCode': mfaCode,
      'mfaToken': mfaToken,
    };
  }

  @override
  List<Object?> get props =>
      [username, password, captcha, rememberMe, mfaCode, mfaToken];
}

/// Captcha response model
class CaptchaResponse extends Equatable {
  final String? captchaId;
  final String? captchaImage;
  final String? captchaBase64;

  const CaptchaResponse({
    this.captchaId,
    this.captchaImage,
    this.captchaBase64,
  });

  factory CaptchaResponse.fromJson(Map<String, dynamic> json) {
    return CaptchaResponse(
      captchaId: json['captchaId'] as String?,
      captchaImage: json['captchaImage'] as String?,
      captchaBase64: json['captchaBase64'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'captchaId': captchaId,
      'captchaImage': captchaImage,
      'captchaBase64': captchaBase64,
    };
  }

  @override
  List<Object?> get props => [captchaId, captchaImage, captchaBase64];
}

/// Authentication settings model
class AuthSettings extends Equatable {
  final bool? captchaEnabled;
  final bool? mfaEnabled;
  final bool? rememberMeEnabled;
  final int? sessionTimeout;
  final int? maxLoginAttempts;
  final int? lockoutDuration;
  final bool? passwordPolicyEnabled;
  final int? passwordMinLength;
  final bool? passwordRequireNumbers;
  final bool? passwordRequireSymbols;
  final bool? passwordRequireUppercase;

  const AuthSettings({
    this.captchaEnabled,
    this.mfaEnabled,
    this.rememberMeEnabled,
    this.sessionTimeout,
    this.maxLoginAttempts,
    this.lockoutDuration,
    this.passwordPolicyEnabled,
    this.passwordMinLength,
    this.passwordRequireNumbers,
    this.passwordRequireSymbols,
    this.passwordRequireUppercase,
  });

  factory AuthSettings.fromJson(Map<String, dynamic> json) {
    return AuthSettings(
      captchaEnabled: json['captchaEnabled'] as bool?,
      mfaEnabled: json['mfaEnabled'] as bool?,
      rememberMeEnabled: json['rememberMeEnabled'] as bool?,
      sessionTimeout: json['sessionTimeout'] as int?,
      maxLoginAttempts: json['maxLoginAttempts'] as int?,
      lockoutDuration: json['lockoutDuration'] as int?,
      passwordPolicyEnabled: json['passwordPolicyEnabled'] as bool?,
      passwordMinLength: json['passwordMinLength'] as int?,
      passwordRequireNumbers: json['passwordRequireNumbers'] as bool?,
      passwordRequireSymbols: json['passwordRequireSymbols'] as bool?,
      passwordRequireUppercase: json['passwordRequireUppercase'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'captchaEnabled': captchaEnabled,
      'mfaEnabled': mfaEnabled,
      'rememberMeEnabled': rememberMeEnabled,
      'sessionTimeout': sessionTimeout,
      'maxLoginAttempts': maxLoginAttempts,
      'lockoutDuration': lockoutDuration,
      'passwordPolicyEnabled': passwordPolicyEnabled,
      'passwordMinLength': passwordMinLength,
      'passwordRequireNumbers': passwordRequireNumbers,
      'passwordRequireSymbols': passwordRequireSymbols,
      'passwordRequireUppercase': passwordRequireUppercase,
    };
  }

  @override
  List<Object?> get props => [
        captchaEnabled,
        mfaEnabled,
        rememberMeEnabled,
        sessionTimeout,
        maxLoginAttempts,
        lockoutDuration,
        passwordPolicyEnabled,
        passwordMinLength,
        passwordRequireNumbers,
        passwordRequireSymbols,
        passwordRequireUppercase,
      ];
}
