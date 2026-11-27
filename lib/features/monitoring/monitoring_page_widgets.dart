part of 'monitoring_page.dart';

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

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

class _ExpandableChartCard extends StatefulWidget {
  final String title;
  final MonitorTimeSeries? timeSeries;
  final String unit;
  final Widget? selector;
  final String? emptyHint;

  const _ExpandableChartCard({
    super.key,
    required this.title,
    required this.timeSeries,
    required this.unit,
    this.selector,
    this.emptyHint,
  });

  @override
  State<_ExpandableChartCard> createState() => _ExpandableChartCardState();
}

class _ExpandableChartCardState extends State<_ExpandableChartCard> {
  bool _isExpanded = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isExpanded =
        PageStorage.maybeOf(context)?.readState(context) as bool? ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final timeSeries = widget.timeSeries;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentValue = timeSeries != null && timeSeries.data.isNotEmpty
        ? '${timeSeries.data.last.value.toStringAsFixed(1)}${widget.unit}'
        : null;

    return SectionCard(
      title: widget.title,
      action: IconButton.filledTonal(
        onPressed: () {
          setState(() {
            _isExpanded = !_isExpanded;
            PageStorage.maybeOf(context)?.writeState(context, _isExpanded);
          });
        },
        icon: AnimatedRotation(
          turns: _isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
      ),
      child: Column(
        children: [
          if (currentValue != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDesignTokens.spacingMd,
                AppDesignTokens.spacingSm,
                AppDesignTokens.spacingMd,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  currentValue,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          if (widget.selector != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDesignTokens.spacingMd,
                AppDesignTokens.spacingSm,
                AppDesignTokens.spacingMd,
                0,
              ),
              child: widget.selector!,
            ),
          AnimatedSize(
            alignment: Alignment.topCenter,
            duration: const Duration(milliseconds: 200),
            child: !_isExpanded
                ? const SizedBox.shrink()
                : timeSeries == null || timeSeries.data.isEmpty
                ? _EmptyView(
                    title: l10n.commonEmpty,
                    hint: widget.emptyHint ?? l10n.monitorSeriesEmptyDesc,
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
    if (timeSeries.data.isEmpty) {
      return const SizedBox.shrink();
    }

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
          meanValue: timeSeries.avg,
          minY: timeSeries.min,
          maxY: timeSeries.max,
          unit: unit,
          label: timeSeries.name,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.title, this.hint});

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

class _GPUStatItem extends StatelessWidget {
  const _GPUStatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
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
  late bool _gpuAutoRefreshEnabled;
  late Duration _gpuRefreshInterval;
  late Duration _refreshInterval;
  late Duration _timeRange;
  late int _maxDataPoints;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MonitoringProvider>();
    _gpuAutoRefreshEnabled = provider.gpuAutoRefreshEnabled;
    _gpuRefreshInterval = provider.gpuRefreshInterval;
    _refreshInterval = provider.refreshInterval;
    _timeRange = provider.timeRange;
    _maxDataPoints = provider.maxDataPoints;
  }

  void _saveSettings() {
    final provider = context.read<MonitoringProvider>();
    if (_refreshInterval != provider.refreshInterval) {
      provider.setRefreshInterval(_refreshInterval);
    }
    if (_timeRange != provider.timeRange) {
      provider.setTimeRange(_timeRange);
    }
    if (_maxDataPoints != provider.maxDataPoints) {
      provider.setMaxDataPoints(_maxDataPoints);
    }
    if (_gpuAutoRefreshEnabled != provider.gpuAutoRefreshEnabled ||
        _gpuRefreshInterval != provider.gpuRefreshInterval) {
      provider.updateGpuRefreshPolicy(
        enabled: _gpuAutoRefreshEnabled,
        interval: _gpuRefreshInterval,
      );
    }
    SnackBarUtils.showSuccess(context, context.l10n.monitorSettingsSaved);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormPanel(
      title: l10n.monitorChartSettings,
      confirmLabel: l10n.commonSave,
      onConfirm: () async => _saveSettings(),
      content: SizedBox(
        width: AdaptiveLayoutSpec.of(context).dialogConstraints.maxWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            DropdownButtonFormField<Duration>(
              initialValue: _timeRange,
              decoration: InputDecoration(
                labelText: l10n.monitorTimeRange,
                border: const OutlineInputBorder(),
              ),
              items: [
                if (_timeRange != const Duration(hours: 1) &&
                    _timeRange != const Duration(hours: 6) &&
                    _timeRange != const Duration(hours: 24) &&
                    _timeRange != const Duration(days: 7))
                  DropdownMenuItem(
                    value: _timeRange,
                    child: Text(l10n.monitorTimeRangeCustom),
                  ),
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
            DropdownButtonFormField<int>(
              initialValue: _maxDataPoints,
              decoration: InputDecoration(
                labelText: l10n.monitorDataPoints,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 6,
                  child: Text(
                    l10n.monitorDataPointsCount(6, l10n.monitorTimeMinutes(30)),
                  ),
                ),
                DropdownMenuItem(
                  value: 12,
                  child: Text(
                    l10n.monitorDataPointsCount(12, l10n.monitorTimeHours(1)),
                  ),
                ),
                DropdownMenuItem(
                  value: 1000,
                  child: Text(
                    l10n.monitorDataPointsCount(1000, l10n.monitorAll),
                  ),
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
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.spacingSm,
      ),
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
