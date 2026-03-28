import 'package:onepanel_client/data/models/host_tool_models.dart';
import 'package:onepanel_client/data/repositories/host_tool_repository.dart';

class ToolboxHostToolSnapshot {
  const ToolboxHostToolSnapshot({
    required this.serviceInfo,
    required this.configContent,
    required this.processes,
  });

  final SupervisorServiceInfo serviceInfo;
  final String configContent;
  final List<HostToolProcessConfig> processes;
}

class ToolboxHostToolService {
  ToolboxHostToolService({HostToolRepository? repository})
      : _repository = repository ?? HostToolRepository();

  final HostToolRepository _repository;

  Future<ToolboxHostToolSnapshot> loadSnapshot() async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _repository.getToolStatus(const HostToolRequest(operate: 'status')),
      _repository.getToolConfig(const HostToolConfigRequest(operate: 'get')),
      _repository.getSupervisorProcesses(),
    ]);
    return ToolboxHostToolSnapshot(
      serviceInfo: (results[0] as HostToolStatusResponse).config,
      configContent: (results[1] as HostToolConfigResponse).content,
      processes: results[2] as List<HostToolProcessConfig>,
    );
  }

  Future<void> initSupervisor({
    required String configPath,
    required String serviceName,
  }) {
    return _repository.initTool(
      HostToolCreateRequest(
        configPath: configPath,
        serviceName: serviceName,
      ),
    );
  }

  Future<void> operateSupervisor(String operate) {
    return _repository.operateTool(HostToolRequest(operate: operate));
  }

  Future<void> saveSupervisorConfig(String content) {
    return _repository.getToolConfig(
      HostToolConfigRequest(operate: 'set', content: content),
    );
  }

  Future<void> saveProcess(HostToolProcessConfigRequest request) {
    return _repository.upsertSupervisorProcess(request);
  }

  Future<void> operateProcess({
    required String name,
    required String operate,
  }) {
    return _repository.operateSupervisorProcess(
      HostToolProcessOperateRequest(name: name, operate: operate),
    );
  }

  Future<String> loadProcessFile({
    required String name,
    required String file,
  }) {
    return _repository.operateSupervisorProcessFile(
      HostToolProcessFileRequest(name: name, operate: 'get', file: file),
    );
  }

  Future<void> clearProcessFile({
    required String name,
    required String file,
  }) {
    return _repository.operateSupervisorProcessFile(
      HostToolProcessFileRequest(name: name, operate: 'clear', file: file),
    );
  }

  Future<void> updateProcessFile({
    required String name,
    required String file,
    required String content,
  }) {
    return _repository.operateSupervisorProcessFile(
      HostToolProcessFileRequest(
        name: name,
        operate: 'update',
        file: file,
        content: content,
      ),
    );
  }
}
