import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/security/app_lock_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:provider/provider.dart';

class AppLockSettingsPage extends StatelessWidget {
  const AppLockSettingsPage({super.key});

  static const List<int> _relockOptions = <int>[1, 5, 10, 30, 60];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appLockTitle)),
      body: Consumer<AppLockController>(
        builder: (context, controller, child) {
          if (!controller.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = controller.settings;
          final protectedModuleIds = settings.protectedModuleIds.toSet();
          final moduleOptions = kPinnableClientModules
              .where((module) => module.requiresServer)
              .toList(growable: false);

          return ListView(
            padding: AppDesignTokens.pagePadding,
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(l10n.appLockDeviceAuthStatus),
                  subtitle: Text(
                    controller.canUseLocalAuth
                        ? l10n.appLockDeviceAuthSupported
                        : (controller.availability.reason ??
                            l10n.appLockDeviceAuthUnsupported),
                  ),
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              Card(
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.lock_outline),
                      title: Text(l10n.appLockEnable),
                      subtitle: Text(l10n.appLockEnableDesc),
                      value: settings.enabled,
                      onChanged: controller.isUnlocking
                          ? null
                          : (value) async {
                              if (value) {
                                final success =
                                    await controller.enableWithVerification(
                                  reason: l10n.appLockUnlockReasonEnable,
                                );
                                if (!context.mounted) {
                                  return;
                                }
                                if (!success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(controller.lastError ??
                                          l10n.appLockAuthFailed),
                                    ),
                                  );
                                }
                                return;
                              }

                              await controller.disable();
                            },
                    ),
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.home_outlined),
                      title: Text(l10n.appLockLockOnAppOpen),
                      subtitle: Text(l10n.appLockLockOnAppOpenDesc),
                      value: settings.lockOnAppOpen,
                      onChanged: settings.enabled
                          ? (value) => controller.updateLockOnAppOpen(value)
                          : null,
                    ),
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.shield_outlined),
                      title: Text(l10n.appLockLockOnProtectedModule),
                      subtitle: Text(l10n.appLockLockOnProtectedModuleDesc),
                      value: settings.lockOnProtectedModule,
                      onChanged: settings.enabled
                          ? (value) =>
                              controller.updateLockOnProtectedModule(value)
                          : null,
                    ),
                    ListTile(
                      leading: const Icon(Icons.timer_outlined),
                      title: Text(l10n.appLockRelockAfterMinutes),
                      trailing: DropdownButton<int>(
                        value: settings.relockAfterMinutes,
                        onChanged: settings.enabled
                            ? (value) {
                                if (value == null) {
                                  return;
                                }
                                controller.updateRelockAfterMinutes(value);
                              }
                            : null,
                        items: _relockOptions
                            .map(
                              (minutes) => DropdownMenuItem<int>(
                                value: minutes,
                                child: Text(
                                  l10n.appLockRelockAfterMinutesOption(minutes),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              Card(
                child: Padding(
                  padding: AppDesignTokens.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.appLockProtectedModules,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: settings.enabled &&
                                    settings.lockOnProtectedModule
                                ? () {
                                    controller.updateProtectedModuleIds(
                                      moduleOptions
                                          .map((module) => module.storageId)
                                          .toList(growable: false),
                                    );
                                  }
                                : null,
                            child: Text(l10n.appLockSelectAll),
                          ),
                          TextButton(
                            onPressed: settings.enabled &&
                                    settings.lockOnProtectedModule
                                ? () {
                                    controller.updateProtectedModuleIds(
                                        const <String>[]);
                                  }
                                : null,
                            child: Text(l10n.appLockClearAll),
                          ),
                        ],
                      ),
                      if (!settings.lockOnProtectedModule)
                        Padding(
                          padding: const EdgeInsets.only(
                              top: AppDesignTokens.spacingSm),
                          child: Text(
                            l10n.appLockNoProtectedModules,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      else
                        ...moduleOptions.map(
                          (module) => CheckboxListTile.adaptive(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(module.label(l10n)),
                            value:
                                protectedModuleIds.contains(module.storageId),
                            onChanged: settings.enabled
                                ? (checked) {
                                    final next = Set<String>.from(
                                      protectedModuleIds,
                                    );
                                    if (checked == true) {
                                      next.add(module.storageId);
                                    } else {
                                      next.remove(module.storageId);
                                    }
                                    controller.updateProtectedModuleIds(
                                      next.toList(growable: false),
                                    );
                                  }
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
