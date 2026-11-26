import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import '../../data/models/ai/agent_models.dart';
import '../../data/models/mcp_models.dart';
import '../../data/models/vm/vm_models.dart';
import '../../data/models/vm/vm_resource_models.dart';
import '../../features/ai/ai_repository.dart';
import '../../features/ai/agents/agents_repository.dart';
import '../../features/ai/mcp_server_service.dart';
import '../../features/ai/model_downloader_service.dart';
import '../../features/alert/alert_service.dart';
import '../../features/files/services/file_transfer_service.dart';
import '../../features/vm/vm_service.dart';
import '../config/api_config.dart';
import '../platform/services/platform_file_service.dart';
import 'native_channel_harmony_alert.dart';

/// ArkUI 计算模块使用既有业务服务与请求模型。
class NativeChannelHarmonyCompute {
  static const _channel = MethodChannel('com.onepanel.client/method');
  static final _isoUploads = <String, bool>{};

  static Future<dynamic> dispatch(String method, dynamic arguments) async {
    final fields = Map<String, dynamic>.from(arguments as Map? ?? const {});
    final vm = VMService();
    switch (method) {
      case 'getAlertRuleTargets':
      case 'saveAlertRule':
      case 'getAlertWebhookPresets':
      case 'saveAlertWebhook':
      case 'testAlertWebhook':
        return NativeChannelHarmonyAlert.handle(method, fields);
      case 'searchNativeOllamaModels':
        final page = await AIRepository().searchOllamaModels(
          page: 1,
          pageSize: 100,
          info: fields['info'] as String?,
        );
        return page.items.map((model) => model.toJson()).toList();
      case 'createNativeMcpServer':
        await McpServerService().createServer(McpServerCreate.fromJson(fields));
        break;
      case 'getNativeOllamaBinding':
        return (await AIRepository().getBindDomain(
          appInstallID: fields['appInstallID'] as int,
        )).toJson();
      case 'saveNativeOllamaBinding':
        final repository = AIRepository();
        final appInstallId = fields['appInstallID'] as int;
        final domain = fields['domain'] as String;
        final websiteId = fields['websiteID'] as int?;
        if (websiteId == null) {
          await repository.bindDomain(
            appInstallID: appInstallId,
            domain: domain,
            ipList: fields['ipList'] as String?,
            sslID: fields['sslID'] as int?,
          );
        } else {
          await repository.updateBindDomain(
            appInstallID: appInstallId,
            domain: domain,
            ipList: fields['ipList'] as String?,
            sslID: fields['sslID'] as int?,
            websiteID: websiteId,
          );
        }
        break;
      case 'createNativeVm':
        return (await vm.createVM(VMCreate.fromJson(fields))).toJson();
      case 'updateNativeVm':
        return (await vm.updateVM(VMUpdate.fromJson(fields))).toJson();
      case 'deleteNativeVm':
        return (await vm.deleteVM(fields['id'] as int,
                force: fields['force'] as bool? ?? false))
            .toJson();
      case 'renameNativeVm':
        return (await vm.renameVM(fields['name'] as String,
                fields['newName'] as String))
            .toJson();
      case 'resizeNativeVmDisk':
        return (await vm.resizeDisk(
          name: fields['name'] as String,
          target: fields['target'] as String,
          sizeGiB: fields['sizeGiB'] as int,
        ))
            .toJson();
      case 'getNativeVmConsole':
        final server = await ApiConfigManager.getCurrentServerMetadata();
        return await vm.buildConsoleUrl(
          name: fields['name'] as String,
          baseUrl: server!.url,
        );
      case 'createNativeVmTemplate':
        return (await vm.createTemplate(VMTemplateCreate.fromJson(fields)))
            .toJson();
      case 'deleteNativeVmTemplate':
        return (await vm.deleteTemplate(fields['id'] as int,
                deleteDisk: fields['deleteDisk'] as bool? ?? false))
            .toJson();
      case 'createNativeVmIso':
        await vm.createIso(VMIsoCreate.fromJson(fields));
        break;
      case 'updateNativeVmIso':
        await vm.updateIso(VMIsoUpdate.fromJson(fields));
        break;
      case 'deleteNativeVmIso':
        await vm.deleteIso(fields['id'] as int,
            deleteFile: fields['deleteFile'] as bool? ?? false);
        break;
      case 'selectVmIso':
        final selection = await PlatformFileService().selectFiles(
          allowedExtensions: const ['iso', 'img'],
        );
        if (selection == null) return null;
        final file = selection.files.single;
        return {'name': file.name, 'path': file.path};
      case 'importVmIso':
        return _importIso(vm, fields);
      case 'cancelVmIsoUpload':
        final token = fields['token'] as String;
        if (_isoUploads.containsKey(token)) _isoUploads[token] = true;
        break;
      case 'createNativeVmNetwork':
        await vm.createNetwork(VMNetworkCreate.fromJson(fields));
        break;
      case 'updateNativeVmNetwork':
        await vm.updateNetwork(VMNetworkUpdate.fromJson(fields));
        break;
      case 'deleteNativeVmNetwork':
        await vm.deleteNetwork(fields['id'] as int);
        break;
      case 'createNativeVmStorage':
        await vm.createStorage(VMStorageCreate.fromJson(fields));
        break;
      case 'updateNativeVmStorage':
        await vm.updateStorage(VMStorageUpdate.fromJson(fields));
        break;
      case 'deleteNativeVmStorage':
        await vm.deleteStorage(fields['id'] as int);
        break;
      case 'getNativeVmOrphans':
        return (await vm.scanOrphans()).map((item) => item.toJson()).toList();
      case 'cleanNativeVmOrphans':
        return (await vm.cleanOrphans((fields['items'] as List)
                .map((item) => VMOrphanItem.fromJson(
                    Map<String, dynamic>.from(item as Map)))
                .toList()))
            .map((item) => item.toJson())
            .toList();
      case 'getNativeAlertChannelForm':
        final channels = await AlertService().listConfigs();
        final channel = channels.firstWhere((item) => item.id == fields['id']);
        return <String, dynamic>{
          ...channel.toJson(),
          'fields': jsonDecode(channel.config),
        };
      case 'getNativeAgentSettings':
        final agents = AgentsRepository();
        final id = fields['agentId'] as int;
        return {
          'security': (await agents.getSecurityConfig(id)).toJson(),
          'other': (await agents.getOtherConfig(id)).toJson(),
          'configFile': (await agents.getConfigFile(id)).toJson(),
          'browser': (await (await AIRepository().getApi())
                  .getAgentBrowserConfig(AgentBrowserConfigReq(agentId: id)))
              .data!
              .toJson(),
        };
      case 'saveNativeAgentSecurity':
        await AgentsRepository().updateSecurityConfig(
          agentId: fields['agentId'] as int,
          allowedOrigins: List<String>.from(fields['allowedOrigins'] as List),
        );
        break;
      case 'saveNativeAgentOther':
        await AgentsRepository().updateOtherConfig(
          agentId: fields['agentId'] as int,
          userTimezone: fields['userTimezone'] as String,
          browserEnabled: fields['browserEnabled'] as bool,
          npmRegistry: fields['npmRegistry'] as String,
        );
        break;
      case 'saveNativeAgentBrowser':
        await (await AIRepository().getApi()).updateAgentBrowserConfig(
          AgentBrowserConfigUpdateReq.fromJson(fields),
        );
        break;
      case 'saveNativeAgentConfigFile':
        await AgentsRepository().updateConfigFile(
          agentId: fields['agentId'] as int,
          content: fields['content'] as String,
        );
        break;
      case 'getNativeAgentSkills':
        return (await AgentsRepository().listSkills(fields['agentId'] as int))
            .map((item) => item.toJson())
            .toList();
      case 'searchNativeAgentSkills':
        return (await AgentsRepository().searchSkills(
          agentId: fields['agentId'] as int,
          source: fields['source'] as String,
          keyword: fields['keyword'] as String,
        ))
            .map((item) => item.toJson())
            .toList();
      case 'toggleNativeAgentSkill':
        await AgentsRepository().updateSkill(
          agentId: fields['agentId'] as int,
          name: fields['name'] as String,
          enabled: fields['enabled'] as bool,
        );
        break;
      case 'installNativeAgentSkill':
        await AgentsRepository().installSkill(
          agentId: fields['agentId'] as int,
          source: fields['source'] as String,
          slug: fields['slug'] as String,
          taskId: fields['taskID'] as String,
        );
        break;
      case 'getNativeAgentPlugins':
        return (await (await AIRepository().getApi()).listAgentPlugins(fields))
            .data;
      case 'searchNativeAgentPlugins':
        return (await (await AIRepository().getApi()).searchAgentPlugins(fields))
            .data;
      case 'installNativeAgentPlugin':
        await (await AIRepository().getApi()).installAgentMarketPlugin(fields);
        break;
      case 'operateNativeAgentPlugin':
        await (await AIRepository().getApi()).operateAgentPlugin(fields);
        break;
      case 'getNativeModelDownloadInfo':
        final service = ModelDownloaderService();
        final repo = fields['repoID'] as String;
        final revision = fields['revision'] as String?;
        final info = fields['source'] == 'modelScope'
            ? await service.getModelScopeInfo(repo, revision: revision)
            : await service.getHuggingFaceInfo(repo, revision: revision);
        return {
          ...info.toJson(),
          'files': info.files.map((file) => file.toJson()).toList(),
        };
      case 'updateNativeMcpServer':
        await McpServerService().updateServer(McpServerUpdate.fromJson(fields));
        break;
      case 'getNativeMcpBinding':
        return (await (await AIRepository().getApi()).getMcpBindDomain())
            .data!
            .toJson();
      case 'saveNativeMcpBinding':
        await McpServerService().bindDomain(McpBindDomain.fromJson(fields));
        break;
      default:
        throw ArgumentError.value(method, 'method');
    }
    return <String, dynamic>{'success': true};
  }

  static Future<Map<String, dynamic>> _importIso(
    VMService vm,
    Map<String, dynamic> fields,
  ) async {
    final directory = fields['directory'] as String;
    final localPath = fields['localPath'] as String?;
    final url = fields['url'] as String?;
    final token = fields['token'] as String;
    final uploadId = localPath == null
        ? null
        : 'iso-${DateTime.now().microsecondsSinceEpoch}';
    final fileName = localPath != null
        ? path.basename(localPath)
        : path.posix.basename(Uri.parse(url!).pathSegments.lastOrNull ?? 'image.iso');
    final transfer = FileTransferService();
    if (uploadId != null) _isoUploads[token] = false;
    int? id;
    try {
      id = await vm.startIsoImport(VMIsoImportStart(
        type: fields['type'] as String,
        name: fields['name'] as String,
        path: path.posix.join(directory, fileName),
        description: fields['description'] as String?,
        status: localPath != null ? 'uploading' : 'downloading',
        tempFileID: uploadId,
        tempFileType: uploadId == null ? null : 'upload',
      ));
      if (localPath != null) {
        if (_isoUploads[token] == true) throw StateError('Upload cancelled');
        await transfer.uploadChunkedLocalFile(
          localPath: localPath,
          targetPath: directory,
          fileName: fileName,
          uploadID: uploadId,
          onProgress: (progress) => _isoProgress(token, progress * 100),
          cancelled: () => _isoUploads[token] == true,
        );
      } else {
        final download = await transfer.wgetDownload(
          url: url!,
          path: directory,
          name: fileName,
        );
        final key = download.key;
        if (!download.success || key == null) {
          throw StateError(download.error ?? 'Download did not start');
        }
        await _awaitIsoDownload(transfer, key, token);
      }
      await vm.updateIsoImport(VMIsoImportUpdate(id: id, status: 'ready'));
      return {'success': true};
    } catch (error) {
      if (id != null) {
        await vm.updateIsoImport(VMIsoImportUpdate(
          id: id,
          status: 'failed',
          error: error.toString(),
        ));
      }
      if (_isoUploads[token] == true) return {'cancelled': true};
      rethrow;
    } finally {
      _isoUploads.remove(token);
    }
  }

  static void _isoProgress(String token, double percent) {
    unawaited(_channel.invokeMethod<void>('vmIsoProgress', {
      'token': token,
      'percent': percent,
    }));
  }

  static Future<void> _awaitIsoDownload(
    FileTransferService transfer,
    String key,
    String token,
  ) async {
    final deadline = DateTime.now().add(const Duration(minutes: 30));
    while (DateTime.now().isBefore(deadline)) {
      final records = await transfer.getWgetProgress(keys: [key]);
      final progress = records.firstOrNull as Map?;
      if (progress != null) {
        final percent = (progress['percent'] as num).toDouble();
        final status = progress['status'] as String?;
        _isoProgress(token, percent);
        if (status == 'Success' || (status == null && percent == 100)) return;
        if (status == 'Failed' || status == 'Canceled') {
          throw StateError(progress['error'] as String? ?? status!);
        }
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    await transfer.stopWget(key);
    throw TimeoutException('ISO download timed out');
  }
}
