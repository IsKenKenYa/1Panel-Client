import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/features/settings/settings_service.dart';
import 'package:onepanel_client/api/v2/setting_v2.dart' as api;

class MenuSettingsProvider extends ChangeNotifier {
  MenuSettingsProvider({SettingsService? service})
      : _service = service ?? SettingsService();

  final SettingsService _service;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  List<String> _menus = const <String>[];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  List<String> get menus => List<String>.unmodifiable(_menus);

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _menus = await _service.getDefaultMenus();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.settings.menu_settings_provider',
        'load menus failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addMenu(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || _menus.contains(normalized)) {
      return;
    }
    _menus = <String>[..._menus, normalized];
    notifyListeners();
  }

  void updateMenu(int index, String value) {
    if (index < 0 || index >= _menus.length) return;
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    final next = List<String>.from(_menus);
    next[index] = normalized;
    _menus = next;
    notifyListeners();
  }

  void deleteMenu(int index) {
    if (index < 0 || index >= _menus.length) return;
    final next = List<String>.from(_menus)..removeAt(index);
    _menus = next;
    notifyListeners();
  }

  void reorderMenu(int oldIndex, int newIndex) {
    final next = List<String>.from(_menus);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    _menus = next;
    notifyListeners();
  }

  Future<bool> save() async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final filtered = _menus
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
      await _service.updateMenuSettings(api.MenuUpdate(menus: filtered));
      _menus = filtered;
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.settings.menu_settings_provider',
        'save menus failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
