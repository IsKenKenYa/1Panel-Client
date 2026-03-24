import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'log_viewer_controller.dart';
import 'log_toolbar.dart';
import 'log_line_widget.dart';

export 'log_viewer_controller.dart';

class LogViewer extends StatefulWidget {
  final LogViewerController controller;
  final VoidCallback onRefresh;
  final String? emptyMessage;

  const LogViewer({
    super.key,
    required this.controller,
    required this.onRefresh,
    this.emptyMessage,
  });

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  final _scrollController = ScrollController();
  late final ScrollController _horizontalScrollController;
  bool _isAutoScrolling = true;
  List<LogLine> _prevLogs = [];

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    widget.controller.addListener(_onControllerChanged);
    _prevLogs = widget.controller.logs;
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _scrollController.dispose();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.logs != _prevLogs) {
      _prevLogs = widget.controller.logs;
      if (_isAutoScrolling) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
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
    if (!_isAutoScrolling) {
      setState(() => _isAutoScrolling = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.controller,
      child: Consumer<LogViewerController>(
        builder: (context, controller, child) {
          // Determine the effective theme for the LogViewer
          final appTheme = Theme.of(context);
          ThemeData effectiveTheme = appTheme;

          if (controller.settings.themeMode != ThemeMode.system) {
            final targetBrightness = controller.settings.themeMode == ThemeMode.dark
                ? Brightness.dark
                : Brightness.light;

            if (appTheme.brightness != targetBrightness) {
              // We need to generate a new theme with the target brightness
              // preserving the seed color if possible
              final seedColor = appTheme.colorScheme.primary;
              final scheme = ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: targetBrightness,
              );
              effectiveTheme = AppTheme.create(scheme);
            }
          }

          // Apply the effective theme to the subtree
          return Theme(
            data: effectiveTheme,
            child: Builder(
              builder: (context) {
                final colorScheme = Theme.of(context).colorScheme;
                return Container(
                  color: colorScheme.surface,
                  child: Column(
                    children: [
                      LogToolbar(
                        controller: controller,
                        isAutoScrolling: _isAutoScrolling,
                        onScrollToBottom: _scrollToBottom,
                        onRefresh: widget.onRefresh,
                      ),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            if (controller.filteredLogs.isEmpty) {
                              return Center(
                                child: Text(
                                  controller.searchQuery.isEmpty 
                                      ? (widget.emptyMessage ?? AppLocalizations.of(context)!.logNoLogs) 
                                      : AppLocalizations.of(context)!.logNoMatches,
                                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                                ),
                              );
                            }

                          Widget listView = ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: controller.filteredLogs.length,
                            itemBuilder: (context, index) {
                              return LogLineWidget(
                                index: index + 1,
                                line: controller.filteredLogs[index],
                                settings: controller.settings,
                                query: controller.searchQuery,
                                firstLogTimestamp: controller.firstLogTimestamp,
                              );
                            },
                          );

                          if (controller.settings.viewMode == LogViewMode.scrollPage) {
                            return Scrollbar(
                              controller: _horizontalScrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: SingleChildScrollView(
                                controller: _horizontalScrollController,
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width * 3,
                                  child: listView,
                                ),
                              ),
                            );
                          }

                          return listView;
                        },
                      ),
                    ),
                  ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
