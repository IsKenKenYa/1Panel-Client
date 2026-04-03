import 'package:flutter/material.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

const List<ClientModule> kPinnableClientModules = [
  ClientModule.files,
  ClientModule.containers,
  ClientModule.apps,
  ClientModule.websites,
  ClientModule.ai,
  ClientModule.verification,
];

enum ClientModule {
  servers,
  files,
  containers,
  apps,
  websites,
  ai,
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

extension ClientModuleX on ClientModule {
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
        return Icons.widgets_outlined;
      case ClientModule.apps:
        return Icons.grid_view_outlined;
      case ClientModule.websites:
        return Icons.public_outlined;
      case ClientModule.ai:
        return Icons.psychology_outlined;
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
        return Icons.widgets;
      case ClientModule.apps:
        return Icons.grid_view;
      case ClientModule.websites:
        return Icons.public;
      case ClientModule.ai:
        return Icons.psychology;
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
      case ClientModule.settings:
        return l10n.settingsPageTitle;
      case ClientModule.verification:
        return l10n.serverActionSecurity;
    }
  }
}
