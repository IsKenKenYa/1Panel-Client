import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';

import '../firewall_v2_service.dart';

class FirewallV2Provider extends ChangeNotifier with SafeChangeNotifier {
  FirewallV2Provider({FirewallV2Service? service})
      : _service = service ?? FirewallV2Service();

  final FirewallV2Service _service;

  bool isLoading = false;
  String? error;
  Map<String, dynamic> settings = const <String, dynamic>{};
  Map<String, dynamic> ruleInventory = const <String, dynamic>{};
  Map<String, dynamic> ruleBackups = const <String, dynamic>{};
  Map<String, dynamic> forwardBase = const <String, dynamic>{};
  Map<String, dynamic> forwardRules = const <String, dynamic>{};
  Map<String, dynamic> dockerPorts = const <String, dynamic>{};
  List<dynamic> dockerEndpoints = const <dynamic>[];

  Future<void> _run(Future<void> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = ErrorMessageUtils.userFacingMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSettings() => _run(() async {
        settings = await _service.loadSettings();
      });

  Future<void> loadRuleInventory({String? info}) => _run(() async {
        ruleInventory = await _service.searchRuleInventory(info: info);
      });

  Future<void> loadRuleBackups(String subsystem) => _run(() async {
        ruleBackups = await _service.loadRuleBackups(subsystem);
      });

  Future<void> loadForward() => _run(() async {
        forwardBase = await _service.loadForwardBase();
        forwardRules = await _service.searchForwardRules();
      });

  Future<void> loadDocker() => _run(() async {
        dockerPorts = await _service.loadDockerPorts();
        dockerEndpoints = await _service.loadDockerEndpoints();
      });
}
