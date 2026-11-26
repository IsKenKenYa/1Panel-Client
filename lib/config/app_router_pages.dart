import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/core/channel/harmony_entry_presentation.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/config/release_channel_config.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
import 'package:onepanel_client/core/services/onboarding_service.dart';
import 'package:onepanel_client/core/services/startup/testing_channel_consent_service.dart';
import 'package:onepanel_client/features/onboarding/onboarding_page.dart';
import 'package:onepanel_client/features/security/app_lock_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, this.settingsDestination});

  final String? settingsDestination;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String? _lockError;
  bool _showOnboarding = false;
  HarmonyEntryPresentation? _entry;
  Completer<String?>? _entryChoice;
  final TestingChannelConsentService _consentService =
      TestingChannelConsentService();

  @override
  void initState() {
    super.initState();
    _entry = context.read<HarmonyEntryPresentation?>();
    _bootstrap();
  }

  @override
  void dispose() {
    final choice = _entryChoice;
    if (choice != null && !choice.isCompleted) choice.complete(null);
    unawaited(_entry?.dismiss(this));
    super.dispose();
  }

  Future<void> _bootstrap() async {
    unawaited(_entry?.show(this, 'loading'));
    // Allow splash screen to render before heavy async work starts
    await Future.delayed(const Duration(milliseconds: 300));

    final canContinue = await _handleTestingChannelGate();
    if (!mounted || !canContinue) {
      return;
    }

    final appLockController = context.read<AppLockController?>();
    final appOpenUnlockReason = context.l10n.appLockUnlockReasonAppOpen;
    if (appLockController != null) {
      if (!appLockController.isLoaded) {
        await appLockController.load();
        if (!mounted) {
          return;
        }
        if (!appLockController.isLoaded) {
          _showStartupError(appLockController.lastError);
          return;
        }
      }

      while (mounted && appLockController.shouldRequireUnlockForAppOpen()) {
        final unlocked = await appLockController.authenticateForUnlock(
          reason: appOpenUnlockReason,
        );
        if (!mounted) {
          return;
        }
        if (unlocked) {
          break;
        }

        final l10n = context.l10n;
        final message = appLockController.lastError ?? l10n.appLockAuthFailed;
        final nativeChoice = await _chooseNative(
          'authRetry',
          title: l10n.appLockTitle,
          message: message,
        );
        if (!mounted) return;
        final retry = nativeChoice != null
            ? nativeChoice == 'retry'
            : await ConfirmActionSheetWidget.show(
                context,
                title: l10n.appLockTitle,
                message: message,
                confirmLabel: l10n.commonRetry,
              );

        if (retry != true) {
          if (mounted) {
            _showStartupError(appLockController.lastError ?? appOpenUnlockReason);
          }
          return;
        }
        unawaited(_entry?.show(this, 'loading'));
      }
    }

    if (!mounted) {
      return;
    }

    final destination = widget.settingsDestination;
    if (await OnboardingService().shouldShowOnboarding()) {
      if (!mounted) return;
      if (destination == null) {
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      } else {
        setState(() => _showOnboarding = true);
      }
      return;
    }
    if (!mounted) return;
    if (destination != null) {
      Navigator.pushReplacementNamed(context, destination);
      return;
    }
    final configs = await ApiConfigManager.getServerMetadata();
    if (mounted) {
      Navigator.pushReplacementNamed(context, configs.isEmpty ? AppRoutes.serverConfig : AppRoutes.home);
    }
  }

  void _showStartupError(String? message) {
    setState(() => _lockError = message);
    unawaited(_entry?.show(
      this,
      'startupError',
      title: context.l10n.appLockTitle,
      message: message ?? context.l10n.appLockAuthFailed,
      onAction: (action) {
        if (mounted && action == 'retry') _retryStartup();
      },
    ));
  }

  void _retryStartup() {
    setState(() => _lockError = null);
    unawaited(_bootstrap());
  }

  Future<String?> _chooseNative(
    String page, {
    required String title,
    String message = '',
    bool requireConsent = false,
  }) async {
    final entry = _entry;
    if (entry == null || !entry.enabled) return null;
    final choice = Completer<String?>();
    _entryChoice = choice;
    final shown = await entry.show(
      this,
      page,
      title: title,
      message: message,
      requireConsent: requireConsent,
      onAction: (action) {
        if (!choice.isCompleted) choice.complete(action);
      },
    );
    if (!shown) {
      _entryChoice = null;
      return null;
    }
    final action = await choice.future;
    _entryChoice = null;
    return action;
  }

  Future<bool> _handleTestingChannelGate() async {
    if (!AppReleaseChannelConfig.shouldShowColdStartWarning) {
      return true;
    }

    final consentState = await _consentService.readState(
      AppReleaseChannelConfig.channelStorageValue,
    );

    if (!mounted) {
      return false;
    }

    final requireConsent = AppReleaseChannelConfig.shouldRequireConsent &&
        consentState.requiresConsent;
    final l10n = context.l10n;
    final nativeChoice = await _chooseNative(
      'warning',
      title: l10n.testingWarningDialogTitle(_channelLabel(l10n)),
      requireConsent: requireConsent,
    );
    if (!mounted) return false;
    final confirmed = nativeChoice != null
        ? nativeChoice == 'continue'
        : await _showTestingWarningDialog(requireConsent: requireConsent);

    if (!mounted) {
      return false;
    }

    if (!confirmed) {
      await SystemNavigator.pop();
      return false;
    }

    if (consentState.requiresConsent) {
      await _consentService.markAccepted(consentState);
    }
    if (mounted) unawaited(_entry?.show(this, 'loading'));

    return true;
  }

  Future<bool> _showTestingWarningDialog({required bool requireConsent}) async {
    final l10n = context.l10n;
    final channelLabel = _channelLabel(l10n);
    var agreed = !requireConsent;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            final dialogL10n = dialogContext.l10n;
            final dialogSpec = AdaptiveLayoutSpec.of(dialogContext);
            return AlertDialog(
              key: const Key('testing-warning-dialog'),
              constraints: dialogSpec.dialogConstraints,
              insetPadding: dialogSpec.dialogInsetPadding,
              title: Text(dialogL10n.testingWarningDialogTitle(channelLabel)),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(dialogL10n.testingWarningDialogBody),
                    const SizedBox(height: 12),
                    Text('• ${dialogL10n.testingWarningRiskUnstable}'),
                    const SizedBox(height: 6),
                    Text('• ${dialogL10n.testingWarningRiskDataLoss}'),
                    const SizedBox(height: 6),
                    Text('• ${dialogL10n.testingWarningRiskNoProd}'),
                    if (requireConsent) ...[
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: agreed,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(dialogL10n.testingWarningConsentText),
                        onChanged: (value) {
                          setState(() {
                            agreed = value ?? false;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(dialogL10n.testingWarningExit),
                ),
                FilledButton(
                  onPressed: agreed
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  child: Text(
                    requireConsent
                        ? dialogL10n.testingWarningAgreeAndContinue
                        : dialogL10n.testingWarningContinue,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }

  String _channelLabel(AppLocalizations l10n) {
    switch (AppReleaseChannelConfig.current) {
      case AppReleaseChannel.preview:
        return l10n.releaseChannelPreview;
      case AppReleaseChannel.alpha:
        return l10n.releaseChannelAlpha;
      case AppReleaseChannel.beta:
        return l10n.releaseChannelBeta;
      case AppReleaseChannel.preRelease:
        return l10n.releaseChannelPreRelease;
      case AppReleaseChannel.release:
        return l10n.releaseChannelRelease;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingPage(settingsDestination: widget.settingsDestination);
    }
    final l10n = context.l10n;
    if (_lockError != null) {
      return Scaffold(
        body: ModuleErrorStateWidget(message: _lockError, onRetry: _retryStartup),
      );
    }
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/branding/app_icon_preview.png',
                width: 72,
                height: 72,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.appName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l10n.commonLoading),
          ],
        ),
      ),
    );
  }
}

class LegacyRedirectPage extends StatelessWidget {
  const LegacyRedirectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.route_outlined, size: 56),
              const SizedBox(height: 16),
              Text(l10n.legacyRouteRedirect, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.home),
                child: Text(l10n.commonConfirm),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text(l10n.notFoundTitle)),
      body: Center(child: Text(l10n.notFoundDesc)),
    );
  }
}
