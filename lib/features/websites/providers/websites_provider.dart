import 'package:flutter/foundation.dart';

import '../../../api/v2/website_v2.dart';
import '../../../data/models/website_models.dart';
import '../services/websites_service.dart';

class WebsiteStats {
  final int total;
  final int running;
  final int stopped;

  const WebsiteStats({
    this.total = 0,
    this.running = 0,
    this.stopped = 0,
  });
}

class WebsitesData {
  static const _unset = Object();

  final List<WebsiteInfo> websites;
  final WebsiteStats stats;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const WebsitesData({
    this.websites = const [],
    this.stats = const WebsiteStats(),
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  WebsitesData copyWith({
    List<WebsiteInfo>? websites,
    WebsiteStats? stats,
    bool? isLoading,
    Object? error = _unset,
    DateTime? lastUpdated,
  }) {
    return WebsitesData(
      websites: websites ?? this.websites,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class WebsitesProvider extends ChangeNotifier {
  WebsitesProvider({
    WebsitesService? service,
    WebsiteV2Api? websiteApi,
  }) : _service = service ?? WebsitesService() {
    if (websiteApi != null) {
      _service = _WebsitesServiceAdapter(websiteApi);
    }
  }

  WebsitesService _service;

  WebsitesData _data = const WebsitesData();
  WebsitesData get data => _data;

  Future<void> loadWebsites() async {
    _data = _data.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final websites = await _service.fetchWebsites(page: 1, pageSize: 100);
      var running = 0;
      var stopped = 0;
      for (final website in websites) {
        if (website.status?.toLowerCase() == 'running') {
          running++;
        } else {
          stopped++;
        }
      }

      _data = _data.copyWith(
        websites: websites,
        stats: WebsiteStats(
          total: websites.length,
          running: running,
          stopped: stopped,
        ),
        isLoading: false,
        error: null,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      _data = _data.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
    notifyListeners();
  }

  Future<bool> startWebsite(int websiteId) async {
    return _operate(() => _service.startWebsite(websiteId));
  }

  Future<bool> stopWebsite(int websiteId) async {
    return _operate(() => _service.stopWebsite(websiteId));
  }

  Future<bool> restartWebsite(int websiteId) async {
    return _operate(() => _service.restartWebsite(websiteId));
  }

  Future<bool> deleteWebsite(int websiteId) async {
    return _operate(() => _service.deleteWebsite(websiteId));
  }

  Future<void> refresh() => loadWebsites();

  void clearError() {
    _data = _data.copyWith(error: null);
    notifyListeners();
  }

  Future<bool> _operate(Future<void> Function() action) async {
    try {
      await action();
      await loadWebsites();
      return true;
    } catch (e) {
      _data = _data.copyWith(error: e.toString());
      notifyListeners();
      return false;
    }
  }
}

class _WebsitesServiceAdapter extends WebsitesService {
  final WebsiteV2Api _websiteApi;

  _WebsitesServiceAdapter(this._websiteApi);

  @override
  Future<List<WebsiteInfo>> fetchWebsites({int page = 1, int pageSize = 100}) async {
    final result = await _websiteApi.getWebsites(page: page, pageSize: pageSize);
    return result.items;
  }

  @override
  Future<void> operateWebsite({required int websiteId, required String action}) {
    return _websiteApi.operateWebsite(id: websiteId, operate: action);
  }

  @override
  Future<void> deleteWebsite(int websiteId) {
    return _websiteApi.deleteWebsite(websiteId);
  }
}
