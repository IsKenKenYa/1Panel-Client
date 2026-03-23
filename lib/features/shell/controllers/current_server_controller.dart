import 'package:flutter/foundation.dart';
import 'package:onepanelapp_app/core/config/api_config.dart';
import 'package:onepanelapp_app/core/network/api_client_manager.dart';

class CurrentServerController extends ChangeNotifier {
  bool _isLoading = false;
  List<ApiConfig> _servers = const [];
  ApiConfig? _currentServer;

  bool get isLoading => _isLoading;
  List<ApiConfig> get servers => _servers;
  ApiConfig? get currentServer => _currentServer;
  String? get currentServerId => _currentServer?.id;
  bool get hasServer => _currentServer != null;
  bool get hasAvailableServers => _servers.isNotEmpty;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      _servers = await ApiConfigManager.getConfigs();
      _currentServer = await ApiConfigManager.getCurrentConfig();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectServer(String id) async {
    await ApiConfigManager.setCurrentConfig(id);
    ApiClientManager.instance.clearAllClients();
    await load();
  }

  Future<void> refresh() async {
    await load();
  }
}
