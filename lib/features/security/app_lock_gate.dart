import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/security/app_lock_controller.dart';
import 'package:provider/provider.dart';

class AppLockGate extends StatelessWidget {
  const AppLockGate({
    super.key,
    required this.target,
    required this.child,
    this.onVisibilityChanged,
  });

  final String? target;
  final Widget child;
  final ValueChanged<bool>? onVisibilityChanged;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppLockController?>();
    if (controller == null) {
      onVisibilityChanged?.call(true);
      return child;
    }
    final name = target;
    final locked = controller.requiresResumeUnlock ||
        (name == AppRoutes.settingsAppLock &&
            controller.isEnabled &&
            !controller.isSessionUnlocked) ||
        (name != null && controller.shouldRequireUnlockForModuleId(name));
    onVisibilityChanged?.call(!locked);
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeFocus(
          excluding: locked,
          child: Offstage(
            offstage: locked,
            child: TickerMode(enabled: !locked, child: child),
          ),
        ),
        if (locked) const AppLockUnlockView(),
      ],
    );
  }
}

class AppLockUnlockView extends StatelessWidget {
  const AppLockUnlockView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppLockController>();
    final l10n = context.l10n;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outlined),
                const SizedBox(height: 12),
                Text(l10n.appLockTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                if (controller.lastError != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(controller.lastError!),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: controller.isUnlocking
                      ? null
                      : () => controller.authenticateForUnlock(
                            reason: l10n.appLockUnlockReasonAppOpen,
                          ),
                  child: Text(l10n.appLockUnlockAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
