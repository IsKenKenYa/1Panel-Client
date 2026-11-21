import 'package:onepanel_client/features/apps/app_service.dart';
import 'package:onepanel_client/features/dashboard/dashboard_provider.dart';
import 'package:onepanel_client/features/monitoring/monitoring_provider.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/websites/websites_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// 这些服务的 Repository 会缓存当前连接的 API 客户端。
List<SingleChildWidget> connectionServiceProviders() => [
      ListenableProxyProvider<(String?, String?), MonitoringProvider>(
        update: (context, _, __) => MonitoringProvider(
          server: context.read<CurrentServerController>().currentServer,
        ),
        dispose: (_, provider) => provider.dispose(),
      ),
      ListenableProxyProvider<(String?, String?), DashboardProvider>(
        update: (context, _, __) => DashboardProvider(
          server: context.read<CurrentServerController>().currentServer,
        ),
        dispose: (_, provider) => provider.dispose(),
      ),
      ProxyProvider<(String?, String?), AppService>(
        update: (_, __, ___) => AppService(),
      ),
      ListenableProxyProvider<(String?, String?), WebsitesProvider>(
        update: (_, __, ___) => WebsitesProvider(),
        dispose: (_, provider) => provider.dispose(),
      ),
    ];
