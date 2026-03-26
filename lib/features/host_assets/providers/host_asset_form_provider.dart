import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/host_asset_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/host_assets/models/host_asset_form_args.dart';
import 'package:onepanel_client/features/host_assets/services/host_asset_service.dart';

class HostAssetFormProvider extends ChangeNotifier with AsyncStateNotifier {
  HostAssetFormProvider({
    HostAssetService? service,
  }) : _service = service ?? HostAssetService();

  final HostAssetService _service;

  List<GroupInfo> _groups = const <GroupInfo>[];
  late HostOperate _draft;
  bool _isTesting = false;
  bool _isSaving = false;
  bool _isConnectionVerified = false;
  String? _testMessage;

  List<GroupInfo> get groups => _groups;
  HostOperate get draft => _draft;
  bool get isTesting => _isTesting;
  bool get isSaving => _isSaving;
  bool get isEditing => _draft.id != null;
  bool get isConnectionVerified => _isConnectionVerified;
  String? get testMessage => _testMessage;

  bool get canSave =>
      !_isSaving &&
      !_isTesting &&
      _draft.name.trim().isNotEmpty &&
      _draft.addr.trim().isNotEmpty &&
      _draft.user.trim().isNotEmpty &&
      _draft.groupID != null &&
      _isConnectionVerified;

  Future<void> initialize(HostAssetFormArgs? args) async {
    final initial = args?.initialValue;
    _draft = initial == null
        ? const HostOperate(
            name: '',
            addr: '',
            port: 22,
            user: 'root',
            authMode: 'password',
            rememberPassword: false,
          )
        : _service.fromHostInfo(initial);

    setLoading();
    try {
      _groups = await _service.loadGroups();
      _draft = _draft.copyWith(
        groupID: _draft.groupID ?? _service.resolveDefaultGroupId(_groups),
      );
      setSuccess(isEmpty: false);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.host_assets.providers.form',
        'initialize failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error);
    }
  }

  void updateBasic({
    String? name,
    int? groupID,
    String? addr,
    int? port,
    String? description,
  }) {
    final previous = _draft;
    _draft = _draft.copyWith(
      name: name,
      groupID: groupID,
      addr: addr,
      port: port,
      description: description,
    );
    _resetVerificationIfNeeded(
      previous: previous,
      current: _draft,
      connectionFieldsChanged: addr != null || port != null,
    );
    notifyListeners();
  }

  void updateAuth({
    String? user,
    String? authMode,
    String? password,
    String? privateKey,
    String? passPhrase,
    bool? rememberPassword,
  }) {
    final nextAuthMode = authMode ?? _draft.authMode;
    final previous = _draft;
    _draft = _draft.copyWith(
      user: user,
      authMode: nextAuthMode,
      password: nextAuthMode == 'password' ? password : '',
      privateKey: nextAuthMode == 'key' ? privateKey : '',
      passPhrase: nextAuthMode == 'key' ? passPhrase : '',
      rememberPassword: rememberPassword,
    );
    _resetVerificationIfNeeded(
      previous: previous,
      current: _draft,
      connectionFieldsChanged: true,
    );
    notifyListeners();
  }

  Future<bool> testConnection() async {
    _isTesting = true;
    _testMessage = null;
    notifyListeners();
    try {
      final success = await _service.testHostByInfo(
        HostConnTest(
          addr: _draft.addr,
          port: _draft.port,
          user: _draft.user,
          authMode: _draft.authMode,
          password: _draft.authMode == 'password' ? _draft.password : null,
          privateKey: _draft.authMode == 'key' ? _draft.privateKey : null,
          passPhrase: _draft.authMode == 'key' ? _draft.passPhrase : null,
        ),
      );
      _isConnectionVerified = success;
      _testMessage = success ? 'success' : 'failed';
      return success;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.host_assets.providers.form',
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

  Future<bool> save() async {
    if (!canSave) {
      return false;
    }
    _isSaving = true;
    clearError(notify: false);
    notifyListeners();
    try {
      if (isEditing) {
        await _service.updateHost(_draft);
      } else {
        await _service.createHost(_draft);
      }
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.host_assets.providers.form',
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

  void _resetVerificationIfNeeded({
    required HostOperate previous,
    required HostOperate current,
    required bool connectionFieldsChanged,
  }) {
    if (!connectionFieldsChanged) {
      return;
    }
    if (previous.addr != current.addr ||
        previous.port != current.port ||
        previous.user != current.user ||
        previous.authMode != current.authMode ||
        previous.password != current.password ||
        previous.privateKey != current.privateKey ||
        previous.passPhrase != current.passPhrase) {
      _isConnectionVerified = false;
      _testMessage = null;
    }
  }
}
