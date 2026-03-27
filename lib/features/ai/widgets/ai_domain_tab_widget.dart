import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/ai/ai_provider.dart';
import 'package:onepanel_client/features/ai/widgets/ai_domain_tab_actions.dart';
import 'package:provider/provider.dart';

class AIDomainTabWidget extends StatefulWidget {
  const AIDomainTabWidget({super.key});

  @override
  State<AIDomainTabWidget> createState() => _AIDomainTabWidgetState();
}

class _AIDomainTabWidgetState extends State<AIDomainTabWidget> {
  final _formKey = GlobalKey<FormState>();
  final _appInstallIdController = TextEditingController();
  final _domainController = TextEditingController();
  final _ipListController = TextEditingController();
  final _sslIdController = TextEditingController();
  final _websiteIdController = TextEditingController();

  @override
  void dispose() {
    _appInstallIdController.dispose();
    _domainController.dispose();
    _ipListController.dispose();
    _sslIdController.dispose();
    _websiteIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer<AIProvider>(
      builder: (context, provider, _) {
        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.aiDomainHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _appInstallIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.aiAppInstallIdLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = AIDomainTabActions.parseInt(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return l10n.aiAppInstallIdRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _domainController,
                decoration: InputDecoration(
                  labelText: l10n.websitesDomainLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.websitesDomainValidationRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ipListController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.aiIpAllowListLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sslIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.aiSslIdOptionalLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _websiteIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.aiWebsiteIdOptionalLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () => AIDomainTabActions.loadDomainBinding(
                              context,
                              appInstallIdController: _appInstallIdController,
                              domainController: _domainController,
                              ipListController: _ipListController,
                              sslIdController: _sslIdController,
                              websiteIdController: _websiteIdController,
                            ),
                    icon: const Icon(Icons.download_outlined),
                    label: Text(l10n.aiLoadBinding),
                  ),
                  FilledButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () => AIDomainTabActions.submitDomainBinding(
                              context,
                              formKey: _formKey,
                              appInstallIdController: _appInstallIdController,
                              domainController: _domainController,
                              ipListController: _ipListController,
                              sslIdController: _sslIdController,
                              websiteIdController: _websiteIdController,
                            ),
                    icon: const Icon(Icons.save_outlined),
                    label: Text(l10n.aiBindDomain),
                  ),
                ],
              ),
              if (provider.bindDomainInfo != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aiCurrentBinding,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${l10n.websitesDomainLabel}: ${provider.bindDomainInfo?.domain ?? '-'}',
                        ),
                        Text(
                          '${l10n.aiConnUrl}: ${provider.bindDomainInfo?.connUrl ?? '-'}',
                        ),
                        Text(
                          '${l10n.aiIpAllowListLabel}: ${(provider.bindDomainInfo?.allowIPs ?? const <String>[]).join(', ')}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
