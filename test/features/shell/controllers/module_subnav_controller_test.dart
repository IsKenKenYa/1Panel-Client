import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanel_client/features/shell/controllers/module_subnav_controller.dart';

void main() {
  group('ModuleSubnavController', () {
    test('keeps first four items visible and the rest in more', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = ModuleSubnavController(
        storageKey: 'test_subnav',
        defaultOrder: const ['a', 'b', 'c', 'd', 'e', 'f'],
      );
      await controller.load();

      expect(controller.visibleIds, ['a', 'b', 'c', 'd']);
      expect(controller.overflowIds, ['e', 'f']);
    });

    test('reorder persists custom order', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = ModuleSubnavController(
        storageKey: 'test_subnav',
        defaultOrder: const ['a', 'b', 'c', 'd'],
      );
      await controller.load();
      await controller.reorder(['c', 'a', 'b', 'd']);

      expect(controller.orderedIds, ['c', 'a', 'b', 'd']);
    });
  });
}
