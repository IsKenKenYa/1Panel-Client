import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'memory_cache_manager.dart';

enum CacheSource {
  memory,
  disk,
  network,
}

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
  static final FilePreviewCacheManager _instance = FilePreviewCacheManager._internal();
  factory FilePreviewCacheManager() => _instance;
  
  FilePreviewCacheManager._internal();
  
  final MemoryCacheManager _memoryCache = MemoryCacheManager();
  final BaseCacheManager _diskCache = DefaultCacheManager();
  
  final Map<String, String> _hashIndex = {};
  
  static const String _cacheKeyPrefix = 'file_preview_';
  
  void initialize({
    required CacheStrategy strategy,
    required int maxSizeMB,
  }) {
    _memoryCache.configure(
      maxSizeBytes: maxSizeMB * 1024 * 1024,
    );
    
    if (strategy != CacheStrategy.diskOnly) {
      _memoryCache.startCleanupTimer();
    }
  }
  
  void onAppPaused() {
    _memoryCache.onAppPaused();
  }
  
  void onAppResumed() {
    _memoryCache.onAppResumed();
  }
  
  String _generateCacheKey(String filePath) {
    return '$_cacheKeyPrefix${filePath.hashCode}_${filePath.split('/').last}';
  }
  
  String _computeHash(Uint8List data) {
    return sha256.convert(data).toString();
  }
  
  Future<CacheResult?> loadFile({
    required String filePath,
    required String fileName,
    required Future<Uint8List> Function() downloadFn,
    required CacheStrategy strategy,
  }) async {
    final cacheKey = _generateCacheKey(filePath);
    
    if (strategy == CacheStrategy.memoryOnly || strategy == CacheStrategy.hybrid) {
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
    
    if (strategy == CacheStrategy.diskOnly || strategy == CacheStrategy.hybrid) {
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
            if (strategy == CacheStrategy.hybrid) {
              _memoryCache.put(cacheKey, data, fileName: fileName, hash: computedHash);
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
    
    if (strategy == CacheStrategy.memoryOnly || strategy == CacheStrategy.hybrid) {
      _memoryCache.put(cacheKey, downloadedData, fileName: fileName, hash: hash);
    }
    
    if (strategy == CacheStrategy.diskOnly || strategy == CacheStrategy.hybrid) {
      try {
        await _diskCache.putFile(
          cacheKey,
          downloadedData,
          fileExtension: _getFileExtension(fileName),
        );
        _hashIndex[cacheKey] = hash;
        appLogger.dWithPackage('cache', 'loadFile: 已缓存到硬盘 $filePath');
      } catch (e) {
        appLogger.wWithPackage('cache', 'loadFile: 硬盘缓存写入失败: $e');
      }
    }
    
    return CacheResult(
      data: downloadedData,
      source: CacheSource.network,
      fileName: fileName,
    );
  }
  
  Future<String?> saveToTempFile(Uint8List data, String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final localPath = '${tempDir.path}/file_preview_$fileName';
      
      final file = File(localPath);
      await file.writeAsBytes(data);
      
      appLogger.dWithPackage('cache', 'saveToTempFile: 已保存到 $localPath');
      return localPath;
    } catch (e) {
      appLogger.eWithPackage('cache', 'saveToTempFile: 保存失败: $e');
      return null;
    }
  }
  
  Future<void> clearMemoryCache() async {
    _memoryCache.clear();
    appLogger.iWithPackage('cache', 'clearMemoryCache: 内存缓存已清除');
  }
  
  Future<void> clearDiskCache() async {
    await _diskCache.emptyCache();
    _hashIndex.clear();
    appLogger.iWithPackage('cache', 'clearDiskCache: 硬盘缓存已清除');
  }
  
  Future<void> clearAllCache() async {
    await clearMemoryCache();
    await clearDiskCache();
  }
  
  Future<void> removeFile(String filePath) async {
    final cacheKey = _generateCacheKey(filePath);
    _memoryCache.remove(cacheKey);
    await _diskCache.removeFile(cacheKey);
    _hashIndex.remove(cacheKey);
  }
  
  Map<String, dynamic> getMemoryCacheStats() {
    return _memoryCache.getStats();
  }
  
  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return '.${parts.last}';
    }
    return '';
  }
  
  bool isInMemoryCache(String filePath) {
    final cacheKey = _generateCacheKey(filePath);
    return _memoryCache.contains(cacheKey);
  }
  
  Future<bool> isInDiskCache(String filePath) async {
    final cacheKey = _generateCacheKey(filePath);
    final fileInfo = await _diskCache.getFileFromCache(cacheKey);
    return fileInfo != null;
  }
  
  void dispose() {
    _memoryCache.dispose();
  }
}
