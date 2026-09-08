import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_read_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// B25 契约钉死：getTranslations 是 WinUI3 宿主 L10n 查表类的单一数据源。
/// 返回当前 locale 的整份 arb 字典（@ 元数据键剥离），期望值为从
/// lib/l10n/app_zh.arb / app_en.arb 手抄的独立 golden，防止自证。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeChannelReadHandlers.getTranslations', () {
    test('zh locale returns zh values with @ metadata stripped', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'zh'});

      final result = await NativeChannelReadHandlers.getTranslations();

      expect(result, isA<Map<dynamic, dynamic>>());
      final map = result as Map<dynamic, dynamic>;
      // golden：手抄自 app_zh.arb。
      expect(map['settingsUIRenderMode'], 'UI 渲染模式');
      expect(map['settingsPageTitle'], '设置');
      expect(map.keys.any((k) => k.toString().startsWith('@')), isFalse);
    });

    test('en locale returns en values', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});

      final result = await NativeChannelReadHandlers.getTranslations();

      final map = result as Map<dynamic, dynamic>;
      expect(map['settingsUIRenderMode'], 'UI Render Mode');
    });

    test('system locale (null pref) falls back by platform language',
        () async {
      // Platform.localeName 在测试进程内不可控，此处只锁定契约形状：
      // 非 zh 环境返回 en 字典或空 Map（加载失败），但绝不抛异常。
      SharedPreferences.setMockInitialValues({'app_locale': 'system'});

      final result = await NativeChannelReadHandlers.getTranslations();

      expect(result, isA<Map<dynamic, dynamic>>());
    });
  });
}
