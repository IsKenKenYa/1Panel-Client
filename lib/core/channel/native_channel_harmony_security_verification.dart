import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../network/browser_connection_policy.dart';
import '../../features/settings/settings_service.dart';

class NativeChannelHarmonySecurityVerification {
  static Future<Map<String, String?>> getPanelEntrance(
    dynamic arguments,
  ) async {
    final server = await ApiConfigManager.getCurrentConfig();
    if (server == null) {
      throw StateError('No current server');
    }
    final settings = await SettingsService.forServer(server).getSystemSettings();
    if (settings == null) {
      throw const FormatException('Missing panel settings');
    }
    return {
      'serverUrl': server.url,
      'securityEntrance': settings.securityEntrance,
    };
  }

  static Future<void> openPanelEntrance(dynamic arguments) async {
    final values = Map<String, dynamic>.from(arguments as Map);
    final entrance = BrowserConnectionPolicy.panelWebEntrance(
      values['serverUrl'] as String,
      values['securityEntrance'] as String?,
    );
    if (!await launchUrl(entrance, mode: LaunchMode.externalApplication)) {
      throw StateError('Unable to open panel account security');
    }
  }
}
