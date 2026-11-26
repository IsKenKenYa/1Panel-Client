import '../../features/security/app_lock_controller.dart';
import '../../features/settings/widgets/system_settings_tiles.dart';
import '../../features/shell/models/client_module.dart';
import '../services/app_preferences_service.dart';
import '../services/app_settings_controller.dart';
import '../services/cache/file_preview_cache_manager.dart';

class NativeChannelHarmonyPrivacy {
  static late AppLockController _appLock;
  static late AppSettingsController _settings;

  static void bind(AppLockController appLock, AppSettingsController settings) {
    _appLock = appLock;
    _settings = settings;
  }

  static Future<Map<String, Object?>> getAppLock(dynamic arguments) async {
    await _appLock.load();
    final settings = _appLock.settings;
    return {
      'enabled': settings.enabled,
      'lockOnAppOpen': settings.lockOnAppOpen,
      'lockOnProtectedModule': settings.lockOnProtectedModule,
      'relockAfterMinutes': settings.relockAfterMinutes,
      'protectedModuleIds': settings.protectedModuleIds,
      'supported': _appLock.canUseLocalAuth,
      'reason': _appLock.availability.reason,
      'unlocked': _appLock.isSessionUnlocked,
      'modules': kPinnableClientModules
          .where((module) => module.requiresServer)
          .map(
            (module) => {
              'id': module.storageId,
              'titleKey': switch (module) {
                ClientModule.files => 'navFiles',
                ClientModule.containers => 'containerManagement',
                ClientModule.apps => 'appsPageTitle',
                ClientModule.websites => 'websitesPageTitle',
                ClientModule.ai => 'serverModuleAi',
                ClientModule.vm => 'serverModuleVm',
                ClientModule.verification => 'serverActionSecurity',
                _ => throw StateError('Unsupported protected module'),
              },
            },
          )
          .toList(growable: false),
    };
  }

  static Future<void> updateAppLock(dynamic arguments) async {
    final args = Map<String, dynamic>.from(arguments as Map);
    switch (args['key'] as String) {
      case 'unlock':
        final authenticated = await _appLock.authenticateForUnlock(
          reason: args['reason'] as String,
        );
        if (!authenticated) {
          throw StateError(
            _appLock.lastError ?? args['failureMessage'] as String,
          );
        }
      case 'enabled':
        if (args['value'] as bool) {
          final authenticated = await _appLock.enableWithVerification(
            reason: args['reason'] as String,
          );
          if (!authenticated) {
            throw StateError(
              _appLock.lastError ?? args['failureMessage'] as String,
            );
          }
        } else {
          await _appLock.disable();
        }
      case 'lockOnAppOpen':
        await _appLock.updateLockOnAppOpen(args['value'] as bool);
      case 'lockOnProtectedModule':
        await _appLock.updateLockOnProtectedModule(args['value'] as bool);
      case 'relockAfterMinutes':
        await _appLock.updateRelockAfterMinutes(args['value'] as int);
      case 'protectedModuleIds':
        await _appLock.updateProtectedModuleIds(
          List<String>.from(args['value'] as List),
        );
      default:
        throw ArgumentError.value(args['key'], 'key');
    }
  }

  static Future<Map<String, Object?>> getStorage(dynamic arguments) async {
    final preferences = AppPreferencesService();
    return {
      'strategy': _settings.cacheStrategy.name,
      'maxSizeMB': _settings.cacheMaxSizeMB,
      'stats': FilePreviewCacheManager().getMemoryCacheStats(),
      'usePicker': await preferences.loadUseFilePickerForFileOperations(),
      'folder': await preferences.loadFileSaveSubDirectoryName(),
    };
  }

  static Future<void> updateStorage(dynamic arguments) async {
    final args = Map<String, dynamic>.from(arguments as Map);
    final preferences = AppPreferencesService();
    switch (args['key'] as String) {
      case 'strategy':
        await _settings.updateCacheStrategy(
          CacheStrategy.values.byName(args['value'] as String),
        );
      case 'maxSizeMB':
        await _settings.updateCacheMaxSizeMB(args['value'] as int);
      case 'usePicker':
        await preferences.saveUseFilePickerForFileOperations(
          args['value'] as bool,
        );
      case 'folder':
        final folder = (args['value'] as String).trim();
        if (!isValidExportFolderName(folder)) {
          throw ArgumentError(args['failureMessage'] as String);
        }
        await preferences.saveFileSaveSubDirectoryName(folder);
      case 'clear':
        await FilePreviewCacheManager().clearAllCache();
      default:
        throw ArgumentError.value(args['key'], 'key');
    }
  }
}
