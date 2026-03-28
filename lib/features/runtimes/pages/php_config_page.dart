import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_manage_args.dart';
import 'package:onepanel_client/features/runtimes/providers/php_config_provider.dart';
import 'package:onepanel_client/features/runtimes/utils/runtime_l10n_helper.dart';
import 'package:onepanel_client/features/runtimes/widgets/php_config/php_basic_config_section_widget.dart';
import 'package:onepanel_client/features/runtimes/widgets/php_config/php_container_section_widget.dart';
import 'package:onepanel_client/features/runtimes/widgets/php_config/php_file_editor_section_widget.dart';
import 'package:onepanel_client/features/runtimes/widgets/php_config/php_fpm_section_widget.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:provider/provider.dart';

class PhpConfigPage extends StatefulWidget {
  const PhpConfigPage({
    super.key,
    required this.args,
  });

  final RuntimeManageArgs args;

  @override
  State<PhpConfigPage> createState() => _PhpConfigPageState();
}

class _PhpConfigPageState extends State<PhpConfigPage> {
  late final TextEditingController _uploadMaxSizeController;
  late final TextEditingController _maxExecutionTimeController;
  late final TextEditingController _disableFunctionsController;
  late final TextEditingController _fpmModeController;
  late final TextEditingController _fpmMaxChildrenController;
  late final TextEditingController _fpmStartServersController;
  late final TextEditingController _fpmMinSpareServersController;
  late final TextEditingController _fpmMaxSpareServersController;
  late final TextEditingController _phpFileContentController;
  late final TextEditingController _fpmFileContentController;

  @override
  void initState() {
    super.initState();
    _uploadMaxSizeController = TextEditingController();
    _maxExecutionTimeController = TextEditingController();
    _disableFunctionsController = TextEditingController();
    _fpmModeController = TextEditingController();
    _fpmMaxChildrenController = TextEditingController();
    _fpmStartServersController = TextEditingController();
    _fpmMinSpareServersController = TextEditingController();
    _fpmMaxSpareServersController = TextEditingController();
    _phpFileContentController = TextEditingController();
    _fpmFileContentController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<PhpConfigProvider>().initialize(widget.args);
    });
  }

  @override
  void dispose() {
    _uploadMaxSizeController.dispose();
    _maxExecutionTimeController.dispose();
    _disableFunctionsController.dispose();
    _fpmModeController.dispose();
    _fpmMaxChildrenController.dispose();
    _fpmStartServersController.dispose();
    _fpmMinSpareServersController.dispose();
    _fpmMaxSpareServersController.dispose();
    _phpFileContentController.dispose();
    _fpmFileContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<PhpConfigProvider>(
      builder: (context, provider, _) {
        _syncController(_uploadMaxSizeController, provider.uploadMaxSize);
        _syncController(_maxExecutionTimeController, provider.maxExecutionTime);
        _syncController(_disableFunctionsController, provider.disableFunctions);
        _syncController(
            _fpmModeController, provider.fpmConfig.params['pm'] ?? '');
        _syncController(
          _fpmMaxChildrenController,
          provider.fpmConfig.params['pm.max_children'] ?? '',
        );
        _syncController(
          _fpmStartServersController,
          provider.fpmConfig.params['pm.start_servers'] ?? '',
        );
        _syncController(
          _fpmMinSpareServersController,
          provider.fpmConfig.params['pm.min_spare_servers'] ?? '',
        );
        _syncController(
          _fpmMaxSpareServersController,
          provider.fpmConfig.params['pm.max_spare_servers'] ?? '',
        );
        _syncController(_phpFileContentController, provider.phpFileContent);
        _syncController(_fpmFileContentController, provider.fpmFileContent);
        final title = provider.runtimeName.trim().isEmpty
            ? l10n.operationsPhpConfigTitle
            : '${provider.runtimeName} · ${l10n.operationsPhpConfigTitle}';
        return ServerAwarePageScaffold(
          title: title,
          onServerChanged: () =>
              context.read<PhpConfigProvider>().initialize(widget.args),
          actions: <Widget>[
            IconButton(
              onPressed: provider.isLoading ? null : provider.load,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
            ),
          ],
          body: AsyncStatePageBodyWidget(
            isLoading: provider.isLoading,
            errorMessage: localizeRuntimeError(l10n, provider.errorMessage),
            onRetry: provider.load,
            child: DefaultTabController(
              length: 5,
              child: Column(
                children: <Widget>[
                  TabBar(
                    isScrollable: true,
                    tabs: <Tab>[
                      Tab(text: l10n.runtimePhpTabBasic),
                      Tab(text: l10n.runtimePhpTabFpm),
                      Tab(text: l10n.runtimePhpTabContainer),
                      Tab(text: l10n.runtimePhpTabPhpFile),
                      Tab(text: l10n.runtimePhpTabFpmFile),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: <Widget>[
                        PhpBasicConfigSectionWidget(
                          uploadMaxSizeController: _uploadMaxSizeController,
                          maxExecutionTimeController:
                              _maxExecutionTimeController,
                          disableFunctionsController:
                              _disableFunctionsController,
                          onUploadMaxSizeChanged: provider.updateUploadMaxSize,
                          onMaxExecutionTimeChanged:
                              provider.updateMaxExecutionTime,
                          onDisableFunctionsChanged:
                              provider.updateDisableFunctions,
                          onSave: _saveBasic,
                          isSaving: provider.isSaving,
                        ),
                        PhpFpmSectionWidget(
                          modeController: _fpmModeController,
                          maxChildrenController: _fpmMaxChildrenController,
                          startServersController: _fpmStartServersController,
                          minSpareServersController:
                              _fpmMinSpareServersController,
                          maxSpareServersController:
                              _fpmMaxSpareServersController,
                          onModeChanged: (value) =>
                              provider.updateFpmParam('pm', value),
                          onMaxChildrenChanged: (value) =>
                              provider.updateFpmParam(
                            'pm.max_children',
                            value,
                          ),
                          onStartServersChanged: (value) => provider
                              .updateFpmParam('pm.start_servers', value),
                          onMinSpareServersChanged: (value) => provider
                              .updateFpmParam('pm.min_spare_servers', value),
                          onMaxSpareServersChanged: (value) => provider
                              .updateFpmParam('pm.max_spare_servers', value),
                          status: provider.fpmStatus,
                          onSave: _saveFpmConfig,
                          isSaving: provider.isSavingFpmConfig,
                        ),
                        PhpContainerSectionWidget(
                          config: provider.containerConfig,
                          onContainerNameChanged: provider.updateContainerName,
                          onAddEnvironment: provider.addEnvironment,
                          onUpdateEnvironment: provider.updateEnvironment,
                          onRemoveEnvironment: provider.removeEnvironment,
                          onAddExposedPort: provider.addExposedPort,
                          onUpdateExposedPort: provider.updateExposedPort,
                          onRemoveExposedPort: provider.removeExposedPort,
                          onAddExtraHost: provider.addExtraHost,
                          onUpdateExtraHost: provider.updateExtraHost,
                          onRemoveExtraHost: provider.removeExtraHost,
                          onAddVolume: provider.addVolume,
                          onUpdateVolume: provider.updateVolume,
                          onRemoveVolume: provider.removeVolume,
                          onSave: _saveContainerConfig,
                          isSaving: provider.isSavingContainerConfig,
                        ),
                        PhpFileEditorSectionWidget(
                          path: provider.phpFilePath,
                          contentController: _phpFileContentController,
                          onContentChanged: provider.updatePhpFileContent,
                          onSave: _savePhpFile,
                          isSaving: provider.isSavingPhpFile,
                        ),
                        PhpFileEditorSectionWidget(
                          path: provider.fpmFilePath,
                          contentController: _fpmFileContentController,
                          onContentChanged: provider.updateFpmFileContent,
                          onSave: _saveFpmFile,
                          isSaving: provider.isSavingFpmFile,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text != value) {
      controller.text = value;
    }
  }

  Future<void> _saveBasic() async {
    final success = await context.read<PhpConfigProvider>().save();
    _showSaveSnackBar(success);
  }

  Future<void> _saveFpmConfig() async {
    final success = await context.read<PhpConfigProvider>().saveFpmConfig();
    _showSaveSnackBar(success);
  }

  Future<void> _saveContainerConfig() async {
    final success =
        await context.read<PhpConfigProvider>().saveContainerConfig();
    _showSaveSnackBar(success);
  }

  Future<void> _savePhpFile() async {
    final success = await context.read<PhpConfigProvider>().savePhpFile();
    _showSaveSnackBar(success);
  }

  Future<void> _saveFpmFile() async {
    final success = await context.read<PhpConfigProvider>().saveFpmFile();
    _showSaveSnackBar(success);
  }

  void _showSaveSnackBar(bool success) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? context.l10n.commonSaveSuccess
              : context.l10n.commonSaveFailed,
        ),
      ),
    );
  }
}
