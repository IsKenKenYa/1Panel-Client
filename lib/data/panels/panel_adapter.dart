import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/server_connection_result.dart';
import 'package:onepanel_client/data/models/server_metrics_snapshot.dart';

enum PanelAccess { read, write }

abstract interface class PanelAdapter {
  String get panelType;

  /// 表单测试使用临时会话，关闭后不影响已保存的连接。
  PanelSession open(ApiConfig config, {bool temporary = false});
}

abstract interface class PanelSession {
  /// 返回当前连接可用的能力。适配器可以向服务器查询当前账户权限。
  Future<Map<String, PanelAccess>> loadCapabilities();

  Future<ServerConnectionResult> testConnection();
  Future<ServerMetricsSnapshot> loadMetrics();
  void close();
}
