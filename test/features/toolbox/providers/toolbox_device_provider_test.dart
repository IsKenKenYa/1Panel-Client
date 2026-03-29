import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_device_provider.dart';
import 'package:onepanel_client/features/toolbox/services/toolbox_device_service.dart';
import 'package:onepanel_client/data/models/toolbox_models.dart';

class _FakeToolboxDeviceService extends ToolboxDeviceService {
  int loadSnapshotCallCount = 0;
  int updateConfigCallCount = 0;
  int verifyDnsCallCount = 0;
  int updatePasswordCallCount = 0;
  int updateSwapCallCount = 0;

  DeviceConfUpdate? lastConfigUpdate;
  String? lastDns;
  String? lastOldPassword;
  String? lastNewPassword;
  String? lastSwap;

  bool failNextConfig = false;
  bool failNextDns = false;
  bool failNextPassword = false;
  bool failNextSwap = false;

  @override
  Future<ToolboxDeviceSnapshot> loadSnapshot() async {
    loadSnapshotCallCount += 1;
    return const ToolboxDeviceSnapshot(
      baseInfo: DeviceBaseInfo(
        dns: '1.1.1.1',
        hostname: 'panel-host',
        ntp: 'ntp.aliyun.com',
      ),
      conf: <String, dynamic>{
        'hostname': 'edge-host',
        'dns': '8.8.8.8',
        'ntp': '',
        'swap': '2048',
      },
      users: <String>['root', 'ubuntu'],
      zoneOptions: <String>['UTC', 'Asia/Shanghai'],
    );
  }

  @override
  Future<void> updateConfig({
    required String dns,
    required String hostname,
    required String ntp,
    required String swap,
  }) async {
    if (failNextConfig) {
      failNextConfig = false;
      throw Exception('mock device config update failure');
    }
    updateConfigCallCount += 1;
    lastConfigUpdate = DeviceConfUpdate(
      dns: dns,
      hostname: hostname,
      ntp: ntp,
      swap: swap,
    );
  }

  @override
  Future<void> verifyDns(String dns) async {
    if (failNextDns) {
      failNextDns = false;
      throw Exception('mock dns verify failure');
    }
    verifyDnsCallCount += 1;
    lastDns = dns;
  }

  @override
  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (failNextPassword) {
      failNextPassword = false;
      throw Exception('mock password update failure');
    }
    updatePasswordCallCount += 1;
    lastOldPassword = oldPassword;
    lastNewPassword = newPassword;
  }

  @override
  Future<void> updateSwap(String swap) async {
    if (failNextSwap) {
      failNextSwap = false;
      throw Exception('mock swap update failure');
    }
    updateSwapCallCount += 1;
    lastSwap = swap;
  }
}

void main() {
  test('ToolboxDeviceProvider load reads conf with base fallback', () async {
    final service = _FakeToolboxDeviceService();
    final provider = ToolboxDeviceProvider(service: service);

    await provider.load();

    expect(provider.error, isNull);
    expect(provider.hostname, 'edge-host');
    expect(provider.dns, '8.8.8.8');
    expect(provider.ntp, 'ntp.aliyun.com');
    expect(provider.swap, '2048');
    expect(provider.users, hasLength(2));
    expect(provider.zoneOptions, hasLength(2));
    expect(service.loadSnapshotCallCount, 1);
  });

  test('ToolboxDeviceProvider checkDns validates empty and success path',
      () async {
    final service = _FakeToolboxDeviceService();
    final provider = ToolboxDeviceProvider(service: service);

    final invalid = await provider.checkDns('   ');
    expect(invalid, isFalse);
    expect(provider.error, 'dns-empty');

    final ok = await provider.checkDns('4.4.4.4');
    expect(ok, isTrue);
    expect(provider.error, isNull);
    expect(service.verifyDnsCallCount, 1);
    expect(service.lastDns, '4.4.4.4');
  });

  test('ToolboxDeviceProvider changePassword enforces validations', () async {
    final provider = ToolboxDeviceProvider(service: _FakeToolboxDeviceService());

    final empty = await provider.changePassword(
      oldPassword: '',
      newPassword: '123456',
      confirmPassword: '123456',
    );
    expect(empty, isFalse);
    expect(provider.error, 'password-empty');

    final tooShort = await provider.changePassword(
      oldPassword: 'old-pass',
      newPassword: '12345',
      confirmPassword: '12345',
    );
    expect(tooShort, isFalse);
    expect(provider.error, 'password-too-short');

    final mismatch = await provider.changePassword(
      oldPassword: 'old-pass',
      newPassword: '123456',
      confirmPassword: '654321',
    );
    expect(mismatch, isFalse);
    expect(provider.error, 'password-mismatch');
  });

  test('ToolboxDeviceProvider changePassword calls service on success',
      () async {
    final service = _FakeToolboxDeviceService();
    final provider = ToolboxDeviceProvider(service: service);

    final ok = await provider.changePassword(
      oldPassword: 'old-pass',
      newPassword: 'new-pass-123',
      confirmPassword: 'new-pass-123',
    );

    expect(ok, isTrue);
    expect(service.updatePasswordCallCount, 1);
    expect(service.lastOldPassword, 'old-pass');
    expect(service.lastNewPassword, 'new-pass-123');
  });

  test('ToolboxDeviceProvider updateSwap validates empty and refreshes',
      () async {
    final service = _FakeToolboxDeviceService();
    final provider = ToolboxDeviceProvider(service: service);

    final invalid = await provider.updateSwap(' ');
    expect(invalid, isFalse);
    expect(provider.error, 'swap-empty');

    await provider.load();
    final initialLoadCount = service.loadSnapshotCallCount;

    final ok = await provider.updateSwap('4096');

    expect(ok, isTrue);
    expect(service.updateSwapCallCount, 1);
    expect(service.lastSwap, '4096');
    expect(service.loadSnapshotCallCount, initialLoadCount + 1);
  });
}
