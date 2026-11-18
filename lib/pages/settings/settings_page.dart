import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/services/native_host_launcher.dart';
import 'package:onepanel_client/core/services/onboarding_service.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/theme/ui_render_mode.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/features/settings/about_page.dart';
import 'package:onepanel_client/features/settings/app_lock_settings_page.dart';
import 'package:onepanel_client/features/settings/screens/theme_settings_page.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/features/shell/widgets/shell_drawer_scope.dart';
import 'package:onepanel_client/pages/settings/cache_settings_page.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';

import '../../core/utils/snackbar_utils.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    this.nativeHostLauncher,
    this.onNativeHostLaunched,
    this.isWindowsHost,
  });

  /// 注入点（测试用）：默认按 C++ bootstrap 同规则探测宿主 exe。
  final NativeHostLauncher? nativeHostLauncher;

  /// 宿主拉起成功后的交接回调（测试用）；默认等待片刻后退出当前进程。
  final VoidCallback? onNativeHostLaunched;

  /// 注入点（测试用）：Windows 宿主才会在选「原生模式」时立即拉起宿主交接；
  /// 为 null 时按当前平台判定。
  final bool? isWindowsHost;

  @override
  Widget build(BuildContext context) {
    final spec = AdaptiveLayoutSpec.of(context);
    if (spec.isDesktop) {
      return _SettingsPageDesktop(
        nativeHostLauncher: nativeHostLauncher,
        onNativeHostLaunched: onNativeHostLaunched,
        isWindowsHost: isWindowsHost,
      );
    }
    if (spec.isTablet) {
      return _SettingsPageTablet(
        nativeHostLauncher: nativeHostLauncher,
        onNativeHostLaunched: onNativeHostLaunched,
        isWindowsHost: isWindowsHost,
      );
    }
    return _SettingsPageMobile(
      nativeHostLauncher: nativeHostLauncher,
      onNativeHostLaunched: onNativeHostLaunched,
      isWindowsHost: isWindowsHost,
    );
  }
}

class _SettingsPageMobile extends StatelessWidget {
  const _SettingsPageMobile({
    this.nativeHostLauncher,
    this.onNativeHostLaunched,
    this.isWindowsHost,
  });

  final NativeHostLauncher? nativeHostLauncher;
  final VoidCallback? onNativeHostLaunched;
  final bool? isWindowsHost;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // When embedded in a shell, canPop is false and we show the drawer button;
    // when pushed standalone (e.g. from onboarding), show a back arrow.
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              )
            : buildShellDrawerLeading(
                context,
                key: const Key('shell-drawer-menu-button'),
              ),
        title: Text(l10n.settingsPageTitle),
      ),
      body: _SettingsBody(
        nativeHostLauncher: nativeHostLauncher,
        onNativeHostLaunched: onNativeHostLaunched,
      ),
    );
  }
}

class _SettingsPageDesktop extends StatelessWidget {
  const _SettingsPageDesktop({
    this.nativeHostLauncher,
    this.onNativeHostLaunched,
    this.isWindowsHost,
  });

  final NativeHostLauncher? nativeHostLauncher;
  final VoidCallback? onNativeHostLaunched;
  final bool? isWindowsHost;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: AdaptiveLayoutSpec.of(context).settingsBodyMaxWidth,
          ),
          child: ColoredBox(
            color: scheme.surface,
            child: _SettingsBody(
              nativeHostLauncher: nativeHostLauncher,
              onNativeHostLaunched: onNativeHostLaunched,
              isWindowsHost: isWindowsHost,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsPageTablet extends StatelessWidget {
  const _SettingsPageTablet({
    this.nativeHostLauncher,
    this.onNativeHostLaunched,
    this.isWindowsHost,
  });

  final NativeHostLauncher? nativeHostLauncher;
  final VoidCallback? onNativeHostLaunched;
  final bool? isWindowsHost;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spec = AdaptiveLayoutSpec.of(context);
    return Scaffold(
      backgroundColor: scheme.surface,
      body: AdaptiveWidthContainer(
        maxWidth: spec.settingsBodyMaxWidth,
        child: ColoredBox(
          color: scheme.surface,
          child: _SettingsBody(
            nativeHostLauncher: nativeHostLauncher,
            onNativeHostLaunched: onNativeHostLaunched,
            isWindowsHost: isWindowsHost,
          ),
        ),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    this.nativeHostLauncher,
    this.onNativeHostLaunched,
    this.isWindowsHost,
  });

  final NativeHostLauncher? nativeHostLauncher;
  final VoidCallback? onNativeHostLaunched;
  final bool? isWindowsHost;

  /// 选「原生模式」= 立即拉起 WinUI3 宿主并交接（退出当前进程）；
  /// 宿主 exe 缺失时保留偏好并给出 dotnet build 指引；
  /// 选「MDUI3」维持既有「重启生效」语义。
  Future<void> _handleRenderModeSelected(
    BuildContext context,
    AppSettingsController settings,
    UIRenderMode value,
  ) async {
    final l10n = context.l10n;
    await settings.updateUIRenderMode(value);
    if (!context.mounted) {
      return;
    }
    Navigator.pop(context);
    if (value != UIRenderMode.native) {
      SnackBarUtils.showSuccess(context, l10n.settingsUIRenderModeRestartHint);
      return;
    }
    final launched =
        await (nativeHostLauncher ?? NativeHostLauncher()).launch();
    if (launched) {
      final handOver = onNativeHostLaunched;
      if (handOver != null) {
        handOver();
      } else {
        // 留出宿主窗口拉起的时间，再交出当前 Flutter runner 会话。
        await Future<void>.delayed(const Duration(milliseconds: 600));
        exit(0);
      }
      return;
    }
    if (context.mounted) {
      SnackBarUtils.showError(context, l10n.settingsUIRenderModeHostMissing);
    }
  }

  /// 渲染模式三选弹窗（native / liquidGlass / md3）。
  /// Windows 桌面选「原生模式」走宿主交接；其余模式更新偏好并提示重启。
  Future<void> _chooseRenderMode(
    BuildContext context,
    AppSettingsController settings,
  ) async {
    final l10n = context.l10n;
    final selectedMode = await showDialog<UIRenderMode>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsUIRenderMode),
        scrollable: true,
        content: RadioGroup<UIRenderMode>(
          groupValue: settings.uiRenderMode,
          onChanged: (mode) {
            if (mode == null) {
              return;
            }
            if (mode == UIRenderMode.native &&
                UIRenderPolicy.canSelectNativeMode() &&
                (isWindowsHost ?? PlatformUtils.isWindows)) {
              _handleRenderModeSelected(context, settings, mode);
              return;
            }
            Navigator.pop(dialogContext, mode);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (UIRenderPolicy.canSelectNativeMode())
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
    if (selectedMode == null ||
        selectedMode == settings.uiRenderMode ||
        !context.mounted) {
      return;
    }
    await settings.updateUIRenderMode(selectedMode);
    if (context.mounted) {
      SnackBarUtils.showSuccess(context, l10n.settingsUIRenderModeRestartHint);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer<AppSettingsController>(
      builder: (context, settings, _) {
        return ListView(
          padding: AdaptiveLayoutSpec.of(context).pagePadding,
          children: [
            SectionEntryList(
              title: l10n.settingsGeneral,
              items: [
                SectionEntryItem(
                  icon: Icons.color_lens_outlined,
                  title: l10n.settingsTheme,
                  subtitle: l10n.settingsThemeSubtitle,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThemeSettingsPage(),
                      ),
                    );
                  },
                ),
                SectionEntryItem(
                  icon: Icons.language_outlined,
                  title: l10n.settingsLanguage,
                  subtitle: _languageLabel(context, settings.locale),
                  // openRouteRespectingShell handles navigation both inside
                  // the shell (module switch) and standalone (push).
                  onTap: () => openRouteRespectingShell(
                    context,
                    AppRoutes.settingsLanguage,
                  ),
                ),
                SectionEntryItem(
                  icon: Icons.design_services_outlined,
                  title: l10n.settingsUIRenderMode,
                  subtitle: settings.nativeHostMissing
                      ? l10n.settingsUIRenderModeHostMissingStatus
                      : switch (settings.uiRenderMode) {
                          UIRenderMode.native =>
                            l10n.settingsUIRenderModeNative,
                          UIRenderMode.liquidGlass =>
                            l10n.settingsUIRenderModeLiquidGlass,
                          UIRenderMode.md3 => l10n.settingsUIRenderModeMD3,
                        },
                  onTap: () => _chooseRenderMode(context, settings),
                ),
                SectionEntryItem(
                  icon: Icons.lock_person_outlined,
                  title: l10n.settingsAppLock,
                  subtitle: l10n.settingsAppLockDesc,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppLockSettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDesignTokens.spacingLg),
            SectionEntryList(
              title: l10n.settingsStorage,
              items: [
                SectionEntryItem(
                  icon: Icons.cached_outlined,
                  title: l10n.settingsCacheTitle,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CacheSettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDesignTokens.spacingLg),
            SectionEntryList(
              title: l10n.settingsSupport,
              items: [
                SectionEntryItem(
                  icon: Icons.feedback_outlined,
                  title: l10n.settingsFeedbackCenterTitle,
                  subtitle: l10n.settingsFeedbackCenterSubtitle,
                  onTap: () => openRouteRespectingShell(
                    context,
                    AppRoutes.settingsFeedbackCenter,
                  ),
                ),
                SectionEntryItem(
                  icon: Icons.policy_outlined,
                  title: l10n.settingsLegalCenterTitle,
                  subtitle: l10n.settingsLegalCenterSubtitle,
                  onTap: () => openRouteRespectingShell(
                    context,
                    AppRoutes.settingsLegalCenter,
                  ),
                ),
                SectionEntryItem(
                  icon: Icons.info_outlined,
                  title: l10n.settingsAbout,
                  subtitle: l10n.settingsAboutSubtitle,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AboutPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDesignTokens.spacingLg),
            SectionEntryList(
              title: l10n.settingsAppSectionTitle,
              items: [
                SectionEntryItem(
                  icon: Icons.dns_outlined,
                  title: l10n.settingsServerManagement,
                  subtitle: l10n.settingsServerManagementSubtitle,
                  onTap: () =>
                      openRouteRespectingShell(context, AppRoutes.server),
                ),
                SectionEntryItem(
                  icon: Icons.slideshow_outlined,
                  title: l10n.settingsResetOnboarding,
                  onTap: () async {
                    await OnboardingService().resetAll();
                    if (!context.mounted) {
                      return;
                    }
                    SnackBarUtils.showSuccess(
                        context, l10n.settingsResetOnboardingDone);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

String _languageLabel(BuildContext context, Locale? locale) {
  final l10n = context.l10n;
  switch (locale?.languageCode) {
    case 'zh':
      return l10n.languageZh;
    case 'en':
      return l10n.languageEn;
    default:
      return l10n.languageSystem;
  }
}
