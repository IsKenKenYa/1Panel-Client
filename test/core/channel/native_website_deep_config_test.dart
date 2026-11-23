import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:onepanel_client/data/models/website_models.dart';

void main() {
  group('网站深度配置写入入口', () {
    test('缓存配置缺少网站标识时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.updateWebsiteProxyCache(
        <String, dynamic>{'open': true},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('websiteID'));
    });

    test('缓存容量超出范围时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.updateWebsiteProxyCache(
        <String, dynamic>{
          'websiteID': 1,
          'open': true,
          'cacheLimit': 10000,
          'shareCache': 5,
          'cacheExpire': 24,
        },
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('cacheLimit'));
    });

    test('真实 IP 开启时缺少来源地址返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.updateWebsiteRealIP(
        <String, dynamic>{
          'websiteID': 1,
          'open': true,
          'ipHeader': 'X-Real-IP',
        },
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('ipFrom'));
    });

    test('真实 IP 自定义头缺少名称返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.updateWebsiteRealIP(
        <String, dynamic>{
          'websiteID': 1,
          'open': true,
          'ipFrom': '127.0.0.1',
          'ipHeader': 'other',
        },
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('ipOther'));
    });

    test('转发端口为空时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.updateWebsiteStream(
        <String, dynamic>{'websiteID': 1, 'streamPorts': '  '},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('streamPorts'));
    });

    test('清理代理缓存缺少网站标识时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.clearWebsiteProxyCache(
        <String, dynamic>{},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('id'));
    });

    test('dispatch 路由清理代理缓存', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'clearWebsiteProxyCache',
        <String, dynamic>{},
      );

      expect(result['success'], isFalse);
    });

    test('dispatch 路由转发配置写入', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'updateWebsiteStream',
        <String, dynamic>{},
      );

      expect(result['success'], isFalse);
    });

    test('网站详情解析 UDP 转发标记', () {
      final info = WebsiteInfo.fromJson(<String, dynamic>{
        'id': 1,
        'primaryDomain': 'example.test',
        'streamPorts': '8080',
        'udp': true,
        'algorithm': 'default',
        'servers': <dynamic>[
          <String, dynamic>{'server': '127.0.0.1:9000', 'weight': 2},
        ],
      });

      expect(info.udp, isTrue);
      expect(info.streamPorts, '8080');
      expect(info.servers.single.server, '127.0.0.1:9000');
      expect(info.toJson()['udp'], isTrue);
    });
  });
}