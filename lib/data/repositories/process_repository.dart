import 'dart:async';

import 'package:onepanel_client/api/v2/process_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/network/process_ws_client.dart';
import 'package:onepanel_client/data/models/process_detail_models.dart';
import 'package:onepanel_client/data/models/process_models.dart';
import 'package:onepanel_client/data/models/process_ws_models.dart';

class ProcessRepository {
  ProcessRepository({
    ApiClientManager? clientManager,
    ProcessV2Api? api,
    ProcessWsClient? wsClient,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _api = api,
        _wsClient = wsClient ?? ProcessWsClient();

  final ApiClientManager _clientManager;
  ProcessV2Api? _api;
  final ProcessWsClient _wsClient;
  final StreamController<List<ProcessSummary>> _processController =
      StreamController<List<ProcessSummary>>.broadcast();

  StreamSubscription<dynamic>? _processSubscription;

  Future<ProcessV2Api> _ensureApi() async {
    return _api ??= await _clientManager.getProcessApi();
  }

  Future<ProcessDetail> getProcessDetail(int pid) async {
    final api = await _ensureApi();
    final response = await api.getProcessByPid(pid);
    if (response.data == null) {
      throw Exception('Process detail unavailable');
    }
    return response.data!;
  }

  Future<void> stopProcess(int pid) async {
    final api = await _ensureApi();
    await api.stopProcess(ProcessStopRequest(pid: pid));
  }

  Future<List<ListeningProcess>> getListeningProcesses() async {
    final api = await _ensureApi();
    final response = await api.getListeningProcesses();
    return response.data ?? const <ListeningProcess>[];
  }

  Stream<List<ProcessSummary>> watchProcesses() => _processController.stream;

  Future<void> connectProcesses(ProcessWsMessage message) async {
    _processSubscription ??= _wsClient.messages.listen((dynamic event) {
      final rawItems = (event as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ProcessSummary.fromJson)
          .toList(growable: false);
      _processController.add(rawItems);
    }, onError: _processController.addError);
    await _wsClient.connect();
    await _wsClient.send(message.toJson());
  }

  Future<void> closeProcesses() async {
    await _processSubscription?.cancel();
    _processSubscription = null;
    await _wsClient.close();
  }
}
