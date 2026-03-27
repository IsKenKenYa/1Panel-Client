import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';

import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/data/models/backup_request_models.dart';
import 'package:onepanel_client/data/repositories/backup_repository.dart';
import 'package:onepanel_client/features/backups/models/backup_account_draft.dart';
import 'package:onepanel_client/features/backups/models/backup_account_form_args.dart';

class BackupAccountService {
  BackupAccountService({
    BackupRepository? repository,
  }) : _repository = repository ?? BackupRepository();

  final BackupRepository _repository;

  Future<List<BackupAccountInfo>> searchAccounts({
    String? keyword,
    String? type,
  }) async {
    final result = await _repository.searchAccounts(
      BackupAccountSearchRequest(
        page: 1,
        pageSize: 100,
        keyword: keyword,
        type: type,
      ),
    );
    return result.items.map(_inflateInfo).toList(growable: false);
  }

  Future<BackupAccountDraft> initializeDraft(
      BackupAccountFormArgs? args) async {
    final initial = args?.initialValue;
    if (initial == null) {
      final localDir = await _repository.getLocalDir();
      return BackupAccountDraft(
        type: 'LOCAL',
        backupPath: localDir,
        manualBucketInput: true,
      );
    }
    final info = _inflateInfo(initial);
    return BackupAccountDraft(
      id: info.id,
      name: info.name,
      type: info.type,
      isPublic: info.isPublic,
      accessKey: _decodeCredential(info.accessKey, info.rememberAuth ?? false),
      credential:
          _decodeCredential(info.credential, info.rememberAuth ?? false),
      bucket: info.bucket ?? '',
      backupPath: info.backupPath ?? '',
      rememberAuth: info.rememberAuth ?? false,
      manualBucketInput: true,
      vars: info.varsJson ?? const <String, dynamic>{},
    );
  }

  Future<List<dynamic>> loadBuckets(BackupAccountDraft draft) {
    return _repository.loadBuckets(
      BackupBucketRequest(
        type: draft.type,
        accessKey: draft.accessKey,
        credential: draft.credential,
        vars: jsonEncode(_sanitizeVars(draft.type, draft.vars)),
      ),
    );
  }

  Future<BackupCheckResult> testConnection(BackupAccountDraft draft) {
    return _repository.checkConnection(_toOperate(draft));
  }

  Future<void> saveDraft(BackupAccountDraft draft) async {
    final request = _toOperate(draft);
    if (draft.isEditing) {
      await _repository.updateAccount(request);
      return;
    }
    await _repository.createAccount(request);
  }

  Future<void> deleteAccount(BackupAccountInfo account) {
    return _repository.deleteAccount(account);
  }

  Future<void> refreshToken(BackupAccountInfo account) {
    return _repository.refreshToken(account);
  }

  Future<List<String>> listFiles(int accountId) {
    return _repository.listFiles(accountId);
  }

  Future<BackupAccountDraft> preloadClientInfo(BackupAccountDraft draft) async {
    final clientType = switch (draft.type) {
      'OneDrive' => 'Onedrive',
      'GoogleDrive' => 'GoogleDrive',
      _ => '',
    };
    if (clientType.isEmpty) {
      return draft;
    }
    final info = await _repository.getClientInfo(clientType);
    final vars = Map<String, dynamic>.from(draft.vars);
    vars['client_id'] = info.clientId ?? '';
    vars['client_secret'] = info.clientSecret ?? '';
    vars['redirect_uri'] = 'onepanel://backup/oauth';
    if (draft.type == 'OneDrive' && !vars.containsKey('isCN')) {
      vars['isCN'] = false;
    }
    return draft.copyWith(vars: vars);
  }

  Future<void> openOAuthAuthorizePage(BackupAccountDraft draft) async {
    final uri = buildAuthorizeUri(draft);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('backup.oauthOpenFailed');
    }
  }

  Uri buildAuthorizeUri(BackupAccountDraft draft) {
    if (draft.type == 'OneDrive') {
      final base = draft.boolVar('isCN')
          ? 'https://login.chinacloudapi.cn/common/oauth2/v2.0/authorize'
          : 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';
      return Uri.parse(base).replace(queryParameters: <String, String>{
        'response_type': 'code',
        'client_id': draft.stringVar('client_id'),
        'redirect_uri': draft.stringVar('redirect_uri'),
        'scope': 'offline_access Files.ReadWrite.All User.Read',
      });
    }
    if (draft.type == 'GoogleDrive') {
      return Uri.parse(
        'https://accounts.google.com/o/oauth2/auth/oauthchooseaccount',
      ).replace(queryParameters: <String, String>{
        'client_id': draft.stringVar('client_id'),
        'response_type': 'code',
        'redirect_uri': draft.stringVar('redirect_uri'),
        'scope':
            'openid profile https://www.googleapis.com/auth/drive https://www.googleapis.com/auth/photoslibrary',
        'access_type': 'offline',
        'prompt': 'consent',
        'service': 'lso',
        'o2v': '1',
        'ddm': '1',
        'flowName': 'GeneralOAuthFlow',
      });
    }
    throw Exception('backup.oauthUnsupportedProvider');
  }

  BackupAccountDraft applyOauthCallback(
    BackupAccountDraft draft,
    Uri uri,
  ) {
    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      return draft;
    }
    final vars = Map<String, dynamic>.from(draft.vars);
    vars['code'] = Uri.decodeComponent(code);
    return draft.copyWith(vars: vars);
  }

  BackupAccountDraft applyAliyunToken(
    BackupAccountDraft draft,
    String tokenJson,
  ) {
    final parsed = jsonDecode(tokenJson) as Map<String, dynamic>;
    final vars = Map<String, dynamic>.from(draft.vars);
    vars['token'] = tokenJson;
    vars['drive_id'] = parsed['default_drive_id']?.toString() ?? '';
    vars['refresh_token'] = parsed['refresh_token']?.toString() ?? '';
    return draft.copyWith(vars: vars);
  }

  String endpointText(BackupAccountInfo account) {
    final vars = account.varsJson ?? const <String, dynamic>{};
    return switch (account.type) {
      'KODO' => vars['domain']?.toString() ?? '',
      'COS' || 'MINIO' || 'OSS' || 'S3' => vars['endpoint']?.toString() ?? '',
      _ => '',
    };
  }

  bool isReadOnlyLocal(BackupAccountInfo account) {
    return account.type == 'LOCAL' ||
        account.name.toLowerCase() == 'localhost' ||
        (account.id ?? -1) == 0;
  }

  bool supportsBucketLoad(String type) {
    return const <String>{'S3', 'MINIO', 'OSS', 'COS', 'KODO', 'UPYUN'}
        .contains(type);
  }

  bool supportsRefreshToken(String type) {
    return type == 'OneDrive' || type == 'ALIYUN';
  }

  bool supportsOAuth(String type) {
    return type == 'OneDrive' || type == 'GoogleDrive';
  }

  List<String> creatableProviderTypes() {
    return const <String>[
      'SFTP',
      'WebDAV',
      'S3',
      'MINIO',
      'OSS',
      'COS',
      'KODO',
      'UPYUN',
      'OneDrive',
      'GoogleDrive',
      'ALIYUN',
    ];
  }

  BackupAccountInfo _inflateInfo(BackupAccountInfo info) {
    final rawVars = info.vars?.trim();
    Map<String, dynamic> varsJson = info.varsJson ?? const <String, dynamic>{};
    if (rawVars != null && rawVars.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawVars);
        if (decoded is Map<String, dynamic>) {
          varsJson = decoded;
        }
      } catch (_) {
        varsJson = const <String, dynamic>{};
      }
    }
    return BackupAccountInfo(
      id: info.id,
      name: info.name,
      type: info.type,
      isPublic: info.isPublic,
      accessKey: info.accessKey,
      bucket: info.bucket,
      backupPath: info.backupPath,
      createdAt: info.createdAt,
      updatedAt: info.updatedAt,
      vars: info.vars,
      varsJson: varsJson,
      rememberAuth: info.rememberAuth,
      credential: info.credential,
    );
  }

  BackupOperate _toOperate(BackupAccountDraft draft) {
    return BackupOperate(
      id: draft.id,
      name: draft.name.trim(),
      type: draft.type,
      isPublic: draft.isPublic,
      accessKey: draft.accessKey.trim().isEmpty ? null : draft.accessKey.trim(),
      credential:
          draft.credential.trim().isEmpty ? null : draft.credential.trim(),
      bucket: draft.bucket.trim().isEmpty ? null : draft.bucket.trim(),
      backupPath:
          draft.backupPath.trim().isEmpty ? null : draft.backupPath.trim(),
      rememberAuth: draft.rememberAuth,
      vars: jsonEncode(_sanitizeVars(draft.type, draft.vars)),
    );
  }

  Map<String, dynamic> _sanitizeVars(
    String type,
    Map<String, dynamic> vars,
  ) {
    final sanitized = Map<String, dynamic>.from(vars);
    sanitized.removeWhere((key, value) => value == null || value == '');
    if (type == 'OneDrive' || type == 'GoogleDrive') {
      sanitized['redirect_uri'] =
          sanitized['redirect_uri'] ?? 'onepanel://backup/oauth';
    }
    if (type == 'ALIYUN') {
      sanitized.remove('token');
    }
    return sanitized;
  }

  String _decodeCredential(String? value, bool rememberAuth) {
    if (!rememberAuth || value == null || value.isEmpty) {
      return value ?? '';
    }
    try {
      return utf8.decode(base64Decode(value), allowMalformed: true);
    } catch (_) {
      return value;
    }
  }
}
