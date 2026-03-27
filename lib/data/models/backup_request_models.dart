import 'package:equatable/equatable.dart';

class BackupAccountSearchRequest extends Equatable {
  const BackupAccountSearchRequest({
    this.page = 1,
    this.pageSize = 20,
    this.keyword,
    this.type,
  });

  final int page;
  final int pageSize;
  final String? keyword;
  final String? type;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        'info': keyword ?? '',
        'name': keyword ?? '',
        'type': type ?? '',
      };

  @override
  List<Object?> get props => <Object?>[page, pageSize, keyword, type];
}

class BackupBucketRequest extends Equatable {
  const BackupBucketRequest({
    required this.type,
    required this.accessKey,
    required this.credential,
    required this.vars,
  });

  final String type;
  final String accessKey;
  final String credential;
  final String vars;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'accessKey': accessKey,
        'credential': credential,
        'vars': vars,
      };

  @override
  List<Object?> get props => <Object?>[type, accessKey, credential, vars];
}

class BackupRecordQuery extends Equatable {
  const BackupRecordQuery({
    required this.type,
    this.name = '',
    this.detailName = '',
    this.page = 1,
    this.pageSize = 20,
  });

  final String type;
  final String name;
  final String detailName;
  final int page;
  final int pageSize;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'name': name,
        'detailName': detailName,
        'page': page,
        'pageSize': pageSize,
      };

  @override
  List<Object?> get props => <Object?>[type, name, detailName, page, pageSize];
}

class BackupRecordByCronjobQuery extends Equatable {
  const BackupRecordByCronjobQuery({
    required this.cronjobID,
    this.page = 1,
    this.pageSize = 20,
  });

  final int cronjobID;
  final int page;
  final int pageSize;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'cronjobID': cronjobID,
        'page': page,
        'pageSize': pageSize,
      };

  @override
  List<Object?> get props => <Object?>[cronjobID, page, pageSize];
}

class BackupRecordSizeQuery extends Equatable {
  const BackupRecordSizeQuery({
    required this.type,
    this.name = '',
    this.detailName = '',
    this.info = '',
    this.cronjobID,
    this.orderBy = '',
    this.order = '',
    this.page = 1,
    this.pageSize = 100,
  });

  final String type;
  final String name;
  final String detailName;
  final String info;
  final int? cronjobID;
  final String orderBy;
  final String order;
  final int page;
  final int pageSize;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'name': name,
        'detailName': detailName,
        'info': info,
        'cronjobID': cronjobID ?? 0,
        'orderBy': orderBy,
        'order': order,
        'page': page,
        'pageSize': pageSize,
      };

  @override
  List<Object?> get props => <Object?>[
        type,
        name,
        detailName,
        info,
        cronjobID,
        orderBy,
        order,
        page,
        pageSize,
      ];
}

class BackupRunRequest extends Equatable {
  const BackupRunRequest({
    required this.type,
    this.name = '',
    this.detailName = '',
    this.secret = '',
    required this.taskID,
    this.fileName = '',
    this.args = const <String>[],
    this.description = '',
    this.stopBefore = false,
  });

  final String type;
  final String name;
  final String detailName;
  final String secret;
  final String taskID;
  final String fileName;
  final List<String> args;
  final String description;
  final bool stopBefore;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'name': name,
        'detailName': detailName,
        'secret': secret,
        'taskID': taskID,
        'fileName': fileName,
        'args': args,
        'description': description,
        'stopBefore': stopBefore,
      };

  @override
  List<Object?> get props => <Object?>[
        type,
        name,
        detailName,
        secret,
        taskID,
        fileName,
        args,
        description,
        stopBefore,
      ];
}

class BackupRecoverRequest extends Equatable {
  const BackupRecoverRequest({
    required this.downloadAccountID,
    required this.type,
    this.name = '',
    this.detailName = '',
    required this.file,
    this.secret = '',
    required this.taskID,
    this.backupRecordID,
    this.timeout,
  });

  final int downloadAccountID;
  final String type;
  final String name;
  final String detailName;
  final String file;
  final String secret;
  final String taskID;
  final int? backupRecordID;
  final int? timeout;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'downloadAccountID': downloadAccountID,
        'type': type,
        'name': name,
        'detailName': detailName,
        'file': file,
        'secret': secret,
        'taskID': taskID,
        if (backupRecordID != null) 'backupRecordID': backupRecordID,
        if (timeout != null) 'timeout': timeout,
      };

  @override
  List<Object?> get props => <Object?>[
        downloadAccountID,
        type,
        name,
        detailName,
        file,
        secret,
        taskID,
        backupRecordID,
        timeout,
      ];
}

class BackupUploadRequest extends Equatable {
  const BackupUploadRequest({
    required this.filePath,
    required this.targetDir,
  });

  final String filePath;
  final String targetDir;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'filePath': filePath,
        'targetDir': targetDir,
      };

  @override
  List<Object?> get props => <Object?>[filePath, targetDir];
}
