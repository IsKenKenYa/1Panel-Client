import 'package:flutter/foundation.dart';

import '../../../data/models/website_group_models.dart';
import '../../../data/models/website_models.dart';
import '../services/website_service.dart';

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
  final List<WebsiteGroup> groups;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;
  final String query;
  final String? typeFilter;
  final int? groupFilterId;

  const WebsitesData({
    this.websites = const [],
    this.stats = const WebsiteStats(),
    this.groups = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
    this.query = '',
    this.typeFilter,
    this.groupFilterId,
  });

  WebsitesData copyWith({
    List<WebsiteInfo>? websites,
    WebsiteStats? stats,
    List<WebsiteGroup>? groups,
    bool? isLoading,
    Object? error = _unset,
    DateTime? lastUpdated,
    String? query,
    Object? typeFilter = _unset,
    Object? groupFilterId = _unset,
  }) {
    return WebsitesData(
      websites: websites ?? this.websites,
      stats: stats ?? this.stats,
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      query: query ?? this.query,
      typeFilter:
          identical(typeFilter, _unset) ? this.typeFilter : typeFilter as String?,
      groupFilterId: identical(groupFilterId, _unset)
          ? this.groupFilterId
          : groupFilterId as int?,
    );
  }
}

class WebsitesProvider extends ChangeNotifier {
  WebsitesProvider({
    WebsiteService? service,
  }) : _service = service ?? WebsiteService();

  final WebsiteService _service;

  WebsitesData _data = const WebsitesData();
  WebsitesData get data => _data;

  Future<void> onServerChanged() async {
    _data = const WebsitesData();
    notifyListeners();
    await loadWebsites();
  }

  Future<void> loadWebsites({
    String? query,
    String? type,
    int? websiteGroupId,
  }) async {
    _data = _data.copyWith(
      isLoading: true,
      error: null,
      query: query ?? _data.query,
      typeFilter: type ?? _data.typeFilter,
      groupFilterId: websiteGroupId ?? _data.groupFilterId,
    );
    notifyListeners();

    try {
      final page = await _service.searchWebsites(
        name: _data.query.isEmpty ? null : _data.query,
        type: _data.typeFilter,
        page: 1,
        pageSize: 100,
      );
      final groups = await _service.listWebsiteGroups();
      final websites = _data.groupFilterId == null
          ? page.items
          : page.items
              .where((item) => item.webSiteGroupId == _data.groupFilterId)
              .toList(growable: false);
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
        groups: groups,
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

  Future<bool> batchOperate({
    required List<int> ids,
    required String action,
  }) {
    return _operate(() => _service.batchOperate(ids: ids, operate: action));
  }

  Future<bool> batchDelete(List<int> ids) {
    return _operate(() => _service.batchDelete(ids: ids));
  }

  Future<bool> batchSetGroup({
    required List<int> ids,
    required int groupId,
  }) {
    return _operate(() => _service.batchSetGroup(ids: ids, groupId: groupId));
  }

  Future<void> refresh() => loadWebsites(
        query: _data.query,
        type: _data.typeFilter,
        websiteGroupId: _data.groupFilterId,
      );

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
