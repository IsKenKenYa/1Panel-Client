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
  List<Map<String, dynamic>> _gpuData = [];
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
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(hours: 1));
      final result = await _repo.searchGpu({
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': now.toUtc().toIso8601String(),
      });
      if (mounted) {
        setState(() {
          _gpuData = result;
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
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh), onPressed: _loadGpuHistory),
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
              : _gpuData.isEmpty
                  ?  Center(child: Text(context.l10n.aiGpuHistoryEmpty))
                  : ListView.builder(
                      itemCount: _gpuData.length,
                      itemBuilder: (context, index) {
                        final item = _gpuData[index];
                        return Card(
                          child: ListTile(
                            title: Text(item['name']?.toString() ?? 'GPU ${index + 1}'),
                            subtitle: Text(
                              'Utilization: ${item['utilization'] ?? 'N/A'}% | '
                              'Memory: ${item['memoryUsed'] ?? 'N/A'}/${item['memoryTotal'] ?? 'N/A'} MB | '
                              'Temp: ${item['temperature'] ?? 'N/A'}°C',
                            ),
                            trailing: Text(item['time']?.toString() ?? ''),
                          ),
                        );
                      },
                    ),
    );
  }
}
