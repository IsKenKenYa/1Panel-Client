import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModuleSubnavController extends ChangeNotifier {
  ModuleSubnavController({
    required this.storageKey,
    required this.defaultOrder,
    this.maxVisibleItems = 4,
  });

  final String storageKey;
  final List<String> defaultOrder;
  final int maxVisibleItems;

  List<String> _orderedIds = const [];
  bool _loaded = false;

  bool get loaded => _loaded;
  List<String> get orderedIds => List.unmodifiable(_orderedIds);
  List<String> get visibleIds => _orderedIds.take(maxVisibleItems).toList(growable: false);
  List<String> get overflowIds => _orderedIds.skip(maxVisibleItems).toList(growable: false);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(storageKey);
    _orderedIds = _normalize(stored ?? defaultOrder);
    _loaded = true;
    notifyListeners();
  }

  Future<void> reorder(List<String> orderedIds) async {
    _orderedIds = _normalize(orderedIds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(storageKey, _orderedIds);
    notifyListeners();
  }

  Future<void> reset() async {
    _orderedIds = List<String>.from(defaultOrder, growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
    notifyListeners();
  }

  List<String> _normalize(List<String> source) {
    final next = <String>[];
    for (final id in source) {
      if (!defaultOrder.contains(id) || next.contains(id)) continue;
      next.add(id);
    }
    for (final id in defaultOrder) {
      if (!next.contains(id)) {
        next.add(id);
      }
    }
    return next;
  }
}
