import 'dart:async';
import 'dart:typed_data';
import 'dart:collection';

class CacheEntry {
  final Uint8List data;
  final String? fileName;
  final String? mimeType;
  final DateTime createdAt;
  DateTime lastAccessedAt;
  final String? hash;

  CacheEntry({
    required this.data,
    this.fileName,
    this.mimeType,
    required this.createdAt,
    required this.lastAccessedAt,
    this.hash,
  });

  bool isExpired(Duration expirationDuration) {
    return DateTime.now().difference(lastAccessedAt) > expirationDuration;
  }
}

class MemoryCacheManager {
  static final MemoryCacheManager _instance = MemoryCacheManager._internal();
  factory MemoryCacheManager() => _instance;

  MemoryCacheManager._internal();

  final LinkedHashMap<String, CacheEntry> _cache = LinkedHashMap();

  int _maxItems = 20;
  int _maxSizeBytes = 100 * 1024 * 1024;
  int _currentSizeBytes = 0;

  static const Duration _defaultExpiration = Duration(minutes: 2);
  Duration _expirationDuration = _defaultExpiration;

  Timer? _cleanupTimer;
  bool _isAppInBackground = false;

  int get maxItems => _maxItems;
  int get maxSizeBytes => _maxSizeBytes;
  int get currentSizeBytes => _currentSizeBytes;
  int get itemCount => _cache.length;
  Duration get expirationDuration => _expirationDuration;

  void configure({
    int? maxItems,
    int? maxSizeBytes,
    Duration? expirationDuration,
  }) {
    if (maxItems != null) _maxItems = maxItems;
    if (maxSizeBytes != null) _maxSizeBytes = maxSizeBytes;
    if (expirationDuration != null) _expirationDuration = expirationDuration;
  }

  void startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _cleanupExpiredEntries();
    });
  }

  void stopCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  void onAppPaused() {
    _isAppInBackground = true;
    clear();
  }

  void onAppResumed() {
    _isAppInBackground = false;
  }

  void put(String key, Uint8List data,
      {String? fileName, String? mimeType, String? hash}) {
    if (_isAppInBackground) return;

    final entry = CacheEntry(
      data: data,
      fileName: fileName,
      mimeType: mimeType,
      createdAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
      hash: hash,
    );

    if (_cache.containsKey(key)) {
      final oldEntry = _cache[key]!;
      _currentSizeBytes -= oldEntry.data.length;
      _cache.remove(key);
    }

    while ((_cache.length >= _maxItems ||
            _currentSizeBytes + data.length > _maxSizeBytes) &&
        _cache.isNotEmpty) {
      _evictOldest();
    }

    _cache[key] = entry;
    _currentSizeBytes += data.length;
  }

  Uint8List? get(String key) {
    if (_isAppInBackground) return null;

    final entry = _cache[key];
    if (entry != null) {
      if (entry.isExpired(_expirationDuration)) {
        remove(key);
        return null;
      }

      entry.lastAccessedAt = DateTime.now();
      _cache.remove(key);
      _cache[key] = entry;
      return entry.data;
    }
    return null;
  }

  bool contains(String key) => _cache.containsKey(key);

  CacheEntry? getEntry(String key) {
    if (_isAppInBackground) return null;

    final entry = _cache[key];
    if (entry != null) {
      if (entry.isExpired(_expirationDuration)) {
        remove(key);
        return null;
      }

      entry.lastAccessedAt = DateTime.now();
      _cache.remove(key);
      _cache[key] = entry;
      return entry;
    }
    return null;
  }

  void remove(String key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      _currentSizeBytes -= entry.data.length;
    }
  }

  void clear() {
    _cache.clear();
    _currentSizeBytes = 0;
  }

  void _evictOldest() {
    if (_cache.isEmpty) return;

    final oldestKey = _cache.keys.first;
    final oldestEntry = _cache[oldestKey]!;
    _currentSizeBytes -= oldestEntry.data.length;
    _cache.remove(oldestKey);
  }

  void _cleanupExpiredEntries() {
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (entry.value.isExpired(_expirationDuration)) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      // 清理了过期缓存项
    }
  }

  Map<String, dynamic> getStats() {
    return {
      'itemCount': itemCount,
      'currentSizeBytes': currentSizeBytes,
      'currentSizeMB': (currentSizeBytes / (1024 * 1024)).toStringAsFixed(2),
      'maxItems': maxItems,
      'maxSizeMB': (maxSizeBytes / (1024 * 1024)).toStringAsFixed(2),
      'expirationMinutes': _expirationDuration.inMinutes,
    };
  }

  void dispose() {
    stopCleanupTimer();
    clear();
  }
}
