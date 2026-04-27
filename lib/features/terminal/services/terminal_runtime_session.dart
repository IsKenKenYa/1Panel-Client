import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/features/terminal/models/terminal_runtime_models.dart';
import 'package:xterm/xterm.dart';

import 'terminal_appearance.dart';
import 'terminal_transport.dart';

class TerminalRuntimeSession {
  TerminalRuntimeSession({
    required this.descriptor,
    required TerminalInfo? settings,
    required VoidCallback onChanged,
  })  : _onChanged = onChanged,
        terminal = Terminal(
          maxLines: TerminalAppearance.resolveScrollback(settings),
        ),
        controller = TerminalController(),
        focusNode = FocusNode();

  final TerminalSessionDescriptor descriptor;
  final VoidCallback _onChanged;

  final Terminal terminal;
  final TerminalController controller;
  final FocusNode focusNode;

  TerminalTransport? _transport;
  StreamSubscription<TerminalTransportEvent>? _subscription;
  Timer? _heartbeatTimer;

  TerminalSessionConnectionState connectionState =
      TerminalSessionConnectionState.idle;
  int? latencyMs;
  String? errorMessage;
  DateTime? lastConnectedAt;

  bool get isConnected =>
      connectionState == TerminalSessionConnectionState.connected;

  Future<void> attachTransport(TerminalTransport transport) async {
    await disposeTransport();
    _transport = transport;
    _subscription = transport.events.listen(_handleEvent);
    terminal.onOutput = (data) {
      _transport?.sendInput(data);
    };
    terminal.onResize = (width, height, _, __) {
      _transport?.resize(columns: width, rows: height);
    };

    connectionState = TerminalSessionConnectionState.connecting;
    errorMessage = null;
    _onChanged();

    try {
      await transport.connect();
      _startHeartbeat();
    } catch (error) {
      connectionState = TerminalSessionConnectionState.error;
      errorMessage = error.toString();
      _onChanged();
    }
  }

  void writeBanner(String message) {
    terminal.write('$message\r\n');
  }

  Future<void> sendCommand(String command) async {
    final normalized = command.endsWith('\n') ? command : '$command\n';
    await _transport?.sendInput(normalized);
  }

  void requestFocus() {
    focusNode.requestFocus();
  }

  void clearSelection() {
    controller.clearSelection();
  }

  void _handleEvent(TerminalTransportEvent event) {
    switch (event) {
      case TerminalOutputEvent():
        terminal.write(event.output);
      case TerminalHeartbeatEvent():
        latencyMs = event.latencyMs;
      case TerminalStatusEvent():
        connectionState = switch (event.status) {
          'connecting' => TerminalSessionConnectionState.connecting,
          'connected' => TerminalSessionConnectionState.connected,
          'closed' => TerminalSessionConnectionState.closed,
          'error' => TerminalSessionConnectionState.error,
          _ => connectionState,
        };
        if (event.status == 'connected') {
          lastConnectedAt = DateTime.now();
          errorMessage = null;
        }
      case TerminalClosedEvent():
        connectionState = TerminalSessionConnectionState.closed;
        errorMessage = event.reason;
      case TerminalErrorEvent():
        connectionState = TerminalSessionConnectionState.error;
        errorMessage = event.message;
    }
    _onChanged();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _transport?.heartbeat();
    });
  }

  Future<void> disposeTransport() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await _transport?.dispose();
    _transport = null;
  }

  Future<void> dispose() async {
    await disposeTransport();
    focusNode.dispose();
  }
}
