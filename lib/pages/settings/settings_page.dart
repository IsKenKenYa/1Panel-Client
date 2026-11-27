import 'dart:io';

import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/services/native_host_launcher.dart';
import 'package:onepanel_client/core/services/onboarding_service.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/theme/theme_controller.dart';
import 'package:onepanel_client/core/theme/ui_render_mode.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/settings/widgets/settings_save_action.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/features/shell/widgets/shell_drawer_scope.dart';
import 'package:onepanel_client/features/shell/widgets/shell_list_bottom_padding.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    this.nativeHostLauncher,
    this.onNativeHostLaunched,
    this.isWindowsHost,
  });

  final NativeHostLauncher? nativeHostLauncher;
  final VoidCallback? onNativeHostLaunched;
  final bool? isWindowsHost;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _choosingRenderMode = false;

  Future<void> _chooseRenderMode() async {
    if (_choosingRenderMode) return;
    setState(() => _choosingRenderMode = true);
    final settings = context.read<AppSettingsController>();
    final l10n = context.l10n;
    final windows = widget.isWindowsHost ?? PlatformUtils.isWindows;
    final supportsNative =
        widget.isWindowsHost == true || UIRenderPolicy.canSelectNativeMode();
    try {
      final selected = await showDialog<UIRenderMode>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.settingsUIRenderMode),
          scrollable: true,
          content: RadioGroup<UIRenderMode>(
            groupValue:
                settings.nativeHostMissing ? null : settings.uiRenderMode,
            onChanged: (mode) => Navigator.pop(dialogContext, mode),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (supportsNative)
                  RadioListTile<UIRenderMode>(
                    title: Text(l10n.settingsUIRenderModeNative),
                    subtitle: UIRenderPolicy.isAppleHost
                        ? Text(l10n.settingsUIRenderModeAppleGlassDesc)
                        : null,
                    value: UIRenderMode.native,
                  ),
                RadioListTile<UIRenderMode>(
                  title: Text(l10n.settingsUIRenderModeLiquidGlass),
                  subtitle: Text(l10n.settingsUIRenderModeLiquidGlassDesc),
                  value: UIRenderMode.liquidGlass,
                ),
                RadioListTile<UIRenderMode>(
                  title: Text(l10n.settingsUIRenderModeMD3),
                  value: UIRenderMode.md3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.commonClose),
            ),
          ],
        ),
      );
      if (!mounted || selected == null) return;
      if (selected == settings.uiRenderMode && !settings.nativeHostMissing) {
        return;
      }
      final saved = await saveAppPreference(
        context,
        () => settings.updateUIRenderMode(selected),
      );
      if (!saved || !mounted) return;
      // 液态玻璃与 MDUI3 都是 Flutter 内渲染形态，切换即时生效；
      // 只有切到原生宿主才需要拉起另一个进程。
      if (selected != UIRenderMode.native || !windows) {
        SnackBarUtils.showSuccess(
          context,
          l10n.settingsUIRenderModeSwitchApplied,
        );
        return;
      }
      final handover = widget.onNativeHostLaunched;
      final launcher = widget.nativeHostLauncher ?? NativeHostLauncher();
      final launched = await launcher.launch();
      if (!launched) {
        settings.markNativeHostMissing();
        if (mounted) {
          SnackBarUtils.showError(
              context, l10n.settingsUIRenderModeHostMissing);
        }
        return;
      }
      if (handover != null) {
        handover();
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        exit(0);
      }
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'settings.appearance',
        '切换界面风格失败',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        SnackBarUtils.showErrorWithDebugDetails(
          context,
          l10n.commonOperationFailed,
          error: error,
          stackTrace: stackTrace,
        );
      }
    } finally {
      if (mounted) setState(() => _choosingRenderMode = false);
    }
  }

  Future<void> _resetOnboarding() async {
    final saved =
        await saveAppPreference(context, OnboardingService().resetAll);
    if (saved && mounted) {
      SnackBarUtils.showSuccess(
        context,
        context.l10n.settingsResetOnboardingDone,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spec = AdaptiveLayoutSpec.of(context);
    final canPop = Navigator.canPop(context);
    final (renderMode, hostMissing, languageCode) = context.select(
      (AppSettingsController settings) => (
        settings.uiRenderMode,
        settings.nativeHostMissing,
        settings.locale?.languageCode
      ),
    );
    final themeMode =
        context.select((ThemeController? theme) => theme?.themeMode);
    final panelName = context.select((CurrentServerController? controller) {
      final server = controller?.currentServer;
      if (server == null || server.panelType != ApiConfig.onePanelType) {
        return null;
      }
      return server.name;
    });

    SectionEntryItem destination(
      IconData icon,
      String title,
      String route, {
      String? subtitle,
    }) {
      return SectionEntryItem(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: () => openRouteRespectingShell(context, route),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: spec.isPhone || canPop
          ? AppBar(
              leading: canPop
                  ? const BackButton()
                  : buildShellDrawerLeading(
                      context,
                      key: const Key('shell-drawer-menu-button'),
                    ),
              title: Text(l10n.settingsPageTitle),
            )
          : null,
      body: AdaptiveWidthContainer(
        maxWidth: spec.settingsBodyMaxWidth,
        child: ListView(
          padding: spec.pagePadding + shellListBottomPadding(context),
          children: [
            SectionEntryList(
              title: l10n.settingsAppearanceLanguage,
              items: [
                destination(
                  Icons.color_lens_outlined,
                  l10n.settingsTheme,
                  AppRoutes.settingsTheme,
                  subtitle: switch (themeMode) {
                    ThemeMode.light => l10n.themeLight,
                    ThemeMode.dark => l10n.themeDark,
                    ThemeMode.system => l10n.themeSystem,
                    null => null,
                  },
                ),
                SectionEntryItem(
                  icon: Icons.design_services_outlined,
                  title: l10n.settingsUIRenderMode,
                  subtitle: hostMissing
                      ? l10n.settingsUIRenderModeHostMissingStatus
                      : switch (renderMode) {
                          UIRenderMode.native =>
                            l10n.settingsUIRenderModeNative,
                          UIRenderMode.liquidGlass =>
                            l10n.settingsUIRenderModeLiquidGlass,
                          UIRenderMode.md3 => l10n.settingsUIRenderModeMD3,
                        },
                  onTap: _choosingRenderMode ? null : _chooseRenderMode,
                ),
                destination(
                  Icons.language_outlined,
                  l10n.settingsLanguage,
                  AppRoutes.settingsLanguage,
                  subtitle: switch (languageCode) {
                    'zh' => l10n.languageZh,
                    'en' => l10n.languageEn,
                    _ => l10n.languageSystem,
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDesignTokens.spacingLg),
            SectionEntryList(
              title: l10n.settingsSecurityStorage,
              items: [
                destination(
                  Icons.lock_person_outlined,
                  l10n.settingsAppLock,
                  AppRoutes.settingsAppLock,
                ),
                destination(
                  Icons.folder_outlined,
                  l10n.settingsCacheTitle,
                  AppRoutes.settingsStorage,
                ),
              ],
            ),
            const SizedBox(height: AppDesignTokens.spacingLg),
            SectionEntryList(
              title: l10n.settingsConnections,
              items: [
                destination(
                  Icons.dns_outlined,
                  l10n.settingsServerManagement,
                  AppRoutes.server,
                  subtitle: l10n.settingsServerManagementSubtitle,
                ),
                if (panelName != null)
                  destination(
                    Icons.tune_outlined,
                    l10n.systemSettingsPanelSection,
                    AppRoutes.systemSettings,
                    subtitle: panelName,
                  ),
              ],
            ),
            const SizedBox(height: AppDesignTokens.spacingLg),
            SectionEntryList(
              title: l10n.settingsHelpAbout,
              items: [
                destination(
                  Icons.feedback_outlined,
                  l10n.settingsFeedbackCenterTitle,
                  AppRoutes.settingsFeedbackCenter,
                ),
                SectionEntryItem(
                  icon: Icons.slideshow_outlined,
                  title: l10n.settingsResetOnboarding,
                  onTap: _resetOnboarding,
                ),
                destination(
                  Icons.policy_outlined,
                  l10n.settingsLegalCenterTitle,
                  AppRoutes.settingsLegalCenter,
                ),
                destination(
                  Icons.info_outlined,
                  l10n.settingsAbout,
                  AppRoutes.settingsAbout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
