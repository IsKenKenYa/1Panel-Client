import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/server_metrics_snapshot.dart';

export 'package:onepanel_client/data/models/server_metrics_snapshot.dart';

class ServerCardViewModel {
  const ServerCardViewModel({
    required this.config,
    required this.isCurrent,
    required this.metrics,
  });

  final ApiConfig config;
  final bool isCurrent;
  final ServerMetricsSnapshot metrics;

  ServerCardViewModel copyWith(
          {bool? isCurrent, ServerMetricsSnapshot? metrics}) =>
      ServerCardViewModel(
        config: config,
        isCurrent: isCurrent ?? this.isCurrent,
        metrics: metrics ?? this.metrics,
      );
}
