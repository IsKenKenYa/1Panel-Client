import 'package:flutter/foundation.dart';
import '../../api/v2/website_v2.dart';
import '../../core/network/api_client_manager.dart';
import '../../data/models/website_models.dart';

/// 网站统计数据
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

/// 网站数据状态
class WebsitesData {
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
    String? error,
    DateTime? lastUpdated,
  }) {
    return WebsitesData(
      websites: websites ?? this.websites,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// 网站管理状态管理器
class WebsitesProvider extends ChangeNotifier {
  WebsitesProvider({WebsiteV2Api? websiteApi}) : _websiteApi = websiteApi;

  WebsiteV2Api? _websiteApi;

  WebsitesData _data = const WebsitesData();

  WebsitesData get data => _data;

  /// 获取API客户端
  Future<void> _ensureApiClient() async {
    if (_websiteApi == null) {
      final manager = ApiClientManager.instance;
      _websiteApi = await manager.getWebsiteApi();
    }
  }

  /// 加载网站列表
  Future<void> loadWebsites() async {
    _data = _data.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      await _ensureApiClient();

      // 获取网站列表
      final result = await _websiteApi!.getWebsites(
        page: 1,
        pageSize: 100,
      );

      final websites = result.items;

      // 计算统计
      int running = 0, stopped = 0;
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
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      _data = _data.copyWith(
        isLoading: false,
        error: '加载网站列表失败: $e',
      );
    }
    notifyListeners();
  }

  /// 启动网站
  Future<bool> startWebsite(int websiteId) async {
    try {
      await _ensureApiClient();
      await _websiteApi!.startWebsite(websiteId);
      await loadWebsites(); // 刷新列表
      return true;
    } catch (e) {
      _data = _data.copyWith(error: '启动网站失败: $e');
      notifyListeners();
      return false;
    }
  }

  /// 停止网站
  Future<bool> stopWebsite(int websiteId) async {
    try {
      await _ensureApiClient();
      await _websiteApi!.stopWebsite(websiteId);
      await loadWebsites(); // 刷新列表
      return true;
    } catch (e) {
      _data = _data.copyWith(error: '停止网站失败: $e');
      notifyListeners();
      return false;
    }
  }

  /// 重启网站
  Future<bool> restartWebsite(int websiteId) async {
    try {
      await _ensureApiClient();
      await _websiteApi!.restartWebsite(websiteId);
      await loadWebsites(); // 刷新列表
      return true;
    } catch (e) {
      _data = _data.copyWith(error: '重启网站失败: $e');
      notifyListeners();
      return false;
    }
  }

  /// 删除网站
  Future<bool> deleteWebsite(int websiteId) async {
    try {
      await _ensureApiClient();
      await _websiteApi!.deleteWebsite(websiteId);
      await loadWebsites(); // 刷新列表
      return true;
    } catch (e) {
      _data = _data.copyWith(error: '删除网站失败: $e');
      notifyListeners();
      return false;
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    await loadWebsites();
  }

  /// 清除错误
  void clearError() {
    _data = _data.copyWith(error: null);
    notifyListeners();
  }
}
