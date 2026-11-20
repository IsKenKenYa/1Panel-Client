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
    registerFallbackValue(const AlertSearch());
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
              AlertInfo(id: 1, title: 'CPU alert', type: 'cpu', status: 'Enable'),
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
              AlertLog(id: 1, status: 'Error', message: 'smtp timeout'),
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
            AlertConfigInfo(id: 1, type: 'email', title: 'Mail', status: 'Enable'),
            AlertConfigInfo(id: 2, type: 'sms', title: 'SMS', status: 'Enable'),
          ]);

      await provider.loadChannels();

      // 服务层已过滤 sms，这里验证 Provider 不额外增删条目。
      expect(provider.channels.length, 2);
      expect(provider.enabledChannels.length, 2);
    });

    test('enabledChannels excludes disabled entries', () async {
      when(() => service.listConfigs()).thenAnswer((_) async =>
          const <AlertConfigInfo>[
            AlertConfigInfo(id: 1, type: 'email', title: 'Mail', status: 'Enable'),
            AlertConfigInfo(id: 2, type: 'bark', title: 'Bark', status: 'Disable'),
          ]);

      await provider.loadChannels();

      expect(provider.enabledChannels.length, 1);
      expect(provider.enabledChannels.single.title, 'Mail');
    });

    test('loadTargetOptions loads disks, clams and cronjobs', () async {
      when(() => service.listDisks())
          .thenAnswer((_) async => const <AlertDisk>[
                AlertDisk(path: '/', type: 'ext4'),
              ]);
      when(() => service.listClams())
          .thenAnswer((_) async => const <AlertClam>[
                AlertClam(id: 1, name: 'daily-scan'),
              ]);
      when(() => service.listCronJobs(type: any(named: 'type')))
          .thenAnswer((_) async => const <AlertCronJob>[
                AlertCronJob(id: 1, name: 'backup', type: 'shell'),
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
