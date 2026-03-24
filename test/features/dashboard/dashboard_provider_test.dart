import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/dashboard/dashboard_provider.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/dashboard_models.dart';

void main() {
  group('DashboardProvider - 状态管理测试', () {
    test('初始状态应该为initial', () {
      final provider = DashboardProvider();
      expect(provider.status, equals(DashboardStatus.initial));
      expect(provider.errorMessage, isEmpty);
      expect(provider.activities, isEmpty);
    });

    test('初始数据应该为空', () {
      final provider = DashboardProvider();
      expect(provider.data.systemInfo, isNull);
      expect(provider.data.cpuPercent, isNull);
      expect(provider.data.memoryPercent, isNull);
      expect(provider.data.diskPercent, isNull);
    });
  });

  group('DashboardData - 数据模型测试', () {
    test('copyWith应该正确复制数据', () {
      final original = DashboardData(
        cpuPercent: 50.0,
        memoryPercent: 60.0,
        uptime: '12345',
      );
      
      final copied = original.copyWith(
        cpuPercent: 75.0,
        uptime: '67890',
      );
      
      expect(copied.cpuPercent, equals(75.0));
      expect(copied.memoryPercent, equals(60.0));
      expect(copied.uptime, equals('67890'));
    });

    test('DashboardData应该正确处理空值', () {
      const data = DashboardData();
      
      expect(data.cpuPercent, isNull);
      expect(data.memoryUsage, equals('--'));
      expect(data.diskUsage, equals('--'));
      expect(data.uptime, equals('--'));
      expect(data.topCpuProcesses, isEmpty);
      expect(data.topMemoryProcesses, isEmpty);
    });

    test('DashboardData应该正确存储进程列表', () {
      final cpuProcesses = [
        const ProcessInfo(pid: 1234, name: 'nginx', cpuPercent: 15.5, memoryPercent: 2.3),
        const ProcessInfo(pid: 5678, name: 'mysql', cpuPercent: 12.3, memoryPercent: 8.5),
      ];
      
      final data = DashboardData(
        topCpuProcesses: cpuProcesses,
      );
      
      expect(data.topCpuProcesses.length, equals(2));
      expect(data.topCpuProcesses[0].name, equals('nginx'));
      expect(data.topCpuProcesses[1].pid, equals(5678));
    });
  });

  group('ProcessInfo - 进程信息模型测试', () {
    test('应该正确从JSON创建ProcessInfo', () {
      final json = {
        'pid': 1234,
        'name': 'nginx',
        'cpuPercent': 15.5,
        'memoryPercent': 2.3,
        'user': 'root',
      };
      
      final process = ProcessInfo.fromJson(json);
      
      expect(process.pid, equals(1234));
      expect(process.name, equals('nginx'));
      expect(process.cpuPercent, equals(15.5));
      expect(process.memoryPercent, equals(2.3));
      expect(process.user, equals('root'));
    });

    test('应该正确处理cpu字段作为cpuPercent的别名', () {
      final json = {
        'pid': 100,
        'cmd': 'docker',
        'cpu': 5.0,
        'mem': 3.0,
      };
      
      final process = ProcessInfo.fromJson(json);
      
      expect(process.name, equals('docker'));
      expect(process.cpuPercent, equals(5.0));
      expect(process.memoryPercent, equals(3.0));
    });

    test('应该正确处理缺失字段', () {
      final json = <String, dynamic>{};
      
      final process = ProcessInfo.fromJson(json);
      
      expect(process.pid, equals(0));
      expect(process.name, isEmpty);
      expect(process.cpuPercent, equals(0.0));
      expect(process.memoryPercent, equals(0.0));
      expect(process.user, isNull);
    });

    test('toJson应该正确转换', () {
      const process = ProcessInfo(
        pid: 1234,
        name: 'nginx',
        cpuPercent: 15.5,
        memoryPercent: 2.3,
        user: 'root',
      );
      
      final json = process.toJson();
      
      expect(json['pid'], equals(1234));
      expect(json['name'], equals('nginx'));
      expect(json['cpuPercent'], equals(15.5));
      expect(json['memoryPercent'], equals(2.3));
      expect(json['user'], equals('root'));
    });

    test('相等性比较应该正确工作', () {
      const process1 = ProcessInfo(
        pid: 1234,
        name: 'nginx',
        cpuPercent: 15.5,
        memoryPercent: 2.3,
      );
      
      const process2 = ProcessInfo(
        pid: 1234,
        name: 'nginx',
        cpuPercent: 15.5,
        memoryPercent: 2.3,
      );
      
      const process3 = ProcessInfo(
        pid: 5678,
        name: 'mysql',
        cpuPercent: 12.3,
        memoryPercent: 8.5,
      );
      
      expect(process1, equals(process2));
      expect(process1, isNot(equals(process3)));
    });
  });

  group('DashboardMetrics - 仪表盘指标模型测试', () {
    test('应该正确从JSON创建DashboardMetrics', () {
      final json = {
        'cpuPercent': 45.5,
        'memoryPercent': 60.0,
        'diskPercent': 75.0,
        'memoryUsed': 8589934592,
        'memoryTotal': 17179869184,
        'diskUsed': 750000000000,
        'diskTotal': 1000000000000,
        'uptime': '86400',
        'cpuCores': 8,
        'hostname': 'test-server',
        'os': 'Ubuntu',
        'kernelVersion': '5.15.0',
      };
      
      final metrics = DashboardMetrics.fromJson(json);
      
      expect(metrics.cpuPercent, equals(45.5));
      expect(metrics.memoryPercent, equals(60.0));
      expect(metrics.diskPercent, equals(75.0));
      expect(metrics.memoryUsed, equals(8589934592));
      expect(metrics.memoryTotal, equals(17179869184));
      expect(metrics.uptime, equals('86400'));
      expect(metrics.cpuCores, equals(8));
      expect(metrics.hostname, equals('test-server'));
    });

    test('toJson应该正确转换', () {
      const metrics = DashboardMetrics(
        cpuPercent: 45.5,
        memoryPercent: 60.0,
        diskPercent: 75.0,
        uptime: '86400',
      );
      
      final json = metrics.toJson();
      
      expect(json['cpuPercent'], equals(45.5));
      expect(json['memoryPercent'], equals(60.0));
      expect(json['diskPercent'], equals(75.0));
      expect(json['uptime'], equals('86400'));
    });
  });

  group('DashboardActivity - 活动记录模型测试', () {
    test('应该正确创建活动对象', () {
      final activity = DashboardActivity(
        title: 'System Restart',
        description: 'System restarted successfully',
        time: DateTime(2024, 1, 1, 12, 0, 0),
        type: ActivityType.success,
      );
      
      expect(activity.title, equals('System Restart'));
      expect(activity.description, equals('System restarted successfully'));
      expect(activity.type, equals(ActivityType.success));
    });

    test('默认活动类型应该是info', () {
      final activity = DashboardActivity(
        title: 'Test',
        description: 'Test',
        time: DateTime.now(),
      );
      
      expect(activity.type, equals(ActivityType.info));
    });
  });

  group('ActivityType - 活动类型枚举测试', () {
    test('应该包含所有活动类型', () {
      expect(ActivityType.values.length, equals(4));
      expect(ActivityType.values, contains(ActivityType.success));
      expect(ActivityType.values, contains(ActivityType.warning));
      expect(ActivityType.values, contains(ActivityType.error));
      expect(ActivityType.values, contains(ActivityType.info));
    });
  });

  group('DashboardStatus - 状态枚举测试', () {
    test('应该包含所有状态', () {
      expect(DashboardStatus.values.length, equals(4));
      expect(DashboardStatus.values, contains(DashboardStatus.initial));
      expect(DashboardStatus.values, contains(DashboardStatus.loading));
      expect(DashboardStatus.values, contains(DashboardStatus.loaded));
      expect(DashboardStatus.values, contains(DashboardStatus.error));
    });
  });

  group('SystemInfo - 系统信息模型测试', () {
    test('应该正确从JSON创建SystemInfo', () {
      final json = {
        'hostname': 'test-server',
        'os': 'Ubuntu',
        'osVersion': '22.04',
        'platform': 'Linux',
        'platformVersion': '22.04 LTS',
        'kernelVersion': '5.15.0-91-generic',
        'architecture': 'x86_64',
        'cpuCores': 8,
        'cpuUsage': 45.5,
        'totalMemory': 17179869184,
        'usedMemory': 8589934592,
        'memoryUsage': 50.0,
        'totalDisk': 1000000000000,
        'usedDisk': 500000000000,
        'diskUsage': 50.0,
        'uptime': '86400',
        'panelVersion': '2.0.0',
        'appCount': 5,
        'containerCount': 10,
        'websiteCount': 3,
        'databaseCount': 2,
      };
      
      final info = SystemInfo.fromJson(json);
      
      expect(info.hostname, equals('test-server'));
      expect(info.os, equals('Ubuntu'));
      expect(info.cpuCores, equals(8));
      expect(info.cpuUsage, equals(45.5));
      expect(info.totalMemory, equals(17179869184));
      expect(info.panelVersion, equals('2.0.0'));
      expect(info.appCount, equals(5));
    });

    test('toJson应该正确转换', () {
      const info = SystemInfo(
        hostname: 'test-server',
        os: 'Ubuntu',
        cpuCores: 8,
        panelVersion: '2.0.0',
      );
      
      final json = info.toJson();
      
      expect(json['hostname'], equals('test-server'));
      expect(json['os'], equals('Ubuntu'));
      expect(json['cpuCores'], equals(8));
      expect(json['panelVersion'], equals('2.0.0'));
    });
  });

  group('边界条件测试', () {
    test('DashboardData应该处理极大值', () {
      final data = DashboardData(
        cpuPercent: 100.0,
        memoryPercent: 100.0,
        diskPercent: 100.0,
      );
      
      expect(data.cpuPercent, equals(100.0));
      expect(data.memoryPercent, equals(100.0));
      expect(data.diskPercent, equals(100.0));
    });

    test('DashboardData应该处理零值', () {
      final data = DashboardData(
        cpuPercent: 0.0,
        memoryPercent: 0.0,
        diskPercent: 0.0,
      );
      
      expect(data.cpuPercent, equals(0.0));
      expect(data.memoryPercent, equals(0.0));
      expect(data.diskPercent, equals(0.0));
    });

    test('ProcessInfo应该处理负值PID（转换为默认值）', () {
      final json = {'pid': -1, 'name': 'test'};
      final process = ProcessInfo.fromJson(json);
      
      expect(process.pid, equals(-1));
    });

    test('DashboardMetrics应该处理空字符串uptime', () {
      final json = {'uptime': ''};
      final metrics = DashboardMetrics.fromJson(json);
      
      expect(metrics.uptime, equals(''));
    });
  });
}
