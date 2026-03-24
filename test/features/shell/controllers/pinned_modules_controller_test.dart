import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';

void main() {
  group('PinnedModulesController', () {
    test('loads defaults when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = PinnedModulesController();
      await controller.load();

      expect(controller.pins, [ClientModule.files, ClientModule.containers]);
    });

    test('setPin swaps duplicate modules instead of duplicating them', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = PinnedModulesController();
      await controller.load();

      await controller.setPin(0, ClientModule.containers);

      expect(controller.pins, [ClientModule.containers, ClientModule.files]);
    });

    test('reset restores default pins', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = PinnedModulesController();
      await controller.load();
      await controller.setPin(0, ClientModule.apps);

      await controller.reset();

      expect(controller.pins, [ClientModule.files, ClientModule.containers]);
    });
  });
}
