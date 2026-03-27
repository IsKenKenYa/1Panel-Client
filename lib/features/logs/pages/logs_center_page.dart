import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/logs/providers/logs_provider.dart';
import 'package:onepanel_client/features/logs/providers/system_logs_provider.dart';
import 'package:onepanel_client/features/logs/providers/task_logs_provider.dart';
import 'package:onepanel_client/features/logs/widgets/logs_login_tab_widget.dart';
import 'package:onepanel_client/features/logs/widgets/logs_operation_tab_widget.dart';
import 'package:onepanel_client/features/logs/widgets/logs_system_tab_widget.dart';
import 'package:onepanel_client/features/logs/widgets/logs_task_tab_widget.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:provider/provider.dart';

class LogsCenterPage extends StatefulWidget {
  const LogsCenterPage({super.key});

  @override
  State<LogsCenterPage> createState() => _LogsCenterPageState();
}

class _LogsCenterPageState extends State<LogsCenterPage> {
  late final TextEditingController _operationController;
  late final TextEditingController _sourceController;
  late final TextEditingController _loginIpController;
  late final TextEditingController _taskTypeController;

  @override
  void initState() {
    super.initState();
    _operationController = TextEditingController();
    _sourceController = TextEditingController();
    _loginIpController = TextEditingController();
    _taskTypeController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      _loadAll();
    });
  }

  @override
  void dispose() {
    _operationController.dispose();
    _sourceController.dispose();
    _loginIpController.dispose();
    _taskTypeController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() {
    return Future.wait<void>(<Future<void>>[
      context.read<LogsProvider>().loadAll(),
      context.read<TaskLogsProvider>().load(),
      context.read<SystemLogsProvider>().loadFiles(),
    ]);
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.commonCopySuccess)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 4,
      child: ServerAwarePageScaffold(
        title: l10n.operationsLogsTitle,
        onServerChanged: _loadAll,
        body: Column(
          children: <Widget>[
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                isScrollable: true,
                tabs: <Tab>[
                  Tab(text: l10n.logsCenterTabOperation),
                  Tab(text: l10n.logsCenterTabLogin),
                  Tab(text: l10n.logsCenterTabTask),
                  Tab(text: l10n.logsCenterTabSystem),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  Consumer<LogsProvider>(
                    builder: (context, provider, _) => LogsOperationTabWidget(
                      provider: provider,
                      operationController: _operationController,
                      sourceController: _sourceController,
                      onCopy: _copyText,
                    ),
                  ),
                  Consumer<LogsProvider>(
                    builder: (context, provider, _) => LogsLoginTabWidget(
                      provider: provider,
                      ipController: _loginIpController,
                      onCopy: _copyText,
                    ),
                  ),
                  Consumer<TaskLogsProvider>(
                    builder: (context, provider, _) => LogsTaskTabWidget(
                      provider: provider,
                      typeController: _taskTypeController,
                      onCopy: _copyText,
                    ),
                  ),
                  Consumer<SystemLogsProvider>(
                    builder: (context, provider, _) =>
                        LogsSystemTabWidget(provider: provider),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
