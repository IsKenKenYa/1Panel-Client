import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/network/browser_connection_policy.dart';

void main() {
  final production = Uri.parse('https://1pc.iskenkenya.com/');

  test('HTTPS 页面要求 HTTPS 面板', () {
    expect(
      BrowserConnectionPolicy.issue('http://panel.example', application: production),
      BrowserConnectionIssue.httpsRequired,
    );
    expect(
      BrowserConnectionPolicy.issue('https://panel.example', application: production),
      isNull,
    );
  });

  test('localhost 开发页面允许 HTTP 测试主机', () {
    expect(
      BrowserConnectionPolicy.issue('http://192.0.2.10:18080',
          application: Uri.parse('http://localhost:8765/')),
      isNull,
    );
  });

  test('拒绝无主机、其他协议与 URL 中的凭据', () {
    for (final url in ['panel', 'file:///panel', 'https://user:pass@panel.example']) {
      expect(BrowserConnectionPolicy.issue(url, application: production),
          BrowserConnectionIssue.invalidAddress);
    }
  });
}
