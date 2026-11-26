import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:onepanel_client/api/v2/ssl_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/ssl_models.dart';

import 'compose_api_test.mocks.dart';

@GenerateMocks([DioClient])
void main() {
  late SSLV2Api api;
  late MockDioClient mockClient;

  setUp(() {
    mockClient = MockDioClient();
    api = SSLV2Api(mockClient);
  });

  RequestOptions _opts(String path) => RequestOptions(path: path);

  Response<Map<String, dynamic>> _successMapResponse(
    Map<String, dynamic> data, {
    String path = '/test',
  }) {
    return Response(
      data: data,
      statusCode: 200,
      requestOptions: _opts(path),
    );
  }

  Response<dynamic> _successDynamicResponse(
    dynamic data, {
    String path = '/test',
  }) {
    return Response(
      data: data,
      statusCode: 200,
      requestOptions: _opts(path),
    );
  }

  group('SSLV2Api', () {
    group('createWebsiteSSL', () {
      test('sends create request successfully', () async {
        when(mockClient.post<void>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: null,
              statusCode: 200,
              requestOptions: _opts('/websites/ssl'),
            ));

        final request = WebsiteSSLCreate(
          acmeAccountId: 1,
          primaryDomain: 'example.com',
          provider: 'letsencrypt',
        );
        final response = await api.createWebsiteSSL(request);
        expect(response.statusCode, 200);
      });
    });

    group('getWebsiteSSLById', () {
      test('returns WebsiteSSL by id', () async {
        when(mockClient.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => _successMapResponse({
              'code': 200,
              'data': {
                'id': 1,
                'primaryDomain': 'example.com',
                'status': 'valid',
                'type': 'lets-encrypt',
                'autoRenew': true,
              },
            }, path: '/websites/ssl/1'));

        final response = await api.getWebsiteSSLById(1);
        expect(response.data, isA<WebsiteSSL>());
        expect(response.data!.id, 1);
        expect(response.data!.primaryDomain, 'example.com');
        expect(response.data!.status, 'valid');
      });
    });

    group('deleteWebsiteSSL', () {
      test('sends delete request with ids', () async {
        when(mockClient.post(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => _successDynamicResponse(
              null,
              path: '/websites/ssl/del',
            ));

        await api.deleteWebsiteSSL([1, 2, 3]);

        verify(mockClient.post(
          any,
          data: anyNamed('data'),
        )).called(1);
      });
    });

    group('downloadSSLFile', () {
      test('returns download path string', () async {
        when(mockClient.post(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => _successDynamicResponse(
              {'data': '/tmp/ssl-cert-1.zip'},
              path: '/websites/ssl/download',
            ));

        final response = await api.downloadSSLFile(1);
        expect(response.data, isA<String>());
      });
    });

    group('applySSL', () {
      test('sends apply request successfully', () async {
        when(mockClient.post<void>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: null,
              statusCode: 200,
              requestOptions: _opts('/websites/ssl/obtain'),
            ));

        final request = WebsiteSSLApply(id: 1);
        final response = await api.applySSL(request);
        expect(response.statusCode, 200);
      });

      test('sends apply request with options', () async {
        when(mockClient.post<void>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: null,
              statusCode: 200,
              requestOptions: _opts('/websites/ssl/obtain'),
            ));

        final request = WebsiteSSLApply(
          id: 1,
          disableLog: true,
          skipDNSCheck: false,
          nameservers: ['8.8.8.8'],
        );
        await api.applySSL(request);
      });
    });

    group('resolveWebsiteSSL', () {
      test('returns DNS TXT records from resolve', () async {
        when(mockClient.post(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => _successMapResponse({
              'code': 200,
              'data': [
                {
                  'domain': 'example.com',
                  'resolve': '_acme-challenge.example.com',
                  'value': 'challenge-token',
                  'err': '',
                },
              ],
            }, path: '/websites/ssl/resolve'));

        final request = WebsiteSSLResolve(
          acmeAccountId: 1,
          websiteSSLId: 1,
        );
        final response = await api.resolveWebsiteSSL(request);
        expect(response.data?.single['resolve'], '_acme-challenge.example.com');
        expect(response.data?.single['value'], 'challenge-token');
      });
    });

    group('searchWebsiteSSL', () {
      test('returns PageResult of WebsiteSSL', () async {
        when(mockClient.post(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => _successMapResponse({
              'data': {
                'items': [
                  {
                    'id': 1,
                    'primaryDomain': 'example.com',
                    'status': 'valid',
                    'domains': 'assets.example.com, shop.example.com',
                    'websites': [
                      {
                        'id': 42,
                        'primaryDomain': 'shop.example.com',
                        'domains': [
                          {'domain': 'www.shop.example.com', 'port': 443},
                        ],
                      },
                    ],
                  },
                  {
                    'id': 2,
                    'primaryDomain': 'test.com',
                    'status': 'expired',
                  },
                ],
                'total': 2,
                'page': 1,
                'pageSize': 10,
              },
            }, path: '/websites/ssl/search'));

        final request = WebsiteSSLSearch(page: 1, pageSize: 10);
        final response = await api.searchWebsiteSSL(request);
        expect(response.data, isA<PageResult<WebsiteSSL>>());
        expect(response.data!.items.length, 2);
        expect(response.data!.items.first.primaryDomain, 'example.com');
        expect(response.data!.items.first.domains,
            ['assets.example.com', 'shop.example.com']);
        expect(response.data!.items.first.websites?.single.id, 42);
        expect(response.data!.items.first.websites?.single.domains,
            ['www.shop.example.com']);
        expect(response.data!.total, 2);
      });
    });

    group('listWebsiteSSL', () {
      test('returns list of WebsiteSSL', () async {
        when(mockClient.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => _successMapResponse({
              'data': [
                {
                  'id': 1,
                  'primaryDomain': 'example.com',
                  'status': 'valid',
                },
              ],
            }, path: '/websites/ssl/list'));

        final request = WebsiteSSLSearch(page: 1, pageSize: 10);
        final response = await api.listWebsiteSSL(request);
        expect(response.data, isA<List<WebsiteSSL>>());
        expect(response.data!.length, 1);
        expect(response.data!.first.primaryDomain, 'example.com');
      });

      test('handles empty list', () async {
        when(mockClient.post<Map<String, dynamic>>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => _successMapResponse({
              'data': [],
            }, path: '/websites/ssl/list'));

        final request = WebsiteSSLSearch(page: 1, pageSize: 10);
        final response = await api.listWebsiteSSL(request);
        expect(response.data, isEmpty);
      });
    });

    group('updateWebsiteSSL', () {
      test('sends update request successfully', () async {
        when(mockClient.post<void>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: null,
              statusCode: 200,
              requestOptions: _opts('/websites/ssl/update'),
            ));

        final request = WebsiteSSLUpdate(
          id: 1,
          primaryDomain: 'example.com',
          provider: 'letsencrypt',
        );
        final response = await api.updateWebsiteSSL(request);
        expect(response.statusCode, 200);
      });
    });

    group('uploadSSL', () {
      test('sends upload request successfully', () async {
        when(mockClient.post<void>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: null,
              statusCode: 200,
              requestOptions: _opts('/websites/ssl/upload'),
            ));

        final request = WebsiteSSLUpload(
          privateKey: '-----BEGIN PRIVATE KEY-----',
          certificate: '-----BEGIN CERTIFICATE-----',
          type: 'custom',
        );
        final response = await api.uploadSSL(request);
        expect(response.statusCode, 200);
      });
    });

    group('getWebsiteSSLByWebsiteId', () {
      test('returns WebsiteSSL for given website', () async {
        when(mockClient.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => _successMapResponse({
              'code': 200,
              'data': {
                'id': 5,
                'primaryDomain': 'mysite.com',
                'status': 'valid',
              },
            }, path: '/websites/ssl/website/10'));

        final response = await api.getWebsiteSSLByWebsiteId(10);
        expect(response.data, isA<WebsiteSSL>());
        expect(response.data!.id, 5);
        expect(response.data!.primaryDomain, 'mysite.com');
      });
    });

    group('getSSLOptions', () {
      test('returns list of SSL options', () async {
        when(mockClient.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
              data: [
                {'label': 'Let\'s Encrypt', 'value': 'letsencrypt'},
                {'label': 'Self-Signed', 'value': 'self-signed'},
              ],
              statusCode: 200,
              requestOptions: _opts('/websites/ssl/options'),
            ));

        final response = await api.getSSLOptions();
        expect(response.data, isA<List<Map<String, dynamic>>>());
        expect(response.data!.length, 2);
        expect(response.data!.first['label'], 'Let\'s Encrypt');
      });
    });

    group('validateSSLConfig', () {
      test('returns validation result', () async {
        when(mockClient.post(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => _successMapResponse({
              'valid': true,
              'message': 'Certificate is valid',
            }, path: '/websites/ssl/validate'));

        final response = await api.validateSSLConfig({
          'certificate': '-----BEGIN CERTIFICATE-----',
          'privateKey': '-----BEGIN PRIVATE KEY-----',
        });
        expect(response.data!['valid'], true);
      });
    });

    group('autoRenewSSL', () {
      test('sends auto-renew request with ids', () async {
        when(mockClient.post(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => _successDynamicResponse(
              null,
              path: '/websites/ssl/auto-renew',
            ));

        await api.autoRenewSSL([1, 2]);
      });
    });

    group('getSSLApplicationStatus', () {
      test('returns application status', () async {
        when(mockClient.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => _successMapResponse({
              'status': 'pending',
              'message': 'Waiting for DNS verification',
            }, path: '/websites/ssl/application/1/status'));

        final response = await api.getSSLApplicationStatus(1);
        expect(response.data!['status'], 'pending');
      });
    });

    group('downloadSystemCert', () {
      test('returns download path string', () async {
        when(mockClient.post(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => _successDynamicResponse(
              {'data': '/tmp/system-cert.zip'},
              path: '/core/settings/ssl/download',
            ));

        final response = await api.downloadSystemCert();
        expect(response.data, isA<String>());
      });
    });

    group('loadSystemCertInfo', () {
      test('returns system cert info', () async {
        when(mockClient.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => _successMapResponse({
              'domain': 'panel.example.com',
              'expireDate': '2025-12-31',
              'type': 'self-signed',
            }, path: '/core/settings/ssl/info'));

        final response = await api.loadSystemCertInfo();
        expect(response.data!['domain'], 'panel.example.com');
        expect(response.data!['type'], 'self-signed');
      });
    });

    group('updateSystemSSL', () {
      test('sends system SSL update request', () async {
        when(mockClient.post<void>(
          any,
          data: anyNamed('data'),
          options: anyNamed('options'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: null,
              statusCode: 200,
              requestOptions: _opts('/core/settings/ssl/update'),
            ));

        final response = await api.updateSystemSSL({
          'cert': '-----BEGIN CERTIFICATE-----',
          'key': '-----BEGIN PRIVATE KEY-----',
        });
        expect(response.statusCode, 200);
      });
    });
  });
}
