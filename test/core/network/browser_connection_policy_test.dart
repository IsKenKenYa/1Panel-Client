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
    for (final url in [
      'panel',
      'file:///panel',
      'https://user:pass@panel.example'
    ]) {
      expect(BrowserConnectionPolicy.issue(url),
          BrowserConnectionIssue.invalidAddress);
    }
  });

  test('面板安全入口保留服务器来源并移除查询参数', () {
    const address = 'https://[::1]:8443/panel?tab=settings#current';
    expect(BrowserConnectionPolicy.panelWebEntrance(address, null).toString(),
        'https://[::1]:8443/panel');
    expect(
        BrowserConnectionPolicy.panelWebEntrance(address, '/entry').toString(),
        'https://[::1]:8443/entry');
    final entry = BrowserConnectionPolicy.panelWebEntrance(
        address, '//other.example/path');
    expect(entry.origin, 'https://[::1]:8443');
    expect(entry.path, '/other.example/path');
    expect(
        () =>
            BrowserConnectionPolicy.panelWebEntrance('file:///panel', 'entry'),
        throwsArgumentError);
  });
}
