import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/settings/widgets/settings_scaffold.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/security/app_lock_controller.dart';
import 'package:onepanel_client/features/security/app_lock_gate.dart';
import 'package:onepanel_client/features/settings/widgets/settings_save_action.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
import 'package:provider/provider.dart';

class AppLockSettingsPage extends StatelessWidget {
  const AppLockSettingsPage({super.key});

  static const List<int> _relockOptions = <int>[1, 5, 10, 30, 60];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SettingsScaffold(
      title: l10n.appLockTitle,
      body: Consumer<AppLockController>(
        builder: (context, controller, child) {
          if (!controller.isLoaded) {
            if (controller.lastError != null) {
              return ModuleErrorStateWidget(
                message: controller.lastError,
                onRetry: controller.load,
              );
            }
            return const Center(child: CircularProgressIndicator());
          }

          final settings = controller.settings;
          if (settings.enabled && !controller.isSessionUnlocked) {
            return const AppLockUnlockView();
          }
          final relockOptions = {
            ..._relockOptions,
            settings.relockAfterMinutes,
          }.toList()
            ..sort();
          final protectedModuleIds = settings.protectedModuleIds.toSet();
          final moduleOptions = kPinnableClientModules
              .where((module) => module.requiresServer)
              .toList(growable: false);

          return ListView(
            padding: AppDesignTokens.scrollPagePadding(context),
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
                      secondary: const Icon(Icons.lock_outlined),
                      title: Text(l10n.appLockEnable),
                      subtitle: Text(l10n.appLockEnableDesc),
                      value: settings.enabled,
                      onChanged: controller.isUnlocking
                          ? null
                          : (value) => saveAppPreference(context, () async {
                                if (value) {
                                  final success =
                                      await controller.enableWithVerification(
                                    reason: l10n.appLockUnlockReasonEnable,
                                  );
                                  if (!context.mounted) {
                                    return;
                                  }
                                  if (!success) {
                                    SnackBarUtils.showError(
                                      context,
                                      controller.lastError ??
                                          l10n.appLockAuthFailed,
                                    );
                                  }
                                  return;
                                }

                                await controller.disable();
                              }),
                    ),
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.home_outlined),
                      title: Text(l10n.appLockLockOnAppOpen),
                      subtitle: Text(l10n.appLockLockOnAppOpenDesc),
                      value: settings.lockOnAppOpen,
                      onChanged: settings.enabled
                          ? (value) => saveAppPreference(
                                context,
                                () => controller.updateLockOnAppOpen(value),
                              )
                          : null,
                    ),
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.shield_outlined),
                      title: Text(l10n.appLockLockOnProtectedModule),
                      subtitle: Text(l10n.appLockLockOnProtectedModuleDesc),
                      value: settings.lockOnProtectedModule,
                      onChanged: settings.enabled
                          ? (value) => saveAppPreference(
                                context,
                                () => controller.updateLockOnProtectedModule(
                                  value,
                                ),
                              )
                          : null,
                    ),
                    ListTile(
                      leading: const Icon(Icons.timer_outlined),
                      title: Text(l10n.appLockRelockAfterMinutes),
                      subtitle: DropdownButton<int>(
                        isExpanded: true,
                        value: settings.relockAfterMinutes,
                        onChanged: settings.enabled
                            ? (value) {
                                if (value == null) {
                                  return;
                                }
                                saveAppPreference(
                                  context,
                                  () => controller.updateRelockAfterMinutes(
                                    value,
                                  ),
                                );
                              }
                            : null,
                        items: relockOptions
                            .map(
                              (minutes) => DropdownMenuItem<int>(
                                value: minutes,
                                child: Text(
                                  l10n.appLockRelockAfterMinutesOption(
                                    minutes,
                                  ),
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
                      Wrap(
                        spacing: AppDesignTokens.spacingSm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            l10n.appLockProtectedModules,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TextButton(
                            onPressed: settings.enabled &&
                                    settings.lockOnProtectedModule
                                ? () {
                                    saveAppPreference(
                                      context,
                                      () => controller.updateProtectedModuleIds(
                                        moduleOptions
                                            .map(
                                              (module) => module.storageId,
                                            )
                                            .toList(growable: false),
                                      ),
                                    );
                                  }
                                : null,
                            child: Text(l10n.appLockSelectAll),
                          ),
                          TextButton(
                            onPressed: settings.enabled &&
                                    settings.lockOnProtectedModule
                                ? () {
                                    saveAppPreference(
                                      context,
                                      () => controller.updateProtectedModuleIds(
                                        const <String>[],
                                      ),
                                    );
                                  }
                                : null,
                            child: Text(l10n.appLockClearAll),
                          ),
                        ],
                      ),
                      if (!settings.lockOnProtectedModule)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppDesignTokens.spacingSm,
                          ),
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
                            value: protectedModuleIds.contains(
                              module.storageId,
                            ),
                            onChanged: settings.enabled
                                ? (checked) {
                                    saveAppPreference(
                                      context,
                                      () => controller.setModuleProtected(
                                        module.storageId,
                                        checked == true,
                                      ),
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
