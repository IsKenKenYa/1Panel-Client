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
  FilesProvider({FilesService? service}) : _service = service ?? FilesService();

  final FilesService _service;
  FilesData _data = const FilesData();
  final Map<String, String> _serverPathMemory = <String, String>{};

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
  }

  String _restorePathForServer(String? serverId) {
    if (serverId == null || serverId.isEmpty) {
      return '/';
    }
    return _normalizePath(_serverPathMemory[serverId] ?? '/');
  }
}
