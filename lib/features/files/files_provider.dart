import 'package:onepanel_client/data/models/paged_query.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'dart:async';
import 'dart:io';

import 'package:onepanel_client/core/network/onepanel_auth_headers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:onepanel_client/core/services/transfer/one_panel_download_source.dart';
import 'package:onepanel_client/core/platform/platform_capabilities.dart';
import 'package:onepanel_client/core/platform/services/ohos_platform_channel.dart';
import 'package:onepanel_client/core/platform/services/platform_system_paths.dart';
import 'package:path_provider/path_provider.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/file_models.dart';

import 'files_service.dart';
import 'models/models.dart';

part 'providers/files_provider_lifecycle_part.dart';
part 'providers/files_provider_recycle_part.dart';
part 'providers/files_provider_browser_part.dart';
part 'providers/files_provider_favorites_transfer_part.dart';
part 'providers/files_provider_system_part.dart';

class FilesProvider extends ChangeNotifier with SafeChangeNotifier {
  FilesProvider({FilesService? service, AppPreferencesService? preferences})
      : _service = service ?? FilesService(),
        _preferences = preferences ?? AppPreferencesService();

  final FilesService _service;
  final AppPreferencesService _preferences;
  FilesData _data = const FilesData();
  // 各服务器上次浏览的目录，跨启动保留。
  final Map<String, String> _serverPathMemory = <String, String>{};
  bool _pathMemoryLoaded = false;

  // Files >= 50 MB trigger a log hint recommending chunked download,
  // but the actual chunked strategy is not yet implemented — this is a
  // threshold for future use / observability only.
  static const int _chunkDownloadThreshold = 50 * 1024 * 1024;

  FilesData get data => _data;

  void _emitChange() {
    if (isDisposed) {
      return;
    }
    notifyListeners();
  }

  List<String> _pathSegments(String path) {
    return path.split('/').where((segment) => segment.isNotEmpty).toList();
  }

  String _normalizePath(String path) {
    final segments = _pathSegments(path);
    if (segments.isEmpty) return '/';
    return '/${segments.join('/')}';
  }

  void _rememberPathForServer(String? serverId, String path) {
    if (serverId == null || serverId.isEmpty) {
      return;
    }
    _serverPathMemory[serverId] = _normalizePath(path);
    // 写入失败不影响浏览，下次进入退回根目录。
    unawaited(
      _preferences.saveFileLastPaths(Map<String, String>.from(_serverPathMemory)),
    );
  }

  String _restorePathForServer(String? serverId) {
    if (serverId == null || serverId.isEmpty) {
      return '/';
    }
    return _normalizePath(_serverPathMemory[serverId] ?? '/');
  }

  /// 首次进入时把持久化的目录记忆读入内存，供 _restorePathForServer 使用。
  Future<void> _ensurePathMemoryLoaded() async {
    if (_pathMemoryLoaded) return;
    _pathMemoryLoaded = true;
    _serverPathMemory.addAll(await _preferences.loadFileLastPaths());
  }
}
