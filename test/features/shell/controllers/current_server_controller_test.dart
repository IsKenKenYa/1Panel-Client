import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';

void main() {
  group('CurrentServerController', () {
    test('loads servers and current selection from storage', () async {
      final configs = [
        ApiConfig(id: 's1', name: 'Alpha', url: 'https://alpha.test', apiKey: 'a'),
        ApiConfig(id: 's2', name: 'Beta', url: 'https://beta.test', apiKey: 'b'),
      ];
      SharedPreferences.setMockInitialValues({
        'api_configs': jsonEncode(configs.map((e) => e.toJson()).toList()),
        'current_api_config_id': 's2',
      });

      final controller = CurrentServerController();
      await controller.load();

      expect(controller.servers, hasLength(2));
      expect(controller.currentServer?.id, 's2');
      expect(controller.hasServer, isTrue);
    });

    test('selectServer persists and updates current server', () async {
      final configs = [
        ApiConfig(id: 's1', name: 'Alpha', url: 'https://alpha.test', apiKey: 'a'),
        ApiConfig(id: 's2', name: 'Beta', url: 'https://beta.test', apiKey: 'b'),
      ];
      SharedPreferences.setMockInitialValues({
        'api_configs': jsonEncode(configs.map((e) => e.toJson()).toList()),
        'current_api_config_id': 's1',
      });

      final controller = CurrentServerController();
      await controller.load();
      await controller.selectServer('s2');

      expect(controller.currentServer?.id, 's2');
    });
  });
}
