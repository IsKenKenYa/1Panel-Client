import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/alert_models.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/features/alert/alert_service.dart';
import 'package:onepanel_client/features/alert/providers/alert_provider.dart';

class _MockAlertService extends Mock implements AlertService {}

void main() {
  late _MockAlertService service;
  late AlertProvider provider;

  setUpAll(() {
    registerFallbackValue(
      const AlertSearch(orderBy: 'created_at', order: 'descending'),
    );
    registerFallbackValue(const AlertCreate(type: 'cpu', method: 'mail'));
    registerFallbackValue(const AlertUpdate(id: 1));
    registerFallbackValue(const AlertUpdateStatus(id: 1, status: 'Enable'));
    registerFallbackValue(const AlertLogSearch());
    registerFallbackValue(const OperateByID(id: 1));
    registerFallbackValue(const AlertConfigFilterReq());
    registerFallbackValue(const AlertConfigUpdate(id: 1));
    registerFallbackValue(const AlertConfigTest());
    registerFallbackValue(const AlertCronJobReq());
  });

  setUp(() {
    service = _MockAlertService();
    provider = AlertProvider(service: service);
  });

  tearDown(() {
    provider.dispose();
  });

  group('AlertProvider', () {
    test('loadRules stores items and total', () async {
      when(() => service.searchAlerts(
            page: any(named: 'page'),
            type: any(named: 'type'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => const PageResult<AlertInfo>(
            items: <AlertInfo>[
              AlertInfo(
                id: 1,
                createdAt: '2024-01-01T00:00:00Z',
                updatedAt: '2024-01-01T00:00:00Z',
                type: 'cpu',
                subType: '',
                cycle: 0,
                count: 80,
                interval: 1,
                method: 'mail',
                title: 'CPU alert',
                project: '',
                status: 'Enable',
                sendCount: 1,
                sendMethod: <String>['mail'],
                advancedParams: '',
              ),
            ],
            total: 1,
          ));

      await provider.loadRules();

      expect(provider.rules.length, 1);
      expect(provider.ruleTotal, 1);
      expect(provider.ruleError, isNull);
    });

    test('loadRules records error on failure', () async {
      when(() => service.searchAlerts(
            page: any(named: 'page'),
            type: any(named: 'type'),
            status: any(named: 'status'),
          )).thenThrow(Exception('boom'));

      await provider.loadRules();

      expect(provider.rules, isEmpty);
      expect(provider.ruleError, isNotNull);
    });

    test('setRuleType reloads with the new filter', () async {
      when(() => service.searchAlerts(
            page: any(named: 'page'),
            type: any(named: 'type'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => const PageResult<AlertInfo>(
            items: <AlertInfo>[],
            total: 0,
          ));

      await provider.setRuleType('disk');

      expect(provider.ruleType, 'disk');
      verify(() => service.searchAlerts(
            page: any(named: 'page'),
            type: 'disk',
            status: any(named: 'status'),
          )).called(1);
    });

    test('toggleRule sends the mapped status value', () async {
      when(() => service.updateAlertStatus(any(), any()))
          .thenAnswer((_) async {});
      when(() => service.searchAlerts(
            page: any(named: 'page'),
            type: any(named: 'type'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => const PageResult<AlertInfo>(
            items: <AlertInfo>[],
            total: 0,
          ));

      await provider.toggleRule(1, false);

      verify(() => service.updateAlertStatus(1, 'Disable')).called(1);
    });

    test('loadLogs stores items and total', () async {
      when(() => service.searchLogs(
            page: any(named: 'page'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => const PageResult<AlertLog>(
            items: <AlertLog>[
              AlertLog(
                id: 1,
                createdAt: '2024-01-01T00:00:00Z',
                updatedAt: '2024-01-01T00:00:00Z',
                alertId: 1,
                alertDetail: AlertDetail(
                  type: 'cpu',
                  licenseId: '',
                  title: 'CPU alert',
                  project: '',
                  method: 'mail',
                ),
                alertRule: AlertInfo(
                  id: 1,
                  createdAt: '2024-01-01T00:00:00Z',
                  updatedAt: '2024-01-01T00:00:00Z',
                  type: 'cpu',
                  subType: '',
                  cycle: 0,
                  count: 80,
                  interval: 1,
                  method: 'mail',
                  title: 'CPU alert',
                  project: '',
                  status: 'Enable',
                  sendCount: 1,
                  sendMethod: <String>['mail'],
                  advancedParams: '',
                ),
                count: 1,
                message: 'smtp timeout',
                status: 'Error',
                method: 'mail',
              ),
            ],
            total: 1,
          ));

      await provider.loadLogs();

      expect(provider.logs.length, 1);
      expect(provider.logs.single.message, 'smtp timeout');
    });

    test('cleanLogs refreshes the log list', () async {
      when(() => service.cleanLogs()).thenAnswer((_) async {});
      when(() => service.searchLogs(
            page: any(named: 'page'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => const PageResult<AlertLog>(
            items: <AlertLog>[],
            total: 0,
          ));

      await provider.cleanLogs();

      verify(() => service.cleanLogs()).called(1);
      expect(provider.logs, isEmpty);
    });

    test('loadChannels filters hidden types from the service result', () async {
      when(() => service.listConfigs()).thenAnswer((_) async =>
          const <AlertConfigInfo>[
            AlertConfigInfo(
              id: 1,
              createdAt: '2024-01-01T00:00:00Z',
              updatedAt: '2024-01-01T00:00:00Z',
              type: 'email',
              title: 'Mail',
              config: '{}',
              status: 'Enable',
            ),
            AlertConfigInfo(
              id: 2,
              createdAt: '2024-01-01T00:00:00Z',
              updatedAt: '2024-01-01T00:00:00Z',
              type: 'sms',
              title: 'SMS',
              config: '{}',
              status: 'Enable',
            ),
          ]);

      await provider.loadChannels();

      // 服务层已过滤 sms，这里验证 Provider 不额外增删条目。
      expect(provider.channels.length, 2);
      expect(provider.enabledChannels.length, 2);
    });

    test('enabledChannels excludes disabled entries', () async {
      when(() => service.listConfigs()).thenAnswer((_) async =>
          const <AlertConfigInfo>[
            AlertConfigInfo(
              id: 1,
              createdAt: '2024-01-01T00:00:00Z',
              updatedAt: '2024-01-01T00:00:00Z',
              type: 'email',
              title: 'Mail',
              config: '{}',
              status: 'Enable',
            ),
            AlertConfigInfo(
              id: 2,
              createdAt: '2024-01-01T00:00:00Z',
              updatedAt: '2024-01-01T00:00:00Z',
              type: 'bark',
              title: 'Bark',
              config: '{}',
              status: 'Disable',
            ),
          ]);

      await provider.loadChannels();

      expect(provider.enabledChannels.length, 1);
      expect(provider.enabledChannels.single.title, 'Mail');
    });

    test('loadTargetOptions loads disks, clams and cronjobs', () async {
      when(() => service.listDisks())
          .thenAnswer((_) async => const <AlertDisk>[
                AlertDisk(
                  path: '/',
                  type: 'ext4',
                  device: 'vda1',
                  total: 100,
                  free: 20,
                  used: 80,
                  usedPercent: 80.0,
                  inodesTotal: 100,
                  inodesUsed: 80,
                  inodesFree: 20,
                  inodesUsedPercent: 80.0,
                ),
              ]);
      when(() => service.listClams())
          .thenAnswer((_) async => const <AlertClam>[
                AlertClam(
                  id: 1,
                  name: 'daily-scan',
                  status: 'Enable',
                  path: '/var/lib/clamav',
                  createdAt: '2024-01-01T00:00:00Z',
                  updatedAt: '2024-01-01T00:00:00Z',
                ),
              ]);
      when(() => service.listCronJobs(type: any(named: 'type')))
          .thenAnswer((_) async => const <AlertCronJob>[
                AlertCronJob(
                  id: 1,
                  name: 'backup',
                  type: 'shell',
                  status: 'Enable',
                  createdAt: '2024-01-01T00:00:00Z',
                  updatedAt: '2024-01-01T00:00:00Z',
                ),
              ]);

      await provider.loadTargetOptions();

      expect(provider.disks.length, 1);
      expect(provider.clams.length, 1);
      expect(provider.cronJobs.length, 1);
    });

    test('onServerChanged resets the service and reloads', () async {
      when(() => service.resetForServerChange()).thenReturn(null);
      when(() => service.searchAlerts(
            page: any(named: 'page'),
            type: any(named: 'type'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => const PageResult<AlertInfo>(
            items: <AlertInfo>[],
            total: 0,
          ));
      when(() => service.searchLogs(
            page: any(named: 'page'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => const PageResult<AlertLog>(
            items: <AlertLog>[],
            total: 0,
          ));
      when(() => service.listConfigs())
          .thenAnswer((_) async => const <AlertConfigInfo>[]);

      await provider.onServerChanged();

      verify(() => service.resetForServerChange()).called(1);
      expect(provider.rules, isEmpty);
      expect(provider.channels, isEmpty);
    });
  });
}
