import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

enum TerminalTargetKind {
  workbench,
  localHost,
  savedHost,
  containerExec,
}

enum TerminalSessionConnectionState {
  idle,
  connecting,
  connected,
  closed,
  error,
}

class TerminalLaunchIntent extends Equatable {
  const TerminalLaunchIntent._({
    required this.kind,
    this.hostId,
    this.hostLabel,
    this.containerId,
    this.containerName,
    this.command,
    this.user,
    this.autoStart = false,
  });

  const TerminalLaunchIntent.workbench()
      : this._(kind: TerminalTargetKind.workbench);

  const TerminalLaunchIntent.localHost({
    bool autoStart = true,
  }) : this._(
          kind: TerminalTargetKind.localHost,
          autoStart: autoStart,
        );

  const TerminalLaunchIntent.savedHost({
    required int hostId,
    String? hostLabel,
    bool autoStart = true,
  }) : this._(
          kind: TerminalTargetKind.savedHost,
          hostId: hostId,
          hostLabel: hostLabel,
          autoStart: autoStart,
        );

  const TerminalLaunchIntent.containerExec({
    required String containerId,
    String? containerName,
    String? command,
    String? user,
    bool autoStart = true,
  }) : this._(
          kind: TerminalTargetKind.containerExec,
          containerId: containerId,
          containerName: containerName,
          command: command,
          user: user,
          autoStart: autoStart,
        );

  final TerminalTargetKind kind;
  final int? hostId;
  final String? hostLabel;
  final String? containerId;
  final String? containerName;
  final String? command;
  final String? user;
  final bool autoStart;

  bool get isWorkbench => kind == TerminalTargetKind.workbench;
  bool get isExplicitSession => !isWorkbench && autoStart;

  factory TerminalLaunchIntent.fromRouteArgs(Object? rawArgs) {
    if (rawArgs is Map) {
      final type = rawArgs['type']?.toString();
      if (type == 'container') {
        final containerId = rawArgs['containerId']?.toString();
        if (containerId != null && containerId.isNotEmpty) {
          return TerminalLaunchIntent.containerExec(
            containerId: containerId,
            containerName: rawArgs['containerName']?.toString(),
            command: rawArgs['command']?.toString(),
            user: rawArgs['user']?.toString(),
          );
        }
      }

      if (type == 'host') {
        final hostId = int.tryParse(rawArgs['hostId']?.toString() ?? '');
        if (hostId != null) {
          return TerminalLaunchIntent.savedHost(
            hostId: hostId,
            hostLabel: rawArgs['hostLabel']?.toString(),
          );
        }
      }

      if (type == 'local') {
        return const TerminalLaunchIntent.localHost();
      }
    }

    return const TerminalLaunchIntent.workbench();
  }

  String title(BuildContext context) {
    final l10n = context.l10n;
    switch (kind) {
      case TerminalTargetKind.localHost:
        return '${l10n.serverModuleTerminal} · Local';
      case TerminalTargetKind.savedHost:
        return hostLabel?.isNotEmpty == true
            ? '${l10n.serverModuleTerminal} · $hostLabel'
            : l10n.serverModuleTerminal;
      case TerminalTargetKind.containerExec:
        return containerName?.isNotEmpty == true
            ? '${l10n.serverModuleTerminal} · $containerName'
            : l10n.serverModuleTerminal;
      case TerminalTargetKind.workbench:
        return l10n.serverModuleTerminal;
    }
  }

  String resolvedTargetTitle() {
    switch (kind) {
      case TerminalTargetKind.localHost:
        return 'Local';
      case TerminalTargetKind.savedHost:
        return hostLabel?.trim().isNotEmpty == true
            ? hostLabel!.trim()
            : 'Host #$hostId';
      case TerminalTargetKind.containerExec:
        return containerName?.trim().isNotEmpty == true
            ? containerName!.trim()
            : (containerId ?? 'Container');
      case TerminalTargetKind.workbench:
        return 'Workbench';
    }
  }

  String endpointPath() {
    switch (kind) {
      case TerminalTargetKind.containerExec:
        return ApiConstants.buildApiPath('/containers/exec');
      case TerminalTargetKind.localHost:
      case TerminalTargetKind.savedHost:
        return ApiConstants.buildApiPath('/hosts/terminal');
      case TerminalTargetKind.workbench:
        return ApiConstants.buildApiPath('/hosts/terminal');
    }
  }

  Map<String, String> queryParameters({
    required int columns,
    required int rows,
  }) {
    final query = <String, String>{
      'cols': '$columns',
      'rows': '$rows',
    };

    switch (kind) {
      case TerminalTargetKind.localHost:
        query['operateNode'] = 'local';
        break;
      case TerminalTargetKind.savedHost:
        query['operateNode'] = 'local';
        if (hostId != null) {
          query['id'] = '$hostId';
        }
        break;
      case TerminalTargetKind.containerExec:
        query['source'] = 'container';
        query['containerid'] = containerId ?? '';
        query['command'] = command?.isNotEmpty == true ? command! : '/bin/sh';
        if (user?.isNotEmpty == true) {
          query['user'] = user!;
        }
        break;
      case TerminalTargetKind.workbench:
        query['operateNode'] = 'local';
        break;
    }
    return query;
  }

  @override
  List<Object?> get props => <Object?>[
        kind,
        hostId,
        hostLabel,
        containerId,
        containerName,
        command,
        user,
        autoStart,
      ];
}

class TerminalSessionDescriptor extends Equatable {
  const TerminalSessionDescriptor({
    required this.sessionKey,
    required this.intent,
    required this.title,
    this.capabilityLabel,
  });

  final String sessionKey;
  final TerminalLaunchIntent intent;
  final String title;
  final String? capabilityLabel;

  IconData get icon {
    switch (intent.kind) {
      case TerminalTargetKind.localHost:
      case TerminalTargetKind.savedHost:
        return Icons.dns_outlined;
      case TerminalTargetKind.containerExec:
        return Icons.inventory_2_outlined;
      case TerminalTargetKind.workbench:
        return Icons.terminal_outlined;
    }
  }

  @override
  List<Object?> get props => <Object?>[
        sessionKey,
        intent,
        title,
        capabilityLabel,
      ];
}
