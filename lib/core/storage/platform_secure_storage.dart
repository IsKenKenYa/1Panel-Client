import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:onepanel_client/core/platform/platform_capabilities.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/logger/logger_service.dart';
import 'browser_vault.dart';

enum PlatformSecureStorageBackend {
  browserVault,
  flutterSecureStorage,
  ohosMethodChannel,
  sharedPreferencesFallback,
}

class PlatformSecureStorage {
  PlatformSecureStorage._({
    required this.backend,
    required bool isOhos,
    FlutterSecureStorage? secureStorage,
    SharedPreferences? prefs,
    MethodChannel? ohosChannel,
  })  : _secureStorage = secureStorage,
        _prefsFallback = prefs,
        _ohosChannel = ohosChannel,
        _isOhos = isOhos;

  static const String ohosChannelName = 'onepanel/secure_storage';
  static const String _prefsKeyPrefix = 'open1panel_secure_';

  final PlatformSecureStorageBackend backend;
  final FlutterSecureStorage? _secureStorage;
  final SharedPreferences? _prefsFallback;
  final MethodChannel? _ohosChannel;
  final bool _isOhos;
  static const String _tag = 'core.storage.platform_secure';

  static Future<PlatformSecureStorage> create({
    PlatformCapabilitiesSnapshot? capabilities,
    FlutterSecureStorage? secureStorage,
    SharedPreferences? sharedPreferences,
    MethodChannel? ohosMethodChannel,
    bool probeSecureStorage = true,
  }) async {
    final resolvedCapabilities = capabilities ?? PlatformCapabilities.current();

    if (resolvedCapabilities.isWeb) {
      await BrowserVault.instance.initialize();
      if (!BrowserVault.instance.isUnlocked) {
        throw StateError('浏览器加密存储尚未解锁');
      }
      return PlatformSecureStorage._(
        backend: PlatformSecureStorageBackend.browserVault,
        isOhos: false,
      );
    }

    if (resolvedCapabilities.isOhos) {
      final ohosChannel =
          ohosMethodChannel ?? const MethodChannel(ohosChannelName);
      try {
        final healthy = await ohosChannel.invokeMethod<bool>('ping');
        if (healthy == true) {
          return PlatformSecureStorage._(
            backend: PlatformSecureStorageBackend.ohosMethodChannel,
            isOhos: true,
            ohosChannel: ohosChannel,
          );
        }
      } catch (error, stackTrace) {
        appLogger.wWithPackage(
          'core.storage.platform_secure',
          'OHOS secure storage channel unavailable, falling back to SharedPreferences',
          error: error,
          stackTrace: stackTrace,
        );
      }

      return PlatformSecureStorage._(
        backend: PlatformSecureStorageBackend.sharedPreferencesFallback,
        isOhos: true,
        prefs: sharedPreferences ?? await SharedPreferences.getInstance(),
        ohosChannel: ohosChannel,
      );
    }

    final candidate = secureStorage ??
        const FlutterSecureStorage(
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
          lOptions: LinuxOptions(),
        );

    if (!probeSecureStorage) {
      return PlatformSecureStorage._(
        backend: PlatformSecureStorageBackend.flutterSecureStorage,
        isOhos: false,
        secureStorage: candidate,
      );
    }

    // Probe: some platforms throw UnsupportedError/MissingPluginException
    // for FlutterSecureStorage; catch early and degrade to SharedPreferences.
    try {
      await candidate.read(key: '__platform_probe__');
      return PlatformSecureStorage._(
        backend: PlatformSecureStorageBackend.flutterSecureStorage,
        isOhos: false,
        secureStorage: candidate,
      );
    } on UnsupportedError catch (error, stackTrace) {
      appLogger.wWithPackage(
        'core.storage.platform_secure',
        'SecureStorage unsupported, falling back to SharedPreferences',
        error: error,
        stackTrace: stackTrace,
      );
    } on MissingPluginException catch (error, stackTrace) {
      appLogger.wWithPackage(
        'core.storage.platform_secure',
        'SecureStorage plugin missing, falling back to SharedPreferences',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      appLogger.wWithPackage(
        'core.storage.platform_secure',
        'SecureStorage probe failed, falling back to SharedPreferences',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return PlatformSecureStorage._(
      backend: PlatformSecureStorageBackend.sharedPreferencesFallback,
      isOhos: false,
      prefs: sharedPreferences ?? await SharedPreferences.getInstance(),
    );
  }

  Future<String?> read({required String key}) async {
    switch (backend) {
      case PlatformSecureStorageBackend.browserVault:
        return BrowserVault.instance.read(key);
      case PlatformSecureStorageBackend.flutterSecureStorage:
        return _secureStorage!.read(key: key);
      case PlatformSecureStorageBackend.ohosMethodChannel:
        return _readOhos(key);
      case PlatformSecureStorageBackend.sharedPreferencesFallback:
        // On OHOS with prefs fallback, try the channel first -- it may have
        // come online after this instance was created.
        if (_isOhos && _ohosChannel != null) {
          final ohosValue = await _readOhosChannel(key);
          if (ohosValue != null && ohosValue.isNotEmpty) return ohosValue;
        }
        return _prefsFallback!.getString(_prefixedKey(key));
    }
  }

  Future<String?> _readOhos(String key) async {
    try {
      final value = await _readOhosChannel(key);
      if (value != null && value.isNotEmpty) {
        return value;
      }
      appLogger.wWithPackage(
        _tag,
        'OHOS secure read returned null for key: $key, attempting SharedPreferences fallback',
      );
      final fallback = await SharedPreferences.getInstance();
      return fallback.getString(_prefixedKey(key));
    } catch (error, stackTrace) {
      appLogger.wWithPackage(
        _tag,
        'OHOS secure read failed for key: $key, attempting SharedPreferences fallback',
        error: error,
        stackTrace: stackTrace,
      );
      try {
        final fallback = await SharedPreferences.getInstance();
        return fallback.getString(_prefixedKey(key));
      } catch (_) {
        return null;
      }
    }
  }

  Future<String?> _readOhosChannel(String key) async {
    try {
      return await _ohosChannel!.invokeMethod<String?>(
        'read',
        <String, Object?>{'key': key},
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write({required String key, required String? value}) async {
    switch (backend) {
      case PlatformSecureStorageBackend.browserVault:
        return BrowserVault.instance.write(key, value);
      case PlatformSecureStorageBackend.flutterSecureStorage:
        if (value == null) {
          await _secureStorage!.delete(key: key);
        } else {
          await _secureStorage!.write(key: key, value: value);
        }
        return;
      case PlatformSecureStorageBackend.ohosMethodChannel:
        await _writeOhos(key, value);
        return;
      case PlatformSecureStorageBackend.sharedPreferencesFallback:
        // Write to prefs first (durable), then best-effort OHOS channel.
        if (value == null) {
          await _prefsFallback!.remove(_prefixedKey(key));
        } else {
          await _prefsFallback!.setString(_prefixedKey(key), value);
        }
        if (_isOhos && _ohosChannel != null) {
          try {
            await _ohosChannel.invokeMethod<void>(
              'write',
              <String, Object?>{'key': key, 'value': value},
            );
          } catch (_) {}
        }
        return;
    }
  }

  Future<void> _writeOhos(String key, String? value) async {
    // Always persist to SharedPreferences as backup because HUKS-backed
    // reads may silently return null on some OHOS builds.
    try {
      final fallback = await SharedPreferences.getInstance();
      if (value == null) {
        await fallback.remove(_prefixedKey(key));
      } else {
        await fallback.setString(_prefixedKey(key), value);
      }
    } catch (_) {}
    try {
      await _ohosChannel!.invokeMethod<void>(
        'write',
        <String, Object?>{'key': key, 'value': value},
      );
    } catch (error, stackTrace) {
      appLogger.wWithPackage(
        _tag,
        'OHOS secure write failed for key: $key (SharedPreferences backup exists)',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> delete({required String key}) async {
    switch (backend) {
      case PlatformSecureStorageBackend.browserVault:
        return BrowserVault.instance.delete(key);
      case PlatformSecureStorageBackend.flutterSecureStorage:
        await _secureStorage!.delete(key: key);
        return;
      case PlatformSecureStorageBackend.ohosMethodChannel:
        // Must clean up prefs backup too, otherwise _readOhos would resurrect
        // the old value from the backup after HUKS deletion.
        try {
          final fallback = await SharedPreferences.getInstance();
          await fallback.remove(_prefixedKey(key));
        } catch (_) {}
        try {
          await _ohosChannel!.invokeMethod<void>(
            'delete',
            <String, Object?>{'key': key},
          );
        } catch (_) {}
        return;
      case PlatformSecureStorageBackend.sharedPreferencesFallback:
        await _prefsFallback!.remove(_prefixedKey(key));
        return;
    }
  }

  Future<void> deleteAll() async {
    switch (backend) {
      case PlatformSecureStorageBackend.browserVault:
        return BrowserVault.instance.deleteAll();
      case PlatformSecureStorageBackend.flutterSecureStorage:
        await _secureStorage!.deleteAll();
        return;
      case PlatformSecureStorageBackend.ohosMethodChannel:
        await _ohosChannel!.invokeMethod<void>('deleteAll');
        return;
      case PlatformSecureStorageBackend.sharedPreferencesFallback:
        final prefs = _prefsFallback!;
        final keys =
            prefs.getKeys().where((key) => key.startsWith(_prefsKeyPrefix));
        for (final key in keys) {
          await prefs.remove(key);
        }
        return;
    }
  }

  String _prefixedKey(String key) => '$_prefsKeyPrefix$key';
}
