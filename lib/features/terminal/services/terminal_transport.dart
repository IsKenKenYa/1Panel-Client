import 'dart:async';

abstract class TerminalTransport {
  Stream<TerminalTransportEvent> get events;

  Future<void> connect();

  Future<void> sendInput(String data);

  Future<void> resize({
    required int columns,
    required int rows,
  });

  Future<void> heartbeat();

  Future<void> dispose();
}

sealed class TerminalTransportEvent {
  const TerminalTransportEvent();
}

class TerminalOutputEvent extends TerminalTransportEvent {
  const TerminalOutputEvent(this.output);

  final String output;
}

class TerminalHeartbeatEvent extends TerminalTransportEvent {
  const TerminalHeartbeatEvent({
    required this.remoteTimestamp,
    required this.localReceivedAt,
  });

  final int remoteTimestamp;
  final DateTime localReceivedAt;

  int get latencyMs =>
      localReceivedAt.millisecondsSinceEpoch - remoteTimestamp;
}

class TerminalStatusEvent extends TerminalTransportEvent {
  const TerminalStatusEvent(this.status);

  final String status;
}

class TerminalClosedEvent extends TerminalTransportEvent {
  const TerminalClosedEvent([this.reason]);

  final String? reason;
}

class TerminalErrorEvent extends TerminalTransportEvent {
  const TerminalErrorEvent(this.message);

  final String message;
}
