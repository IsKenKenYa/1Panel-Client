import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/ai/ai_provider.dart';
import 'package:provider/provider.dart';

class AIGpuTabWidget extends StatefulWidget {
  const AIGpuTabWidget({super.key});

  @override
  State<AIGpuTabWidget> createState() => _AIGpuTabWidgetState();
}

class _AIGpuTabWidgetState extends State<AIGpuTabWidget> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AIProvider>().loadGpuInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer<AIProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          onRefresh: provider.loadGpuInfo,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: provider.isLoading ? null : provider.loadGpuInfo,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.commonRefresh),
                ),
              ),
              const SizedBox(height: 12),
              if (provider.gpuInfoList.isEmpty && !provider.isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Text(l10n.aiNoGpuData),
                  ),
                )
              else
                ...provider.gpuInfoList.map((gpu) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ExpansionTile(
                      title: Text(
                        'GPU ${gpu.index ?? '-'}  ${gpu.productName ?? ''}'
                            .trim(),
                      ),
                      subtitle: Text(
                        '${l10n.monitorGPUTemperature}: ${gpu.temperature ?? '-'}',
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _MetricLine(
                                label: l10n.monitorGPUUtilization,
                                value: gpu.gpuUtil,
                              ),
                              _MetricLine(
                                label: l10n.monitorGPUMemory,
                                value:
                                    '${gpu.memUsed ?? '-'} / ${gpu.memTotal ?? '-'}',
                              ),
                              _MetricLine(
                                label: l10n.monitorGPUTemperature,
                                value: gpu.temperature,
                              ),
                              _MetricLine(
                                label: l10n.aiFanSpeed,
                                value: gpu.fanSpeed,
                              ),
                              _MetricLine(
                                label: l10n.aiPowerUsage,
                                value:
                                    '${gpu.powerDraw ?? '-'} / ${gpu.maxPowerLimit ?? '-'}',
                              ),
                              _MetricLine(
                                label: l10n.aiPerformanceState,
                                value: gpu.performanceState,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
