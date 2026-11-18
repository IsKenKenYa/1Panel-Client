import 'package:flutter/material.dart';
import 'package:onepanel_client/api/v2/host_v2.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';

/// 主机运行时诊断页。
/// 对齐前端 `host/process/diagnostics`：诊断摘要、goroutine 转储、性能剖析采集。
class HostDiagnosticsPage extends StatefulWidget {
  const HostDiagnosticsPage({super.key});

  @override
  State<HostDiagnosticsPage> createState() => _HostDiagnosticsPageState();
}

class _HostDiagnosticsPageState extends State<HostDiagnosticsPage> {
  Map<String, dynamic>? _summary;
  String? _goroutines;
  bool _isLoading = true;
  bool _isCapturing = false;
  String? _error;
  String _profileType = 'cpu';
  int _profileDuration = 15;

  static const List<String> _profileTypes = <String>[
    'cpu',
    'heap',
    'goroutine',
    'mutex',
    'block',
    'trace',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final api = HostV2Api(await ApiClientManager.instance.getCurrentClient());
      final summary = await api.getDiagnosticsSummary();
      final goroutines = await api.getDiagnosticsGoroutines();
      if (mounted) {
        setState(() {
          _summary = summary.data;
          _goroutines = goroutines.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorMessageUtils.userFacingMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _captureProfile() async {
    setState(() => _isCapturing = true);
    try {
      final api = HostV2Api(await ApiClientManager.instance.getCurrentClient());
      await api.createRuntimeProfile(
        type: _profileType,
        duration: _profileDuration,
      );
      if (mounted) {
        SnackBarUtils.showSuccess(
            context, context.l10n.hostDiagnosticsCaptureDone);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
            context, ErrorMessageUtils.userFacingMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.hostDiagnosticsTitle),
        actions: [
          IconButton(tooltip: context.l10n.commonRefresh, icon: const Icon(Icons.refresh_outlined), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      TextButton(
                        onPressed: _load,
                        child: Text(l10n.commonRetry),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.hostDiagnosticsSummary,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium),
                            const SizedBox(height: 8),
                            if (_summary == null || _summary!.isEmpty)
                              Text(l10n.commonEmpty)
                            else
                              for (final entry in _summary!.entries)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('${entry.key}: ',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      Expanded(
                                        child: Text(
                                          entry.value.toString(),
                                          style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.hostDiagnosticsCaptureTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final type in _profileTypes)
                                  ChoiceChip(
                                    label: Text(type),
                                    selected: _profileType == type,
                                    onSelected: _isCapturing
                                        ? null
                                        : (_) => setState(
                                            () => _profileType = type),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(l10n.hostDiagnosticsDuration),
                                Slider(
                                  value: _profileDuration.toDouble(),
                                  min: 5,
                                  max: 60,
                                  divisions: 11,
                                  label: '$_profileDuration s',
                                  onChanged: _isCapturing
                                      ? null
                                      : (value) => setState(() =>
                                          _profileDuration = value.round()),
                                ),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _isCapturing
                                        ? null
                                        : _captureProfile,
                                    icon: _isCapturing
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : const Icon(Icons.bolt),
                                    label:
                                        Text(l10n.hostDiagnosticsCapture),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.hostDiagnosticsGoroutines,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium),
                            const SizedBox(height: 8),
                            Text(
                              _goroutines?.isEmpty == true
                                  ? l10n.commonEmpty
                                  : (_goroutines ?? ''),
                              maxLines: 12,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
