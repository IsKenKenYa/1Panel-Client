import 'package:flutter/material.dart';

import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/data/models/website_models.dart';
import 'package:onepanel_client/data/models/website_group_models.dart';
import 'package:onepanel_client/features/websites/providers/websites_provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

import 'website_list_dialogs.dart';

void applyWebsiteFilters(
  WebsitesProvider provider, {
  required String query,
  required String? type,
  required int? websiteGroupId,
}) {
  provider.loadWebsites(
    query: query,
    type: type,
    websiteGroupId: websiteGroupId,
  );
}

void openWebsiteDetail(BuildContext context, WebsiteInfo website) {
  final id = website.id;
  if (id == null) return;
  Navigator.pushNamed(
    context,
    AppRoutes.websiteDetail,
    arguments: {'websiteId': id},
  );
}

Future<void> runWebsiteBatchDelete(
  BuildContext context, {
  required WebsitesProvider provider,
  required List<int> ids,
  required String? domain,
  required VoidCallback clearSelection,
}) async {
  final confirmed = await WebsiteListDialogs.confirmDelete(
    context,
    ids: ids,
    domain: domain,
  );
  if (!confirmed || !context.mounted) {
    return;
  }
  final l10n = context.l10n;
  final ok = await provider.batchDelete(ids);
  if (!context.mounted) {
    return;
  }
  if (ok) {
    clearSelection();
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok ? l10n.websitesDeleteSuccess : l10n.websitesOperateFailed,
      ),
    ),
  );
}

Future<void> runWebsiteBatchSetGroup(
  BuildContext context, {
  required WebsitesProvider provider,
  required List<int> ids,
  required List<WebsiteGroup> groups,
  required VoidCallback clearSelection,
}) async {
  final selectedId = await WebsiteListDialogs.selectBatchGroup(context, groups);
  if (selectedId == null) {
    return;
  }
  final ok = await provider.batchSetGroup(
    ids: ids,
    groupId: selectedId,
  );
  if (!context.mounted) {
    return;
  }
  if (ok) {
    clearSelection();
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok
            ? context.l10n.websitesOperateSuccess
            : context.l10n.websitesOperateFailed,
      ),
    ),
  );
}
