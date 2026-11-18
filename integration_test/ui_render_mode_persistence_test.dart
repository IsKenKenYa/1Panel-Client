import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:onepanel_client/core/theme/ui_render_mode.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('已保存的界面风格通过原生通道原样返回', (tester) async {
    const key = 'app_ui_render_mode';
    final preferences = await SharedPreferences.getInstance();
    final original = preferences.getString(key);
    addTearDown(() async {
      if (original == null) {
        await preferences.remove(key);
      } else {
        await preferences.setString(key, original);
      }
    });

    final service = AppPreferencesService();
    final channel = NativeChannelManager.instance;
    for (final mode in UIRenderMode.values) {
      final resolved = UIRenderPolicy.resolveSupportedMode(mode);
      await service.saveUIRenderMode(mode);
      await preferences.reload();
      expect(preferences.getString(key), resolved.name);
      expect(await service.loadUIRenderMode(), resolved);
      expect(await channel.handleMethodCall('getUIRenderMode', null),
          resolved.name);
      final settings = await channel.handleMethodCall('getSettings', null);
      expect(settings, containsPair('renderMode', resolved.name));
    }
  });
}
