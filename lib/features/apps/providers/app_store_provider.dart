import 'package:flutter/foundation.dart';
import '../../../data/models/app_models.dart';
import '../app_service.dart';

class AppStoreProvider extends ChangeNotifier {
  final AppService _appService;
  bool _disposed = false;

  AppStoreProvider({AppService? appService})
      : _appService = appService ?? AppService();

  List<AppItem> _apps = [];
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  int _pageSize = 20;
  int _total = 0;
  bool _hasMore = true;

  List<AppItem> get apps => _apps;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  void _notifySafely() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  Future<void> onServerChanged() async {
    _appService.resetForServerChange();
    _apps = [];
    _page = 1;
    _total = 0;
    _hasMore = true;
    _isLoading = false;
    _error = null;
    _notifySafely();
    await loadApps(refresh: true);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> loadApps({
    bool refresh = false,
    int pageSize = 20,
    String? name,
    String? type,
    String? resource,
    bool? recommend,
    List<String>? tags,
  }) async {
    if (_isLoading) return;
    if (!refresh && !_hasMore) return;

    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      if (refresh) {
        _page = 1;
        _apps = [];
      } else {
        _page++;
      }
      _pageSize = pageSize;

      final request = AppSearchRequest(
        page: _page,
        pageSize: _pageSize,
        name: name,
        type: type,
        resource: resource,
        recommend: recommend,
        tags: tags,
      );
      final response = await _appService.searchApps(request);

      if (refresh) {
        _apps = response.items;
      } else {
        _apps.addAll(response.items);
      }
      _total = response.total;
      _hasMore = _apps.length < _total;
    } catch (e) {
      _error = e.toString();
      if (!refresh && _page > 1) {
        _page--; // Revert page increment on failure
      }
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<void> installApp(AppInstallCreateRequest request) async {
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      await _appService.installApp(request);
    } catch (e) {
      _error = 'Installation failed: ${e.toString()}';
      rethrow;
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<void> syncApps() async {
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      await _appService.syncRemoteApps();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<void> syncLocalApps() async {
    _isLoading = true;
    _error = null;
    _notifySafely();

    try {
      await _appService.syncLocalApps();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<List<AppInstallInfo>> loadIgnoredUpdates() async {
    return _appService.getIgnoredAppDetails();
  }

  Future<void> cancelIgnoreUpdate(int appInstallId) async {
    await _appService.cancelIgnoreAppUpdate(
      AppInstalledIgnoreUpgradeRequest(
        appInstallId: appInstallId,
        reason: '',
      ),
    );
  }
}
