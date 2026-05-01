import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/database_v2.dart';
import 'package:onepanel_client/api/v2/snapshot_v2.dart';
import 'package:onepanel_client/api/v2/ssh_v2.dart';
import 'package:onepanel_client/api/v2/toolbox_v2.dart';
import 'package:onepanel_client/api/v2/update_v2.dart';
import 'package:onepanel_client/api/v2/website_group_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';

void main() {
  group('Phase C batch3 contract alignment', () {
    late HttpServer server;
    late DioClient client;
    late String requestMethod;
    late String requestPath;
    late Map<String, dynamic>? requestBody;
    late Map<String, dynamic> Function() responseBuilder;

    setUp(() async {
      requestMethod = '';
      requestPath = '';
      requestBody = null;
      responseBuilder = () => <String, dynamic>{'code': 200, 'data': null};

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        requestMethod = request.method;
        requestPath = request.uri.path;

        final raw = await utf8.decoder.bind(request).join();
        if (raw.isNotEmpty) {
          requestBody = jsonDecode(raw) as Map<String, dynamic>;
        } else {
          requestBody = null;
        }

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(responseBuilder()));
        await request.response.close();
      });

      client = DioClient(
        baseUrl: 'http://${server.address.host}:${server.port}',
        apiKey: 'test-key',
      );
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('SshV2Api fail2ban status should align to POST with operate body',
        () async {
      final api = SshV2Api(client);
      await api.getFail2banSshdStatus();

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/toolbox/fail2ban/operate/sshd');
      expect(requestBody, isNotNull);
      expect(requestBody?['operate'], isNotNull);
    });

    test('UpdateV2Api release notes should align to POST with version body',
        () async {
      responseBuilder = () => <String, dynamic>{'code': 200, 'data': 'notes'};

      final api = UpdateV2Api(client);
      await api.getUpgradeNotes();

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/core/settings/upgrade/notes');
      expect(requestBody, isNotNull);
      expect(requestBody?['version'], isNotNull);
    });

    test('UpdateV2Api upgrade should send version body payload', () async {
      final api = UpdateV2Api(client);
      await api.systemUpgrade();

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/core/settings/upgrade');
      expect(requestBody, isNotNull);
      expect(requestBody?['version'], isNotNull);
    });

    test('WebsiteGroupV2Api /groups should align to POST with request body',
        () async {
      final api = WebsiteGroupV2Api(client);
      await api.getGroups();

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/groups');
      expect(requestBody, isNotNull);
      expect(requestBody?['name'], isNotNull);
      expect(requestBody?['type'], isNotNull);
    });

    test('SnapshotV2Api recreate should send OperateByID payload', () async {
      final api = SnapshotV2Api(client);
      await api.recreateSnapshot();

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/settings/snapshot/recreate');
      expect(requestBody, isNotNull);
      expect(requestBody?['id'], isNotNull);
    });

    test('ToolboxV2Api sync ftp should send BatchDeleteReq payload', () async {
      final api = ToolboxV2Api(client);
      await api.syncFtp();

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/toolbox/ftp/sync');
      expect(requestBody, isNotNull);
      expect(requestBody?['ids'], isNotNull);
    });

    test('DatabaseV2Api postgresql load should send PostgresqlLoadDB body',
        () async {
      final api = DatabaseV2Api(client);
      await api.loadPostgresqlDatabaseFromRemote('analytics');

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/databases/pg/analytics/load');
      expect(requestBody, isNotNull);
      expect(requestBody?['database'], isNotNull);
      expect(requestBody?['from'], isNotNull);
      expect(requestBody?['type'], isNotNull);
    });
  });
}
