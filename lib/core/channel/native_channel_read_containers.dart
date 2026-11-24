import 'dart:async';

import 'package:flutter/services.dart';

import '../config/api_constants.dart';
import '../network/api_client_manager.dart';
import '../utils/error_message_utils.dart';
import '../../api/v2/api_response_parser.dart';
import '../../data/models/container_models.dart';
import '../../data/models/process_models.dart';
import '../../features/containers/container_service.dart';
import '../../features/orchestration/services/orchestration_service.dart';
import '../services/logger/logger_service.dart';

/// 读通道容器域：容器列表与日志流、镜像、网络、卷、仓库、模板、文件、inspect、Compose。
class NativeChannelContainerReadHandlers {
  static Future<dynamic> getContainers(dynamic arguments) async {
    final containers = await ContainerService().listContainers();
    return containers
        .map((c) => {
              'id': c.id,
              'name': c.name,
              'image': c.image,
              'status': c.status,
              'state': c.state,
              'createTime': c.createTime,
              'cpuUsage': c.cpuUsage,
              'memoryUsage': c.memoryUsage,
            })
        .toList();
  }

  /// 容器日志（SSE 帧已由服务层剥离）。参数：`{name: String, tail?: String}`
  static Future<dynamic> getContainerLogs(dynamic arguments) async {
    final name = arguments['name'] as String;
    final tail = arguments['tail'] as String?;
    return ContainerService().getContainerLogs(name, tail: tail);
  }

  static StreamSubscription<String>? _containerLogSubscription;
  static int _containerLogSession = 0;
  /// 当前活动订阅的归属令牌，由原生侧传入的 requestID。
  static int? _containerLogRequestID;

  /// 开始跟随容器日志。
  ///
  /// 服务端以 base64 SSE 帧持续推送；每个文本块通过方法通道回调
  /// `containerLogChunk` 交给原生侧，结束时回调 `containerLogDone`。
  /// 原生侧可传入 `requestID`，回调会原样回传，用于在开始回复到达前
  /// 就匹配回调归属、丢弃上一轮订阅的迟到帧。参数：
  /// `{container: String, tail?: String, since?: String, follow?: bool, requestID?: int}`。
  static Future<dynamic> startContainerLogStream(dynamic arguments) async {
    final container = (arguments?['container'] as String? ?? '').trim();
    if (container.isEmpty) {
      throw ArgumentError('container is required');
    }
    final requestID = arguments?['requestID'] as int?;
    final session = ++_containerLogSession;
    final previous = _containerLogSubscription;
    _containerLogSubscription = null;
    await previous?.cancel();
    if (session != _containerLogSession) {
      return <String, dynamic>{
        'success': false,
        'error': 'superseded',
        'session': _containerLogSession,
      };
    }
    _containerLogRequestID = requestID;
    final follow = arguments?['follow'] as bool? ?? true;
    _containerLogSubscription = ContainerService()
        .streamContainerLogs(
          container,
          tail: arguments?['tail'] as String?,
          since: arguments?['since'] as String?,
          follow: follow,
        )
        .listen(
          (chunk) {
            if (session != _containerLogSession) return;
            _logChannel?.invokeMethod<void>('containerLogChunk', {
              'container': container,
              'session': session,
              if (requestID != null) 'requestID': requestID,
              'chunk': chunk,
            });
          },
          onError: (Object error) {
            if (session != _containerLogSession) return;
            _logChannel?.invokeMethod<void>('containerLogError', {
              'container': container,
              'session': session,
              if (requestID != null) 'requestID': requestID,
              'error': ErrorMessageUtils.userFacingMessage(error),
            });
          },
          onDone: () {
            if (session != _containerLogSession) return;
            _logChannel?.invokeMethod<void>('containerLogDone', {
              'container': container,
              'session': session,
              if (requestID != null) 'requestID': requestID,
            });
          },
          cancelOnError: true,
        );
    return <String, dynamic>{
      'success': true,
      'session': session,
      if (requestID != null) 'requestID': requestID,
    };
  }

  /// 停止跟随容器日志。
  ///
  /// 原生侧传入 `requestID` 时只终止该归属的订阅：多个页面并存时，
  /// 旧页面的停止不会取消新页面刚建立的连接。
  static Future<dynamic> stopContainerLogStream(dynamic arguments) async {
    final requestID = arguments is Map ? arguments['requestID'] as int? : null;
    if (requestID != null && requestID != _containerLogRequestID) {
      return <String, dynamic>{'success': true, 'skipped': true};
    }
    _containerLogSession++;
    _containerLogRequestID = null;
    final subscription = _containerLogSubscription;
    _containerLogSubscription = null;
    await subscription?.cancel();
    return <String, dynamic>{'success': true, 'session': _containerLogSession};
  }

  /// 由通道管理器注入同一个方法通道，供日志块回调使用。
  static void bindContainerLogChannel(MethodChannel channel) {
    _logChannel = channel;
  }

  static MethodChannel? _logChannel;

  /// 容器镜像列表（`/containers/image/all`）。字段与上游真实返回一致。
  static Future<dynamic> getContainerImages(dynamic arguments) async {
    final client = await ApiClientManager.instance.getCurrentClient();
    final response = await client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/image/all'),
    );
    final items = ApiResponseParser.asList(response.data);
    return items
        .whereType<Map>()
        .map((item) => {
              'id': item['id']?.toString() ?? '',
              'tags': (item['tags'] as List?)?.map((e) => '$e').toList() ?? const [],
              'size': item['size'] ?? 0,
              'createdAt': item['createdAt']?.toString() ?? '',
              'isUsed': item['isUsed'] ?? false,
              'description': item['description']?.toString() ?? '',
            })
        .toList();
  }

  /// 容器网络列表（`/containers/network/search`）。参数：`{page?, pageSize?}`。
  static Future<dynamic> getContainerNetworks(dynamic arguments) async {
    final client = await ApiClientManager.instance.getCurrentClient();
    final response = await client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/network/search'),
      data: <String, dynamic>{
        'page': int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
        'pageSize': int.tryParse('${arguments?['pageSize'] ?? 50}') ?? 50,
      },
    );
    final items = ApiResponseParser.asList(
      response.data,
      nestedItemsKey: 'items',
    );
    return items
        .whereType<Map>()
        .map((item) => {
              'id': item['id']?.toString() ?? '',
              'name': item['name']?.toString() ?? '',
              'driver': item['driver']?.toString() ?? '',
              'subnet': item['subnet']?.toString() ?? '',
              'gateway': item['gateway']?.toString() ?? '',
              'createdAt': item['createdAt']?.toString() ?? '',
              'attachable': item['attachable'] ?? false,
            })
        .toList();
  }

  /// 容器存储卷列表（`/containers/volume/search`）。参数：`{page?, pageSize?}`。
  static Future<dynamic> getContainerVolumes(dynamic arguments) async {
    final client = await ApiClientManager.instance.getCurrentClient();
    final response = await client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/volume/search'),
      data: <String, dynamic>{
        'page': int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
        'pageSize': int.tryParse('${arguments?['pageSize'] ?? 50}') ?? 50,
      },
    );
    final items = ApiResponseParser.asList(
      response.data,
      nestedItemsKey: 'items',
    );
    return items
        .whereType<Map>()
        .map((item) => {
              'name': item['name']?.toString() ?? '',
              'driver': item['driver']?.toString() ?? '',
              'mountpoint': item['mountpoint']?.toString() ?? '',
              'createdAt': item['createdAt']?.toString() ?? '',
            })
        .toList();
  }

  /// 监听端口进程列表。参数：无。POST /process/listening。
  static Future<dynamic> getListeningProcesses(dynamic arguments) async {
    try {
      final processes = (await (await ApiClientManager.instance.getProcessApi())
                  .getListeningProcesses())
              .data ??
          const <ListeningProcess>[];
      return processes
          .map((process) => {
                'pid': process.pid,
                'protocol': process.protocol,
                'name': process.name,
                'ports': process.ports,
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get listening processes for native: $e');
      return [];
    }
  }

  /// 容器镜像仓库列表。参数：无。GET /containers/repo。
  static Future<dynamic> getContainerRepos(dynamic arguments) async {
    try {
      final response = await (await ApiClientManager.instance.getContainerApi())
          .getRepos();
      return (response.data ?? const <ContainerRepo>[])
          .map((repo) => repo.toJson())
          .toList();
    } catch (e) {
      appLogger.e('Failed to get container repos for native: $e');
      return [];
    }
  }

  /// 容器编排模版列表。参数：无。GET /containers/template。
  static Future<dynamic> getContainerTemplates(dynamic arguments) async {
    try {
      final response =
          await (await ApiClientManager.instance.getContainerApi()).getTemplates();
      return (response.data ?? const <ContainerTemplate>[])
          .map((template) => template.toJson())
          .toList();
    } catch (e) {
      appLogger.e('Failed to get container templates for native: $e');
      return [];
    }
  }

  /// 容器内文件列表。参数：`{containerId: String, path: String}`。
  static Future<dynamic> getContainerFiles(dynamic arguments) async {
    try {
      final containerId = (arguments?['containerId'] as String? ?? '').trim();
      final path = (arguments?['path'] as String? ?? '/').trim();
      if (containerId.isEmpty) {
        return [];
      }
      final response =
          await (await ApiClientManager.instance.getFileApi()).searchContainerFiles(
        ContainerFileRequest(containerId: containerId, path: path),
      );
      return (response.data ?? const <ContainerFileInfo>[])
          .map((file) => file.toJson())
          .toList();
    } catch (e) {
      appLogger.e('Failed to get container files for native: $e');
      return [];
    }
  }

  /// 容器内文件内容。参数：`{containerId: String, path: String}`。
  static Future<dynamic> getContainerFileContent(dynamic arguments) async {
    try {
      final containerId = (arguments?['containerId'] as String? ?? '').trim();
      final path = (arguments?['path'] as String? ?? '').trim();
      if (containerId.isEmpty || path.isEmpty) {
        return <String, dynamic>{};
      }
      final response =
          await (await ApiClientManager.instance.getFileApi()).getContainerFileContent(
        ContainerFileRequest(containerId: containerId, path: path),
      );
      return response.data?.toJson() ?? <String, dynamic>{};
    } catch (e) {
      appLogger.e('Failed to get container file content for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 容器 inspect（格式化 JSON）。参数：`{name}`。
  static Future<dynamic> getContainerInspect(dynamic arguments) async {
    final name = arguments['name'] as String;
    final service = ContainerService();
    return service.inspectContainerFormatted(name);
  }

  /// Compose 项目内容。参数：`{name: String, path: String}`。POST /containers/inspect。
  static Future<dynamic> getComposeContent(dynamic arguments) async {
    try {
      final name = (arguments?['name'] as String? ?? '').trim();
      final path = (arguments?['path'] as String? ?? '').trim();
      if (name.isEmpty || path.isEmpty) {
        return '';
      }
      final client = await ApiClientManager.instance.getCurrentClient();
      final response = await client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/containers/inspect'),
        data: <String, dynamic>{
          'id': name,
          'type': 'compose',
          'detail': path,
        },
      );
      final data = response.data?['data'];
      return data is String ? data : '';
    } catch (e) {
      appLogger.e('Failed to get compose content for native: $e');
      return '';
    }
  }

  /// Compose 项目容器列表。参数：`{name: String}`，来自 Compose 列表的 containers。
  static Future<dynamic> getComposeContainers(dynamic arguments) async {
    try {
      final name = (arguments?['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        return [];
      }
      final composes = await OrchestrationService().loadComposes(pageSize: 100);
      final matches = composes.where((compose) => compose.name == name).toList();
      final containers =
          matches.isEmpty ? const <dynamic>[] : matches.first.containers ?? const <dynamic>[];
      return containers.whereType<Map>().map((item) {
        final ports = (item['ports'] as List? ?? const <dynamic>[])
            .map((port) => '$port')
            .toList(growable: false);
        return <String, Object?>{
          'id': item['containerID']?.toString() ?? '',
          'name': item['name']?.toString() ?? '',
          'image': '',
          'state': item['state']?.toString() ?? '',
          'status': item['createTime']?.toString() ?? '',
          'ports': ports,
        };
      }).toList();
    } catch (e) {
      appLogger.e('Failed to get compose containers for native: $e');
      return [];
    }
  }

  /// Compose 项目日志：指定容器时只取该容器日志，否则汇总项目内各容器日志。
  /// 参数：`{name: String, tail?: String, container?: String}`。
  static Future<dynamic> getComposeLogs(dynamic arguments) async {
    try {
      final name = (arguments?['name'] as String? ?? '').trim();
      if (name.isEmpty) {
        return '';
      }
      final tail = (arguments?['tail'] as String? ?? '').trim();
      final container = (arguments?['container'] as String? ?? '').trim();
      if (container.isNotEmpty) {
        return ContainerService().getContainerLogs(
          container,
          tail: tail.isEmpty ? null : tail,
        );
      }
      final containers = await getComposeContainers({'name': name});
      final buffer = StringBuffer();
      for (final raw in (containers as List).whereType<Map>()) {
        final containerName = '${raw['name'] ?? ''}';
        if (containerName.isEmpty) continue;
        final logs = await ContainerService().getContainerLogs(
          containerName,
          tail: tail.isEmpty ? null : tail,
        );
        buffer.writeln('===== $containerName =====');
        buffer.writeln(logs);
      }
      return buffer.toString();
    } catch (e) {
      appLogger.e('Failed to get compose logs for native: $e');
      return '';
    }
  }

  /// Compose 项目列表（B18）。
  static Future<dynamic> getComposes(dynamic arguments) async {
    try {
      final service = OrchestrationService();
      final composes = await service.loadComposes(pageSize: 100);
      return composes
          .map((c) => {
                'id': c.id.isEmpty ? c.name : c.id,
                'name': c.name,
                'path': c.path ?? '',
                'version': c.version ?? '',
                'status': c.status ?? '',
                'createTime': c.createTime ?? '',
                'containerCount': c.containerCount ?? 0,
                'runningCount': c.runningCount ?? 0,
                'containers': c.containers ?? const <dynamic>[],
              })
          .toList();
    } catch (e) {
      if (e.toString().contains('No API config available')) {
        appLogger.i('getComposes skipped: No active server configured.');
      } else {
        appLogger.e('Failed to get composes for native: $e');
      }
      return [];
    }
  }
}