import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_read_handlers.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:onepanel_client/core/channel/native_vm_payloads.dart';
import 'package:onepanel_client/data/models/vm/vm_models.dart';
import 'package:onepanel_client/data/models/vm/vm_resource_models.dart';

void main() {
  group('vmEnvironmentPayload', () {
    test('透传环境探测各项状态与提示', () {
      final payload = vmEnvironmentPayload(
        const VMEnvironment(
          arch: 'x86_64',
          archSupported: true,
          ready: true,
          helperExist: true,
          helperMessage: 'helper ready',
          kvmExist: true,
          libvirtExist: true,
          libvirtActive: true,
          storageExist: true,
        ),
      );

      expect(payload['arch'], 'x86_64');
      expect(payload['ready'], isTrue);
      expect(payload['libvirtActive'], isTrue);
      expect(payload['helperMessage'], 'helper ready');
    });
  });

  group('vmSummaryPayload', () {
    test('关机实例给出启动能力与中性状态', () {
      final vm = VMItem.fromJson(<String, dynamic>{
        'id': 7,
        'name': 'demo',
        'status': 'shut off',
        'cpu': 2,
        'memory': 2048,
        'diskSize': 1073741824,
      });

      final payload = vmSummaryPayload(vm);
      final capabilities =
          payload['capabilities'] as Map<String, Object?>;

      expect(payload['statusKey'], 'shut off');
      expect(payload['statusTone'], 'neutral');
      expect(capabilities['canStart'], isTrue);
      expect(capabilities['canShutdown'], isFalse);
      expect(capabilities['canCreateSnapshot'], isTrue);
    });

    test('运行实例给出关机与监控能力', () {
      final vm = VMItem.fromJson(<String, dynamic>{
        'id': 8,
        'name': 'running-vm',
        'status': 'running',
        'graphics': <String, dynamic>{'type': 'vnc'},
      });

      final payload = vmSummaryPayload(vm);
      final capabilities =
          payload['capabilities'] as Map<String, Object?>;

      expect(payload['statusTone'], 'positive');
      expect(payload['graphicsType'], 'vnc');
      expect(capabilities['canStart'], isFalse);
      expect(capabilities['canShutdown'], isTrue);
      expect(capabilities['canMonitor'], isTrue);
      expect(capabilities['canOpenConsole'], isTrue);
    });

    test('创建中实例屏蔽资源级操作', () {
      final vm = VMItem.fromJson(<String, dynamic>{
        'id': 9,
        'name': 'creating-vm',
        'status': 'creating',
      });

      final capabilities =
          vmSummaryPayload(vm)['capabilities'] as Map<String, Object?>;

      expect(capabilities['canStart'], isFalse);
      expect(capabilities['canCreateSnapshot'], isFalse);
      expect(capabilities['canHealthCheck'], isFalse);
    });
  });

  group('vmDetailPayload', () {
    test('携带磁盘、网卡与图形控制台结构', () {
      final vm = VMItem.fromJson(<String, dynamic>{
        'id': 12,
        'name': 'detail-vm',
        'status': 'running',
        'uuid': 'uuid-1',
        'bootOrder': 'cdrom,hd',
        'isoPaths': <String>['/iso/a.iso'],
        'disks': <Map<String, dynamic>>[
          <String, dynamic>{
            'target': 'vda',
            'capacity': 20,
            'bus': 'virtio',
          },
        ],
        'interfaces': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'network',
            'source': 'default',
            'mac': '52:54:00:00:00:01',
            'ip': '192.168.1.10',
          },
        ],
        'graphics': <String, dynamic>{
          'type': 'vnc',
          'port': '5900',
          'listen': '127.0.0.1',
        },
      });

      final payload = vmDetailPayload(vm);
      final disks = payload['disks'] as List<Object?>;
      final interfaces = payload['interfaces'] as List<Object?>;
      final graphics = payload['graphics'] as Map<String, Object?>;

      expect(payload['uuid'], 'uuid-1');
      expect(payload['bootOrder'], 'cdrom,hd');
      expect(disks, hasLength(1));
      expect((disks.first as Map<String, Object?>)['target'], 'vda');
      expect((interfaces.first as Map<String, Object?>)['ip'], '192.168.1.10');
      expect(graphics['port'], '5900');
    });
  });

  group('vmSnapshotPayload', () {
    test('恢复能力由实例状态在 Dart 侧判定', () {
      const snapshot = VMSnapshotItem(
        name: 'snap-1',
        createdAt: 1730000000,
        current: true,
      );

      final blocked = vmSnapshotPayload(snapshot, canRecover: false);
      final allowed = vmSnapshotPayload(snapshot, canRecover: true);

      expect(blocked['canRecover'], isFalse);
      expect(allowed['canRecover'], isTrue);
      expect(allowed['current'], isTrue);
      expect(allowed['createdAtMillis'], 1730000000000);
    });
  });

  group('vmStoragePayload', () {
    test('缺少 usedPercent 时按容量与可用空间计算', () {
      final storage = VMStorageItem.fromJson(<String, dynamic>{
        'id': 3,
        'name': 'pool',
        'capacity': 1000,
        'available': 250,
      });

      expect(vmStoragePayload(storage)['usedPercent'], 75.0);
    });
  });

  group('VmStatsSampler', () {
    test('首次采样只给内存占用，完成两次采样后给出速率', () {
      final sampler = VmStatsSampler();
      final first = VMStats.fromJson(<String, dynamic>{
        'name': 'demo',
        'timestamp': 1000,
        'cpuTime': 1000,
        'vcpu': 2,
        'memory': <String, dynamic>{
          'actualKiB': 1000,
          'availableKiB': 400,
        },
        'disk': <String, dynamic>{'readBytes': 1000, 'writeBytes': 2000},
        'network': <String, dynamic>{'rxBytes': 500, 'txBytes': 700},
      });
      final second = VMStats.fromJson(<String, dynamic>{
        'name': 'demo',
        'timestamp': 1002,
        'cpuTime': 1500,
        'vcpu': 2,
        'memory': <String, dynamic>{
          'actualKiB': 1000,
          'availableKiB': 400,
        },
        'disk': <String, dynamic>{'readBytes': 4000, 'writeBytes': 3000},
        'network': <String, dynamic>{'rxBytes': 1500, 'txBytes': 900},
      });

      final firstPayload = sampler.sample(serverId: 'server-a', stats: first);
      final secondPayload = sampler.sample(serverId: 'server-a', stats: second);

      expect(firstPayload['hasDelta'], isFalse);
      expect(firstPayload['memoryPercent'], 60.0);
      expect(secondPayload['hasDelta'], isTrue);
      expect(secondPayload['cpuPercent'], 100.0);
      expect(secondPayload['diskBytesPerSecond'], 2000.0);
      expect(secondPayload['networkBytesPerSecond'], 600.0);
    });

    test('不同服务器与实例分别保存采样基线', () {
      final sampler = VmStatsSampler();
      final sample = VMStats.fromJson(<String, dynamic>{
        'name': 'demo',
        'timestamp': 1000,
        'cpuTime': 1000,
        'vcpu': 1,
      });

      final first = sampler.sample(serverId: 'server-a', stats: sample);
      final second = sampler.sample(serverId: 'server-b', stats: sample);

      expect(first['hasDelta'], isFalse);
      expect(second['hasDelta'], isFalse);
    });
  });

  group('虚拟机通道入口', () {
    test('实例详情缺少 name 时直接抛出参数错误', () async {
      expect(
        () => NativeChannelReadHandlers.getVmInfo(<String, dynamic>{}),
        throwsArgumentError,
      );
    });

    test('电源操作拒绝未知操作名且不发起请求', () async {
      final result = await NativeChannelWriteHandlers.operateVm(
        <String, dynamic>{'name': 'demo', 'operate': 'unknown'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('operate'));
    });

    test('dispatch 路由 operateVm 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'operateVm',
        <String, dynamic>{'name': 'demo', 'operate': 'unknown'},
      );

      expect(result['success'], isFalse);
    });

    test('快照创建缺少 snapshotName 时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.createVmSnapshot(
        <String, dynamic>{'name': 'demo', 'snapshotName': ' '},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('snapshotName'));
    });
  });
}