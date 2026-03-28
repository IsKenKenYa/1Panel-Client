import 'package:equatable/equatable.dart';

class FilePermission extends Equatable {
  final String path;
  final String? permission;
  final String? user;
  final String? group;
  final bool? recursive;

  const FilePermission({
    required this.path,
    this.permission,
    this.user,
    this.group,
    this.recursive,
  });

  factory FilePermission.fromJson(Map<String, dynamic> json) {
    return FilePermission(
      path: json['path'] as String,
      permission: json['permission'] as String?,
      user: json['user'] as String?,
      group: json['group'] as String?,
      recursive: json['recursive'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'permission': permission,
      'user': user,
      'group': group,
      'recursive': recursive,
    };
  }

  @override
  List<Object?> get props => [
        path,
        permission,
        user,
        group,
        recursive,
      ];
}

class FileModeChange extends Equatable {
  final String path;
  final int mode;
  final bool? sub;

  const FileModeChange({
    required this.path,
    required this.mode,
    this.sub,
  });

  factory FileModeChange.fromJson(Map<String, dynamic> json) {
    return FileModeChange(
      path: json['path'] as String,
      mode: json['mode'] as int,
      sub: json['sub'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'mode': mode,
      if (sub != null) 'sub': sub,
    };
  }

  @override
  List<Object?> get props => [path, mode, sub];
}

class FileOwnerChange extends Equatable {
  final String path;
  final String user;
  final String group;
  final bool? sub;

  const FileOwnerChange({
    required this.path,
    required this.user,
    required this.group,
    this.sub,
  });

  factory FileOwnerChange.fromJson(Map<String, dynamic> json) {
    return FileOwnerChange(
      path: json['path'] as String,
      user: json['user'] as String,
      group: json['group'] as String,
      sub: json['sub'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'user': user,
      'group': group,
      if (sub != null) 'sub': sub,
    };
  }

  @override
  List<Object?> get props => [path, user, group, sub];
}

class FileUserGroup extends Equatable {
  final String user;
  final String group;

  const FileUserGroup({
    required this.user,
    required this.group,
  });

  factory FileUserGroup.fromJson(Map<String, dynamic> json) {
    return FileUserGroup(
      user: json['user'] as String? ?? '',
      group: json['group'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user,
      'group': group,
    };
  }

  @override
  List<Object?> get props => [user, group];
}

class FileUserGroupResponse extends Equatable {
  final List<FileUserGroup> users;
  final List<String> groups;

  const FileUserGroupResponse({
    required this.users,
    required this.groups,
  });

  factory FileUserGroupResponse.fromJson(Map<String, dynamic> json) {
    return FileUserGroupResponse(
      users: (json['users'] as List?)
              ?.map((item) =>
                  FileUserGroup.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      groups: (json['groups'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'users': users.map((item) => item.toJson()).toList(),
      'groups': groups,
    };
  }

  @override
  List<Object?> get props => [users, groups];
}

class FileBatchRoleRequest extends Equatable {
  final List<String> paths;
  final int? mode;
  final String? user;
  final String? group;
  final bool? sub;

  const FileBatchRoleRequest({
    required this.paths,
    this.mode,
    this.user,
    this.group,
    this.sub,
  });

  Map<String, dynamic> toJson() {
    return {
      'paths': paths,
      if (mode != null) 'mode': mode,
      if (user != null) 'user': user,
      if (group != null) 'group': group,
      if (sub != null) 'sub': sub,
    };
  }

  @override
  List<Object?> get props => [paths, mode, user, group, sub];
}
