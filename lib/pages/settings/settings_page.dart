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
  });

  /// 注入点（测试用）：默认按 C++ bootstrap 同规则探测宿主 exe。
  final NativeHostLauncher? nativeHostLauncher;

  /// 宿主拉起成功后的交接回调（测试用）；默认等待片刻后退出当前进程。
  final VoidCallback? onNativeHostLaunched;

  @override
  Widget build(BuildContext context) {
    final spec = AdaptiveLayoutSpec.of(context);
    if (spec.isDesktop) {
      return _SettingsPageDesktop(
        nativeHostLauncher: nativeHostLauncher,
        onNativeHostLaunched: onNativeHostLaunched,
      );
    }
    if (spec.isTablet) {
      return _SettingsPageTablet(
        nativeHostLauncher: nativeHostLauncher,
        onNativeHostLaunched: onNativeHostLaunched,
      );
    }
    return _SettingsPageMobile(
      nativeHostLauncher: nativeHostLauncher,
      onNativeHostLaunched: onNativeHostLaunched,
    );
  }
}

class _SettingsPageMobile extends StatelessWidget {
  const _SettingsPageMobile({
    this.nativeHostLauncher,
    this.onNativeHostLaunched,
  });

  final NativeHostLauncher? nativeHostLauncher;
  final VoidCallback? onNativeHostLaunched;

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
  });

  final NativeHostLauncher? nativeHostLauncher;
  final VoidCallback? onNativeHostLaunched;

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
  });

  final NativeHostLauncher? nativeHostLauncher;
  final VoidCallback? onNativeHostLaunched;

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
  });

  final NativeHostLauncher? nativeHostLauncher;
  final VoidCallback? onNativeHostLaunched;

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
    final launched = await (nativeHostLauncher ?? NativeHostLauncher()).launch();
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
                      : settings.uiRenderMode == UIRenderMode.native
                          ? l10n.settingsUIRenderModeNative
                          : l10n.settingsUIRenderModeMD3,
                  onTap: () {
                    showDialog(
                      context: context,
                      // builder context 在对话框 pop 后即 unmount，回调用
                      // 页面级 context 展示反馈（弹错误 SnackBar 必需）。
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: Text(l10n.settingsUIRenderMode),
                          content: RadioGroup<UIRenderMode>(
                            groupValue: settings.uiRenderMode,
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              _handleRenderModeSelected(
                                context,
                                settings,
                                value,
                              );
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (UIRenderPolicy.canSelectNativeMode())
                                  RadioListTile<UIRenderMode>(
                                    title:
                                        Text(l10n.settingsUIRenderModeNative),
                                    value: UIRenderMode.native,
                                  ),
                                RadioListTile<UIRenderMode>(
                                  title: Text(l10n.settingsUIRenderModeMD3),
                                  value: UIRenderMode.md3,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
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
                  icon: Icons.info_outline,
                  title: l10n.settingsAbout,
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
                    SnackBarUtils.showSuccess(context, l10n.settingsResetOnboardingDone);
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
