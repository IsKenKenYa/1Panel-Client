import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';

import 'memory_cache_manager.dart';

enum CacheSource { memory, disk, network }

class CacheResult {
  final Uint8List data;
  final String? localPath;
  final CacheSource source;
  final String? fileName;
  final String? mimeType;

  CacheResult({
    required this.data,
    this.localPath,
    required this.source,
    this.fileName,
    this.mimeType,
  });

  bool get isFromCache => source != CacheSource.network;
}

class FilePreviewCacheManager {
  static final FilePreviewCacheManager _instance =
      FilePreviewCacheManager._internal();
  factory FilePreviewCacheManager() => _instance;

  FilePreviewCacheManager._internal();

  final MemoryCacheManager _memoryCache = MemoryCacheManager();
  late final BaseCacheManager _diskCache = CacheManager(
    Config('kenpanel_file_previews'),
  );

  final Map<String, String> _hashIndex = {};
  final Lock _diskWrites = Lock();
  int _generation = 0;
  CacheStrategy? _configuredStrategy;

  static const String _cacheKeyPrefix = 'file_preview_';

  void initialize({required CacheStrategy strategy, required int maxSizeMB}) {
    configure(strategy: strategy, maxSizeMB: maxSizeMB);
    if (kIsWeb || strategy != CacheStrategy.diskOnly) {
      _memoryCache.startCleanupTimer();
    }
  }

  void configure({required CacheStrategy strategy, required int maxSizeMB}) {
    if (kIsWeb) strategy = CacheStrategy.memoryOnly;
    if (strategy != _configuredStrategy) {
      _configuredStrategy = strategy;
      _generation++;
    }
    _memoryCache.configure(maxSizeBytes: maxSizeMB * 1024 * 1024);

    if (!kIsWeb && strategy == CacheStrategy.diskOnly) {
      _memoryCache.stopCleanupTimer();
      _memoryCache.clear();
    }
  }

  void onAppPaused() {
    _memoryCache.onAppPaused();
  }

  void onAppResumed() {
    _memoryCache.onAppResumed();
  }

  String _generateCacheKey(String connectionId, String filePath) {
    final identity = utf8.encode(jsonEncode([connectionId, filePath]));
    return '$_cacheKeyPrefix${sha256.convert(identity)}';
  }

  String _computeHash(Uint8List data) {
    return sha256.convert(data).toString();
  }

  Future<CacheResult?> loadFile({
    required String connectionId,
    required String filePath,
    required String fileName,
    required Future<Uint8List> Function() downloadFn,
    required CacheStrategy strategy,
  }) async {
    if (kIsWeb) strategy = CacheStrategy.memoryOnly;
    final generation = _generation;
    final cacheKey = _generateCacheKey(connectionId, filePath);

    if (strategy == CacheStrategy.memoryOnly ||
        strategy == CacheStrategy.hybrid) {
      final memoryData = _memoryCache.get(cacheKey);
      if (memoryData != null) {
        appLogger.dWithPackage('cache', 'loadFile: 从内存缓存加载 $filePath');
        final entry = _memoryCache.getEntry(cacheKey);
        return CacheResult(
          data: memoryData,
          source: CacheSource.memory,
          fileName: entry?.fileName ?? fileName,
          mimeType: entry?.mimeType,
        );
      }
    }

    if (strategy == CacheStrategy.diskOnly ||
        strategy == CacheStrategy.hybrid) {
      try {
        final fileInfo = await _diskCache.getFileFromCache(cacheKey);
        if (fileInfo != null) {
          final data = await fileInfo.file.readAsBytes();

          final storedHash = _hashIndex[cacheKey];
          final computedHash = _computeHash(data);

          if (storedHash != null && storedHash != computedHash) {
            appLogger.wWithPackage('cache', 'loadFile: 硬盘缓存文件哈希不匹配，可能被篡改');
            await _diskCache.removeFile(cacheKey);
            _hashIndex.remove(cacheKey);
          } else {
            if (generation == _generation && strategy == CacheStrategy.hybrid) {
              _memoryCache.put(
                cacheKey,
                data,
                fileName: fileName,
                hash: computedHash,
              );
            }

            appLogger.dWithPackage('cache', 'loadFile: 从硬盘缓存加载 $filePath');
            return CacheResult(
              data: data,
              localPath: fileInfo.file.path,
              source: CacheSource.disk,
              fileName: fileName,
            );
          }
        }
      } catch (e) {
        appLogger.wWithPackage('cache', 'loadFile: 硬盘缓存读取失败: $e');
      }
    }

    appLogger.dWithPackage('cache', 'loadFile: 从网络下载 $filePath');
    final downloadedData = await downloadFn();
    final hash = _computeHash(downloadedData);

    if (generation == _generation && strategy != CacheStrategy.diskOnly) {
      _memoryCache.put(
        cacheKey,
        downloadedData,
        fileName: fileName,
        hash: hash,
      );
    }

    String? localPath;
    if (strategy != CacheStrategy.memoryOnly) {
      try {
        await _diskWrites.synchronized(() async {
          if (generation != _generation) return;
          final file = await _diskCache.putFile(
            cacheKey,
            downloadedData,
            fileExtension: path.extension(fileName).replaceFirst('.', ''),
          );
          _hashIndex[cacheKey] = hash;
          localPath = file.path;
        });
      } catch (e) {
        appLogger.wWithPackage('cache', 'loadFile: 硬盘缓存写入失败: $e');
      }
    }

    return CacheResult(
      data: downloadedData,
      localPath: localPath,
      source: CacheSource.network,
      fileName: fileName,
    );
  }

  Future<String?> saveToTempFile(Uint8List data, String fileName) async {
    try {
      final directory = await _viewerDirectory();
      await directory.create(recursive: true);
      final file = File(path.join(
          directory.path, '${const Uuid().v4()}${path.extension(fileName)}'));
      await file.writeAsBytes(data);

      appLogger.dWithPackage('cache', 'saveToTempFile: 已保存文件预览');
      return file.path;
    } catch (e) {
      appLogger.eWithPackage('cache', 'saveToTempFile: 保存失败: $e');
      return null;
    }
  }

  Future<Directory> _viewerDirectory() async => Directory(path.join(
      (await getTemporaryDirectory()).path, 'kenpanel_preview_viewer'));

  Future<void> releaseViewerFile(String filePath) async {
    final directory = await _viewerDirectory();
    if (!path.equals(path.dirname(filePath), directory.path)) return;
    try {
      await File(filePath).delete();
    } on PathNotFoundException {
      // 用户可在播放期间从设置中清理文件。
    } on FileSystemException catch (error) {
      appLogger.wWithPackage('cache', '释放播放文件失败', error: error);
    }
  }

  Future<void> clearMemoryCache() async {
    _memoryCache.clear();
    appLogger.iWithPackage('cache', 'clearMemoryCache: 内存缓存已清除');
  }

  Future<void> clearDiskCache() async {
    await _diskCache.emptyCache();
    _hashIndex.clear();
    final directory = await _viewerDirectory();
    if (await directory.exists()) {
      await for (final file in directory.list(followLinks: false)) {
        if (file is File) await file.delete();
      }
    }
    appLogger.iWithPackage('cache', 'clearDiskCache: 硬盘缓存已清除');
  }

  Future<void> clearAllCache() async {
    _generation++;
    _memoryCache.clear();
    if (!kIsWeb) await _diskWrites.synchronized(clearDiskCache);
  }

  Future<void> removeFile(String connectionId, String filePath) async {
    final cacheKey = _generateCacheKey(connectionId, filePath);
    _memoryCache.remove(cacheKey);
    if (!kIsWeb) await _diskCache.removeFile(cacheKey);
    _hashIndex.remove(cacheKey);
  }

  Map<String, dynamic> getMemoryCacheStats() {
    return _memoryCache.getStats();
  }

  bool isInMemoryCache(String connectionId, String filePath) {
    final cacheKey = _generateCacheKey(connectionId, filePath);
    return _memoryCache.contains(cacheKey);
  }

  Future<bool> isInDiskCache(String connectionId, String filePath) async {
    if (kIsWeb) return false;
    final cacheKey = _generateCacheKey(connectionId, filePath);
    final fileInfo = await _diskCache.getFileFromCache(cacheKey);
    return fileInfo != null;
  }

  void dispose() {
    _memoryCache.dispose();
  }
}
