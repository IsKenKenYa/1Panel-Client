import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/features/backups/models/backup_account_draft.dart';
import 'package:onepanel_client/features/backups/models/backup_account_form_args.dart';
import 'package:onepanel_client/features/backups/services/backup_account_service.dart';
import 'package:onepanel_client/features/backups/services/backup_oauth_callback_service.dart';

class BackupAccountFormProvider extends ChangeNotifier with AsyncStateNotifier {
  BackupAccountFormProvider({
    BackupAccountService? service,
    BackupOauthCallbackService? callbackService,
  })  : _service = service ?? BackupAccountService(),
        _callbackService = callbackService ?? BackupOauthCallbackService();

  final BackupAccountService _service;
  final BackupOauthCallbackService _callbackService;

  BackupAccountDraft _draft = const BackupAccountDraft(type: 'SFTP');
  StreamSubscription<Uri>? _callbackSubscription;
  List<String> _bucketOptions = const <String>[];
  bool _isTesting = false;
  bool _isSaving = false;
  bool _isLoadingBuckets = false;
  bool _isConnectionVerified = false;
  String? _testMessage;

  BackupAccountDraft get draft => _draft;
  List<String> get bucketOptions => _bucketOptions;
  bool get isTesting => _isTesting;
  bool get isSaving => _isSaving;
  bool get isLoadingBuckets => _isLoadingBuckets;
  bool get isConnectionVerified => _isConnectionVerified;
  String? get testMessage => _testMessage;
  bool get isEditing => _draft.isEditing;
  bool get supportsBucketLoad => _service.supportsBucketLoad(_draft.type);
  bool get supportsOAuth => _service.supportsOAuth(_draft.type);
  bool get supportsRefreshToken => _service.supportsRefreshToken(_draft.type);
  List<String> get providerTypes => _service.creatableProviderTypes();
  bool get canSave =>
      !_isSaving &&
      !_isTesting &&
      _draft.type != 'LOCAL' &&
      _draft.name.trim().isNotEmpty &&
      _isConnectionVerified;

  Future<void> initialize(BackupAccountFormArgs? args) async {
    setLoading();
    try {
      await _callbackService.start();
      _callbackSubscription ??=
          _callbackService.callbacks.listen(_handleOAuthCallback);
      _draft = await _service.initializeDraft(args);
      if (!isEditing && _draft.type == 'LOCAL') {
        _draft = _draft.copyWith(
          type: 'SFTP',
          backupPath: '',
          vars: <String, dynamic>{'port': 22, 'authMode': 'password'},
        );
      }
      if (_service.supportsOAuth(_draft.type)) {
        _draft = await _service.preloadClientInfo(_draft);
      }
      final initial = _callbackService.consumeInitialUri();
      if (initial != null) {
        _handleOAuthCallback(initial);
      }
      setSuccess(isEmpty: false);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.backups.providers.account_form',
        'initialize failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error);
    }
  }

  void updateBasic({
    String? name,
    bool? isPublic,
  }) {
    _draft = _draft.copyWith(name: name, isPublic: isPublic);
    _resetVerification();
    notifyListeners();
  }

  Future<void> updateType(String type) async {
    final vars = switch (type) {
      'SFTP' => <String, dynamic>{'port': 22, 'authMode': 'password'},
      'OneDrive' => <String, dynamic>{'isCN': false},
      _ => <String, dynamic>{},
    };
    _draft = BackupAccountDraft(
      id: _draft.id,
      name: _draft.name,
      type: type,
      isPublic: _draft.isPublic,
      backupPath: type == 'LOCAL' ? _draft.backupPath : '',
      manualBucketInput: true,
      vars: vars,
    );
    if (_service.supportsOAuth(type)) {
      _draft = await _service.preloadClientInfo(_draft);
    }
    _bucketOptions = const <String>[];
    _resetVerification();
    notifyListeners();
  }

  void updateCommon({
    String? accessKey,
    String? credential,
    String? bucket,
    String? backupPath,
    bool? rememberAuth,
    bool? manualBucketInput,
  }) {
    _draft = _draft.copyWith(
      accessKey: accessKey,
      credential: credential,
      bucket: bucket,
      backupPath: backupPath,
      rememberAuth: rememberAuth,
      manualBucketInput: manualBucketInput,
    );
    _resetVerification();
    notifyListeners();
  }

  Future<void> updateOneDriveRegion(bool isCN) async {
    final vars = Map<String, dynamic>.from(_draft.vars);
    vars['isCN'] = isCN;
    _draft = _draft.copyWith(vars: vars);
    if (!isCN) {
      _draft = await _service.preloadClientInfo(_draft);
    }
    _resetVerification();
    notifyListeners();
  }

  void updateVar(String key, dynamic value) {
    final vars = Map<String, dynamic>.from(_draft.vars);
    vars[key] = value;
    _draft = _draft.copyWith(vars: vars);
    _resetVerification();
    notifyListeners();
  }

  Future<void> loadBuckets() async {
    _isLoadingBuckets = true;
    clearError(notify: false);
    notifyListeners();
    try {
      final raw = await _service.loadBuckets(_draft);
      _bucketOptions =
          raw.map((dynamic item) => item.toString()).toList(growable: false);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.backups.providers.account_form',
        'loadBuckets failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
    } finally {
      _isLoadingBuckets = false;
      notifyListeners();
    }
  }

  Future<bool> testConnection() async {
    _isTesting = true;
    _testMessage = null;
    clearError(notify: false);
    notifyListeners();
    try {
      final result = await _service.testConnection(_draft);
      _isConnectionVerified = result.isOk;
      _testMessage = result.msg;
      if (result.isOk &&
          result.token != null &&
          result.token!.isNotEmpty &&
          _service.supportsOAuth(_draft.type)) {
        final vars = Map<String, dynamic>.from(_draft.vars);
        vars['refresh_token'] =
            utf8.decode(base64Decode(result.token!), allowMalformed: true);
        _draft = _draft.copyWith(vars: vars);
      }
      return result.isOk;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.backups.providers.account_form',
        'testConnection failed',
        error: error,
        stackTrace: stackTrace,
      );
      _isConnectionVerified = false;
      _testMessage = error.toString();
      setError(error, notify: false);
      return false;
    } finally {
      _isTesting = false;
      notifyListeners();
    }
  }

  Future<void> startOAuth() {
    return _service.openOAuthAuthorizePage(_draft);
  }

  void applyAliyunToken(String tokenJson) {
    _draft = _service.applyAliyunToken(_draft, tokenJson);
    _resetVerification();
    notifyListeners();
  }

  Future<bool> save() async {
    if (_draft.name.trim().isEmpty || !_isConnectionVerified) {
      return false;
    }
    _isSaving = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.saveDraft(_draft);
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.backups.providers.account_form',
        'save failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _handleOAuthCallback(Uri uri) {
    _draft = _service.applyOauthCallback(_draft, uri);
    _resetVerification();
    notifyListeners();
  }

  void _resetVerification() {
    _isConnectionVerified = false;
    _testMessage = null;
  }

  @override
  void dispose() {
    _callbackSubscription?.cancel();
    _callbackService.dispose();
    super.dispose();
  }
}
