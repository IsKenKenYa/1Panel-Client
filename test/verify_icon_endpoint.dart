import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanelapp_app/core/network/dio_client.dart';
import 'package:onepanelapp_app/api/v2/app_v2.dart';
import 'package:onepanelapp_app/data/models/app_models.dart';
import 'core/test_config_manager.dart';

void main() {
  late DioClient client;
  late AppV2Api api;

  setUp(() async {
    await TestEnvironment.initialize();
    client = DioClient(baseUrl: TestEnvironment.baseUrl, apiKey: TestEnvironment.apiKey);
    api = AppV2Api(client);
  });

  test('Verify App Icon Endpoint', () async {
    // 1. Search for OpenResty to get ID and Key
    final search = await api.searchApps(AppSearchRequest(page: 1, pageSize: 1, name: 'openresty'));
    if (search.items.isEmpty) {
      debugPrint('OpenResty not found');
      return;
    }
    final app = search.items.first;
    debugPrint('App: ${app.name}, ID: ${app.id}, Key: ${app.key}');

    // 2. Try getting icon by ID
    try {
      debugPrint('Trying icon by ID: ${app.id}');
      final res1 = await api.getAppIcon(app.id.toString());
      debugPrint('Icon by ID status: ${res1.statusCode}, Data length: ${res1.data?.length}');
    } catch (e) {
      debugPrint('Icon by ID failed: $e');
    }

    // 3. Try getting icon by Key
    try {
      debugPrint('Trying icon by Key: ${app.key}');
      final res2 = await api.getAppIcon(app.key!);
      debugPrint('Icon by Key status: ${res2.statusCode}, Data length: ${res2.data?.length}');
    } catch (e) {
      debugPrint('Icon by Key failed: $e');
    }
    // 4. Edge Cases
    debugPrint('\n--- Edge Cases ---');
    
    // 4.1 Empty/Invalid ID
    try {
      debugPrint('Trying icon by Invalid ID: 999999');
      await api.getAppIcon('999999');
      debugPrint('WARNING: Invalid ID did not throw (might be 200 OK empty?)');
    } catch (e) {
      debugPrint('Invalid ID failed as expected: $e');
    }

    // 4.2 Empty Key (if applicable)
    try {
      debugPrint('Trying icon by Empty Key');
      await api.getAppIcon('');
      debugPrint('WARNING: Empty Key did not throw');
    } catch (e) {
      debugPrint('Empty Key failed as expected: $e');
    }
  });
}
