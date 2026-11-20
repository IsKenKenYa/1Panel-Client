import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/vm/vm_models.dart';
import 'package:onepanel_client/data/models/vm/vm_resource_models.dart';
import 'package:onepanel_client/features/vm/providers/vm_provider.dart';
import 'package:onepanel_client/features/vm/vm_service.dart';

class _MockVMService extends Mock implements VMService {}

void main() {
  late _MockVMService service;
  late VmProvider provider;

  const running = VMItem(
    id: 1,
    name: 'vm-a',
    cpu: 2,
    memory: 2048,
    diskSize: 20 * 1024 * 1024 * 1024,
    status: 'running',
  );
  const shutOff = VMItem(
    id: 2,
    name: 'vm-b',
    cpu: 4,
    memory: 4096,
    diskSize: 40 * 1024 * 1024 * 1024,
    status: 'shut off',
  );

  setUpAll(() {
    registerFallbackValue(const VMInfoReq(name: 'vm'));
    registerFallbackValue(const VMCreate(
      name: 'vm',
      cpu: 1,
      memory: 1024,
      diskSize: 10,
      network: 'nat',
      startAfterCreate: false,
      autoStart: false,
    ));
    registerFallbackValue(const VMUpdate(
      name: 'vm',
      cpu: 1,
      memory: 1024,
      isoPaths: <String>[],
      network: 'nat',
      autoStart: false,
    ));
    registerFallbackValue(const VMNetworkCreate(
      name: 'net',
      type: 'nat',
      autoStart: false,
    ));
    registerFallbackValue(const VMNetworkUpdate(id: 1));
    registerFallbackValue(const VMStorageCreate(
      name: 'pool',
      type: 'dir',
      path: '/data',
      autoStart: false,
    ));
    registerFallbackValue(const VMStorageUpdate(id: 1));
    registerFallbackValue(const VMTemplateCreate(
      name: 'vm',
      templateName: 'tpl',
    ));
    registerFallbackValue(const VMSnapshotReq(name: 'vm', snapshotName: 's'));
    registerFallbackValue(const VMDiskResize(
      name: 'vm',
      target: 'vda',
      sizeGiB: 10,
    ));
    registerFallbackValue(const VMIsoCreate(type: 'Ubuntu', name: 'iso', path: '/i'));
    registerFallbackValue(const VMIsoUpdate(
      id: 1,
      type: 'Ubuntu',
      name: 'iso',
      path: '/i',
    ));
    registerFallbackValue(const VMIsoImportStart(
      type: 'Ubuntu',
      name: 'iso',
      path: '/i',
      status: 'uploading',
    ));
    registerFallbackValue(const VMIsoImportUpdate(id: 1, status: 'ready'));
  });

  setUp(() {
    service = _MockVMService();
    provider = VmProvider(service: service);
  });

  tearDown(() {
    provider.dispose();
  });

  group('VmProvider', () {
    test('loadVms populates list, total and quota limit', () async {
      when(() => service.searchVMs(info: any(named: 'info')))
          .thenAnswer((_) async => const VMSearchResult(
                items: <VMItem>[running, shutOff],
                total: 2,
                limit: 5,
              ));

      await provider.loadVms();

      expect(provider.vms.length, 2);
      expect(provider.vmTotal, 2);
      expect(provider.vmLimit, 5);
      expect(provider.canCreateVm, isTrue);
      expect(provider.vmState.error, isNull);
    });

    test('canCreateVm is false when quota reached', () async {
      when(() => service.searchVMs(info: any(named: 'info')))
          .thenAnswer((_) async => const VMSearchResult(
                items: <VMItem>[running, shutOff],
                total: 2,
                limit: 2,
              ));

      await provider.loadVms();

      expect(provider.canCreateVm, isFalse);
    });

    test('limit of zero means unlimited', () async {
      when(() => service.searchVMs(info: any(named: 'info')))
          .thenAnswer((_) async => const VMSearchResult(
                items: <VMItem>[running, shutOff],
                total: 2,
                limit: 0,
              ));

      await provider.loadVms();

      expect(provider.canCreateVm, isTrue);
    });

    test('allocated resources sum across instances', () async {
      when(() => service.searchVMs(info: any(named: 'info')))
          .thenAnswer((_) async => const VMSearchResult(
                items: <VMItem>[running, shutOff],
              ));

      await provider.loadVms();

      expect(provider.allocatedCpu, 6);
      expect(provider.allocatedMemory, 6144);
      expect(provider.allocatedDisk, 60 * 1024 * 1024 * 1024);
    });

    test('loadVms records error and clears list on failure', () async {
      when(() => service.searchVMs(info: any(named: 'info')))
          .thenThrow(Exception('network down'));

      await provider.loadVms();

      expect(provider.vms, isEmpty);
      expect(provider.vmState.error, isNotNull);
    });

    test('loadEnvironment marks ready flag from service result', () async {
      when(() => service.checkEnvironment())
          .thenAnswer((_) async => const VMEnvironment(
                arch: 'x86_64',
                archSupported: true,
                ready: true,
                helperExist: true,
                kvmExist: true,
                libvirtExist: true,
                libvirtActive: true,
                storageExist: true,
              ));

      await provider.loadEnvironment();

      expect(provider.environmentReady, isTrue);
      expect(provider.environment.kvmExist, isTrue);
      expect(provider.environmentState.error, isNull);
    });

    test('enableEnvironment reloads environment state', () async {
      when(() => service.enableEnvironment()).thenAnswer((_) async {});
      when(() => service.checkEnvironment())
          .thenAnswer((_) async => const VMEnvironment(ready: true));

      final success = await provider.enableEnvironment();

      expect(success, isTrue);
      expect(provider.environmentReady, isTrue);
      verify(() => service.enableEnvironment()).called(1);
    });

    test('setVmSearch forwards the trimmed keyword', () async {
      when(() => service.searchVMs(info: any(named: 'info')))
          .thenAnswer((_) async => const VMSearchResult());

      await provider.setVmSearch('  demo  ');

      expect(provider.vmSearch, 'demo');
      verify(() => service.searchVMs(info: 'demo')).called(1);
    });

    test('setVmStatusFilter keeps only matching status', () async {
      when(() => service.searchVMs(info: any(named: 'info')))
          .thenAnswer((_) async => const VMSearchResult(
                items: <VMItem>[running, shutOff],
              ));

      await provider.setVmStatusFilter('shut off');

      expect(provider.vms.length, 1);
      expect(provider.vms.single.name, 'vm-b');
    });

    test('operate uses the given power operation', () async {
      when(() => service.operateVM(any(), any())).thenAnswer((_) async {});
      when(() => service.searchVMs(info: any(named: 'info')))
          .thenAnswer((_) async => const VMSearchResult());

      await provider.operate('vm-a', 'shutdown');

      verify(() => service.operateVM('vm-a', 'shutdown')).called(1);
    });

    test('isMutating returns to false after a failed write', () async {
      when(() => service.createVM(any())).thenThrow(Exception('boom'));

      await expectLater(provider.createVm(const VMCreate(
        name: 'vm',
        cpu: 1,
        memory: 1024,
        diskSize: 10,
        network: 'nat',
        startAfterCreate: false,
        autoStart: false,
      )), throwsException);

      expect(provider.isMutating, isFalse);
    });

    test('startIsoImport rejects a missing import id', () async {
      when(() => service.startIsoImport(any()))
          .thenThrow(StateError('服务端未返回 ISO 导入记录 id'));

      await expectLater(
        provider.startIsoImport(const VMIsoImportStart(
          type: 'Ubuntu',
          name: 'iso',
          path: '/i',
          status: 'uploading',
        )),
        throwsStateError,
      );
    });

    test('onServerChanged resets service and reloads sections', () async {
      when(() => service.resetForServerChange()).thenReturn(null);
      when(() => service.checkEnvironment())
          .thenAnswer((_) async => const VMEnvironment());
      when(() => service.searchVMs(info: any(named: 'info')))
          .thenAnswer((_) async => const VMSearchResult());
      when(() => service.listIso()).thenAnswer((_) async => const <VMIsoItem>[]);
      when(() => service.listTemplates())
          .thenAnswer((_) async => const <VMTemplateItem>[]);
      when(() => service.listNetworks())
          .thenAnswer((_) async => const <VMNetworkItem>[]);
      when(() => service.listStorages())
          .thenAnswer((_) async => const <VMStorageItem>[]);

      await provider.onServerChanged();

      verify(() => service.resetForServerChange()).called(1);
      expect(provider.vms, isEmpty);
      expect(provider.storages, isEmpty);
    });
  });
}
