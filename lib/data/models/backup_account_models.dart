import 'package:equatable/equatable.dart';

/// 备份账户操作模型
class BackupOperate extends Equatable {
  final int? id;
  final String name;
  final String type;
  final bool isPublic;
  final String? accessKey;
  final String? credential;
  final String? bucket;
  final String? backupPath;
  final bool? rememberAuth;
  final String? vars;

  const BackupOperate({
    this.id,
    required this.name,
    required this.type,
    this.isPublic = false,
    this.accessKey,
    this.credential,
    this.bucket,
    this.backupPath,
    this.rememberAuth,
    this.vars,
  });

  factory BackupOperate.fromJson(Map<String, dynamic> json) {
    return BackupOperate(
      id: json['id'] as int?,
      name: json['name'] as String,
      type: json['type'] as String,
      isPublic: json['isPublic'] as bool? ?? false,
      accessKey: json['accessKey'] as String?,
      credential: json['credential'] as String?,
      bucket: json['bucket'] as String?,
      backupPath: json['backupPath'] as String?,
      rememberAuth: json['rememberAuth'] as bool?,
      vars: json['vars'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'isPublic': isPublic,
      'accessKey': accessKey,
      'credential': credential,
      'bucket': bucket,
      'backupPath': backupPath,
      'rememberAuth': rememberAuth,
      'vars': vars,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        isPublic,
        accessKey,
        credential,
        bucket,
        backupPath,
        rememberAuth,
        vars,
      ];
}

/// 备份账户选项模型
class BackupOption extends Equatable {
  final int id;
  final bool isPublic;
  final String name;
  final String type;

  const BackupOption({
    required this.id,
    required this.isPublic,
    required this.name,
    required this.type,
  });

  factory BackupOption.fromJson(Map<String, dynamic> json) {
    return BackupOption(
      id: json['id'] as int,
      isPublic: json['isPublic'] as bool,
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isPublic': isPublic,
      'name': name,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [id, isPublic, name, type];
}

/// 备份连通性检查结果
class BackupCheckResult extends Equatable {
  final bool isOk;
  final String? msg;
  final String? token;

  const BackupCheckResult({
    required this.isOk,
    this.msg,
    this.token,
  });

  factory BackupCheckResult.fromJson(Map<String, dynamic> json) {
    return BackupCheckResult(
      isOk: json['isOk'] as bool? ?? false,
      msg: json['msg'] as String?,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isOk': isOk,
      'msg': msg,
      'token': token,
    };
  }

  @override
  List<Object?> get props => [isOk, msg, token];
}

/// 核心备份客户端基础信息
class BackupClientInfo extends Equatable {
  final String? clientId;
  final String? clientSecret;
  final String? redirectUri;

  const BackupClientInfo({
    this.clientId,
    this.clientSecret,
    this.redirectUri,
  });

  factory BackupClientInfo.fromJson(Map<String, dynamic> json) {
    return BackupClientInfo(
      clientId: json['client_id'] as String?,
      clientSecret: json['client_secret'] as String?,
      redirectUri: json['redirect_uri'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'client_secret': clientSecret,
      'redirect_uri': redirectUri,
    };
  }

  @override
  List<Object?> get props => [clientId, clientSecret, redirectUri];
}

/// 备份记录搜索模型
class RecordSearch extends Equatable {
  final int page;
  final int pageSize;
  final String type;
  final String? name;
  final String? detailName;

  const RecordSearch({
    this.page = 1,
    this.pageSize = 20,
    required this.type,
    this.name,
    this.detailName,
  });

  factory RecordSearch.fromJson(Map<String, dynamic> json) {
    return RecordSearch(
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      type: json['type'] as String? ?? '',
      name: json['name'] as String?,
      detailName: json['detailName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'detailName': detailName,
      'page': page,
      'pageSize': pageSize,
    };
  }

  @override
  List<Object?> get props => [type, name, detailName, page, pageSize];
}

/// 按定时任务搜索备份记录模型
class RecordSearchByCronjob extends Equatable {
  final int cronjobID;
  final int page;
  final int pageSize;

  const RecordSearchByCronjob({
    required this.cronjobID,
    this.page = 1,
    this.pageSize = 20,
  });

  factory RecordSearchByCronjob.fromJson(Map<String, dynamic> json) {
    return RecordSearchByCronjob(
      cronjobID:
          json['cronjobID'] as int? ?? json['cronjobId'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cronjobID': cronjobID,
      'page': page,
      'pageSize': pageSize,
    };
  }

  @override
  List<Object?> get props => [cronjobID, page, pageSize];
}

/// 文件大小搜索模型
class SearchForSize extends RecordSearch {
  final String? info;
  final String? order;
  final String? orderBy;
  final int? cronjobID;

  const SearchForSize({
    super.page,
    super.pageSize,
    required super.type,
    super.name,
    super.detailName,
    this.info,
    this.order,
    this.orderBy,
    this.cronjobID,
  });

  factory SearchForSize.fromJson(Map<String, dynamic> json) {
    return SearchForSize(
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      type: json['type'] as String? ?? '',
      name: json['name'] as String?,
      detailName: json['detailName'] as String?,
      info: json['info'] as String?,
      order: json['order'] as String?,
      orderBy: json['orderBy'] as String?,
      cronjobID:
          json['cronjobID'] as int? ?? json['cronjobId'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (info != null) json['info'] = info;
    if (order != null) json['order'] = order;
    if (orderBy != null) json['orderBy'] = orderBy;
    if (cronjobID != null) json['cronjobID'] = cronjobID;
    return json;
  }

  @override
  List<Object?> get props => [
        ...super.props,
        info,
        order,
        orderBy,
        cronjobID,
      ];
}

/// 文件记录大小模型
class RecordFileSize extends Equatable {
  final int id;
  final String name;
  final int size;

  const RecordFileSize({
    required this.id,
    required this.name,
    required this.size,
  });

  factory RecordFileSize.fromJson(Map<String, dynamic> json) {
    return RecordFileSize(
      id: json['id'] as int,
      name: json['name'] as String,
      size: json['size'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
    };
  }

  @override
  List<Object?> get props => [id, name, size];
}

/// 下载记录模型
class DownloadRecord extends Equatable {
  final int downloadAccountID;
  final String? fileDir;
  final String? fileName;

  const DownloadRecord({
    required this.downloadAccountID,
    this.fileDir,
    this.fileName,
  });

  factory DownloadRecord.fromJson(Map<String, dynamic> json) {
    return DownloadRecord(
      downloadAccountID: json['downloadAccountID'] as int,
      fileDir: json['fileDir'] as String?,
      fileName: json['fileName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'downloadAccountID': downloadAccountID,
      'fileDir': fileDir,
      'fileName': fileName,
    };
  }

  @override
  List<Object?> get props => [downloadAccountID, fileDir, fileName];
}

/// 通用备份模型
class CommonBackup extends Equatable {
  final String? detailName;
  final String? fileName;
  final String? name;
  final String? secret;
  final String? taskID;
  final List<String>? args;
  final String? description;
  final String type;

  const CommonBackup({
    this.detailName,
    this.fileName,
    this.name,
    this.secret,
    this.taskID,
    this.args,
    this.description,
    required this.type,
  });

  factory CommonBackup.fromJson(Map<String, dynamic> json) {
    return CommonBackup(
      detailName: json['detailName'] as String?,
      fileName: json['fileName'] as String?,
      name: json['name'] as String?,
      secret: json['secret'] as String?,
      taskID: json['taskID'] as String?,
      args: (json['args'] as List<dynamic>?)?.cast<String>(),
      description: json['description'] as String?,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detailName': detailName,
      'fileName': fileName,
      'name': name,
      'secret': secret,
      'taskID': taskID,
      'args': args,
      'description': description,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [
        detailName,
        fileName,
        name,
        secret,
        taskID,
        args,
        description,
        type,
      ];
}

/// 通用恢复模型
class CommonRecover extends CommonBackup {
  final int? backupRecordID;
  final String? file;
  final int? downloadAccountID;
  final int? timeout;

  const CommonRecover({
    super.detailName,
    super.fileName,
    super.name,
    super.secret,
    super.taskID,
    super.type = '',
    this.backupRecordID,
    this.file,
    this.downloadAccountID,
    this.timeout,
  });

  factory CommonRecover.fromJson(Map<String, dynamic> json) {
    return CommonRecover(
      detailName: json['detailName'] as String?,
      fileName: json['fileName'] as String?,
      name: json['name'] as String?,
      secret: json['secret'] as String?,
      taskID: json['taskID'] as String?,
      type: json['type'] as String,
      backupRecordID: json['backupRecordID'] as int?,
      file: json['file'] as String?,
      downloadAccountID: json['downloadAccountID'] as int?,
      timeout: json['timeout'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (backupRecordID != null) json['backupRecordID'] = backupRecordID;
    if (file != null) json['file'] = file;
    if (downloadAccountID != null) json['downloadAccountID'] = downloadAccountID;
    if (timeout != null) json['timeout'] = timeout;
    return json;
  }

  @override
  List<Object?> get props => [
        ...super.props,
        backupRecordID,
        file,
        downloadAccountID,
        timeout,
      ];
}

/// 备份使用情况模型
class BackupUsage extends Equatable {
  final int totalBackups;
  final int totalSize;
  final int usedSize;
  final double usedPercentage;
  final int lastBackupTime;
  final String? lastBackupStatus;

  const BackupUsage({
    required this.totalBackups,
    required this.totalSize,
    required this.usedSize,
    required this.usedPercentage,
    required this.lastBackupTime,
    this.lastBackupStatus,
  });

  factory BackupUsage.fromJson(Map<String, dynamic> json) {
    return BackupUsage(
      totalBackups: json['totalBackups'] as int,
      totalSize: json['totalSize'] as int,
      usedSize: json['usedSize'] as int,
      usedPercentage: (json['usedPercentage'] as num).toDouble(),
      lastBackupTime: json['lastBackupTime'] as int,
      lastBackupStatus: json['lastBackupStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBackups': totalBackups,
      'totalSize': totalSize,
      'usedSize': usedSize,
      'usedPercentage': usedPercentage,
      'lastBackupTime': lastBackupTime,
      'lastBackupStatus': lastBackupStatus,
    };
  }

  @override
  List<Object?> get props => [
        totalBackups,
        totalSize,
        usedSize,
        usedPercentage,
        lastBackupTime,
        lastBackupStatus,
      ];
}

/// 备份账户信息模型
class BackupAccountInfo extends Equatable {
  final int? id;
  final String name;
  final String type;
  final bool isPublic;
  final String? accessKey;
  final String? bucket;
  final String? backupPath;
  final String? createdAt;
  final String? updatedAt;
  final String? vars;
  final Map<String, dynamic>? varsJson;
  final bool? rememberAuth;
  final String? credential;

  const BackupAccountInfo({
    this.id,
    required this.name,
    required this.type,
    this.isPublic = false,
    this.accessKey,
    this.bucket,
    this.backupPath,
    this.createdAt,
    this.updatedAt,
    this.vars,
    this.varsJson,
    this.rememberAuth,
    this.credential,
  });

  factory BackupAccountInfo.fromJson(Map<String, dynamic> json) {
    return BackupAccountInfo(
      id: json['id'] as int?,
      name: json['name'] as String,
      type: json['type'] as String,
      isPublic: json['isPublic'] as bool? ?? false,
      accessKey: json['accessKey'] as String?,
      bucket: json['bucket'] as String?,
      backupPath: json['backupPath'] as String?,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      vars: json['vars'] as String?,
      varsJson: json['varsJson'] as Map<String, dynamic>?,
      rememberAuth: json['rememberAuth'] as bool?,
      credential: json['credential'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'isPublic': isPublic,
      'accessKey': accessKey,
      'bucket': bucket,
      'backupPath': backupPath,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'vars': vars,
      'varsJson': varsJson,
      'rememberAuth': rememberAuth,
      'credential': credential,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        isPublic,
        accessKey,
        bucket,
        backupPath,
        createdAt,
        updatedAt,
        vars,
        varsJson,
        rememberAuth,
        credential,
      ];
}

/// 备份账户搜索模型
class BackupAccountSearch extends Equatable {
  final int page;
  final int pageSize;
  final String? info;
  final String? type;

  const BackupAccountSearch({
    required this.page,
    required this.pageSize,
    this.info,
    this.type,
  });

  factory BackupAccountSearch.fromJson(Map<String, dynamic> json) {
    return BackupAccountSearch(
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      info: json['info'] as String? ?? json['search'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      'info': info,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [page, pageSize, info, type];
}

/// 备份文件搜索模型
class BackupFileSearch extends Equatable {
  final int? backupAccountId;
  final String? path;
  final String? prefix;
  final int page;
  final int pageSize;

  const BackupFileSearch({
    this.backupAccountId,
    this.path,
    this.prefix,
    required this.page,
    required this.pageSize,
  });

  factory BackupFileSearch.fromJson(Map<String, dynamic> json) {
    return BackupFileSearch(
      backupAccountId: json['backupAccountId'] as int?,
      path: json['path'] as String?,
      prefix: json['prefix'] as String?,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'backupAccountId': backupAccountId,
      'path': path,
      'prefix': prefix,
      'page': page,
      'pageSize': pageSize,
    };
  }

  @override
  List<Object?> get props => [backupAccountId, path, prefix, page, pageSize];
}

/// 备份文件模型
class BackupFile extends Equatable {
  final String name;
  final String path;
  final int size;
  final String? lastModified;
  final String? etag;
  final bool isDirectory;

  const BackupFile({
    required this.name,
    required this.path,
    required this.size,
    this.lastModified,
    this.etag,
    this.isDirectory = false,
  });

  factory BackupFile.fromJson(Map<String, dynamic> json) {
    return BackupFile(
      name: json['name'] as String,
      path: json['path'] as String,
      size: json['size'] as int,
      lastModified: json['lastModified'] as String?,
      etag: json['etag'] as String?,
      isDirectory: json['isDirectory'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'size': size,
      'lastModified': lastModified,
      'etag': etag,
      'isDirectory': isDirectory,
    };
  }

  @override
  List<Object?> get props => [name, path, size, lastModified, etag, isDirectory];
}

/// 备份记录模型
class BackupRecord extends Equatable {
  final int? id;
  final String? accountType;
  final String? accountName;
  final int? downloadAccountID;
  final String? fileDir;
  final String? fileName;
  final String? taskID;
  final String status;
  final String? message;
  final String? description;
  final String? createdAt;

  const BackupRecord({
    this.id,
    this.accountType,
    this.accountName,
    this.downloadAccountID,
    this.fileDir,
    this.fileName,
    this.taskID,
    this.description,
    required this.status,
    this.message,
    this.createdAt,
  });

  factory BackupRecord.fromJson(Map<String, dynamic> json) {
    return BackupRecord(
      id: json['id'] as int?,
      accountType: json['accountType'] as String?,
      accountName: json['accountName'] as String?,
      downloadAccountID: json['downloadAccountID'] as int?,
      fileDir: json['fileDir'] as String?,
      fileName: json['fileName'] as String?,
      taskID: json['taskID'] as String?,
      status: json['status'] as String,
      message: json['message'] as String?,
      description: json['description'] as String?,
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountType': accountType,
      'accountName': accountName,
      'downloadAccountID': downloadAccountID,
      'fileDir': fileDir,
      'fileName': fileName,
      'taskID': taskID,
      'status': status,
      'message': message,
      'description': description,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        accountType,
        accountName,
        downloadAccountID,
        fileDir,
        fileName,
        taskID,
        status,
        message,
        description,
        createdAt,
      ];
}

/// 备份验证请求模型
class BackupVerifyRequest extends Equatable {
  final int backupAccountId;
  final String filePath;
  final String? checksum;

  const BackupVerifyRequest({
    required this.backupAccountId,
    required this.filePath,
    this.checksum,
  });

  factory BackupVerifyRequest.fromJson(Map<String, dynamic> json) {
    return BackupVerifyRequest(
      backupAccountId: json['backupAccountId'] as int,
      filePath: json['filePath'] as String,
      checksum: json['checksum'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'backupAccountId': backupAccountId,
      'filePath': filePath,
      'checksum': checksum,
    };
  }

  @override
  List<Object?> get props => [backupAccountId, filePath, checksum];
}
