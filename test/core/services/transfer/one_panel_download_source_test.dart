import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/services/transfer/one_panel_download_source.dart';

void main() {
  final server = ApiConfig(
    id: 'files',
    name: 'Files',
    url: 'https://panel.example:9443/proxy/',
    apiKey: '',
  );

  test('download targets include the configured address and API path', () {
    const path = '/带空格的目录/a b&c.txt';
    final uri = OnePanelDownloadSource.urlFor(server, path);
    expect(uri.queryParameters['path'], path);
    expect(OnePanelDownloadSource.matches(server, uri), isTrue);
    for (final changed in [
      uri.replace(host: 'other.example'),
      uri.replace(port: 443),
      uri.replace(scheme: 'http'),
      uri.replace(path: '/api/v2/files/download'),
      uri.replace(path: '/proxy/api/v2/files/upload'),
      uri.replace(userInfo: 'other'),
      uri.replace(queryParameters: {'path': path, 'extra': 'query'}),
    ]) {
      expect(OnePanelDownloadSource.matches(server, changed), isFalse);
    }
  });

  test('other panel types cannot build a 1Panel download URL', () {
    final config = ApiConfig.fromJson({
      ...server.toJson(),
      'panelType': 'other',
    });
    expect(
      () => OnePanelDownloadSource.urlFor(config, '/home/user'),
      throwsUnsupportedError,
    );
  });
}
