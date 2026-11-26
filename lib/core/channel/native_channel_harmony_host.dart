import 'dart:async';
import 'dart:convert';

import 'package:xterm/xterm.dart';

import '../../api/v2/host_v2.dart';
import '../../data/models/disk_management_models.dart';
import '../../data/models/firewall_v2_models.dart';
import '../../data/models/host_asset_models.dart';
import '../../data/models/host_tool_models.dart';
import '../../data/models/process_models.dart';
import '../../data/models/ssh_cert_models.dart';
import '../../data/models/ssh_log_models.dart';
import '../../data/models/ssh_session_models.dart';
import '../../data/models/toolbox_models.dart';
import '../../features/firewall/firewall_v2_service.dart';
import '../../features/host_assets/services/host_asset_service.dart';
import '../../features/processes/services/process_service.dart';
import '../../features/ssh/services/ssh_service.dart';
import '../../features/terminal/models/terminal_runtime_models.dart';
import '../../features/terminal/services/terminal_transport.dart';
import '../../features/terminal/services/ws_terminal_transport.dart';
import '../../features/toolbox/services/toolbox_clam_service.dart';
import '../../features/toolbox/services/toolbox_device_service.dart';
import '../../features/toolbox/services/toolbox_disk_service.dart';
import '../../features/toolbox/services/toolbox_fail2ban_service.dart';
import '../../features/toolbox/services/toolbox_ftp_service.dart';
import '../../features/toolbox/services/toolbox_host_tool_service.dart';
import '../config/api_config.dart';
import '../network/api_client_manager.dart';
import '../platform/services/platform_file_service.dart';
import 'native_firewall_payloads.dart';

/// ArkUI 主机页面复用共享业务服务。
class NativeChannelHarmonyHost {
  static final _terminals = <String, _HarmonyHostTerminal>{};

  static Future<dynamic> dispatch(String method, dynamic arguments) async {
    final args = Map<String, dynamic>.from(arguments as Map? ?? const {});
    switch (method) {
      case 'getNativeHostFirewallInventory':
        final config = await ApiConfigManager.getCurrentConfig();
        if (config == null) throw StateError('No API config available');
        final result = await FirewallV2Service().searchRuleInventory(
          page: args['page'] as int? ?? 1,
          pageSize: args['pageSize'] as int? ?? 20,
          info: args['info'] as String?,
        );
        final inventory = FirewallRuleInventoryResponse.fromJson(
          result,
          serverId: config.id,
        );
        return {
          'items': firewallRulePayloads(inventory.items, serverId: config.id),
          'total': inventory.total,
        };
      case 'getNativeHostAssets':
        final service = HostAssetService();
        final page = await service.searchHosts(HostSearchRequest(
          page: args['page'] as int? ?? 1,
          pageSize: args['pageSize'] as int? ?? 50,
          groupID: args['groupID'] as int?,
          info: args['info'] as String?,
        ));
        return {
          'items': page.items
              .map((host) => {
                    'id': host.id,
                    'name': host.name,
                    'addr': host.addr,
                    'port': host.port,
                    'user': host.user,
                    'groupID': host.groupID,
                    'description': host.description,
                  })
              .toList(),
          'total': page.total,
          'groups': (await service.loadGroups()).map((group) => group.toJson()).toList(),
        };
      case 'getNativeHostAsset':
        return (await HostAssetService().getHostById(args['id'] as int)).toJson();
      case 'getNativeHostGroups':
        final service = HostAssetService();
        final groups = await service.loadGroups();
        return {
          'items': groups.map((group) => group.toJson()).toList(),
          'defaultId': service.resolveDefaultGroupId(groups),
        };
      case 'saveNativeHostAsset':
        final request = HostOperate(
          id: args['id'] as int?,
          name: args['name'] as String,
          groupID: args['groupID'] as int?,
          addr: args['addr'] as String,
          port: args['port'] as int,
          user: args['user'] as String,
          authMode: args['authMode'] as String,
          password: args['password'] as String?,
          privateKey: args['privateKey'] as String?,
          passPhrase: args['passPhrase'] as String?,
          rememberPassword: args['rememberPassword'] as bool? ?? false,
          description: args['description'] as String?,
        );
        if (request.id == null) {
          await HostAssetService().createHost(request);
        } else {
          await HostAssetService().updateHost(request);
        }
        return true;
      case 'testNativeHostAsset':
        if (args['id'] != null) {
          return HostAssetService().testHostById(args['id'] as int);
        }
        return HostAssetService().testHostByInfo(HostConnTest(
          addr: args['addr'] as String,
          port: args['port'] as int,
          user: args['user'] as String,
          authMode: args['authMode'] as String,
          password: args['password'] as String?,
          privateKey: args['privateKey'] as String?,
          passPhrase: args['passPhrase'] as String?,
        ));
      case 'deleteNativeHostAssets':
        await HostAssetService().deleteHosts((args['ids'] as List).cast<int>());
        return true;
      case 'updateNativeHostGroup':
        await HostAssetService().updateHostGroup(HostGroupChange(
          id: args['id'] as int,
          groupID: args['groupID'] as int,
        ));
        return true;
      case 'getNativeProcesses':
        return _processes(args);
      case 'getNativeProcessDetail':
        final detail = await ProcessService().loadDetail(args['pid'] as int);
        return {
          'pid': detail.pid, 'name': detail.name, 'parentPid': detail.parentPid,
          'username': detail.username, 'status': detail.status, 'startTime': detail.startTime,
          'numThreads': detail.numThreads, 'numConnections': detail.numConnections,
          'diskRead': detail.diskRead, 'diskWrite': detail.diskWrite, 'cmdLine': detail.cmdLine,
          'rss': detail.rss, 'pss': detail.pss, 'uss': detail.uss, 'swap': detail.swap,
          'shared': detail.shared, 'vms': detail.vms, 'hwm': detail.hwm, 'data': detail.data,
          'stack': detail.stack, 'locked': detail.locked, 'text': detail.text, 'dirty': detail.dirty,
          'envs': detail.envs,
          'openFiles': detail.openFiles.map((file) => {'path': file.path, 'fd': file.fd}).toList(),
          'connections': detail.connections.map((connection) => {
            'type': connection.type, 'status': connection.status,
            'local': '${connection.localAddress.ip}:${connection.localAddress.port}',
            'remote': '${connection.remoteAddress.ip}:${connection.remoteAddress.port}',
          }).toList(),
        };
      case 'stopNativeProcess':
        await ProcessService().stopProcess(args['pid'] as int);
        return true;
      case 'getNativeSshSettings':
        final info = await SSHService().loadInfo();
        return {
          'autoStart': info.autoStart, 'isExist': info.isExist, 'isActive': info.isActive,
          'message': info.message, 'port': info.port, 'listenAddress': info.listenAddress,
          'passwordAuthentication': info.passwordAuthentication,
          'pubkeyAuthentication': info.pubkeyAuthentication,
          'permitRootLogin': info.permitRootLogin, 'useDNS': info.useDNS,
          'currentUser': info.currentUser,
        };
      case 'getNativeSshConfig':
        return SSHService().loadRawConfig();
      case 'saveNativeSshConfig':
        await SSHService().saveRawConfig(args['value'] as String);
        return true;
      case 'operateNativeSsh':
        await SSHService().operate(args['operation'] as String);
        return true;
      case 'updateNativeSshSetting':
        await SSHService().updateSetting(
          key: args['key'] as String,
          newValue: args['newValue'] as String,
          oldValue: args['oldValue'] as String,
        );
        return true;
      case 'getNativeSshCerts':
        final page = await SSHService().searchCerts(
          page: args['page'] as int? ?? 1,
          pageSize: args['pageSize'] as int? ?? 50,
        );
        return {
          'total': page.total,
          'items': page.items.map((cert) => {
            'id': cert.id, 'name': cert.name, 'encryptionMode': cert.encryptionMode,
            'publicKey': cert.publicKey, 'privateKey': cert.privateKey,
            'passPhrase': cert.passPhrase, 'description': cert.description,
            'createdAt': cert.createdAt?.toIso8601String(),
          }).toList(),
        };
      case 'saveNativeSshCert':
        final request = SshCertOperate(
          id: args.containsKey('id') ? args['id'] as int : 0,
          name: args['name'] as String,
          mode: args['mode'] as String,
          encryptionMode: args['encryptionMode'] as String,
          passPhrase: args['passPhrase'] as String,
          publicKey: args['publicKey'] as String,
          privateKey: args['privateKey'] as String,
          description: args['description'] as String,
        );
        if (args['id'] == null) {
          await SSHService().createCert(request);
        } else {
          await SSHService().updateCert(request);
        }
        return true;
      case 'pickNativeSshKey':
        final selection = await PlatformFileService().selectFiles(withData: true);
        final file = selection?.files.single;
        return file == null ? null : utf8.decode(file.bytes!);
      case 'deleteNativeSshCerts':
        await SSHService().deleteCerts((args['ids'] as List).cast<int>(), forceDelete: args['forceDelete'] as bool);
        return true;
      case 'syncNativeSshCerts':
        await SSHService().syncCerts();
        return true;
      case 'getNativeSshLogs':
        final page = await SSHService().searchLogs(_sshLogQuery(args));
        return {
          'total': page.total,
          'items': page.items.map((log) => {
            'date': log.date?.toIso8601String(), 'area': log.area, 'user': log.user,
            'authMode': log.authMode, 'address': log.address, 'port': log.port,
            'status': log.status, 'message': log.message,
          }).toList(),
        };
      case 'exportNativeSshLogs':
        final saved = await SSHService().exportLogs(_sshLogQuery(args));
        return {'success': saved.success, 'cancelled': saved.wasCancelled, 'filePath': saved.filePath, 'error': saved.errorMessage};
      case 'getNativeSshSessions':
        return _sshSessions(args);
      case 'disconnectNativeSshSession':
        await SSHService().disconnectSession(args['pid'] as int);
        return true;
      case 'getNativeSshLocalConnection':
        return (await SSHService().loadLocalConnection()).toJson();
      case 'checkNativeSshLocalConnection':
        return SSHService().checkLocalConnection();
      case 'setNativeSshLocalVisibility':
        await SSHService().updateLocalConnectionVisibility(visible: args['visible'] as bool, withReset: args['withReset'] as bool);
        return true;
      case 'getNativeDevice':
        final snapshot = await ToolboxDeviceService().loadSnapshot();
        return {'base': snapshot.baseInfo.toJson(), 'conf': snapshot.conf, 'users': snapshot.users, 'zones': snapshot.zoneOptions};
      case 'saveNativeDevice':
        await ToolboxDeviceService().updateConfig(dns: args['dns'] as String, hostname: args['hostname'] as String, ntp: args['ntp'] as String, swap: args['swap'] as String);
        return true;
      case 'saveNativeDevicePassword':
        await ToolboxDeviceService().updatePassword(oldPassword: args['oldPassword'] as String, newPassword: args['newPassword'] as String);
        return true;
      case 'saveNativeDeviceSwap':
        await ToolboxDeviceService().updateSwap(args['swap'] as String);
        return true;
      case 'verifyNativeDeviceDns':
        await ToolboxDeviceService().verifyDns(args['key'] as String, args['value'] as String);
        return true;
      case 'getNativeDisks':
        final snapshot = await ToolboxDiskService().loadSnapshot();
        return {'disks': snapshot.disks.map((disk) => disk.toJson()).toList(), 'unpartitioned': snapshot.unpartitionedDisks.map((disk) => disk.toJson()).toList()};
      case 'mountNativeDisk':
        await ToolboxDiskService().mountDisk(DiskMountRequest(device: args['device'] as String, filesystem: args['filesystem'] as String, mountPoint: args['mountPoint'] as String, autoMount: args['autoMount'] as bool, noFail: args['noFail'] as bool));
        return true;
      case 'partitionNativeDisk':
        await ToolboxDiskService().partitionDisk(DiskPartitionRequest(device: args['device'] as String, filesystem: args['filesystem'] as String, mountPoint: args['mountPoint'] as String, label: args['label'] as String, autoMount: args['autoMount'] as bool));
        return true;
      case 'unmountNativeDisk':
        await ToolboxDiskService().unmountDisk(DiskUnmountRequest(mountPoint: args['mountPoint'] as String));
        return true;
      case 'getNativeFtp':
        final snapshot = await ToolboxFtpService().loadSnapshot(page: args['page'] as int? ?? 1, keyword: args['info'] as String?);
        return {'base': snapshot.baseInfo.toJson(), 'users': snapshot.users.map((user) => user.toJson()).toList()};
      case 'saveNativeFtpUser':
        if (args['id'] == null) {
          await ToolboxFtpService().createUser(FtpCreate.fromJson(args));
        } else {
          await ToolboxFtpService().updateUser(FtpUpdate.fromJson(args));
        }
        return true;
      case 'deleteNativeFtpUsers':
        await ToolboxFtpService().deleteUsers((args['ids'] as List).cast<int>());
        return true;
      case 'syncNativeFtpUsers':
        await ToolboxFtpService().syncUsers();
        return true;
      case 'operateNativeFtp':
        await ToolboxFtpService().operateService(args['operation'] as String);
        return true;
      case 'getNativeFail2ban':
        final snapshot = await ToolboxFail2banService().loadSnapshot();
        return {'base': snapshot.baseInfo.toJson(), 'config': snapshot.configText, 'records': snapshot.records.map((record) => record.toJson()).toList()};
      case 'saveNativeFail2ban':
        await ToolboxFail2banService().updateConfig(Fail2banUpdate.fromJson(args));
        return true;
      case 'operateNativeFail2ban':
        await ToolboxFail2banService().operate(args['operation'] as String);
        return true;
      case 'operateNativeFail2banSshd':
        await ToolboxFail2banService().operateSshd(operate: args['operate'] as String, ips: (args['ips'] as List).cast<String>());
        return true;
      case 'getNativeClam':
        final snapshot = await ToolboxClamService().loadSnapshot(selectedTaskId: args['id'] as int?);
        return {'tasks': snapshot.tasks.map((task) => task.toJson()).toList(), 'records': snapshot.records.map((record) => record.toJson()).toList(), 'selectedTaskId': snapshot.selectedTaskId};
      case 'saveNativeClamTask':
        if (args['id'] == null) {
          await ToolboxClamService().createTask(ClamCreate.fromJson(args));
        } else {
          await ToolboxClamService().updateTask(ClamUpdate.fromJson(args));
        }
        return true;
      case 'deleteNativeClamTasks':
        await ToolboxClamService().deleteTasks(ids: (args['ids'] as List).cast<int>(), removeInfected: args['removeInfected'] as bool);
        return true;
      case 'runNativeClamTask':
        await ToolboxClamService().handleTask(args['id'] as int);
        return true;
      case 'operateNativeClam':
        await ToolboxClamService().operateService(args['operation'] as String);
        return true;
      case 'cleanNativeClamRecords':
        await ToolboxClamService().cleanRecords(args['id'] as int);
        return true;
      case 'getNativeClamFile':
        return (await ToolboxClamService().loadClamFileLines(name: args['name'] as String)).map((line) => line.toJson()).toList();
      case 'saveNativeClamFile':
        await ToolboxClamService().saveClamFile(name: args['name'] as String, file: args['file'] as String);
        return true;
      case 'getNativeSupervisor':
        final snapshot = await ToolboxHostToolService().loadSnapshot();
        return {'service': snapshot.serviceInfo.toJson(), 'config': snapshot.configContent, 'processes': snapshot.processes.map((process) => process.toJson()).toList()};
      case 'initializeNativeSupervisor':
        await ToolboxHostToolService().initSupervisor(configPath: args['configPath'] as String, serviceName: args['serviceName'] as String);
        return true;
      case 'operateNativeSupervisor':
        await ToolboxHostToolService().operateSupervisor(args['operate'] as String);
        return true;
      case 'saveNativeSupervisorConfig':
        await ToolboxHostToolService().saveSupervisorConfig(args['content'] as String);
        return true;
      case 'saveNativeSupervisorProcess':
        await ToolboxHostToolService().saveProcess(HostToolProcessConfigRequest(name: args['name'] as String, operate: args['operate'] as String, command: args['command'] as String, user: args['user'] as String, dir: args['dir'] as String, numprocs: args['numprocs'] as String, autoRestart: args['autoRestart'] as String, autoStart: args['autoStart'] as String, environment: args['environment'] as String));
        return true;
      case 'operateNativeSupervisorProcess':
        await ToolboxHostToolService().operateProcess(name: args['name'] as String, operate: args['operate'] as String);
        return true;
      case 'getNativeSupervisorFile':
        return ToolboxHostToolService().loadProcessFile(name: args['name'] as String, file: args['file'] as String);
      case 'saveNativeSupervisorFile':
        await ToolboxHostToolService().updateProcessFile(name: args['name'] as String, file: args['file'] as String, content: args['content'] as String);
        return true;
      case 'clearNativeSupervisorFile':
        await ToolboxHostToolService().clearProcessFile(name: args['name'] as String, file: args['file'] as String);
        return true;
      case 'getNativeHostDiagnostics':
        final api = HostV2Api(await ApiClientManager.instance.getCurrentClient());
        return {'summary': (await api.getDiagnosticsSummary()).data, 'goroutines': (await api.getDiagnosticsGoroutines()).data};
      case 'captureNativeHostProfile':
        await HostV2Api(await ApiClientManager.instance.getCurrentClient())
            .createRuntimeProfile(
          type: args['type'] as String,
          duration: args['duration'] as int?,
        );
        return true;
      case 'openNativeHostTerminal':
        return _openTerminal(args);
      case 'readNativeHostTerminal':
        final session = _terminals[args['sessionId'] as String]!;
        return {
          'text': session.terminal.buffer.getText(),
          'status': session.status,
          'closed': session.closed,
        };
      case 'writeNativeHostTerminal':
        await _terminals[args['sessionId'] as String]!.transport.sendInput(args['data'] as String);
        return true;
      case 'resizeNativeHostTerminal':
        final session = _terminals[args['sessionId'] as String]!;
        final columns = args['columns'] as int;
        final rows = args['rows'] as int;
        session.terminal.resize(columns, rows);
        await session.transport.resize(columns: columns, rows: rows);
        return true;
      case 'closeNativeHostTerminal':
        final session = _terminals.remove(args['sessionId'] as String);
        await session?.subscription.cancel();
        await session?.transport.dispose();
        return true;
      default:
        throw UnimplementedError(method);
    }
  }

  static SshLogSearchRequest _sshLogQuery(Map<String, dynamic> args) => SshLogSearchRequest(
    page: args['page'] as int? ?? 1,
    pageSize: args['pageSize'] as int? ?? 50,
    info: args['info'] as String?,
    status: SshLogStatus.values.firstWhere((status) => status.value == (args['status'] ?? 'All')),
  );

  static Future<List<Map<String, Object?>>> _processes(Map<String, dynamic> args) async {
    final service = ProcessService();
    final result = service.watchProcesses().first;
    try {
      await service.connectProcesses(ProcessListQuery(pid: args['pid'] as int?, name: args['name'] as String? ?? '', username: args['username'] as String? ?? ''));
      final processes = await result.timeout(const Duration(seconds: 30));
      final merged = service.mergeListeningData(processes, await service.loadListening());
      return merged.map((process) => <String, Object?>{
        'pid': process.pid, 'name': process.name, 'parentPid': process.parentPid,
        'username': process.username, 'status': process.status, 'startTime': process.startTime,
        'numThreads': process.numThreads, 'numConnections': process.numConnections,
        'cpuPercent': process.cpuPercent, 'memory': process.memoryText, 'ports': process.listeningPorts,
      }).toList();
    } finally {
      await service.closeProcesses();
    }
  }

  static Future<List<Map<String, Object?>>> _sshSessions(Map<String, dynamic> args) async {
    final service = SSHService();
    final result = service.watchSessions().first;
    try {
      await service.connectSessions(SshSessionQuery(loginUser: args['loginUser'] as String? ?? '', loginIP: args['loginIP'] as String? ?? ''));
      return (await result.timeout(const Duration(seconds: 30))).map((session) => <String, Object?>{
        'pid': session.pid, 'username': session.username, 'terminal': session.terminal,
        'host': session.host, 'loginTime': session.loginTime,
      }).toList();
    } finally {
      await service.closeSessions();
    }
  }

  static Future<String> _openTerminal(Map<String, dynamic> args) async {
    final config = await ApiConfigManager.getCurrentConfig();
    if (config == null) throw StateError('No API config available');
    final hostId = args['hostId'] as int?;
    final intent = hostId == null ? const TerminalLaunchIntent.localHost() : TerminalLaunchIntent.savedHost(hostId: hostId);
    final transport = WebSocketTerminalTransport(config: config, intent: intent, columns: 80, rows: 24);
    final id = 'host-${DateTime.now().microsecondsSinceEpoch}';
    final session = _HarmonyHostTerminal(transport);
    _terminals[id] = session;
    session.subscription = transport.events.listen((event) {
      switch (event) {
        case TerminalOutputEvent():
          session.terminal.write(event.output);
        case TerminalStatusEvent():
          session.status = event.status;
        case TerminalClosedEvent():
          session.status = event.reason ?? '';
          session.closed = true;
        case TerminalErrorEvent():
          session.status = event.message;
          session.closed = true;
        case TerminalHeartbeatEvent():
          break;
      }
    });
    try {
      await transport.connect();
    } catch (_) {
      _terminals.remove(id);
      await session.subscription.cancel();
      await transport.dispose();
      rethrow;
    }
    return id;
  }
}

class _HarmonyHostTerminal {
  _HarmonyHostTerminal(this.transport);

  final WebSocketTerminalTransport transport;
  final Terminal terminal = Terminal(maxLines: 2000);
  late final StreamSubscription<TerminalTransportEvent> subscription;
  String status = '';
  bool closed = false;
}
