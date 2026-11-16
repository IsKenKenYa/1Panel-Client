import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/onepanel_auth_headers.dart';

void main() {
  group('OnePanelAuthHeaders', () {
    test('build returns map with token and timestamp headers', () {
      final headers = OnePanelAuthHeaders.build('test-api-key');
      expect(headers, contains(ApiConstants.authHeaderToken));
      expect(headers, contains(ApiConstants.authHeaderTimestamp));
      expect(headers.length, 2);
    });

    test('timestamp is unix epoch in seconds', () {
      final before = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
      final headers = OnePanelAuthHeaders.build('key');
      final after = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
      final ts = int.parse(headers[ApiConstants.authHeaderTimestamp]!);
      expect(ts, greaterThanOrEqualTo(before));
      expect(ts, lessThanOrEqualTo(after));
    });

    test('认证签名为 64 个十六进制字符', () {
      final headers = OnePanelAuthHeaders.build('my-key');
      final token = headers[ApiConstants.authHeaderToken]!;
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(token), isTrue);
    });

    test('HMAC-SHA256 与独立生成的协议测试向量一致', () {
      final headers = OnePanelAuthHeaders.build('test-api-key',
          now: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true));
      expect(headers[ApiConstants.authHeaderTimestamp], '1700000000');
      expect(headers[ApiConstants.authHeaderToken],
          '751a37be9a78d4a8e8de84a9d455b1d351f571994b02228c67580b42b5c78fc5');
      expect(headers.values.any((value) => value.contains('test-api-key')), isFalse);
    });

    test('different API keys produce different tokens', () {
      final now = DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true);
      final h1 = OnePanelAuthHeaders.build('key-alpha', now: now);
      final h2 = OnePanelAuthHeaders.build('key-beta', now: now);
      expect(h1[ApiConstants.authHeaderToken], isNot(h2[ApiConstants.authHeaderToken]));
    });

    test('签名按 UTF-8 处理 API Key', () {
      final headers = OnePanelAuthHeaders.build('面板密钥',
          now: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true));
      expect(headers[ApiConstants.authHeaderToken],
          '8be253e10f158f75cda8f7656d6c5c41b96f4d3d1b76504aec36036bc07209ed');
    });

    test('空 API Key 拒绝生成认证签名', () {
      expect(() => OnePanelAuthHeaders.build(''), throwsArgumentError);
    });

    test('auth prefix is "1panel"', () {
      expect(ApiConstants.authPrefix, '1panel');
    });

    test('header names match constants', () {
      expect(ApiConstants.authHeaderToken, '1Panel-Token');
      expect(ApiConstants.authHeaderTimestamp, '1Panel-Timestamp');
    });
  });
}
