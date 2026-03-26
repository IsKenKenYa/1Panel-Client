import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/process_detail_models.dart';
import 'package:onepanel_client/features/processes/providers/process_detail_provider.dart';
import 'package:onepanel_client/features/processes/widgets/process_detail_section_card_widget.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

class ProcessDetailPage extends StatefulWidget {
  const ProcessDetailPage({
    super.key,
    required this.pid,
  });

  final int pid;

  @override
  State<ProcessDetailPage> createState() => _ProcessDetailPageState();
}

class _ProcessDetailPageState extends State<ProcessDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) return;
      context.read<ProcessDetailProvider>().load(widget.pid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<ProcessDetailProvider>(
      builder: (context, provider, _) {
        final detail = provider.detail;
        return ServerAwarePageScaffold(
          title: l10n.operationsProcessDetailTitle,
          onServerChanged: () => context.read<ProcessDetailProvider>().load(widget.pid),
          actions: <Widget>[
            IconButton(
              onPressed: provider.isLoading ? null : () => provider.load(widget.pid),
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
            ),
            IconButton(
              onPressed: provider.isStopping || detail == null ? null : _stopProcess,
              icon: const Icon(Icons.stop_circle_outlined),
              tooltip: l10n.commonStop,
            ),
          ],
          body: AsyncStatePageBodyWidget(
            isLoading: provider.isLoading,
            isEmpty: provider.isEmpty,
            errorMessage: provider.errorMessage,
            onRetry: () => provider.load(widget.pid),
            emptyTitle: l10n.processesEmptyTitle,
            emptyDescription: l10n.processDetailNoConnections,
            child: detail == null
                ? const SizedBox.shrink()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      _overviewSection(context, detail),
                      const SizedBox(height: 12),
                      _memorySection(context, detail),
                      const SizedBox(height: 12),
                      _openFilesSection(context, detail),
                      const SizedBox(height: 12),
                      _connectionsSection(context, detail),
                      const SizedBox(height: 12),
                      _environmentSection(context, detail),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _overviewSection(BuildContext context, ProcessDetail detail) {
    final l10n = context.l10n;
    return ProcessDetailSectionCardWidget(
      title: l10n.processDetailOverviewSectionTitle,
      child: Column(
        children: <Widget>[
          _detailRow('PID', detail.pid.toString()),
          _detailRow(l10n.processDetailParentPidLabel, detail.parentPid.toString()),
          _detailRow(l10n.commonName, detail.name),
          _detailRow(l10n.commonUsername, detail.username),
          _detailRow(l10n.processesConnectionsLabel, detail.numConnections.toString()),
          _detailRow(l10n.processesThreadsLabel, detail.numThreads.toString()),
          _detailRow(l10n.processesStartTimeLabel, detail.startTime),
          _detailRow(l10n.processDetailDiskReadLabel, detail.diskRead),
          _detailRow(l10n.processDetailDiskWriteLabel, detail.diskWrite),
          _detailRow(l10n.processDetailCommandLineLabel, detail.cmdLine),
        ],
      ),
    );
  }

  Widget _memorySection(BuildContext context, ProcessDetail detail) {
    final l10n = context.l10n;
    return ProcessDetailSectionCardWidget(
      title: l10n.processDetailMemorySectionTitle,
      child: Column(
        children: <Widget>[
          _detailRow('RSS', detail.rss),
          _detailRow('PSS', detail.pss),
          _detailRow('USS', detail.uss),
          _detailRow('Swap', detail.swap),
          _detailRow('Shared', detail.shared),
          _detailRow('VMS', detail.vms),
          _detailRow('HWM', detail.hwm),
          _detailRow('Data', detail.data),
          _detailRow('Stack', detail.stack),
          _detailRow('Locked', detail.locked),
          _detailRow('Text', detail.text),
          _detailRow('Dirty', detail.dirty),
        ],
      ),
    );
  }

  Widget _openFilesSection(BuildContext context, ProcessDetail detail) {
    final l10n = context.l10n;
    return ProcessDetailSectionCardWidget(
      title: l10n.processDetailOpenFilesSectionTitle,
      child: detail.openFiles.isEmpty
          ? Text(l10n.processDetailNoOpenFiles)
          : Column(
              children: detail.openFiles
                  .map((item) => _detailRow(item.fd.toString(), item.path))
                  .toList(growable: false),
            ),
    );
  }

  Widget _connectionsSection(BuildContext context, ProcessDetail detail) {
    final l10n = context.l10n;
    return ProcessDetailSectionCardWidget(
      title: l10n.processDetailConnectionsSectionTitle,
      child: detail.connections.isEmpty
          ? Text(l10n.processDetailNoConnections)
          : Column(
              children: detail.connections.map((ProcessConnection item) {
                final local = '${item.localAddress.ip}:${item.localAddress.port}';
                final remote = '${item.remoteAddress.ip}:${item.remoteAddress.port}';
                return _detailRow(local, '${item.status} · $remote');
              }).toList(growable: false),
            ),
    );
  }

  Widget _environmentSection(BuildContext context, ProcessDetail detail) {
    final l10n = context.l10n;
    return ProcessDetailSectionCardWidget(
      title: l10n.processDetailEnvironmentSectionTitle,
      child: detail.envs.isEmpty
          ? Text(l10n.processDetailNoEnvironment)
          : SelectableText(
              detail.envs.join('\n'),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 120, child: Text(label)),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }

  Future<void> _stopProcess() async {
    final provider = context.read<ProcessDetailProvider>();
    final detail = provider.detail;
    if (detail == null) return;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.commonStop,
      message: context.l10n.processesStopConfirm(detail.name),
      confirmLabel: context.l10n.commonStop,
      confirmIcon: Icons.power_settings_new_outlined,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    final shouldPop = await provider.stopProcess();
    if (shouldPop && mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
