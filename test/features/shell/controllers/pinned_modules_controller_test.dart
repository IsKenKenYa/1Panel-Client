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

    test('setPin swaps duplicate modules instead of duplicating them',
        () async {
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
    test('vm is pinnable so users can reach it from the bottom bar', () async {
      // 虚拟机进 ClientModule 枚举后如果漏加可固定列表，就会既不出现在
      // 底栏、也不出现在服务器详情的 Modules 分组，用户无法触达。
      SharedPreferences.setMockInitialValues({});
      final controller = PinnedModulesController();
      await controller.load();

      expect(controller.options.contains(ClientModule.vm), isTrue);
      await controller.setPin(1, ClientModule.vm);
      expect(controller.pins, [ClientModule.files, ClientModule.vm]);
    });
  });
}
