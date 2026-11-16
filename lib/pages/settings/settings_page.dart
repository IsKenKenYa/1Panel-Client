import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
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
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final spec = AdaptiveLayoutSpec.of(context);
    if (spec.isDesktop) {
      return const _SettingsPageDesktop();
    }
    if (spec.isTablet) {
      return const _SettingsPageTablet();
    }
    return const _SettingsPageMobile();
  }
}

class _SettingsPageMobile extends StatelessWidget {
  const _SettingsPageMobile();

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
      body: const _SettingsBody(),
    );
  }
}

class _SettingsPageDesktop extends StatelessWidget {
  const _SettingsPageDesktop();

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
            child: const _SettingsBody(),
          ),
        ),
      ),
    );
  }
}

class _SettingsPageTablet extends StatelessWidget {
  const _SettingsPageTablet();

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
          child: const _SettingsBody(),
        ),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

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
                  subtitle: switch (settings.uiRenderMode) {
                    UIRenderMode.native => l10n.settingsUIRenderModeNative,
                    UIRenderMode.liquidGlass =>
                      l10n.settingsUIRenderModeLiquidGlass,
                    UIRenderMode.md3 => l10n.settingsUIRenderModeMD3,
                  },
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(l10n.settingsUIRenderMode),
                          content: RadioGroup<UIRenderMode>(
                            groupValue: settings.uiRenderMode,
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              settings.updateUIRenderMode(value);
                              Navigator.pop(context);
                              SnackBarUtils.showSuccess(context, l10n
                                        .settingsUIRenderModeRestartHint);
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
                                  title:
                                      Text(l10n.settingsUIRenderModeLiquidGlass),
                                  subtitle: Text(
                                      l10n.settingsUIRenderModeLiquidGlassDesc),
                                  value: UIRenderMode.liquidGlass,
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
