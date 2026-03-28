import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/mcp_models.dart';
import 'package:onepanel_client/features/ai/mcp_server_provider.dart';
import 'package:onepanel_client/features/ai/mcp_server_service.dart';

class MockMcpServerService extends Mock implements McpServerService {}

class FakeMcpBindDomain extends Fake implements McpBindDomain {}

class FakeMcpBindDomainUpdate extends Fake implements McpBindDomainUpdate {}

void main() {
  group('McpServerProvider', () {
    late MockMcpServerService service;
    late McpServerProvider provider;

    setUp(() {
      registerFallbackValue(FakeMcpBindDomain());
      registerFallbackValue(FakeMcpBindDomainUpdate());
      service = MockMcpServerService();
      provider = McpServerProvider(service: service);
    });

    test('load success updates servers and binding', () async {
      when(() => service.loadSnapshot(keyword: null)).thenAnswer(
        (_) async => McpServerSnapshot(
          servers: const <McpServerDTO>[
            McpServerDTO(
              id: 7,
              name: 'ops-mcp',
              status: 'Running',
              port: 8081,
              outputTransport: 'sse',
            ),
          ],
          binding: const McpBindDomainRes(
            domain: 'mcp.example.com',
            connUrl: 'https://mcp.example.com/sse',
          ),
        ),
      );

      await provider.load();

      expect(provider.error, isNull);
      expect(provider.servers, hasLength(1));
      expect(provider.servers.first.name, 'ops-mcp');
      expect(provider.binding.domain, 'mcp.example.com');
    });

    test('saveDomainBinding uses update when binding already exists', () async {
      when(() => service.loadSnapshot(keyword: null)).thenAnswer(
        (_) async => McpServerSnapshot(
          servers: const <McpServerDTO>[],
          binding: const McpBindDomainRes(
            domain: 'mcp.example.com',
            websiteID: 3,
          ),
        ),
      );
      when(
        () => service.updateDomain(any()),
      ).thenAnswer((_) async {});

      await provider.load();
      final success = await provider.saveDomainBinding(
        domain: 'mcp.example.com',
        websiteId: 3,
        ipList: '10.0.0.1',
      );

      expect(success, isTrue);
      verify(() => service.updateDomain(any())).called(1);
      verifyNever(() => service.bindDomain(any()));
    });
  });
}
