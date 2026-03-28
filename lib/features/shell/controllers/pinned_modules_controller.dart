import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';

class PinnedModulesController extends ChangeNotifier {
  static const _storageKey = 'client_shell_pinned_modules';

  List<ClientModule> _pins = const [
    ClientModule.files,
    ClientModule.containers,
  ];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<ClientModule> get pins => List.unmodifiable(_pins);
  ClientModule get primaryPin => _pins.first;
  ClientModule get secondaryPin => _pins.last;
  List<ClientModule> get options => List.unmodifiable(kPinnableClientModules);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_storageKey);
    _pins = _normalizePins(
        stored?.map(clientModuleFromId).whereType<ClientModule>().toList());
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setPin(int slotIndex, ClientModule module) async {
    if (!module.pinnable || slotIndex < 0 || slotIndex > 1) {
      return;
    }

    final next = List<ClientModule>.from(_pins);
    final previousIndex = next.indexOf(module);
    if (previousIndex != -1) {
      final previous = next[slotIndex];
      next[previousIndex] = previous;
    }
    next[slotIndex] = module;

    _pins = _normalizePins(next);
    await _persist();
    notifyListeners();
  }

  Future<void> reset() async {
    _pins = const [ClientModule.files, ClientModule.containers];
    await _persist();
    notifyListeners();
  }

  List<ClientModule> _normalizePins(List<ClientModule>? candidate) {
    final next = <ClientModule>[];
    for (final module in candidate ?? const <ClientModule>[]) {
      if (!module.pinnable || next.contains(module)) {
        continue;
      }
      next.add(module);
      if (next.length == 2) break;
    }

    for (final fallback in const [
      ClientModule.files,
      ClientModule.containers,
      ClientModule.apps
    ]) {
      if (next.length == 2) break;
      if (!next.contains(fallback)) {
        next.add(fallback);
      }
    }

    return next.take(2).toList(growable: false);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      _pins.map((module) => module.storageId).toList(growable: false),
    );
  }
}
