import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/toolbox_models.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_fail2ban_provider.dart';
import 'package:onepanel_client/features/toolbox/services/toolbox_fail2ban_service.dart';

class _FakeToolboxFail2banService extends ToolboxFail2banService {
  int loadSnapshotCallCount = 0;
  int updateConfigCallCount = 0;
  int operateCallCount = 0;
  int operateSshdCallCount = 0;

  String? lastOperate;
  String? lastSshdOperate;
  List<String>? lastSshdIps;
  Fail2banUpdate? lastUpdateRequest;

  bool failNextUpdate = false;
  bool failNextOperate = false;

  @override
  Future<ToolboxFail2banSnapshot> loadSnapshot() async {
    loadSnapshotCallCount += 1;
    return const ToolboxFail2banSnapshot(
      baseInfo: Fail2banBaseInfo(
        bantime: '10m',
        findtime: '10m',
        maxretry: '5',
        port: 'ssh',
        isEnable: false,
      ),
      configText: '[sshd]\nenabled=true',
      records: <Fail2banRecord>[
        Fail2banRecord(ip: '1.1.1.1', status: 'banned'),
      ],
    );
  }

  @override
  Future<void> updateConfig(Fail2banUpdate request) async {
    if (failNextUpdate) {
      failNextUpdate = false;
      throw Exception('mock fail2ban update failure');
    }
    updateConfigCallCount += 1;
    lastUpdateRequest = request;
  }

  @override
  Future<void> operate(String operation) async {
    if (failNextOperate) {
      failNextOperate = false;
      throw Exception('mock fail2ban operation failure');
    }
    operateCallCount += 1;
    lastOperate = operation;
  }

  @override
  Future<void> operateSshd({
    required String operate,
    List<String> ips = const <String>[],
  }) async {
    operateSshdCallCount += 1;
    lastSshdOperate = operate;
    lastSshdIps = ips;
  }
}

void main() {
  test('ToolboxFail2banProvider load hydrates state', () async {
    final service = _FakeToolboxFail2banService();
    final provider = ToolboxFail2banProvider(service: service);

    await provider.load();

    expect(provider.error, isNull);
    expect(provider.baseInfo.maxretry, '5');
    expect(provider.configText, contains('[sshd]'));
    expect(provider.records, hasLength(1));
    expect(service.loadSnapshotCallCount, 1);
  });

  test('ToolboxFail2banProvider toggle/start/stop/restart call operate',
      () async {
    final service = _FakeToolboxFail2banService();
    final provider = ToolboxFail2banProvider(service: service);

    final toggleOk = await provider.toggle(true);
    final startOk = await provider.start();
    final stopOk = await provider.stop();
    final restartOk = await provider.restart();

    expect(toggleOk, isTrue);
    expect(startOk, isTrue);
    expect(stopOk, isTrue);
    expect(restartOk, isTrue);
    expect(service.operateCallCount, 4);
    expect(service.lastOperate, 'restart');
    expect(service.loadSnapshotCallCount, 4);
  });

  test('ToolboxFail2banProvider operateSshd forwards payload', () async {
    final service = _FakeToolboxFail2banService();
    final provider = ToolboxFail2banProvider(service: service);

    final ok = await provider.operateSshd(
      operate: 'unban',
      ips: const <String>['2.2.2.2'],
    );

    expect(ok, isTrue);
    expect(service.operateSshdCallCount, 1);
    expect(service.lastSshdOperate, 'unban');
    expect(service.lastSshdIps, const <String>['2.2.2.2']);
    expect(service.loadSnapshotCallCount, 1);
  });

  test('ToolboxFail2banProvider saveConfig failure exposes error', () async {
    final service = _FakeToolboxFail2banService();
    final provider = ToolboxFail2banProvider(service: service);
    service.failNextUpdate = true;

    final ok = await provider.saveConfig(
      bantime: '10m',
      findtime: '10m',
      maxretry: '5',
      port: 'ssh',
      isEnable: true,
    );

    expect(ok, isFalse);
    expect(provider.error, contains('mock fail2ban update failure'));
    expect(service.updateConfigCallCount, 0);
  });
}
