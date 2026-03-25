import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/onboarding_service.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  final OnboardingService _service = OnboardingService();
  int _index = 0;

  Future<void> _skip() async {
    await _service.completeOnboarding();
    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    await _service.completeOnboarding();
    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.serverConfig);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      (l10n.onboardingTitle1, l10n.onboardingDesc1, Icons.dns_rounded),
      (
        l10n.onboardingTitle2,
        l10n.onboardingDesc2,
        Icons.dashboard_customize_rounded,
      ),
      (
        l10n.onboardingTitle3,
        l10n.onboardingDesc3,
        Icons.speed_rounded,
      ),
      (l10n.onboardingTitle4, l10n.onboardingDesc4, Icons.key_rounded),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppDesignTokens.pagePadding,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skip,
                    child: Text(l10n.onboardingSkip),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (value) {
                    setState(() {
                      _index = value;
                    });
                  },
                  itemBuilder: (context, index) {
                    final (title, desc, icon) = pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 84),
                        const SizedBox(height: AppDesignTokens.spacingXl),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDesignTokens.spacingMd),
                        Text(
                          desc,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (i) => AnimatedContainer(
                    duration: AppDesignTokens.motionNormal,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: i == _index ? 28 : 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: i == _index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingLg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (_index == pages.length - 1) {
                      await _start();
                      return;
                    }

                    _controller.nextPage(
                      duration: AppDesignTokens.motionNormal,
                      curve: Curves.easeOut,
                    );
                  },
                  child: Text(_index == pages.length - 1
                      ? l10n.onboardingStart
                      : l10n.onboardingNext),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
