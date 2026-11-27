import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/core/channel/harmony_entry_presentation.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/onboarding_service.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';
import 'package:onepanel_client/features/server/panels/panel_presentation.dart';
import 'package:provider/provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.settingsDestination});

  final String? settingsDestination;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  final OnboardingService _service = OnboardingService();
  HarmonyEntryPresentation? _entry;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _entry = context.read<HarmonyEntryPresentation?>();
    unawaited(
      _entry?.show(
        this,
        'onboarding',
        onAction: (action) async {
          if (!mounted) return;
          if (action == 'skip') {
            await _complete(AppRoutes.home);
          } else if (action == 'start') {
            await _complete(AppRoutes.serverConfig);
          }
        },
      ),
    );
  }

  Future<void> _complete(String nextRoute) async {
    await _service.completeOnboarding();
    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(
      context,
      widget.settingsDestination ?? nextRoute,
    );
  }

  @override
  void dispose() {
    unawaited(_entry?.dismiss(this));
    _controller.dispose();
    super.dispose();
  }

  void _goToPage(int target) {
    _controller.animateToPage(
      target,
      duration: AppDesignTokens.motionNormal,
      curve: AppDesignTokens.motionEmphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final panelNames = PanelPresentations.entries.values
        .map((panel) => panel.name)
        .toList(growable: false);

    final pages = [
      _OnboardingSlideData(
        title: l10n.onboardingTitle1,
        description: l10n.onboardingDesc1,
        icon: Icons.hub_rounded,
        chips: panelNames,
      ),
      _OnboardingSlideData(
        title: l10n.onboardingTitle2,
        description: l10n.onboardingDesc2,
        icon: Icons.dashboard_customize_rounded,
        chips: [
          l10n.navFiles,
          l10n.serverModuleContainers,
          l10n.serverModuleApps,
          l10n.websitesPageTitle,
          l10n.serverModuleTerminal,
          l10n.serverModuleMonitoring,
        ],
      ),
      _OnboardingSlideData(
        title: l10n.onboardingTitle3,
        description: l10n.onboardingDesc3,
        icon: Icons.speed_rounded,
        chips: [
          l10n.dashboardCpuUsage,
          l10n.dashboardMemoryUsage,
          l10n.dashboardDiskUsage,
        ],
      ),
      _OnboardingSlideData(
        title: l10n.onboardingTitle4,
        description: l10n.onboardingDesc4,
        icon: Icons.vpn_key_rounded,
        chips: panelNames,
      ),
    ];

    final isLast = _index == pages.length - 1;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: AppDesignTokens.pagePadding,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_index > 0)
                            IconButton(
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).backButtonTooltip,
                              onPressed: () => _goToPage(_index - 1),
                              icon: const Icon(Icons.arrow_back_rounded),
                            )
                          else
                            const SizedBox(width: 48, height: 48),
                          TextButton(
                            onPressed: () => _complete(AppRoutes.home),
                            child: Text(l10n.onboardingSkip),
                          ),
                        ],
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _controller,
                          itemCount: pages.length,
                          onPageChanged: (value) {
                            setState(() => _index = value);
                          },
                          itemBuilder: (context, index) => _OnboardingSlideView(
                            data: pages[index],
                            isWide: isWide,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDesignTokens.spacingMd),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          pages.length,
                          (i) => Semantics(
                            button: true,
                            selected: i == _index,
                            label: '${i + 1} / ${pages.length}',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(99),
                              onTap: () => _goToPage(i),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 12,
                                ),
                                child: AnimatedContainer(
                                  duration: AppDesignTokens.motionNormal,
                                  curve: AppDesignTokens.motionEmphasized,
                                  height: 8,
                                  width: i == _index ? 28 : 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(99),
                                    color: i == _index
                                        ? scheme.primary
                                        : scheme.outlineVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDesignTokens.spacingMd),
                      SizedBox(
                        width: isWide ? 360 : double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            if (isLast) {
                              await _complete(AppRoutes.serverConfig);
                              return;
                            }
                            _goToPage(_index + 1);
                          },
                          child: Text(
                            isLast ? l10n.onboardingStart : l10n.onboardingNext,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.title,
    required this.description,
    required this.icon,
    required this.chips,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<String> chips;
}

class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({required this.data, required this.isWide});

  final _OnboardingSlideData data;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          vertical: AppDesignTokens.spacingMd,
        ),
        child: Card(
          color: AppTheme.cardSurface(scheme),
          child: Padding(
            padding: EdgeInsets.all(
              isWide ? AppDesignTokens.spacingXl + 8 : AppDesignTokens.spacingXl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(
                      AppDesignTokens.radiusXl,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    data.icon,
                    size: 42,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: AppDesignTokens.spacingXl),
                Semantics(
                  header: true,
                  child: Text(
                    data.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppDesignTokens.spacingMd),
                Text(
                  data.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (data.chips.isNotEmpty) ...[
                  const SizedBox(height: AppDesignTokens.spacingLg),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppDesignTokens.spacingSm,
                    runSpacing: AppDesignTokens.spacingSm,
                    children: [
                      for (final label in data.chips)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDesignTokens.spacingMd,
                            vertical: AppDesignTokens.spacingXs + 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Text(
                            label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
