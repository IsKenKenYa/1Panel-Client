import 'package:flutter/foundation.dart';

import '../firewall_service.dart';
import '../../../data/models/firewall_models.dart';

class FirewallStatusProvider extends ChangeNotifier {
  FirewallStatusProvider({FirewallServiceInterface? service})
      : _service = service ?? FirewallService();

  final FirewallServiceInterface _service;

  bool _loading = false;
  bool _busy = false;
  String? _error;
  FirewallBaseInfo? _status;

  bool get loading => _loading;
  bool get busy => _busy;
  String? get error => _error;
  FirewallBaseInfo? get status => _status;

  Future<void> load({String tab = 'base'}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _status = await _service.loadBaseInfo(tab: tab);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> operate({
    required String operation,
    bool withDockerRestart = false,
  }) async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      await _service.operateFirewall(
        operation: FirewallOperation(
          operation: operation,
          withDockerRestart: withDockerRestart,
        ),
      );
      await load();
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
