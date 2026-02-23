import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/features/containers/container_service.dart';
import 'package:onepanelapp_app/features/containers/widgets/log_viewer_controller.dart';
import 'package:onepanelapp_app/features/containers/widgets/log_toolbar.dart';
import 'package:onepanelapp_app/features/containers/widgets/log_line_widget.dart';
import 'package:provider/provider.dart';

class ContainerLogsView extends StatefulWidget {
  final String containerName;

  const ContainerLogsView({
    super.key,
    required this.containerName,
  });

  @override
  State<ContainerLogsView> createState() => _ContainerLogsViewState();
}

class _ContainerLogsViewState extends State<ContainerLogsView> {
  final _service = ContainerService();
  final _controller = LogViewerController();
  final _scrollController = ScrollController();
  
  bool _isLoading = true;
  String? _error;
  bool _isAutoScrolling = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadLogs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    // If user scrolls up significantly (more than 50 pixels from bottom), disable auto-scroll
    if (maxScroll - currentScroll > 50) {
      if (_isAutoScrolling) {
        setState(() => _isAutoScrolling = false);
      }
    } else {
      if (!_isAutoScrolling) {
        setState(() => _isAutoScrolling = true);
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    setState(() => _isAutoScrolling = true);
  }

  Future<void> _loadLogs() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logs = await _service.getContainerLogs(widget.containerName, tail: '1000');
      if (!mounted) return;
      
      _controller.setLogs(logs);
      
      setState(() {
        _isLoading = false;
      });
      
      // Auto-scroll to bottom if enabled
      if (_isAutoScrolling) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading && _controller.logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _controller.logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.containerOperateFailed(_error!),
              style: TextStyle(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadLogs,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Column(
        children: [
          Consumer<LogViewerController>(
            builder: (context, controller, _) {
              return LogToolbar(
                controller: controller,
                isAutoScrolling: _isAutoScrolling,
                onScrollToBottom: _scrollToBottom,
                onRefresh: _loadLogs,
              );
            },
          ),
          Expanded(
            child: Consumer<LogViewerController>(
              builder: (context, controller, _) {
                if (controller.filteredLogs.isEmpty) {
                  return Center(
                    child: Text(
                      controller.searchQuery.isEmpty 
                          ? l10n.containerNoLogs 
                          : 'No matches found',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: controller.filteredLogs.length,
                  itemBuilder: (context, index) {
                    return LogLineWidget(
                      index: index + 1,
                      line: controller.filteredLogs[index],
                      settings: controller.settings,
                      query: controller.searchQuery,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
