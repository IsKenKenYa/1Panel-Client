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
  final Map<String, dynamic>? vars;

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
      vars: json['vars'] as Map<String, dynamic>?,
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

/// 备份记录搜索模型
class RecordSearch extends Equatable {
  final String? name;
  final String? type;
  final String? detailName;
  final int page;
  final int pageSize;

  const RecordSearch({
    this.name,
    this.type,
    this.detailName,
    this.page = 1,
    this.pageSize = 20,
  });

  factory RecordSearch.fromJson(Map<String, dynamic> json) {
    return RecordSearch(
      name: json['name'] as String?,
      type: json['type'] as String?,
      detailName: json['detailName'] as String?,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
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
  List<Object?> get props => [name, type, detailName, page, pageSize];
}

/// 按定时任务搜索备份记录模型
class RecordSearchByCronjob extends Equatable {
  final int cronjobId;
  final int page;
  final int pageSize;

  const RecordSearchByCronjob({
    required this.cronjobId,
    this.page = 1,
    this.pageSize = 20,
  });

  factory RecordSearchByCronjob.fromJson(Map<String, dynamic> json) {
    return RecordSearchByCronjob(
      cronjobId: json['cronjobId'] as int,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cronjobId': cronjobId,
      'page': page,
      'pageSize': pageSize,
    };
  }

  @override
  List<Object?> get props => [cronjobId, page, pageSize];
}

/// 文件大小搜索模型
class SearchForSize extends RecordSearch {
  final String? info;
  final String? order;
  final String? orderBy;

  const SearchForSize({
    super.name,
    super.type,
    super.detailName,
    super.page,
    super.pageSize,
    this.info,
    this.order,
    this.orderBy,
  });

  factory SearchForSize.fromJson(Map<String, dynamic> json) {
    return SearchForSize(
      name: json['name'] as String?,
      type: json['type'] as String?,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      detailName: json['detailName'] as String?,
      info: json['info'] as String?,
      order: json['order'] as String?,
      orderBy: json['orderBy'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (detailName != null) json['detailName'] = detailName;
    if (info != null) json['info'] = info;
    if (order != null) json['order'] = order;
    if (orderBy != null) json['orderBy'] = orderBy;
    return json;
  }

  @override
  List<Object?> get props => [
        ...super.props,
        detailName,
        info,
        order,
        orderBy,
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
  final String type;

  const CommonBackup({
    this.detailName,
    this.fileName,
    this.name,
    this.secret,
    this.taskID,
    required this.type,
  });

  factory CommonBackup.fromJson(Map<String, dynamic> json) {
    return CommonBackup(
      detailName: json['detailName'] as String?,
      fileName: json['fileName'] as String?,
      name: json['name'] as String?,
      secret: json['secret'] as String?,
      taskID: json['taskID'] as String?,
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
        type,
      ];
}

/// 通用恢复模型
class CommonRecover extends CommonBackup {
  final int? backupRecordID;
  final String? file;
  final int? downloadAccountID;

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
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (backupRecordID != null) json['backupRecordID'] = backupRecordID;
    if (file != null) json['file'] = file;
    if (downloadAccountID != null) json['downloadAccountID'] = downloadAccountID;
    return json;
  }

  @override
  List<Object?> get props => [
        ...super.props,
        backupRecordID,
        file,
        downloadAccountID,
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
  final Map<String, dynamic>? vars;

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
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      vars: json['vars'] as Map<String, dynamic>?,
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
      ];
}

/// 备份账户搜索模型
class BackupAccountSearch extends Equatable {
  final int page;
  final int pageSize;
  final String? search;
  final String? type;

  const BackupAccountSearch({
    required this.page,
    required this.pageSize,
    this.search,
    this.type,
  });

  factory BackupAccountSearch.fromJson(Map<String, dynamic> json) {
    return BackupAccountSearch(
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      search: json['search'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      'search': search,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [page, pageSize, search, type];
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
  final String name;
  final String type;
  final String? accountType;
  final String? accountName;
  final int? downloadAccountID;
  final String? fileDir;
  final String? fileName;
  final String? detailName;
  final int? backupAccountId;
  final String? backupPath;
  final int size;
  final String status;
  final String? taskID;
  final String? message;
  final String? description;
  final String? createdAt;
  final String? updatedAt;
  final String? backupTime;
  final String? recoverTime;

  const BackupRecord({
    this.id,
    required this.name,
    required this.type,
    this.accountType,
    this.accountName,
    this.downloadAccountID,
    this.fileDir,
    this.fileName,
    this.detailName,
    this.backupAccountId,
    this.backupPath,
    required this.size,
    required this.status,
    this.taskID,
    this.message,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.backupTime,
    this.recoverTime,
  });

  factory BackupRecord.fromJson(Map<String, dynamic> json) {
    return BackupRecord(
      id: json['id'] as int?,
      name: json['name'] as String,
      type: json['type'] as String,
      accountType: json['accountType'] as String?,
      accountName: json['accountName'] as String?,
      downloadAccountID: json['downloadAccountID'] as int?,
      fileDir: json['fileDir'] as String?,
      fileName: json['fileName'] as String?,
      detailName: json['detailName'] as String?,
      backupAccountId: json['backupAccountId'] as int?,
      backupPath: json['backupPath'] as String?,
      size: json['size'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      taskID: json['taskID'] as String?,
      message: json['message'] as String?,
      description: json['description'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      backupTime: json['backupTime'] as String?,
      recoverTime: json['recoverTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'accountType': accountType,
      'accountName': accountName,
      'downloadAccountID': downloadAccountID,
      'fileDir': fileDir,
      'fileName': fileName,
      'detailName': detailName,
      'backupAccountId': backupAccountId,
      'backupPath': backupPath,
      'size': size,
      'status': status,
      'taskID': taskID,
      'message': message,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'backupTime': backupTime,
      'recoverTime': recoverTime,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        accountType,
        accountName,
        downloadAccountID,
        fileDir,
        fileName,
        detailName,
        backupAccountId,
        backupPath,
        size,
        status,
        taskID,
        message,
        description,
        createdAt,
        updatedAt,
        backupTime,
        recoverTime,
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
