import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/panels/dpanel_adapter.dart';
import 'package:onepanel_client/data/panels/panel_adapter.dart';
import 'package:onepanel_client/data/panels/panel_registry.dart';

import 'dpanel_module_sections.dart';
import 'one_panel_module_sections.dart';

/// 注册时提供本地化标签，凭据值只交给所选面板。
class PanelCredentialField {
  const PanelCredentialField(
    this.id,
    this.label, {
    this.isRequired = true,
    this.obscureText = true,
  });

  final String id;
  final String Function(BuildContext) label;
  final bool isRequired;
  final bool obscureText;
}

class PanelPresentation {
  const PanelPresentation({
    required this.name,
    required this.buildModules,
    this.usesApiKey = true,
    this.needsCapabilities = true,
    this.fields = const [],
  });

  final String name;
  final bool usesApiKey;
  final bool needsCapabilities;
  final List<PanelCredentialField> fields;
  final Widget Function(BuildContext, ApiConfig, Map<String, PanelAccess>)
  buildModules;
}

/// 应用启动时注册；每种面板同时提供数据适配器、凭据字段与专属内容。
abstract final class PanelPresentations {
  static final _entries = <String, PanelPresentation>{
    ApiConfig.onePanelType: PanelPresentation(
      name: '1Panel',
      needsCapabilities: false,
      buildModules: (context, server, access) =>
          OnePanelModuleSections(serverId: server.id),
    ),
    DPanelAdapter.panelTypeId: PanelPresentation(
      name: 'DPanel',
      usesApiKey: false,
      needsCapabilities: true,
      fields: [
        PanelCredentialField(
          DPanelAdapter.fieldUsername,
          (context) => context.l10n.commonUsername,
          obscureText: false,
        ),
        PanelCredentialField(
          DPanelAdapter.fieldPassword,
          (context) => context.l10n.commonPassword,
        ),
        PanelCredentialField(
          DPanelAdapter.fieldEntrance,
          (context) => context.l10n.securitySettingsSecurityEntrance,
          isRequired: false,
          obscureText: false,
        ),
        PanelCredentialField(
          DPanelAdapter.fieldTotpCode,
          (context) => context.l10n.securitySettingsMfaCode,
          isRequired: false,
        ),
      ],
      buildModules: (context, server, access) =>
          DPanelModuleSections(server: server, capabilities: access),
    ),
  };

  static final entries = UnmodifiableMapView(_entries);

  static String displayName(String type) => _entries[type]?.name ?? type;

  static void register(PanelAdapter adapter, PanelPresentation presentation) {
    final fields = presentation.fields.map((field) => field.id).toSet();
    if (fields.contains('') || fields.length != presentation.fields.length) {
      throw ArgumentError('面板凭据字段必须有唯一名称');
    }
    PanelRegistry.instance.register(adapter);
    _entries[adapter.panelType] = presentation;
  }
}
