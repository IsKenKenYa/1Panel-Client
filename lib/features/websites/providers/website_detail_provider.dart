import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';

import '../../../data/models/website_models.dart';
import '../../../data/repositories/website_repository.dart';
import 'website_detail_store.dart';

class WebsiteDetailProvider extends ChangeNotifier with SafeChangeNotifier {
  final int websiteId;
  final WebsiteRepository _repository;
  final WebsiteDetailStore? _store;

  WebsiteDetailProvider({
    required this.websiteId,
    WebsiteRepository? repository,
    WebsiteDetailStore? store,
  })  : _repository = repository ?? WebsiteRepository(),
        _store = store;

  bool isLoading = false;
  String? error;
  WebsiteInfo? website;

  Future<void> loadDetail() async {
    if (isDisposed) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // When a WebsiteDetailStore is available (SSOT), read from it to
      // avoid redundant API calls across sibling providers.
      website = _store != null
          ? await _store.load()
          : await _repository.getWebsiteDetail(websiteId);
      // Guard against notifying a disposed listener after the async gap.
      if (isDisposed) return;
    } catch (e) {
      if (!isDisposed) {
        error = ErrorMessageUtils.userFacingMessage(e);
      }
    } finally {
      if (!isDisposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> operate(String action) async {
    if (isDisposed) return;
    await _repository.operateWebsite(websiteId: websiteId, action: action);
    await loadDetail();
  }

  Future<void> setDefaultServer() async {
    if (isDisposed) return;
    await _repository.changeDefaultServer(id: websiteId);
    await loadDetail();
  }

  Future<void> deleteWebsite() async {
    if (isDisposed) return;
    await _repository.deleteWebsite(websiteId);
  }
}
