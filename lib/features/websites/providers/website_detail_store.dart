import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/data/models/website_models.dart';
import 'package:onepanel_client/data/repositories/website_repository.dart';

/// Single source of truth for [WebsiteInfo] across all website sub-providers.
///
/// Previously, 4 providers (WebsiteDetailProvider, WebsiteLifecycleProvider,
/// WebsiteConfigProvider, WebsiteConfigCenterProvider) each independently
/// called `WebsiteRepository.getWebsiteDetail(websiteId)`, resulting in up
/// to 5 redundant API calls for the same website. This store caches the
/// detail and broadcasts updates so all providers share one fetch
/// (architecture review candidate ⑳/⑪).
///
/// Providers inject this store and call [load] (once) or [refresh] (after
/// mutations). They read [website] to access the cached data.
class WebsiteDetailStore extends ChangeNotifier with SafeChangeNotifier {
  WebsiteDetailStore({
    required int websiteId,
    WebsiteRepository? repository,
  })  : _websiteId = websiteId,
        _repository = repository ?? WebsiteRepository();

  final int _websiteId;
  final WebsiteRepository _repository;

  WebsiteInfo? _website;
  bool _isLoading = false;
  String? _error;

  WebsiteInfo? get website => _website;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetches the website detail and caches it. Subsequent callers that
  /// arrive while a fetch is in-flight share the same future (dedup).
  Future<WebsiteInfo?> load() async {
    if (_isLoading) return _website;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _website = await _repository.getWebsiteDetail(_websiteId);
    } catch (e) {
      _error = ErrorMessageUtils.userFacingMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _website;
  }

  /// Forces a fresh fetch (use after mutations like update/operate).
  Future<WebsiteInfo?> refresh() => load();

  /// Updates the cached website in-place without an API call (use when the
  /// mutation already returned the updated data).
  void update(WebsiteInfo updated) {
    _website = updated;
    notifyListeners();
  }
}
