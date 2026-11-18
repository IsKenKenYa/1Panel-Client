import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('启动阶段写入日志后再次初始化日志服务', () {
    appLogger.d('启动阶段配置已读取');

    expect(appLogger.init, returnsNormally);
  });
}
