import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/server_connection_result.dart';
import 'package:onepanel_client/data/panels/panel_registry.dart';

export 'package:onepanel_client/data/models/server_connection_result.dart';

class ServerConnectionService {
  ServerConnectionService({PanelRegistry? registry})
      : _registry = registry ?? PanelRegistry.instance;

  final PanelRegistry _registry;

  Future<ServerConnectionResult> testConnection({
    required String serverUrl,
    required String apiKey,
    String? serverId,
    String panelType = ApiConfig.onePanelType,
    Map<String, String> additionalCredentials = const {},
    bool allowInsecureTls = false,
  }) =>
      testConfig(ApiConfig(
        id: serverId ?? '',
        name: '',
        url: serverUrl,
        apiKey: apiKey,
        panelType: panelType,
        additionalCredentials: additionalCredentials,
        allowInsecureTls: allowInsecureTls,
      ));

  Future<ServerConnectionResult> testConfig(ApiConfig config) async {
    try {
      final session =
          _registry.adapterFor(config.panelType).open(config, temporary: true);
      try {
        return await session.testConnection();
      } finally {
        session.close();
      }
    } on UnsupportedError catch (error) {
      return ServerConnectionResult(
        success: false,
        errorMessage: error.message,
      );
    } on ArgumentError catch (error) {
      return ServerConnectionResult(
        success: false,
        errorMessage: error.message.toString(),
      );
    }
  }
}
