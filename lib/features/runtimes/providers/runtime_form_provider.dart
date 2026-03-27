import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_form_args.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_form_draft.dart';
import 'package:onepanel_client/features/runtimes/services/runtime_service.dart';

class RuntimeFormProvider extends ChangeNotifier with AsyncStateNotifier {
  RuntimeFormProvider({
    RuntimeService? service,
  })  : _service = service ?? RuntimeService(),
        _draft = (service ?? RuntimeService())
            .createDraft(RuntimeService.orderedTypes.first);

  final RuntimeService _service;
  RuntimeFormDraft _draft;
  bool _isSaving = false;

  RuntimeFormDraft get draft => _draft;
  bool get isSaving => _isSaving;
  bool get isEditing => _draft.isEditing;

  bool get canSave {
    if (_isSaving) return false;
    if (_draft.name.trim().isEmpty) return false;
    if (_draft.port <= 0) return false;
    if (_draft.codeDir.trim().isEmpty) return false;
    if (_draft.containerName.trim().isEmpty) return false;
    if (_draft.resource == 'appstore' && !_draft.isEditing) return false;
    if (_draft.isPhp && !_draft.isEditing) return false;
    if (_draft.image.trim().isEmpty) return false;
    if (!_draft.isPhp && _draft.execScript.trim().isEmpty) return false;
    if (_draft.isNode && _draft.packageManager.trim().isEmpty) return false;
    return true;
  }

  Future<void> initialize(RuntimeFormArgs? args) async {
    setLoading();
    try {
      final runtimeId = args?.runtimeId;
      if (runtimeId == null) {
        _draft = _service.createDraft(args?.initialType ?? 'php');
        setSuccess(isEmpty: false);
        return;
      }
      final detail = await _service.getRuntimeDetail(runtimeId);
      if (detail == null) {
        setError('runtime.form.loadFailed');
        return;
      }
      _draft = _service.draftFromRuntime(detail);
      setSuccess(isEmpty: false);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.form',
        'initialize failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError('runtime.form.loadFailed');
    } finally {
      notifyListeners();
    }
  }

  void updateBasic({
    String? type,
    String? name,
    String? resource,
    String? version,
  }) {
    final nextType = type ?? _draft.type;
    _draft = _draft.copyWith(
      type: nextType,
      name: name,
      resource: resource,
      version: version,
      image: type != null ? _service.defaultImage(nextType) : null,
      source: type != null ? _service.defaultSource(nextType) : null,
      execScript: type != null ? _service.defaultExecScript(nextType) : null,
      packageManager: type != null ? (nextType == 'node' ? 'npm' : '') : null,
    );
    notifyListeners();
  }

  void updateRuntimeConfig({
    String? image,
    String? codeDir,
    int? port,
    String? source,
    String? hostIp,
    String? containerName,
    String? execScript,
    String? packageManager,
  }) {
    _draft = _draft.copyWith(
      image: image,
      codeDir: codeDir,
      port: port,
      source: source,
      hostIp: hostIp,
      containerName: containerName,
      execScript: execScript,
      packageManager: packageManager,
    );
    notifyListeners();
  }

  void updateAdvanced({
    String? remark,
    bool? rebuild,
  }) {
    _draft = _draft.copyWith(
      remark: remark,
      rebuild: rebuild,
    );
    notifyListeners();
  }

  Future<bool> save() async {
    final validationError = _validate();
    if (validationError != null) {
      setError(validationError);
      return false;
    }
    _isSaving = true;
    clearError(notify: false);
    notifyListeners();
    try {
      if (_draft.isEditing) {
        await _service.updateRuntime(_draft);
      } else {
        await _service.createRuntime(_draft);
      }
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.form',
        'save failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError('runtime.form.saveFailed', notify: false);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  String? _validate() {
    if (_draft.name.trim().isEmpty) return 'runtime.form.nameRequired';
    if (_draft.resource == 'appstore' && !_draft.isEditing) {
      return 'runtime.form.week8AppStoreCreate';
    }
    if (_draft.isPhp && !_draft.isEditing) {
      return 'runtime.form.week8PhpCreate';
    }
    if (_draft.image.trim().isEmpty) return 'runtime.form.imageRequired';
    if (_draft.codeDir.trim().isEmpty) return 'runtime.form.codeDirRequired';
    if (_draft.port <= 0) return 'runtime.form.portInvalid';
    if (_draft.containerName.trim().isEmpty) {
      return 'runtime.form.containerRequired';
    }
    if (!_draft.isPhp && _draft.execScript.trim().isEmpty) {
      return 'runtime.form.execScriptRequired';
    }
    if (_draft.isNode && _draft.packageManager.trim().isEmpty) {
      return 'runtime.form.packageManagerRequired';
    }
    return null;
  }
}
