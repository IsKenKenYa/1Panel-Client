import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/data/repositories/runtime_repository.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_form_draft.dart';

class RuntimeService {
  RuntimeService({
    RuntimeRepository? repository,
  }) : _repository = repository ?? RuntimeRepository();

  final RuntimeRepository _repository;

  static const List<String> orderedTypes = <String>[
    'php',
    'node',
    'java',
    'go',
    'python',
    'dotnet',
  ];

  Future<PageResult<RuntimeInfo>> searchRuntimes({
    required String type,
    String? name,
    String? status,
  }) {
    return _repository.searchRuntimes(
      RuntimeSearch(
        type: type,
        name: name?.trim().isEmpty == true ? null : name?.trim(),
        status: status?.trim().isEmpty == true ? null : status?.trim(),
      ),
    );
  }

  Future<RuntimeInfo?> getRuntimeDetail(int id) {
    return _repository.getRuntime(id);
  }

  Future<RuntimeInfo?> createRuntime(RuntimeFormDraft draft) {
    return _repository.createRuntime(buildCreateRequest(draft));
  }

  Future<void> updateRuntime(RuntimeFormDraft draft) {
    return _repository.updateRuntime(buildUpdateRequest(draft));
  }

  Future<void> deleteRuntime(int id) {
    return _repository.deleteRuntime(RuntimeDelete(id: id));
  }

  Future<void> operateRuntime(int id, String operate) {
    return _repository.operateRuntime(RuntimeOperate(id: id, operate: operate));
  }

  Future<void> syncRuntimeStatus() {
    return _repository.syncRuntimeStatus();
  }

  Future<void> updateRuntimeRemark(int id, String remark) {
    final normalized = remark.trim();
    if (normalized.length > 128) {
      throw Exception('runtime.remark.tooLong');
    }
    return _repository.updateRuntimeRemark(
      RuntimeRemarkUpdate(id: id, remark: normalized),
    );
  }

  RuntimeFormDraft createDraft(String type) {
    final normalizedType = orderedTypes.contains(type) ? type : 'php';
    return RuntimeFormDraft(
      type: normalizedType,
      image: defaultImage(normalizedType),
      source: defaultSource(normalizedType),
      execScript: defaultExecScript(normalizedType),
      packageManager: normalizedType == 'node' ? 'npm' : '',
    );
  }

  RuntimeFormDraft draftFromRuntime(RuntimeInfo info) {
    final params = info.params ?? const <String, dynamic>{};
    final portValue = int.tryParse(info.port ?? '');
    return RuntimeFormDraft(
      id: info.id,
      appDetailId: info.appDetailId,
      appId: info.appId,
      type: info.type ?? 'php',
      name: info.name ?? '',
      resource: info.resource ?? 'local',
      image: info.image ?? '',
      version: info.version ?? '',
      source: info.source ?? defaultSource(info.type ?? 'php'),
      codeDir: info.codeDir ?? '/',
      port: portValue ?? 8080,
      remark: info.remark ?? '',
      hostIp: params['HOST_IP']?.toString() ?? '0.0.0.0',
      containerName: params['CONTAINER_NAME']?.toString() ?? info.name ?? '',
      execScript: params['EXEC_SCRIPT']?.toString() ??
          defaultExecScript(info.type ?? 'php'),
      packageManager: params['PACKAGE_MANAGER']?.toString() ??
          (info.type == 'node' ? 'npm' : ''),
      rebuild: true,
      exposedPorts: info.exposedPorts ?? const <RuntimeExposedPort>[],
      environments: info.environments ?? const <RuntimeEnvironment>[],
      volumes: info.volumes ?? const <RuntimeVolume>[],
      extraHosts: info.extraHosts ?? const <RuntimeExtraHost>[],
    );
  }

  RuntimeCreate buildCreateRequest(RuntimeFormDraft draft) {
    return RuntimeCreate(
      appDetailId: draft.resource == 'appstore' ? draft.appDetailId : null,
      appId: draft.resource == 'appstore' ? draft.appId : null,
      name: draft.name.trim(),
      resource: draft.resource,
      image: draft.image.trim(),
      type: draft.type,
      version: _optional(draft.version),
      source: _optional(draft.source),
      codeDir: _optional(draft.codeDir),
      port: draft.port,
      remark: _optional(draft.remark),
      params: _paramsForDraft(draft),
      rebuild: draft.rebuild,
      exposedPorts: draft.exposedPorts,
      environments: draft.environments,
      volumes: draft.volumes,
      extraHosts: draft.extraHosts,
    );
  }

  RuntimeUpdate buildUpdateRequest(RuntimeFormDraft draft) {
    return RuntimeUpdate(
      id: draft.id ?? 0,
      appDetailId: draft.resource == 'appstore' ? draft.appDetailId : null,
      appId: draft.resource == 'appstore' ? draft.appId : null,
      name: draft.name.trim(),
      resource: draft.resource,
      type: draft.type,
      image: _optional(draft.image),
      version: _optional(draft.version),
      source: _optional(draft.source),
      codeDir: _optional(draft.codeDir),
      port: draft.port,
      remark: _optional(draft.remark),
      rebuild: draft.rebuild,
      params: _paramsForDraft(draft),
      exposedPorts: draft.exposedPorts,
      environments: draft.environments,
      volumes: draft.volumes,
      extraHosts: draft.extraHosts,
    );
  }

  bool canStart(RuntimeInfo item) {
    return !_isDisabled(item, 'start');
  }

  bool canStop(RuntimeInfo item) {
    return !_isDisabled(item, 'stop');
  }

  bool canRestart(RuntimeInfo item) {
    return !_isDisabled(item, 'restart');
  }

  bool canEdit(RuntimeInfo item) {
    return !_isDisabled(item, 'edit');
  }

  bool canOpenAdvanced(RuntimeInfo item) {
    return !_isDisabled(item, 'config');
  }

  String defaultExecScript(String type) {
    return switch (type) {
      'node' => 'npm start',
      'java' => 'java -jar app.jar',
      'go' => './main',
      'python' => 'python main.py',
      'dotnet' => 'dotnet app.dll',
      _ => '',
    };
  }

  String defaultSource(String type) {
    return switch (type) {
      'node' => 'https://registry.npmjs.org/',
      _ => '',
    };
  }

  String defaultImage(String type) {
    return switch (type) {
      'php' => 'php:8.2-fpm',
      'node' => 'node:20-alpine',
      'java' => 'eclipse-temurin:17-jre',
      'go' => 'golang:1.22-alpine',
      'python' => 'python:3.12-slim',
      'dotnet' => 'mcr.microsoft.com/dotnet/aspnet:8.0',
      _ => '',
    };
  }

  bool _isDisabled(RuntimeInfo row, String type) {
    switch (type) {
      case 'stop':
        return row.status == 'Recreating' ||
            row.status == 'Stopped' ||
            row.status == 'Building' ||
            row.resource == 'local';
      case 'start':
        return row.status == 'Starting' ||
            row.status == 'Recreating' ||
            row.status == 'Running' ||
            row.status == 'Building' ||
            row.resource == 'local';
      case 'restart':
        return row.status == 'Recreating' ||
            row.status == 'Building' ||
            row.resource == 'local';
      case 'edit':
        return row.status == 'Recreating' || row.status == 'Building';
      case 'config':
        return row.status != 'Running';
      default:
        return false;
    }
  }

  Map<String, dynamic> _paramsForDraft(RuntimeFormDraft draft) {
    final params = <String, dynamic>{
      'HOST_IP': draft.hostIp.trim().isEmpty ? '0.0.0.0' : draft.hostIp.trim(),
      'CONTAINER_NAME': draft.containerName.trim(),
    };
    if (draft.port > 0) {
      params['APP_PORT'] = draft.port;
    }
    if (draft.execScript.trim().isNotEmpty) {
      params['EXEC_SCRIPT'] = draft.execScript.trim();
    }
    if (draft.isNode && draft.packageManager.trim().isNotEmpty) {
      params['PACKAGE_MANAGER'] = draft.packageManager.trim();
    }
    return params;
  }

  String? _optional(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
