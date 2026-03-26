import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/host_asset_models.dart';
import 'package:onepanel_client/data/models/host_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/host_assets/models/host_asset_form_args.dart';
import 'package:onepanel_client/features/host_assets/providers/host_asset_form_provider.dart';
import 'package:onepanel_client/features/host_assets/services/host_asset_service.dart';

class _MockHostAssetService extends Mock implements HostAssetService {}

void main() {
  late _MockHostAssetService service;
  late HostAssetFormProvider provider;

  final groups = <GroupInfo>[
    const GroupInfo(id: 1, name: 'Default', type: 'host', isDefault: true),
  ];

  setUpAll(() {
    registerFallbackValue(
      const HostOperate(
        name: 'fallback',
        groupID: 1,
        addr: '127.0.0.1',
        port: 22,
        user: 'root',
        authMode: 'password',
      ),
    );
    registerFallbackValue(
      const HostConnTest(
        addr: '127.0.0.1',
        port: 22,
        user: 'root',
        authMode: 'password',
      ),
    );
    registerFallbackValue(
      const HostInfo(
        id: 1,
        name: 'fallback',
        addr: '127.0.0.1',
        user: 'root',
        port: 22,
        groupID: 1,
        groupBelong: 'Default',
        authMode: 'password',
        status: 'active',
      ),
    );
  });

  setUp(() {
    service = _MockHostAssetService();
    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => groups);
    when(() => service.resolveDefaultGroupId(any())).thenReturn(1);
    when(() => service.testHostByInfo(any())).thenAnswer((_) async => true);
    when(() => service.createHost(any())).thenAnswer((_) async {});
    when(() => service.updateHost(any())).thenAnswer(
      (_) async => const HostInfo(
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
    );
    when(() => service.fromHostInfo(any())).thenReturn(
      const HostOperate(
        id: 1,
        name: 'edge-01',
        groupID: 1,
        addr: '10.0.0.7',
        port: 22,
        user: 'root',
        authMode: 'password',
      ),
    );
    provider = HostAssetFormProvider(service: service);
  });

  test('initialize sets default group', () async {
    await provider.initialize(null);

    expect(provider.draft.groupID, 1);
    expect(provider.isEditing, isFalse);
  });

  test('testConnection enables save', () async {
    await provider.initialize(null);
    provider.updateBasic(name: 'edge-01', addr: '10.0.0.7');
    provider.updateAuth(user: 'root', password: 'secret');

    final success = await provider.testConnection();

    expect(success, isTrue);
    expect(provider.isConnectionVerified, isTrue);
  });

  test('connection field changes reset verification', () async {
    await provider.initialize(null);
    provider.updateBasic(name: 'edge-01', addr: '10.0.0.7');
    provider.updateAuth(user: 'root', password: 'secret');
    await provider.testConnection();

    provider.updateBasic(addr: '10.0.0.8');

    expect(provider.isConnectionVerified, isFalse);
  });

  test('save edit calls updateHost', () async {
    await provider.initialize(
      const HostAssetFormArgs(
        initialValue: HostInfo(
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
      ),
    );
    await provider.testConnection();

    final result = await provider.save();

    expect(result, isTrue);
    verify(() => service.updateHost(any())).called(1);
  });
}
