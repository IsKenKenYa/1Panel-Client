import 'package:flutter/material.dart';
import 'package:onepanelapp_app/l10n/generated/app_localizations.dart';
import 'log_viewer_controller.dart';
import 'log_theme_editor.dart';

class LogToolbar extends StatefulWidget {
  final LogViewerController controller;
  final VoidCallback onScrollToBottom;
  final VoidCallback onRefresh;
  final bool isAutoScrolling;

  const LogToolbar({
    super.key,
    required this.controller,
    required this.onScrollToBottom,
    required this.onRefresh,
    required this.isAutoScrolling,
  });

  @override
  State<LogToolbar> createState() => _LogToolbarState();
}

class _LogToolbarState extends State<LogToolbar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.controller.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.logSearchHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: widget.controller.searchQuery.isNotEmpty
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.controller.totalMatches > 0)
                                  Text(
                                    '${widget.controller.currentMatchCount}/${widget.controller.totalMatches}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                                  onPressed: widget.controller.previousMatch,
                                  tooltip: l10n.logPreviousMatch,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                  onPressed: widget.controller.nextMatch,
                                  tooltip: l10n.logNextMatch,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    widget.controller.search('');
                                    _searchController.clear();
                                  },
                                ),
                              ],
                            )
                          : null,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: widget.controller.search,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.logRefresh,
                onPressed: widget.onRefresh,
              ),
              if (!widget.isAutoScrolling)
                IconButton(
                  icon: const Icon(Icons.vertical_align_bottom),
                  tooltip: l10n.logScrollToBottom,
                  onPressed: widget.onScrollToBottom,
                ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: l10n.logSettings,
                onPressed: () => _showSettings(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LogSettingsSheet(controller: widget.controller),
    );
  }
}

class _LogSettingsSheet extends StatelessWidget {
  final LogViewerController controller;

  const _LogSettingsSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final settings = controller.settings;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.logSettingsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              // Font Size
              Text('${l10n.logFontSize}: ${settings.fontSize.toInt()}'),
              Slider(
                value: settings.fontSize,
                min: 10,
                max: 20,
                divisions: 10,
                label: settings.fontSize.toInt().toString(),
                onChanged: (value) {
                  controller.updateSettings(settings.copyWith(fontSize: value));
                },
              ),
              
              const Divider(),

              // Wrap
              SwitchListTile(
                title: Text(l10n.logWrap),
                value: settings.isWrap,
                onChanged: (value) {
                  controller.updateSettings(settings.copyWith(isWrap: value));
                },
              ),

              const Divider(),

              // Timestamp
              SwitchListTile(
                title: Text(l10n.logShowTimestamp),
                value: settings.showTimestamp,
                onChanged: (value) {
                  controller.updateSettings(settings.copyWith(showTimestamp: value));
                },
              ),
              
              if (settings.showTimestamp) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(l10n.logTimestampFormat),
                      const Spacer(),
                      SegmentedButton<LogTimestampFormat>(
                        segments: [
                          ButtonSegment(
                            value: LogTimestampFormat.absolute,
                            label: Text(l10n.logTimestampAbsolute),
                          ),
                          ButtonSegment(
                            value: LogTimestampFormat.relative,
                            label: Text(l10n.logTimestampRelative),
                          ),
                        ],
                        selected: {settings.timestampFormat},
                        onSelectionChanged: (Set<LogTimestampFormat> newSelection) {
                          controller.updateSettings(settings.copyWith(timestampFormat: newSelection.first));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              const Divider(),

              // Theme
              const SizedBox(height: 8),
              Text(l10n.logTheme),
              const SizedBox(height: 8),
              Center(
                child: SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode),
                      label: Text(l10n.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode),
                      label: Text(l10n.themeDark),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto),
                      label: Text(l10n.themeSystem),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    controller.updateSettings(settings.copyWith(themeMode: newSelection.first));
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              Center(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LogThemeEditor(controller: controller),
                      ),
                    );
                  },
                  icon: const Icon(Icons.palette),
                  label: Text(l10n.logEditTheme),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
