import 'package:flutter/material.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

const List<ClientModule> kPinnableClientModules = [
  ClientModule.files,
  ClientModule.containers,
  ClientModule.apps,
  ClientModule.websites,
  ClientModule.ai,
  ClientModule.vm,
  ClientModule.verification,
];

enum ClientModule {
  servers,
  files,
  containers,
  apps,
  websites,
  ai,
  vm,
  settings,
  verification,
}

ClientModule? clientModuleFromId(String? id) {
  if (id == null) return null;
  for (final module in ClientModule.values) {
    if (module.storageId == id) {
      return module;
    }
  }
  return null;
}

bool supportsOnePanelModules(String? panelType) =>
    panelType == null || panelType == ApiConfig.onePanelType;

ClientModule initialShellModule(int tabIndex, String? moduleId) {
  const tabs = [
    ClientModule.servers,
    ClientModule.files,
    ClientModule.containers,
    ClientModule.settings,
  ];
  return clientModuleFromId(moduleId) ??
      tabs[tabIndex.clamp(0, tabs.length - 1)];
}

extension ClientModuleX on ClientModule {
  bool supportsPanel(String? panelType) =>
      !requiresServer || supportsOnePanelModules(panelType);

  ClientModule forServer(ApiConfig? server) =>
      !requiresServer || server != null && supportsPanel(server.panelType)
          ? this
          : ClientModule.servers;

  String get storageId {
    switch (this) {
      case ClientModule.servers:
        return 'servers';
      case ClientModule.files:
        return 'files';
      case ClientModule.containers:
        return 'containers';
      case ClientModule.apps:
        return 'apps';
      case ClientModule.websites:
        return 'websites';
      case ClientModule.ai:
        return 'ai';
      case ClientModule.vm:
        return 'vm';
      case ClientModule.settings:
        return 'settings';
      case ClientModule.verification:
        return 'verification';
    }
  }

  bool get requiresServer {
    switch (this) {
      case ClientModule.servers:
      case ClientModule.settings:
        return false;
      case ClientModule.files:
      case ClientModule.containers:
      case ClientModule.apps:
      case ClientModule.websites:
      case ClientModule.ai:
      case ClientModule.vm:
      case ClientModule.verification:
        return true;
    }
  }

  bool get pinnable => kPinnableClientModules.contains(this);

  bool get experimental {
    switch (this) {
      case ClientModule.websites:
      case ClientModule.ai:
        return true;
      case ClientModule.servers:
      case ClientModule.files:
      case ClientModule.containers:
      case ClientModule.apps:
      case ClientModule.vm:
      case ClientModule.settings:
      case ClientModule.verification:
        return false;
    }
  }

  IconData get icon {
    switch (this) {
      case ClientModule.servers:
        return Icons.dns_outlined;
      case ClientModule.files:
        return Icons.folder_open_outlined;
      case ClientModule.containers:
        return Icons.inventory_2_outlined;
      case ClientModule.apps:
        return Icons.grid_view_outlined;
      case ClientModule.websites:
        return Icons.public_outlined;
      case ClientModule.ai:
        return Icons.psychology_outlined;
      case ClientModule.vm:
        return Icons.computer_outlined;
      case ClientModule.settings:
        return Icons.settings_outlined;
      case ClientModule.verification:
        return Icons.shield_outlined;
    }
  }

  IconData get selectedIcon {
    switch (this) {
      case ClientModule.servers:
        return Icons.dns;
      case ClientModule.files:
        return Icons.folder_open;
      case ClientModule.containers:
        return Icons.inventory_2;
      case ClientModule.apps:
        return Icons.grid_view;
      case ClientModule.websites:
        return Icons.public;
      case ClientModule.ai:
        return Icons.psychology;
      case ClientModule.vm:
        return Icons.computer;
      case ClientModule.settings:
        return Icons.settings;
      case ClientModule.verification:
        return Icons.shield;
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case ClientModule.servers:
        return l10n.navServer;
      case ClientModule.files:
        return l10n.navFiles;
      case ClientModule.containers:
        return l10n.containerManagement;
      case ClientModule.apps:
        return l10n.appsPageTitle;
      case ClientModule.websites:
        return l10n.websitesPageTitle;
      case ClientModule.ai:
        return l10n.serverModuleAi;
      case ClientModule.vm:
        return l10n.serverModuleVm;
      case ClientModule.settings:
        return l10n.settingsPageTitle;
      case ClientModule.verification:
        return l10n.serverActionSecurity;
    }
  }
}

List<ClientModule> shellModulesForPanel(
  String? panelType,
  Iterable<ClientModule> pins, {
  bool compact = false,
  ClientModule? activeModule,
}) {
  return [
    ClientModule.servers,
    ...{
      ...pins,
      if (!compact) ...kPinnableClientModules,
      if (compact && activeModule != null && activeModule.pinnable) activeModule,
    }.where((module) => module.supportsPanel(panelType)),
    ClientModule.settings,
  ];
}
