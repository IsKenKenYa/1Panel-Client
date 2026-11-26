import 'package:flutter/services.dart';

import '../../features/runtimes/models/runtime_form_args.dart';
import '../../features/runtimes/models/runtime_form_draft.dart';
import '../../features/runtimes/providers/runtime_form_provider.dart';
import '../../features/runtimes/services/runtime_service.dart';

class NativeChannelWebsiteRuntimesHandlers {
  static Future<dynamic> dispatch(String method, dynamic arguments) async {
    final args = Map<String, dynamic>.from(arguments as Map);
    final service = RuntimeService();
    switch (method) {
      case 'searchNativeRuntimes':
        final page = args['page'] as int;
        const pageSize = 20;
        final result = await service.searchRuntimes(
          type: args['type'] as String,
          name: args['name'] as String?,
          status: args['status'] as String?,
          page: page,
          pageSize: pageSize,
        );
        return {
          'items': result.items.map((runtime) => runtime.toJson()).toList(),
          'hasNextPage': result.total > page * pageSize,
        };
      case 'getNativeRuntimeDetail':
        final id = args['id'] as int;
        final runtime = await service.getRuntimeDetail(id);
        if (runtime == null) {
          throw PlatformException(code: 'runtime.detail.loadFailed');
        }
        return {
          ...runtime.toJson(),
          'canStart': service.canStart(runtime),
          'canStop': service.canStop(runtime),
          'canRestart': service.canRestart(runtime),
          'canEdit': service.canEdit(runtime),
          'canOpenAdvanced': service.canOpenAdvanced(runtime),
        };
      case 'getNativeRuntimeForm':
      case 'saveNativeRuntime':
        return _form(service, args, save: method == 'saveNativeRuntime');
      case 'operateNativeRuntime':
        return service.operateRuntime(
          args['id'] as int,
          args['operation'] as String,
        );
      case 'syncNativeRuntimes':
        return service.syncRuntimeStatus();
      case 'updateNativeRuntimeRemark':
        return service.updateRuntimeRemark(
          args['id'] as int,
          args['remark'] as String,
        );
      case 'checkNativeRuntimeDelete':
        final values = await service.checkDeleteDependency(args['id'] as int);
        return values
            .map((item) {
              return (item['name'] ??
                      item['appName'] ??
                      item['resourceName'] ??
                      item['label'] ??
                      item['id'])
                  ?.toString()
                  .trim();
            })
            .whereType<String>()
            .where((name) => name.isNotEmpty)
            .toList();
      case 'deleteNativeRuntime':
        return service.deleteRuntime(args['id'] as int);
      default:
        throw ArgumentError.value(method, 'method');
    }
  }

  static Future<Map<String, Object?>?> _form(
    RuntimeService service,
    Map<String, dynamic> args, {
    required bool save,
  }) async {
    final id = args['id'] as int?;
    final form = RuntimeFormProvider(service: service);
    try {
      await form.initialize(
        RuntimeFormArgs(runtimeId: id, initialType: args['type'] as String?),
      );
      if (form.hasError || (id != null && form.draft.id != id)) {
        throw PlatformException(code: 'runtime.form.loadFailed');
      }
      if (!save) {
        return _draft(form.draft);
      }
      form.updateBasic(
        name: args['name'] as String,
        version: args['version'] as String?,
      );
      form.updateRuntimeConfig(
        image: args['image'] as String,
        source: args['source'] as String?,
        codeDir: args['codeDir'] as String,
        port: args['port'] as int,
        hostIp: args['hostIp'] as String?,
        containerName: args['containerName'] as String,
        execScript: args['execScript'] as String?,
        packageManager: args['packageManager'] as String?,
      );
      form.updateAdvanced(
        remark: args['remark'] as String?,
        rebuild: args['rebuild'] as bool?,
      );
      if (!await form.save()) {
        return {'error': form.errorMessage};
      }
      return null;
    } finally {
      form.dispose();
    }
  }

  static Map<String, Object?> _draft(RuntimeFormDraft draft) => {
    'type': draft.type,
    'resource': draft.resource,
    'name': draft.name,
    'version': draft.version,
    'image': draft.image,
    'source': draft.source,
    'codeDir': draft.codeDir,
    'port': draft.port,
    'hostIp': draft.hostIp,
    'containerName': draft.containerName,
    'execScript': draft.execScript,
    'packageManager': draft.packageManager,
    'remark': draft.remark,
    'rebuild': draft.rebuild,
  };
}
