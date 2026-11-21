import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/features/settings/widgets/settings_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';

class MainlandSdkDisclosurePage extends StatefulWidget {
  const MainlandSdkDisclosurePage({super.key});

  @override
  State<MainlandSdkDisclosurePage> createState() =>
      _MainlandSdkDisclosurePageState();
}

class _MainlandSdkDisclosurePageState extends State<MainlandSdkDisclosurePage> {
  static Future<List<String>> _packagesFuture = _collectPackages();

  static Future<List<String>> _collectPackages() async {
    final packages = <String>{};
    try {
      await for (final license in LicenseRegistry.licenses) {
        packages.addAll(license.packages.where((pkg) => pkg.trim().isNotEmpty));
      }
    } catch (error, stackTrace) {
      appLogger.eWithPackage('settings.licenses', '读取依赖清单失败',
          error: error, stackTrace: stackTrace);
      rethrow;
    }

    packages.remove('onepanel_client');

    return packages.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  void _refresh() {
    setState(() {
      _packagesFuture = _collectPackages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FutureBuilder<List<String>>(
      future: _packagesFuture,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final packages = snapshot.data ?? const <String>[];
        return SettingsScaffold(
          title: l10n.settingsMainlandSdkDisclosureTitle,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              tooltip: l10n.commonRefresh,
              onPressed: loading ? null : _refresh,
            ),
          ],
          body: AsyncStatePageBodyWidget(
            isLoading: loading && !snapshot.hasData,
            errorMessage: !loading && snapshot.hasError
                ? ErrorMessageUtils.userFacingMessage(snapshot.error!)
                : null,
            onRetry: _refresh,
            child: ListView.builder(
              padding: AppDesignTokens.scrollPagePadding(context),
              itemCount: packages.isEmpty ? 2 : packages.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionCard(
                        padding: AppDesignTokens.pagePadding,
                        child: Text(l10n.settingsMainlandSdkNone),
                      ),
                      const SizedBox(height: AppDesignTokens.spacingLg),
                      SectionTitle(l10n.settingsMainlandSdkAutoScanTitle),
                    ],
                  );
                }
                if (packages.isEmpty) {
                  return ListTile(
                      title: Text(l10n.settingsMainlandSdkAutoScanEmpty));
                }
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.extension_outlined),
                  title: Text(packages[index - 1]),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
