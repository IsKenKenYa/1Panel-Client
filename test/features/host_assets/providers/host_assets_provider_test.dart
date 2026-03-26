import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/host_asset_models.dart';
import 'package:onepanel_client/data/models/host_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/host_assets/models/host_asset_test_state.dart';
import 'package:onepanel_client/features/host_assets/providers/host_assets_provider.dart';
import 'package:onepanel_client/features/host_assets/services/host_asset_service.dart';

class _MockHostAssetService extends Mock implements HostAssetService {}

void main() {
  late _MockHostAssetService service;
  late HostAssetsProvider provider;

  final groups = <GroupInfo>[
    const GroupInfo(id: 1, name: 'Default', type: 'host', isDefault: true),
  ];
  final hosts = <HostInfo>[
    const HostInfo(
      id: 1,
      name: 'edge-01',
      addr: '10.0.0.7',
      user: 'root',
      port: 22,
      groupID: 1,
      groupBelong: 'Default',
      authMode: 'password',
      status: 'active',
    ),
  ];

  setUpAll(() {
    registerFallbackValue(const HostSearchRequest());
    registerFallbackValue(const HostGroupChange(id: 1, groupID: 2));
  });

  setUp(() {
    service = _MockHostAssetService();
    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => groups);
    when(() => service.searchHosts(any())).thenAnswer(
      (_) async => PageResult<HostInfo>(
        items: hosts,
        total: hosts.length,
      ),
    );
    when(() => service.deleteHosts(any())).thenAnswer((_) async {});
    when(() => service.testHostById(any())).thenAnswer((_) async => true);
    when(() => service.updateHostGroup(any())).thenAnswer((_) async {});
    provider = HostAssetsProvider(service: service);
  });

  test('load sets hosts and groups', () async {
    await provider.load();

    expect(provider.hosts, hasLength(1));
    expect(provider.groups, hasLength(1));
  });

  test('testHost stores success state', () async {
    await provider.testHost(hosts.first);

    expect(provider.testStateFor(1).status, HostAssetTestStatus.success);
  });

  test('deleteSelected calls service', () async {
    await provider.load();
    provider.toggleSelection(1);

    await provider.deleteSelected();

    verify(() => service.deleteHosts(<int>[1])).called(1);
  });

  test('moveHostGroup calls service', () async {
    await provider.moveHostGroup(
      host: hosts.first,
      groupId: 2,
    );

    verify(
      () => service.updateHostGroup(
        const HostGroupChange(id: 1, groupID: 2),
      ),
    ).called(1);
  });
}
