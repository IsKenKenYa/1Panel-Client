import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/api/v2/container_v2.dart';
import 'package:onepanel_client/data/models/container_docker_models.dart';

/// Container file browser page.
/// Mirrors frontend's container files tab: browse files inside a container.
class ContainerFilesPage extends StatefulWidget {
  const ContainerFilesPage({
    super.key,
    required this.containerId,
    required this.containerName,
    this.apiOverride,
  });

  final String containerId;
  final String containerName;

  /// Test seam: overrides API construction (widget tests inject a mock).
  @visibleForTesting
  final Future<ContainerV2Api> Function()? apiOverride;

  @override
  State<ContainerFilesPage> createState() => _ContainerFilesPageState();
}

class _ContainerFilesPageState extends State<ContainerFilesPage> {
  List<dynamic> _files = [];
  String _currentPath = '/';
  bool _isLoading = true;
  String? _error;

  Future<ContainerV2Api> _getApi() async {
    final override = widget.apiOverride;
    if (override != null) {
      return override();
    }
    return ContainerV2Api(await ApiClientManager.instance.getCurrentClient());
  }

  void _navigateUp() {
    if (_currentPath == '/' || _currentPath.isEmpty) return;
    final parts = _currentPath.split('/')..removeWhere((s) => s.isEmpty);
    if (parts.isEmpty) {
      _navigateTo('/');
      return;
    }
    parts.removeLast();
    _navigateTo(parts.isEmpty ? '/' : '/${parts.join('/')}/');
  }

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final api = await _getApi();
      final response = await api.searchContainerFiles(ContainerFileRequest(
        containerId: widget.containerId,
        path: _currentPath,
      ));
      if (mounted) {
        final data = response.data ?? const [];
        setState(() {
          _files = data.map((e) => {'name': e.name, 'isDir': e.isDir, 'size': e.size}).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _navigateTo(String path) {
    setState(() => _currentPath = path);
    _loadFiles();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final navigatorCanPop = Navigator.of(context).canPop();
    final inSubdirectory = _currentPath != '/' && _currentPath.isNotEmpty;
    return PopScope(
      canPop: navigatorCanPop && !inSubdirectory,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (inSubdirectory) {
          _navigateUp();
        }
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          title: Text(
              '${widget.containerName} - ${context.l10n.containerFilesTitle}'),
          leading: inSubdirectory
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _navigateUp,
                  tooltip:
                      MaterialLocalizations.of(context).backButtonTooltip,
                )
              : (navigatorCanPop ? const BackButton() : null),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _currentPath,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.commonBack,
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    onPressed:
                        inSubdirectory ? _navigateUp : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _files.isEmpty
                    ? Center(
                        child: Text(context.l10n.containerFilesEmpty))
                    : ListView.builder(
                        itemCount: _files.length,
                        itemBuilder: (context, index) {
                          final file = _files[index] as Map? ?? {};
                          final isDir = file['isDir'] == true;
                          final name = file['name']?.toString() ?? '';
                          return ListTile(
                            leading: Icon(
                              isDir ? Icons.folder : Icons.insert_drive_file,
                              color: isDir
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            title: Text(name),
                            subtitle: Text(
                              isDir
                                  ? context.l10n.containerFilesDirectory
                                  : context.l10n.containerFilesSizeBytes(
                                      file['size']?.toString() ?? 'N/A'),
                            ),
                            onTap: isDir
                                ? () => _navigateTo('$_currentPath$name/')
                                : null,
                          );
                        },
                      ),
      ),
    );
  }
}
