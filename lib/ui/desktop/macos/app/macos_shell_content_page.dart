import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/module_page_factory.dart';
import 'package:onepanel_client/ui/desktop/macos/bridge/macos_shell_channel.dart';

/// Flutter-side content area for macOS native shell.
///
/// Phase 1: native Sidebar/Toolbar drives navigation via MethodChannel.
class MacosShellContentPage extends StatefulWidget {
  const MacosShellContentPage({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  State<MacosShellContentPage> createState() => _MacosShellContentPageState();
}

class _MacosShellContentPageState extends State<MacosShellContentPage> {
  final MacosShellChannel _channel = MacosShellChannel();
  late ClientModule _selectedModule;
  String? _lastSentTitle;

  @override
  void initState() {
    super.initState();
    _selectedModule = _moduleFromIndex(widget.initialIndex);
    _channel.setHandler(_handleNativeCall);
  }

  @override
  void dispose() {
    _channel.setHandler(null);
    super.dispose();
  }

  ClientModule _moduleFromIndex(int index) {
    switch (index.clamp(0, 3)) {
      case 0:
        return ClientModule.servers;
      case 1:
        return ClientModule.files;
      case 2:
        return ClientModule.containers;
      case 3:
        return ClientModule.settings;
      default:
        return ClientModule.servers;
    }
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'selectModule':
        final args = call.arguments;
        if (args is Map) {
          final moduleId = args['moduleId']?.toString();
          final module = clientModuleFromId(moduleId);
          if (module != null && mounted) {
            setState(() => _selectedModule = module);
          }
        }
        return null;
      case 'navigate':
        final args = call.arguments;
        if (!mounted) return null;
        if (args is Map) {
          final route = args['route']?.toString();
          final arguments = args['arguments'];
          if (route != null) {
            await Navigator.of(context).pushNamed(route, arguments: arguments);
          }
        }
        return null;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentServerController>(
      builder: (context, currentServer, _) {
        final selected = (!currentServer.hasServer && _selectedModule.requiresServer)
            ? ClientModule.servers
            : _selectedModule;
        final title = selected.label(context.l10n);

        if (title != _lastSentTitle) {
          _lastSentTitle = title;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _channel.setTitle(title);
          });
        }

        return buildShellModulePage(
          context,
          module: selected,
          serverId: currentServer.currentServerId,
        );
      },
    );
  }
}
