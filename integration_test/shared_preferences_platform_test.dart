import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('默认设置读取与自定义前缀数据分别处理', (_) async {
    const defaultKey = 'flutter.shared_preferences_platform_test.value';
    const customKey = 'kenpanel.shared_preferences_platform_test.value';
    final store = SharedPreferencesStorePlatform.instance;
    addTearDown(() async {
      await store.remove(defaultKey);
      await store.remove(customKey);
    });
    await store.setValue('String', defaultKey, 'default-value');
    await store.setValue('String', customKey, 'custom-value');

    final defaults = await store.getAll();
    expect(defaults.keys.every((key) => key.startsWith('flutter.')), isTrue);
    expect(defaults[defaultKey], 'default-value');
    expect(defaults.containsKey(customKey), isFalse);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('shared_preferences_platform_test.value'),
      'default-value',
    );
    final custom = await store.getAllWithParameters(
      GetAllParameters(
        filter: PreferencesFilter(
          prefix: 'kenpanel.shared_preferences_platform_test.',
        ),
      ),
    );
    expect(custom[customKey], 'custom-value');
  });
}
