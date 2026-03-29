import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/network/onepanel_auth_headers.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _heartbeatTimer;

  bool _bootstrapped = false;
  bool _connecting = false;
  bool _connected = false;
  String? _error;
  String _output = '';
  int? _latencyMs;

  late _TerminalConnectionArgs _connection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) {
      return;
    }
    _bootstrapped = true;
    _connection = _TerminalConnectionArgs.fromRouteArgs(
      ModalRoute.of(context)?.settings.arguments,
    );
    unawaited(_connect());
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    unawaited(_socketSubscription?.cancel());
    unawaited(_socket?.close());
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _error = null;
      _latencyMs = null;
    });

    try {
      await _disconnectInternal();

      final config = await ApiConfigManager.getCurrentConfig();
      if (config == null) {
        throw StateError('No API config available');
      }

      final uri = _buildWsUri(config, _connection);
      final headers = <String, dynamic>{
        ...OnePanelAuthHeaders.build(config.apiKey),
        'User-Agent': ApiConstants.userAgent,
      };

      HttpClient? customClient;
      if (config.allowInsecureTls) {
        customClient = HttpClient()
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
      }

      final socket = await WebSocket.connect(
        uri.toString(),
        headers: headers,
        customClient: customClient,
      );

      _socket = socket;
      _socketSubscription = socket.listen(
        _handleSocketMessage,
        onError: _handleSocketError,
        onDone: _handleSocketDone,
        cancelOnError: false,
      );

      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _sendHeartbeat(),
      );

      setState(() {
        _connected = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _connected = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _connecting = false;
        });
      }
    }
  }

  Future<void> _disconnectInternal() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _socket?.close();
    _socket = null;
  }

  void _handleSocketMessage(dynamic event) {
    if (event is! String) {
      _appendOutput(event.toString());
      return;
    }

    try {
      final payload = jsonDecode(event);
      if (payload is Map<String, dynamic>) {
        final type = payload['type']?.toString();
        if (type == 'cmd') {
          final encoded = payload['data']?.toString() ?? '';
          if (encoded.isNotEmpty) {
            final decoded = utf8.decode(
              base64.decode(encoded),
              allowMalformed: true,
            );
            _appendOutput(decoded);
          }
          return;
        }

        if (type == 'heartbeat') {
          final remoteTs = int.tryParse(payload['timestamp']?.toString() ?? '');
          if (remoteTs != null && mounted) {
            setState(() {
              _latencyMs = DateTime.now().millisecondsSinceEpoch - remoteTs;
            });
          }
          return;
        }
      }

      _appendOutput(event);
    } catch (_) {
      _appendOutput(event);
    }
  }

  void _handleSocketError(Object error) {
    if (!mounted) {
      return;
    }
    setState(() {
      _connected = false;
      _error = error.toString();
    });
  }

  void _handleSocketDone() {
    if (!mounted) {
      return;
    }
    setState(() {
      _connected = false;
      _error ??= 'Terminal connection closed';
    });
  }

  void _sendHeartbeat() {
    if (!_connected || _socket == null) {
      return;
    }

    _socket!.add(
      jsonEncode({
        'type': 'heartbeat',
        'timestamp': '${DateTime.now().millisecondsSinceEpoch}',
      }),
    );
  }

  void _sendCommand([String? raw]) {
    if (!_connected || _socket == null) {
      return;
    }

    final input = (raw ?? _inputController.text).trim();
    if (input.isEmpty) {
      return;
    }

    final command = input.endsWith('\n') ? input : '$input\n';
    _socket!.add(
      jsonEncode({
        'type': 'cmd',
        'data': base64.encode(utf8.encode(command)),
      }),
    );

    _appendOutput('\n\$ $input\n');
    _inputController.clear();
  }

  void _appendOutput(String text) {
    if (!mounted || text.isEmpty) {
      return;
    }

    setState(() {
      _output += text;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    });
  }

  Uri _buildWsUri(ApiConfig config, _TerminalConnectionArgs connection) {
    final baseUri = Uri.parse(config.url);
    final normalizedBasePath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    final endpointPath = connection.endpoint.startsWith('/')
        ? connection.endpoint
        : '/${connection.endpoint}';
    final wsPath = '$normalizedBasePath$endpointPath';

    final query = <String, String>{
      'cols': '120',
      'rows': '36',
      ...connection.query,
    };

    return baseUri.replace(
      scheme: baseUri.scheme == 'https' ? 'wss' : 'ws',
      path: wsPath,
      queryParameters: query,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(_connection.title(l10n)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _connecting ? null : _connect,
            tooltip: l10n.commonRefresh,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: AppDesignTokens.pagePadding,
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                _connected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                color: _connected ? Colors.green : Colors.orange,
              ),
              title: Text(_connection.endpoint),
              subtitle: Text(
                _connecting
                    ? l10n.commonLoading
                    : _connected
                        ? (_latencyMs == null
                            ? l10n.systemSettingsEnabled
                            : '${l10n.systemSettingsEnabled} · ${_latencyMs}ms')
                        : l10n.systemSettingsDisabled,
              ),
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: SelectableText(
                  _output.isEmpty ? (_error ?? l10n.commonEmpty) : _output,
                  style: TextStyle(
                    color: _error != null && _output.isEmpty
                        ? Colors.redAccent
                        : Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingSm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  enabled: _connected,
                  onSubmitted: _sendCommand,
                  decoration: InputDecoration(
                    hintText: _connected ? '>' : l10n.systemSettingsDisabled,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: l10n.commonConfirm,
                onPressed: _connected ? _sendCommand : null,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TerminalConnectionArgs {
  const _TerminalConnectionArgs({
    required this.endpoint,
    required this.query,
    this.targetName,
  });

  final String endpoint;
  final Map<String, String> query;
  final String? targetName;

  factory _TerminalConnectionArgs.fromRouteArgs(Object? rawArgs) {
    if (rawArgs is Map) {
      final type = rawArgs['type']?.toString();
      if (type == 'container') {
        final containerId = rawArgs['containerId']?.toString();
        if (containerId != null && containerId.isNotEmpty) {
          final command = rawArgs['command']?.toString();
          final user = rawArgs['user']?.toString();
          return _TerminalConnectionArgs(
            endpoint: ApiConstants.buildApiPath('/containers/exec'),
            query: <String, String>{
              'source': 'container',
              'containerid': containerId,
              if (command != null && command.isNotEmpty) 'command': command,
              if (user != null && user.isNotEmpty) 'user': user,
            },
            targetName: rawArgs['containerName']?.toString() ?? containerId,
          );
        }
      }
    }

    return _TerminalConnectionArgs(
      endpoint: ApiConstants.buildApiPath('/hosts/terminal'),
      query: const <String, String>{'operateNode': 'local'},
    );
  }

  String title(AppLocalizations l10n) {
    if (targetName == null || targetName!.isEmpty) {
      return l10n.serverModuleTerminal;
    }
    return '${l10n.serverModuleTerminal} · $targetName';
  }
}
