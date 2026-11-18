import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/app_models.dart';

/// 回归测试：应用安装表单的上游字段形状。
///
/// 问题背景：
/// - `/apps/detail/:appId/:version/:type` 的 `params.formFields[].child`
///   只给 `{type, envKey, required}`，没有 `labelZh` / `labelEn`，
///   生成的解析器按非空 String 读取会抛类型错误，整个安装表单打不开。
/// - `values` 在 `select` 下是字符串，在 `apps`（依赖应用）下是
///   `{label, value}` 对象，原生侧需要统一的枚举形状。
void main() {
  group('AppFormField child shape', () {
    test('child without label fields parses with empty labels', () {
      final field = AppFormField.fromJson({
        'type': 'apps',
        'envKey': 'PANEL_DB_TYPE',
        'labelZh': '数据库服务',
        'labelEn': 'Database Service',
        'required': true,
        'default': 'mysql',
        'values': [
          {'label': 'MySQL', 'value': 'mysql'},
          {'label': 'MariaDB', 'value': 'mariadb'},
        ],
        'child': {
          'type': 'service',
          'envKey': 'PANEL_DB_HOST',
          'required': true,
          'default': '',
        },
      });

      expect(field.type, 'apps');
      expect(field.child, isNotNull);
      expect(field.child!.envKey, 'PANEL_DB_HOST');
      expect(field.child!.type, 'service');
      expect(field.child!.labelZh, isEmpty);
      expect(field.child!.labelEn, isEmpty);
      expect(field.values, hasLength(2));
    });

    test('select field keeps plain string values', () {
      final field = AppFormField.fromJson({
        'type': 'select',
        'envKey': 'PANEL_APP_OS',
        'labelZh': '系统',
        'labelEn': 'OS',
        'required': false,
        'values': ['ubuntu', 'alpine'],
      });

      expect(field.values, ['ubuntu', 'alpine']);
    });
  });
}
