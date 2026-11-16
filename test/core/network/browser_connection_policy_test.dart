import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/network/browser_connection_policy.dart';

void main() {
  test('接受 HTTP 与 HTTPS 地址，网络访问由浏览器执行检查', () {
    for (final address in [
      'http://192.168.1.10:13802',
      'http://203.0.113.10:26314',
      'http://localhost:18080',
      'http://[::1]:18080',
      'https://panel.example',
    ]) {
      expect(BrowserConnectionPolicy.issue(address), isNull);
    }
  });

  test('拒绝无主机、其他协议与 URL 中的凭据', () {
    for (final url in ['panel', 'file:///panel', 'https://user:pass@panel.example']) {
      expect(BrowserConnectionPolicy.issue(url),
          BrowserConnectionIssue.invalidAddress);
    }
  });
}
