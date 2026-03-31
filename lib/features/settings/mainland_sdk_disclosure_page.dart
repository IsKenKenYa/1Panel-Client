import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class MainlandSdkDisclosurePage extends StatefulWidget {
  const MainlandSdkDisclosurePage({super.key});

  @override
  State<MainlandSdkDisclosurePage> createState() =>
      _MainlandSdkDisclosurePageState();
}

class _MainlandSdkDisclosurePageState extends State<MainlandSdkDisclosurePage> {
  late Future<List<String>> _packagesFuture;

  @override
  void initState() {
    super.initState();
    _packagesFuture = _collectPackages();
  }

  Future<List<String>> _collectPackages() async {
    final packages = <String>{};

    await for (final license in LicenseRegistry.licenses) {
      packages.addAll(license.packages.where((pkg) => pkg.trim().isNotEmpty));
    }

    packages.remove('onepanel_client');

    final sorted = packages.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsMainlandSdkDisclosureTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: l10n.commonRefresh,
            onPressed: () {
              setState(() {
                _packagesFuture = _collectPackages();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _packagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final packages = snapshot.data ?? const <String>[];

          return ListView(
            padding: AppDesignTokens.pagePadding,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsMainlandSdkDisclaimer,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.settingsMainlandSdkNone,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              Text(
                l10n.settingsMainlandSdkAutoScanTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppDesignTokens.spacingSm),
              Card(
                child: packages.isEmpty
                    ? ListTile(
                        title: Text(l10n.settingsMainlandSdkAutoScanEmpty),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: packages.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final packageName = packages[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.extension_outlined),
                            title: Text(packageName),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
