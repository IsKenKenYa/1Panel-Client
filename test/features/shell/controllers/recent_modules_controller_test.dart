import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanelapp_app/features/shell/controllers/recent_modules_controller.dart';
import 'package:onepanelapp_app/features/shell/models/client_module.dart';

void main() {
  group('RecentModulesController', () {
    test('tracks recent modules in MRU order', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = RecentModulesController();
      await controller.load();

      await controller.track(ClientModule.files);
      await controller.track(ClientModule.containers);
      await controller.track(ClientModule.files);

      expect(controller.recent, [ClientModule.files, ClientModule.containers]);
    });

    test('ignores non-trackable shell modules', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = RecentModulesController();
      await controller.load();

      await controller.track(ClientModule.servers);
      await controller.track(ClientModule.workbench);
      await controller.track(ClientModule.settings);

      expect(controller.recent, isEmpty);
    });
  });
}
