import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanelapp_app/features/shell/models/client_module.dart';

class RecentModulesController extends ChangeNotifier {
  static const _storageKey = 'client_shell_recent_modules';
  static const _maxItems = 6;

  List<ClientModule> _recent = const [];
  bool _loaded = false;

  bool get loaded => _loaded;
  List<ClientModule> get recent => List.unmodifiable(_recent);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey) ?? const [];
    _recent = stored
        .map(clientModuleFromId)
        .whereType<ClientModule>()
        .where(_isTrackedModule)
        .toList(growable: false);
    _loaded = true;
    notifyListeners();
  }

  Future<void> track(ClientModule module) async {
    if (!_isTrackedModule(module)) {
      return;
    }

    final next = [module, ..._recent.where((item) => item != module)]
        .take(_maxItems)
        .toList(growable: false);
    _recent = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      next.map((item) => item.storageId).toList(growable: false),
    );
    notifyListeners();
  }

  bool _isTrackedModule(ClientModule module) {
    switch (module) {
      case ClientModule.servers:
      case ClientModule.workbench:
      case ClientModule.settings:
        return false;
      case ClientModule.files:
      case ClientModule.containers:
      case ClientModule.apps:
      case ClientModule.verification:
        return true;
    }
  }
}
