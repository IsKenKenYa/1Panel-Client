import 'package:flutter/material.dart';
import 'log_viewer_controller.dart';

class LogToolbar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
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
                    decoration: InputDecoration(
                      hintText: 'Search logs...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: controller.search,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Logs',
                onPressed: onRefresh,
              ),
              if (!isAutoScrolling && onScrollToBottom != null)
                IconButton(
                  icon: const Icon(Icons.vertical_align_bottom),
                  tooltip: 'Scroll to Bottom',
                  onPressed: onScrollToBottom,
                ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
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
      builder: (context) => _LogSettingsSheet(controller: controller),
    );
  }
}

class _LogSettingsSheet extends StatelessWidget {
  final LogViewerController controller;

  const _LogSettingsSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
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
                'Log Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              // Font Size
              Text('Font Size: ${settings.fontSize.toInt()}'),
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
                title: const Text('Wrap Text'),
                value: settings.isWrap,
                onChanged: (value) {
                  controller.updateSettings(settings.copyWith(isWrap: value));
                },
              ),

              const Divider(),

              // Timestamp
              SwitchListTile(
                title: const Text('Show Timestamp'),
                value: settings.showTimestamp,
                onChanged: (value) {
                  controller.updateSettings(settings.copyWith(showTimestamp: value));
                },
              ),

              const Divider(),

              // Theme
              const SizedBox(height: 8),
              const Text('Theme'),
              const SizedBox(height: 8),
              Center(
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode),
                      label: Text('Dark'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto),
                      label: Text('System'),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    controller.updateSettings(settings.copyWith(themeMode: newSelection.first));
                  },
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
