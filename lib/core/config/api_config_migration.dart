import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

const String _migrationPackage = 'core.config.api_config_migration';

/// Migrates API keys from SharedPreferences fallback to secure storage
///
/// This is needed for users who had the fallback mechanism active
/// and stored their API keys in SharedPreferences instead of keychain
class ApiConfigMigration {
  static const String _migrationCompleteKey = 'api_config_migration_v1_complete';
  static const String _fallbackPrefix = 'secure_api_key_fallback_';

  /// Runs the migration if it hasn't been completed yet
  static Future<void> runMigrationIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if migration already completed
    if (prefs.getBool(_migrationCompleteKey) == true) {
      appLogger.dWithPackage(
        _migrationPackage,
        'Migration already completed, skipping',
      );
      return;
    }

    appLogger.iWithPackage(
      _migrationPackage,
      'Starting API config migration from SharedPreferences to secure storage',
    );

    try {
      // Get all keys from SharedPreferences
      final allKeys = prefs.getKeys();
      var migratedCount = 0;

      for (final key in allKeys) {
        if (key.startsWith(_fallbackPrefix)) {
          final apiKey = prefs.getString(key);
          if (apiKey != null && apiKey.isNotEmpty) {
            // Extract the server ID from the key
            final serverId = key.substring(_fallbackPrefix.length);
            final storageKey = 'api_config_api_key_$serverId';

            // Write to secure storage
            await ApiConfigManager.apiKeyStore.write(storageKey, apiKey);

            // Remove from SharedPreferences
            await prefs.remove(key);

            migratedCount++;
            appLogger.dWithPackage(
              _migrationPackage,
              'Migrated API key for server: $serverId',
            );
          }
        }
      }

      // Mark migration as complete
      await prefs.setBool(_migrationCompleteKey, true);

      appLogger.iWithPackage(
        _migrationPackage,
        'Migration completed successfully. Migrated $migratedCount API keys',
      );
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        _migrationPackage,
        'Migration failed',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't mark as complete so it can retry next time
    }
  }
}
