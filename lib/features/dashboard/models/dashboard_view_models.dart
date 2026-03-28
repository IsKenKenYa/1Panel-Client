import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/dashboard_models.dart';

class NodeInfo {
  const NodeInfo({
    this.name,
    this.status,
    this.version,
    this.ip,
  });

  final String? name;
  final String? status;
  final String? version;
  final String? ip;

  factory NodeInfo.fromJson(Map<String, dynamic> json) {
    return NodeInfo(
      name: json['name'] as String?,
      status: json['status'] as String?,
      version: json['version'] as String?,
      ip: json['ip'] as String?,
    );
  }
}

class AppLauncherOption {
  const AppLauncherOption({
    required this.key,
    required this.name,
    this.icon,
  });

  final String key;
  final String name;
  final String? icon;

  factory AppLauncherOption.fromJson(Map<String, dynamic> json) {
    return AppLauncherOption(
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String?,
    );
  }
}

class AppLauncherItem {
  const AppLauncherItem({
    required this.key,
    required this.name,
    this.icon,
    this.url,
  });

  final String key;
  final String name;
  final String? icon;
  final String? url;

  factory AppLauncherItem.fromJson(Map<String, dynamic> json) {
    return AppLauncherItem(
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String?,
      url: json['url'] as String?,
    );
  }
}

class QuickJumpOption {
  const QuickJumpOption({
    required this.key,
    required this.name,
    this.icon,
    this.enabled = true,
  });

  final String key;
  final String name;
  final String? icon;
  final bool enabled;

  factory QuickJumpOption.fromJson(Map<String, dynamic> json) {
    return QuickJumpOption(
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class DashboardData {
  const DashboardData({
    this.systemInfo,
    this.metrics,
    this.nodeInfo,
    this.cpuPercent,
    this.memoryPercent,
    this.diskPercent,
    this.memoryUsage = '--',
    this.diskUsage = '--',
    this.uptime = '--',
    this.lastUpdated,
    this.topCpuProcesses = const [],
    this.topMemoryProcesses = const [],
    this.appLaunchers = const [],
    this.appLauncherOptions = const [],
    this.quickOptions = const [],
  });

  final SystemInfo? systemInfo;
  final DashboardMetrics? metrics;
  final NodeInfo? nodeInfo;
  final double? cpuPercent;
  final double? memoryPercent;
  final double? diskPercent;
  final String memoryUsage;
  final String diskUsage;
  final String uptime;
  final DateTime? lastUpdated;
  final List<ProcessInfo> topCpuProcesses;
  final List<ProcessInfo> topMemoryProcesses;
  final List<AppLauncherItem> appLaunchers;
  final List<AppLauncherOption> appLauncherOptions;
  final List<QuickJumpOption> quickOptions;

  DashboardData copyWith({
    SystemInfo? systemInfo,
    DashboardMetrics? metrics,
    NodeInfo? nodeInfo,
    double? cpuPercent,
    double? memoryPercent,
    double? diskPercent,
    String? memoryUsage,
    String? diskUsage,
    String? uptime,
    DateTime? lastUpdated,
    List<ProcessInfo>? topCpuProcesses,
    List<ProcessInfo>? topMemoryProcesses,
    List<AppLauncherItem>? appLaunchers,
    List<AppLauncherOption>? appLauncherOptions,
    List<QuickJumpOption>? quickOptions,
  }) {
    return DashboardData(
      systemInfo: systemInfo ?? this.systemInfo,
      metrics: metrics ?? this.metrics,
      nodeInfo: nodeInfo ?? this.nodeInfo,
      cpuPercent: cpuPercent ?? this.cpuPercent,
      memoryPercent: memoryPercent ?? this.memoryPercent,
      diskPercent: diskPercent ?? this.diskPercent,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      diskUsage: diskUsage ?? this.diskUsage,
      uptime: uptime ?? this.uptime,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      topCpuProcesses: topCpuProcesses ?? this.topCpuProcesses,
      topMemoryProcesses: topMemoryProcesses ?? this.topMemoryProcesses,
      appLaunchers: appLaunchers ?? this.appLaunchers,
      appLauncherOptions: appLauncherOptions ?? this.appLauncherOptions,
      quickOptions: quickOptions ?? this.quickOptions,
    );
  }
}

enum ActivityType { success, warning, error, info }

class DashboardActivity {
  const DashboardActivity({
    required this.title,
    required this.description,
    required this.time,
    this.type = ActivityType.info,
  });

  final String title;
  final String description;
  final DateTime time;
  final ActivityType type;
}
