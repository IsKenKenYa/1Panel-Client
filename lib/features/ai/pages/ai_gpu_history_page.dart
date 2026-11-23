import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/ai/ai_repository.dart';

/// AI GPU monitor history page.
/// Mirrors frontend's gpu/history page: shows GPU utilization time-series chart.
class AiGpuHistoryPage extends StatefulWidget {
  const AiGpuHistoryPage({super.key});

  @override
  State<AiGpuHistoryPage> createState() => _AiGpuHistoryPageState();
}

class _AiGpuHistoryPageState extends State<AiGpuHistoryPage> {
  final AIRepository _repo = AIRepository();
  Map<String, dynamic> _gpuData = const <String, dynamic>{};
  String _deviceLabel = '';
  int _sampleCount = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGpuHistory();
  }

  Future<void> _loadGpuHistory() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // 服务端要求 history 查询必须带设备，先取设备再查序列；
      // 没有 GPU 时直接显示空态，不发起必然失败的请求。
      final options = await _repo.getGpuOptions();
      final device = AIRepository.firstGpuDevice(options);
      if (device == null) {
        if (mounted) {
          setState(() {
            _gpuData = const <String, dynamic>{};
            _deviceLabel = '';
            _sampleCount = 0;
            _isLoading = false;
          });
        }
        return;
      }
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 1));
      final result = await _repo.searchGpu(<String, dynamic>{
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': now.toUtc().toIso8601String(),
        'deviceID': device.deviceId,
        'productName': device.productName,
        'legacy': device.legacy,
      });
      if (mounted) {
        setState(() {
          _gpuData = result;
          _deviceLabel = device.productName.isNotEmpty
              ? device.productName
              : device.deviceId;
          _sampleCount = (result['sampleCount'] as num?)?.toInt() ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title:  Text(context.l10n.aiGpuHistoryTitle),
        actions: [
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh_outlined), onPressed: _loadGpuHistory),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadGpuHistory,
                        child:  Text(context.l10n.commonRetry),
                      ),
                    ],
                  ),
                )
              : _gpuData.isEmpty || _sampleCount == 0
                  ?  Center(child: Text(context.l10n.aiGpuHistoryEmpty))
                  : _seriesList(context),
    );
  }

  /// 把 `{memoryActivity, computeUtil, ...}` 序列逐项列出最后采样值。
  Widget _seriesList(BuildContext context) {
    final entries = <MapEntry<String, dynamic>>[
      for (final entry in _gpuData.entries)
        if (entry.value is List && (entry.value as List).isNotEmpty) entry,
    ];
    if (entries.isEmpty) {
      return Center(child: Text(context.l10n.aiGpuHistoryEmpty));
    }
    return ListView.separated(
      itemCount: entries.length + 1,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return ListTile(
            title: Text(_deviceLabel),
            subtitle: Text('$_sampleCount samples'),
            dense: true,
          );
        }
        final entry = entries[index - 1];
        final list = entry.value as List;
        final latest = list.last;
        return ListTile(
          title: Text(_seriesLabel(entry.key)),
          trailing: Text(
            latest == null ? '--' : '$latest',
            style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
          ),
          dense: true,
        );
      },
    );
  }

  String _seriesLabel(String key) {
    switch (key) {
      case 'memoryActivity':
        return 'Memory activity';
      case 'computeUtil':
        return 'Compute util';
      case 'encoderUtil':
        return 'Encoder util';
      case 'decoderUtil':
        return 'Decoder util';
      case 'jpegUtil':
        return 'JPEG util';
      case 'hotspotTemperature':
        return 'Hotspot temperature';
      case 'fanRPM':
        return 'Fan RPM';
      case 'hbmUsed':
        return 'HBM used';
      case 'hbmTotal':
        return 'HBM total';
      default:
        return key;
    }
  }
}
