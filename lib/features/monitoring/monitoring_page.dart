import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';
import 'package:provider/provider.dart';
import '../../api/v2/monitor_v2.dart';
import '../../data/repositories/monitor_repository.dart';
import 'monitoring_provider.dart';
import 'widgets/monitor_chart.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MonitoringProvider>();
      provider.load();
      provider.loadGPUInfo();
      // 默认启用自动刷新
      provider.toggleAutoRefresh(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.serverModuleMonitoring),
        actions: [
          Consumer<MonitoringProvider>(
            builder: (context, provider, _) => IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: provider.data.isLoading ? null : provider.refresh,
              tooltip: l10n.commonRefresh,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: l10n.monitorSettings,
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: AppDesignTokens.pagePadding,
        child: Consumer<MonitoringProvider>(
          builder: (context, provider, _) {
            return _buildBody(context, provider.data, provider.refresh);
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    MonitoringData data,
    Future<void> Function() onRefresh,
  ) {
    final l10n = context.l10n;
    final hasData = data.currentMetrics != null ||
        data.cpuTimeSeries != null ||
        data.memoryTimeSeries != null;

    if (data.error != null && !hasData) {
      return _ErrorView(
        title: l10n.commonLoadFailedTitle,
        error: data.error!,
        onRetry: onRefresh,
      );
    }

    if (data.isLoading && !hasData) {
      return const _LoadingView();
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: [
          _buildCurrentMetrics(context, data.currentMetrics),
          const SizedBox(height: AppDesignTokens.spacingMd),
          _buildTimeSeriesCard(
            context,
            l10n.serverCpuLabel,
            data.cpuTimeSeries,
            '%',
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          _buildTimeSeriesCard(
            context,
            l10n.serverMemoryLabel,
            data.memoryTimeSeries,
            '%',
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          _buildTimeSeriesCard(
            context,
            l10n.serverLoadLabel,
            data.loadTimeSeries,
            '',
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          _buildTimeSeriesCard(
            context,
            '${l10n.serverDiskLabel} IO',
            data.ioTimeSeries,
            'KB/s',
            selector: _MetricSelector(
              value: data.selectedIO,
              options: data.ioOptions,
              onChanged: (value) =>
                  context.read<MonitoringProvider>().selectIOOption(value),
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          _buildTimeSeriesCard(
            context,
            l10n.monitorNetworkLabel,
            data.networkTimeSeries,
            'KB/s',
            selector: _MetricSelector(
              value: data.selectedNetwork,
              options: data.networkOptions,
              onChanged: (value) =>
                  context.read<MonitoringProvider>().selectNetworkOption(value),
            ),
          ),
          // GPU监控卡片（如果有GPU）
          if (data.gpuInfo.isNotEmpty) ...[
            const SizedBox(height: AppDesignTokens.spacingSm),
            _buildGPUCard(context, data.gpuInfo),
          ],
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _MonitorSettingsDialog(),
    );
  }

  Widget _buildGPUCard(BuildContext context, List<GPUInfo> gpuInfo) {
    final l10n = context.l10n;

    return AppCard(
      title: l10n.monitorGPU,
      child: Column(
        children: gpuInfo.map((gpu) => _buildGPUItem(context, gpu)).toList(),
      ),
    );
  }

  Widget _buildGPUItem(BuildContext context, GPUInfo gpu) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesignTokens.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gpu.name ?? 'GPU',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppDesignTokens.spacingXs),
          Row(
            children: [
              Expanded(
                child: _GPUStatItem(
                  label: l10n.monitorGPUUtilization,
                  value: gpu.utilization != null
                      ? '${gpu.utilization!.toStringAsFixed(1)}%'
                      : '--',
                ),
              ),
              Expanded(
                child: _GPUStatItem(
                  label: l10n.monitorGPUMemory,
                  value: gpu.memory != null
                      ? '${gpu.memory!.toStringAsFixed(1)}%'
                      : '--',
                ),
              ),
              Expanded(
                child: _GPUStatItem(
                  label: l10n.monitorGPUTemperature,
                  value: gpu.temperature != null
                      ? '${gpu.temperature!.toStringAsFixed(0)}°C'
                      : '--',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMetrics(
      BuildContext context, MonitorMetricsSnapshot? metrics) {
    final l10n = context.l10n;
    if (metrics == null) return const SizedBox.shrink();

    return AppCard(
      title: l10n.monitorMetricCurrent,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: AppDesignTokens.spacingSm,
        crossAxisSpacing: AppDesignTokens.spacingSm,
        childAspectRatio: 3.5,
        children: [
          _MetricChip(
            label: l10n.serverCpuLabel,
            value: metrics.cpuPercent != null
                ? '${metrics.cpuPercent!.toStringAsFixed(1)}%'
                : '--',
            icon: Icons.memory_outlined,
          ),
          _MetricChip(
            label: l10n.serverMemoryLabel,
            value: metrics.memoryPercent != null
                ? '${metrics.memoryPercent!.toStringAsFixed(1)}%'
                : '--',
            icon: Icons.storage_outlined,
          ),
          _MetricChip(
            label: l10n.serverDiskLabel,
            value: metrics.diskPercent != null
                ? '${metrics.diskPercent!.toStringAsFixed(1)}%'
                : '--',
            icon: Icons.folder_outlined,
          ),
          _MetricChip(
            label: l10n.serverLoadLabel,
            value: metrics.load1 != null
                ? metrics.load1!.toStringAsFixed(2)
                : '--',
            icon: Icons.speed_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSeriesCard(BuildContext context, String title,
      MonitorTimeSeries? timeSeries, String unit,
      {Widget? selector}) {
    return _ExpandableChartCard(
      title: title,
      timeSeries: timeSeries,
      unit: unit,
      selector: selector,
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$label: $value'),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.spacingSm,
        vertical: AppDesignTokens.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingXs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppDesignTokens.spacingMd),
          Text(l10n.commonLoading),
        ],
      ),
    );
  }
}

class _ExpandableChartCard extends StatefulWidget {
  final String title;
  final MonitorTimeSeries? timeSeries;
  final String unit;
  final Widget? selector;

  const _ExpandableChartCard({
    required this.title,
    required this.timeSeries,
    required this.unit,
    this.selector,
  });

  @override
  State<_ExpandableChartCard> createState() => _ExpandableChartCardState();
}

class _ExpandableChartCardState extends State<_ExpandableChartCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final timeSeries = widget.timeSeries;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentValue = timeSeries != null && timeSeries.data.isNotEmpty
        ? '${timeSeries.data.last.value.toStringAsFixed(1)}${widget.unit}'
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDesignTokens.spacingMd,
              AppDesignTokens.spacingMd,
              AppDesignTokens.spacingMd,
              AppDesignTokens.spacingSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppDesignTokens.spacingXs),
                          Text(
                            currentValue ?? l10n.commonEmpty,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: currentValue != null
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      icon: AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                    ),
                  ],
                ),
                if (widget.selector != null) ...[
                  const SizedBox(height: AppDesignTokens.spacingSm),
                  widget.selector!,
                ],
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: timeSeries == null || timeSeries.data.isEmpty
                ? _EmptyView(
                    title: l10n.commonEmpty,
                    hint: widget.title.contains('IO')
                        ? '请在设置中配置磁盘IO设备（如 /dev/vda2）'
                        : widget.title.contains('网络')
                            ? '请在设置中配置网络接口（如 eth0）'
                            : null,
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDesignTokens.spacingMd,
                      AppDesignTokens.spacingSm,
                      AppDesignTokens.spacingMd,
                      AppDesignTokens.spacingMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsRow(context, timeSeries, widget.unit),
                        const SizedBox(height: AppDesignTokens.spacingMd),
                        _buildSimpleChart(context, timeSeries, widget.unit),
                      ],
                    ),
                  ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    MonitorTimeSeries timeSeries,
    String unit,
  ) {
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: _StatItem(
            label: l10n.monitorMetricMin,
            value: timeSeries.min != null
                ? '${timeSeries.min!.toStringAsFixed(1)}$unit'
                : '--',
          ),
        ),
        const SizedBox(width: AppDesignTokens.spacingSm),
        Expanded(
          child: _StatItem(
            label: l10n.monitorMetricAvg,
            value: timeSeries.avg != null
                ? '${timeSeries.avg!.toStringAsFixed(1)}$unit'
                : '--',
          ),
        ),
        const SizedBox(width: AppDesignTokens.spacingSm),
        Expanded(
          child: _StatItem(
            label: l10n.monitorMetricMax,
            value: timeSeries.max != null
                ? '${timeSeries.max!.toStringAsFixed(1)}$unit'
                : '--',
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleChart(
    BuildContext context,
    MonitorTimeSeries timeSeries,
    String unit,
  ) {
    if (timeSeries.data.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDesignTokens.spacingSm,
        AppDesignTokens.spacingSm,
        AppDesignTokens.spacingSm,
        AppDesignTokens.spacingXs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
      ),
      child: SizedBox(
        height: 220,
        child: MonitorChart(
          data: timeSeries.data,
          unit: unit,
          label: timeSeries.name,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.title,
    this.hint,
  });

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spacingMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            if (hint != null) ...[
              const SizedBox(height: AppDesignTokens.spacingSm),
              Text(
                hint!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.title,
    required this.error,
    required this.onRetry,
  });

  final String title;
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: AppDesignTokens.spacingMd),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDesignTokens.spacingSm),
            Text(
              error,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignTokens.spacingLg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _GPUStatItem extends StatelessWidget {
  const _GPUStatItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _MonitorSettingsDialog extends StatefulWidget {
  const _MonitorSettingsDialog();

  @override
  State<_MonitorSettingsDialog> createState() => _MonitorSettingsDialogState();
}

class _MonitorSettingsDialogState extends State<_MonitorSettingsDialog> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _enabled = true;
  int _retention = 30;
  bool _gpuAutoRefreshEnabled = true;
  Duration _gpuRefreshInterval = const Duration(seconds: 30);
  Duration _refreshInterval = const Duration(seconds: 5);
  Duration _timeRange = const Duration(hours: 1);
  int _maxDataPoints = 1000;
  String _defaultIO = 'all';
  String _defaultNetwork = 'all';
  List<String> _ioOptions = const ['all'];
  List<String> _networkOptions = const ['all'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final provider = context.read<MonitoringProvider>();
    await provider.loadSettings();
    final settings = provider.data.settings;
    if (mounted) {
      setState(() {
        _enabled = settings?.enabled ?? true;
        _retention = settings?.retention ?? 30;
        _gpuAutoRefreshEnabled = provider.gpuAutoRefreshEnabled;
        _gpuRefreshInterval = provider.gpuRefreshInterval;
        _refreshInterval = provider.refreshInterval;
        _timeRange = provider.timeRange;
        _maxDataPoints = provider.maxDataPoints;
        _defaultIO = settings?.defaultIO ?? 'all';
        _defaultNetwork = settings?.defaultNetwork ?? 'all';
        _ioOptions = provider.data.ioOptions;
        _networkOptions = provider.data.networkOptions;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    final provider = context.read<MonitoringProvider>();

    // 应用所有设置
    provider.setRefreshInterval(_refreshInterval);
    provider.setTimeRange(_timeRange);
    provider.setMaxDataPoints(_maxDataPoints);
    provider.updateGpuRefreshPolicy(
      enabled: _gpuAutoRefreshEnabled,
      interval: _gpuRefreshInterval,
    );

    final success = await provider.updateSettings(
      enabled: _enabled,
      retention: _retention,
      defaultIO: _defaultIO,
      defaultNetwork: _defaultNetwork,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.monitorSettingsSaved)),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.monitorSettingsFailed)),
        );
      }
    }
  }

  Future<void> _cleanData() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.monitorCleanData),
        content: Text(l10n.monitorCleanConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<MonitoringProvider>();
      final success = await provider.cleanData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success ? l10n.monitorCleanSuccess : l10n.monitorCleanFailed),
          ),
        );
        // 清理后重新加载数据
        if (success) {
          provider.load();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.monitorSettings),
      content: _isLoading
          ? const SizedBox(
              width: 300,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.monitorEnable,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SwitchListTile(
                      title: Text(l10n.monitorEnable),
                      value: _enabled,
                      onChanged: (value) {
                        setState(() {
                          _enabled = value;
                        });
                      },
                    ),
                    const Divider(),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    Text(
                      l10n.monitorRefreshInterval,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    DropdownButtonFormField<Duration>(
                      initialValue: _refreshInterval,
                      decoration: InputDecoration(
                        labelText: l10n.monitorRefreshInterval,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: const Duration(seconds: 3),
                          child: Text(l10n.monitorSeconds(3)),
                        ),
                        DropdownMenuItem(
                          value: const Duration(seconds: 5),
                          child: Text(l10n.monitorSecondsDefault(5)),
                        ),
                        DropdownMenuItem(
                          value: const Duration(seconds: 10),
                          child: Text(l10n.monitorSeconds(10)),
                        ),
                        DropdownMenuItem(
                          value: const Duration(seconds: 30),
                          child: Text(l10n.monitorSeconds(30)),
                        ),
                        DropdownMenuItem(
                          value: const Duration(minutes: 1),
                          child: Text(l10n.monitorMinute(1)),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _refreshInterval = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppDesignTokens.spacingMd),
                    const Divider(),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    Text(
                      l10n.monitorTimeRange,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    DropdownButtonFormField<Duration>(
                      initialValue: _timeRange,
                      decoration: InputDecoration(
                        labelText: l10n.monitorTimeRange,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: const Duration(hours: 1),
                          child: Text(l10n.monitorTimeRangeLast1h),
                        ),
                        DropdownMenuItem(
                          value: const Duration(hours: 6),
                          child: Text(l10n.monitorTimeRangeLast6h),
                        ),
                        DropdownMenuItem(
                          value: const Duration(hours: 24),
                          child: Text(l10n.monitorTimeRangeLast24h),
                        ),
                        DropdownMenuItem(
                          value: const Duration(days: 7),
                          child: Text(l10n.monitorTimeRangeLast7d),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _timeRange = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppDesignTokens.spacingMd),
                    const Divider(),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    Text(
                      l10n.monitorDataPoints,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    DropdownButtonFormField<int>(
                      initialValue: _maxDataPoints,
                      decoration: InputDecoration(
                        labelText: l10n.monitorDataPoints,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 6,
                          child: Text(l10n.monitorDataPointsCount(
                              6, l10n.monitorTimeMinutes(30))),
                        ),
                        DropdownMenuItem(
                          value: 12,
                          child: Text(l10n.monitorDataPointsCount(
                              12, l10n.monitorTimeHours(1))),
                        ),
                        DropdownMenuItem(
                          value: 1000,
                          child: Text(l10n.monitorDataPointsCount(1000, '全部')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _maxDataPoints = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppDesignTokens.spacingMd),
                    const Divider(),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    Text(
                      '${l10n.monitorGPU} ${l10n.monitorSettings}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SwitchListTile(
                      title: Text('${l10n.monitorGPU} ${l10n.monitorEnable}'),
                      value: _gpuAutoRefreshEnabled,
                      onChanged: (value) {
                        setState(() {
                          _gpuAutoRefreshEnabled = value;
                        });
                      },
                    ),
                    if (_gpuAutoRefreshEnabled) ...[
                      const SizedBox(height: AppDesignTokens.spacingSm),
                      DropdownButtonFormField<Duration>(
                        initialValue: _gpuRefreshInterval,
                        decoration: InputDecoration(
                          labelText:
                              '${l10n.monitorGPU} ${l10n.monitorRefreshInterval}',
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: const Duration(seconds: 5),
                            child: Text(l10n.monitorSeconds(5)),
                          ),
                          DropdownMenuItem(
                            value: const Duration(seconds: 10),
                            child: Text(l10n.monitorSeconds(10)),
                          ),
                          DropdownMenuItem(
                            value: const Duration(seconds: 30),
                            child: Text(l10n.monitorSeconds(30)),
                          ),
                          DropdownMenuItem(
                            value: const Duration(minutes: 1),
                            child: Text(l10n.monitorMinute(1)),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _gpuRefreshInterval = value;
                            });
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: AppDesignTokens.spacingMd),
                    const Divider(),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    Text(
                      l10n.monitorRetention,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    Slider(
                      value: _retention.toDouble(),
                      min: 1,
                      max: 365,
                      divisions: 364,
                      label: '$_retention ${l10n.monitorRetentionUnit}',
                      onChanged: (value) {
                        setState(() {
                          _retention = value.round();
                        });
                      },
                    ),
                    Text('$_retention ${l10n.monitorRetentionUnit}'),
                    const SizedBox(height: AppDesignTokens.spacingLg),
                    const Divider(),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    Text(
                      '${l10n.serverDiskLabel} IO ${l10n.monitorSettings}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    DropdownButtonFormField<String>(
                      initialValue: _ioOptions.contains(_defaultIO)
                          ? _defaultIO
                          : _ioOptions.first,
                      decoration: InputDecoration(
                        labelText: '${l10n.serverDiskLabel} IO 设备',
                        helperText: '优先使用具体设备，避免 all 返回空数据',
                        border: const OutlineInputBorder(),
                      ),
                      items: _ioOptions
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _defaultIO = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppDesignTokens.spacingMd),
                    const Divider(),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    Text(
                      '${l10n.monitorNetworkLabel} ${l10n.monitorSettings}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                    DropdownButtonFormField<String>(
                      initialValue: _networkOptions.contains(_defaultNetwork)
                          ? _defaultNetwork
                          : _networkOptions.first,
                      decoration: InputDecoration(
                        labelText: '${l10n.monitorNetworkLabel} 接口',
                        helperText: '优先使用具体网卡，避免 all 返回空数据',
                        border: const OutlineInputBorder(),
                      ),
                      items: _networkOptions
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _defaultNetwork = value;
                        });
                      },
                    ),
                    const SizedBox(height: AppDesignTokens.spacingLg),
                    OutlinedButton.icon(
                      onPressed: _cleanData,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.monitorCleanData),
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveSettings,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.commonSave),
        ),
      ],
    );
  }
}

class _MetricSelector extends StatelessWidget {
  const _MetricSelector({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final items = options.isEmpty ? const ['all'] : options;
    final currentValue = items.contains(value) ? value : items.first;

    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding:
          const EdgeInsets.symmetric(horizontal: AppDesignTokens.spacingSm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          icon: const Icon(Icons.arrow_drop_down_rounded),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (next) {
            if (next != null) {
              onChanged(next);
            }
          },
        ),
      ),
    );
  }
}
