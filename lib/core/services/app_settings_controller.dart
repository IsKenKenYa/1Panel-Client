import 'package:flutter/material.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:onepanel_client/core/services/cache/file_preview_cache_manager.dart';
import 'package:onepanel_client/core/theme/ui_render_mode.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';

class AppSettingsController extends ChangeNotifier with SafeChangeNotifier {
  AppSettingsController({AppPreferencesService? preferencesService})
      : _preferencesService = preferencesService ?? AppPreferencesService();

  final AppPreferencesService _preferencesService;

  Locale? _locale;
  bool _loaded = false;
  CacheStrategy _cacheStrategy = CacheStrategy.hybrid;
  int _cacheMaxSizeMB = 100;
  UIRenderMode _uiRenderMode = UIRenderMode.native;
  bool _nativeHostMissing = false;

  Locale? get locale => _locale;
  bool get loaded => _loaded;
  CacheStrategy get cacheStrategy => _cacheStrategy;
  int get cacheMaxSizeMB => _cacheMaxSizeMB;
  UIRenderMode get uiRenderMode => _uiRenderMode;
  bool get nativeHostMissing => _nativeHostMissing;

  /// 冷启动宿主缺失（bootstrap 置 ONEPANEL_FORCE_MD3=1）时由装配层标记，
  /// 设置页据此展示「已回退 MDUI3」状态行。非持久化，仅本次会话有效。
  void markNativeHostMissing({bool value = true}) {
    if (_nativeHostMissing == value) {
      return;
    }
    _nativeHostMissing = value;
    notifyListeners();
  }

  Future<void> load() async {
    final (locale, cacheStrategy, cacheMaxSizeMB, uiRenderMode) =
        await _preferencesService.loadAppSettings();
    _locale = locale;
    _cacheStrategy = cacheStrategy;
    _cacheMaxSizeMB = cacheMaxSizeMB;
    _uiRenderMode = uiRenderMode;
    _applyCacheSettings();
    // 载入后同步策略，使读取静态开关的旧调用点与控制器保持一致。
    UIRenderPolicy.applyMode(_uiRenderMode);
    _loaded = true;
    notifyListeners();
  }

  Future<void> updateLocale(Locale? locale) async {
    await _preferencesService.saveLocale(locale);
    _locale = locale;
    notifyListeners();
  }

  Future<void> updateCacheStrategy(CacheStrategy strategy) async {
    await _preferencesService.saveCacheStrategy(strategy);
    _cacheStrategy = strategy;
    _applyCacheSettings();
    notifyListeners();
  }

  Future<void> updateCacheMaxSizeMB(int sizeMB) async {
    await _preferencesService.saveCacheMaxSizeMB(sizeMB);
    _cacheMaxSizeMB = sizeMB;
    _applyCacheSettings();
    notifyListeners();
  }

  void _applyCacheSettings() => FilePreviewCacheManager().configure(
        strategy: _cacheStrategy,
        maxSizeMB: _cacheMaxSizeMB,
      );

  Future<void> updateUIRenderMode(UIRenderMode mode) async {
    _uiRenderMode = await _preferencesService.saveUIRenderMode(mode);
    if (_uiRenderMode != UIRenderMode.native) _nativeHostMissing = false;
    // 同步刷新渲染策略；界面经 notifyListeners 重建，切换无需重启。
    UIRenderPolicy.applyMode(_uiRenderMode);
    notifyListeners();
  }
}
