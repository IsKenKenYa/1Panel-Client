import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';

import '../providers/website_lifecycle_provider.dart';
import '../widgets/website_async_state_view.dart';
import '../widgets/website_lifecycle_form_widgets.dart';

class WebsiteCreateFlowPage extends StatelessWidget {
  const WebsiteCreateFlowPage({
    super.key,
    this.provider,
  })  : mode = WebsiteLifecycleMode.create,
        websiteId = null;

  const WebsiteCreateFlowPage.edit({
    super.key,
    required this.websiteId,
    this.provider,
  }) : mode = WebsiteLifecycleMode.edit;

  final WebsiteLifecycleMode mode;
  final int? websiteId;
  final WebsiteLifecycleProvider? provider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          provider ??
          WebsiteLifecycleProvider(
            mode: mode,
            websiteId: websiteId,
          )..load(),
      child: _WebsiteLifecycleBody(mode: mode),
    );
  }
}

class _WebsiteLifecycleBody extends StatelessWidget {
  const _WebsiteLifecycleBody({required this.mode});

  final WebsiteLifecycleMode mode;

  bool get isEditMode => mode == WebsiteLifecycleMode.edit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<WebsiteLifecycleProvider>(
      builder: (context, provider, _) {
        final state = provider.state;
        final title = isEditMode
            ? l10n.websitesLifecycleEditTitle
            : l10n.websitesLifecycleCreateTitle;
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: WebsiteAsyncStateView(
            isLoading: state.isLoading,
            error: state.isLoading ? null : _messageFor(context, state.error),
            onRetry: provider.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!isEditMode) ...[
                  WebsiteLifecycleTextFieldCard(
                    label: l10n.websitesAliasLabel,
                    initialValue: state.alias,
                    onChanged: provider.setAlias,
                  ),
                  const SizedBox(height: 12),
                  WebsiteLifecycleTypeCard(
                    value: state.type,
                    onChanged: provider.setType,
                  ),
                  const SizedBox(height: 12),
                ],
                WebsiteLifecycleTextFieldCard(
                  label: l10n.websitesPrimaryDomainLabel,
                  initialValue: state.primaryDomain,
                  onChanged: provider.setPrimaryDomain,
                ),
                const SizedBox(height: 12),
                WebsiteLifecycleGroupCard(
                  groups: state.groups,
                  value: state.groupId,
                  onChanged: provider.setGroupId,
                ),
                const SizedBox(height: 12),
                WebsiteLifecycleTextFieldCard(
                  label: l10n.websitesRemarkLabel,
                  initialValue: state.remark,
                  maxLines: 3,
                  onChanged: provider.setRemark,
                ),
                if (!isEditMode) ...[
                  const SizedBox(height: 12),
                  if (state.type == 'runtime')
                    WebsiteLifecycleRuntimeCard(
                      runtimes: state.runtimes,
                      value: state.runtimeId,
                      siteDir: state.siteDir,
                      onRuntimeChanged: provider.setRuntimeId,
                      onSiteDirChanged: provider.setSiteDir,
                    ),
                  if (state.type == 'proxy')
                    WebsiteLifecycleProxyCard(
                      proxyType: state.proxyType,
                      proxyAddress: state.proxyAddress,
                      port: state.port,
                      onProxyTypeChanged: provider.setProxyType,
                      onProxyAddressChanged: provider.setProxyAddress,
                      onPortChanged: provider.setPort,
                    ),
                  if (state.type == 'subsite')
                    WebsiteLifecycleParentCard(
                      websites: state.parentWebsites,
                      value: state.parentWebsiteId,
                      onChanged: provider.setParentWebsiteId,
                    ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          final ok = await provider.submit();
                          if (!context.mounted || !ok) return;
                          navigator.pop(true);
                        },
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.commonSave),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _messageFor(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    switch (value) {
      case 'group':
        return context.l10n.websitesValidationGroupRequired;
      case 'domain':
        return context.l10n.websitesValidationPrimaryDomainRequired;
      case 'alias':
        return context.l10n.websitesValidationAliasRequired;
      case 'runtime':
        return context.l10n.websitesValidationRuntimeRequired;
      case 'proxy':
        return context.l10n.websitesValidationProxyRequired;
      case 'parent':
        return context.l10n.websitesValidationParentRequired;
      default:
        return value;
    }
  }
}
