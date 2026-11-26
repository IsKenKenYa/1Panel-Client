import 'package:flutter/services.dart';

import '../../data/models/runtime_models.dart';
import '../../features/runtimes/models/runtime_manage_args.dart';
import '../../features/runtimes/providers/php_extensions_provider.dart';
import '../../features/runtimes/providers/php_supervisor_provider.dart';
import '../../features/runtimes/services/node_runtime_service.dart';
import '../../features/runtimes/services/php_runtime_service.dart';
import '../../features/runtimes/services/runtime_service.dart';

class NativeChannelWebsiteRuntimeAdvancedHandlers {
  static Future<dynamic> dispatch(String method, dynamic arguments) async {
    final args = Map<String, dynamic>.from(arguments as Map);
    final id = args['id'] as int;
    final section = args['section'] as String;
    final php = PhpRuntimeService();
    final node = NodeRuntimeService();
    switch (method) {
      case 'getNativeRuntimeManagement':
        switch (section) {
          case 'node/modules':
            final runtime = await _runtime(id);
            final items = await node.loadModules(id);
            return {
              'items': items.map((item) => item.toJson()).toList(),
              'packageManager': _packageManager(runtime),
            };
          case 'node/scripts':
            final runtime = await _runtime(id);
            final path = runtime.codeDir;
            final items = path == null || path.trim().isEmpty
                ? const <NodeScriptInfo>[]
                : await node.loadScripts(path.trim());
            return {'items': items.map((item) => item.toJson()).toList()};
          case 'php/extensions':
            final provider = PhpExtensionsProvider(service: php);
            try {
              await provider.initialize(RuntimeManageArgs(runtimeId: id));
              if (provider.hasError) {
                throw PlatformException(code: 'runtime.detail.loadFailed');
              }
              return {
                ...provider.extensions.toJson(),
                'records': provider.extensionRecords
                    .map((item) => item.toJson())
                    .toList(),
              };
            } finally {
              provider.dispose();
            }
          case 'php/supervisor':
            final items = await php.loadSupervisorProcesses(id);
            final provider = PhpSupervisorProvider(service: php);
            try {
              return {
                'items': items
                    .map(
                      (item) => {
                        ...item.toJson(),
                        'state': provider.processState(item),
                      },
                    )
                    .toList(),
              };
            } finally {
              provider.dispose();
            }
          case 'php/supervisor-file':
            return {
              'content': await php.loadSupervisorFile(
                runtimeId: id,
                name: args['name'] as String,
                file: args['file'] as String,
              ),
            };
          case 'php/basic':
            return (await php.loadConfig(id))?.toJson() ?? <String, Object?>{};
          case 'php/fpm':
            final config = await php.loadFpmConfig(id);
            final status = await php.loadFpmStatus(id);
            return {
              'params': config.params,
              'status': status.map((item) => item.toJson()).toList(),
            };
          case 'php/container':
            return (await php.loadContainerConfig(id)).toJson();
          case 'php/file':
            return (await php.loadConfigFile(
              runtimeId: id,
              type: args['type'] as String,
            )).toJson();
          default:
            throw ArgumentError.value(section, 'section');
        }
      case 'performNativeRuntimeManagement':
        final action = args['action'] as String;
        switch (section) {
          case 'node/modules':
            return node.operateModule(
              runtimeId: id,
              module: (args['name'] as String).trim(),
              operate: action,
              packageManager: args['packageManager'] as String,
            );
          case 'node/scripts':
            final runtime = await _runtime(id);
            final result = await node.runScript(
              runtimeId: id,
              scriptName: args['name'] as String,
              packageManager: _packageManager(runtime),
            );
            return {
              'success': result.isSuccess,
              'status': result.status,
              'message': result.message,
              'timedOut': result.timedOut,
              'attempts': result.attempts,
            };
          case 'php/extensions':
            final name = args['name'] as String;
            return switch (action) {
              'install' => php.installExtension(id, name),
              'uninstall' => php.uninstallExtension(id, name),
              _ => throw ArgumentError.value(action, 'action'),
            };
          case 'php/extension-record':
            switch (action) {
              case 'create':
                return php.createExtensionRecord(
                  name: (args['name'] as String).trim(),
                  extensions: (args['extensions'] as String).trim(),
                );
              case 'update':
                return php.updateExtensionRecord(
                  id: args['recordId'] as int,
                  extensions: (args['extensions'] as String).trim(),
                );
              case 'delete':
                return php.deleteExtensionRecord(args['recordId'] as int);
              default:
                throw ArgumentError.value(action, 'action');
            }
          case 'php/supervisor':
            final name = (args['name'] as String).trim();
            if (action == 'create' || action == 'update') {
              return php.upsertSupervisorProcess(
                runtimeId: id,
                operate: action,
                name: name,
                command: (args['command'] as String).trim(),
                user: (args['user'] as String).trim(),
                dir: (args['dir'] as String).trim(),
                numprocs: (args['numprocs'] as String).trim(),
                environment: (args['environment'] as String).trim(),
              );
            }
            return php.operateSupervisorProcess(
              runtimeId: id,
              name: name,
              operate: action,
            );
          case 'php/supervisor-file':
            final name = args['name'] as String;
            final file = args['file'] as String;
            if (action == 'update') {
              return php.updateSupervisorFile(
                runtimeId: id,
                name: name,
                file: file,
                content: args['content'] as String,
              );
            }
            if (action == 'clear') {
              return php.clearSupervisorLog(
                runtimeId: id,
                name: name,
                file: file,
              );
            }
            throw ArgumentError.value(action, 'action');
          case 'php/basic':
            final basic = await php.loadConfig(id);
            return php.saveConfig(
              PHPConfigUpdate(
                id: id,
                scope: 'php',
                params: basic?.params,
                disableFunctions: (args['disableFunctions'] as String?)
                    ?.split(',')
                    .map((item) => item.trim())
                    .where((item) => item.isNotEmpty)
                    .toList(),
                uploadMaxSize: _optional(args['uploadMaxSize']),
                maxExecutionTime: _optional(args['maxExecutionTime']),
              ),
            );
          case 'php/fpm':
            return php.saveFpmConfig(
              runtimeId: id,
              params: Map<String, String>.from(args['params'] as Map),
            );
          case 'php/container':
            final config = Map<String, dynamic>.from(args['config'] as Map);
            for (final field in [
              'environments',
              'exposedPorts',
              'extraHosts',
              'volumes',
            ]) {
              final items = config[field] as List?;
              if (items != null) {
                config[field] = items
                    .map((item) => Map<String, dynamic>.from(item as Map))
                    .toList();
              }
            }
            return php.saveContainerConfig(
              PHPContainerConfig.fromJson({...config, 'id': id}),
            );
          case 'php/file':
            return php.saveConfigFile(
              runtimeId: id,
              type: args['type'] as String,
              content: args['content'] as String,
            );
          default:
            throw ArgumentError.value(section, 'section');
        }
      default:
        throw ArgumentError.value(method, 'method');
    }
  }

  static Future<RuntimeInfo> _runtime(int id) async {
    final runtime = await RuntimeService().getRuntimeDetail(id);
    if (runtime == null) {
      throw PlatformException(code: 'runtime.detail.loadFailed');
    }
    return runtime;
  }

  static String _packageManager(RuntimeInfo runtime) =>
      _optional(runtime.params?['PACKAGE_MANAGER']?.toString()) ?? 'npm';

  static String? _optional(dynamic value) {
    final text = (value as String?)?.trim();
    return text == '' ? null : text;
  }
}
