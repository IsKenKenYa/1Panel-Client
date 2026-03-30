import 'package:shared_preferences/shared_preferences.dart';

class AppLockSettings {
  const AppLockSettings({
    required this.enabled,
    required this.lockOnAppOpen,
    required this.lockOnProtectedModule,
    required this.relockAfterMinutes,
    required this.protectedModuleIds,
  });

  static const List<String> defaultProtectedModuleIds = <String>[
    'files',
    'containers',
    'apps',
    'websites',
    'ai',
    'verification',
  ];

  static const AppLockSettings defaults = AppLockSettings(
    enabled: false,
    lockOnAppOpen: true,
    lockOnProtectedModule: true,
    relockAfterMinutes: 5,
    protectedModuleIds: defaultProtectedModuleIds,
  );

  final bool enabled;
  final bool lockOnAppOpen;
  final bool lockOnProtectedModule;
  final int relockAfterMinutes;
  final List<String> protectedModuleIds;

  AppLockSettings copyWith({
    bool? enabled,
    bool? lockOnAppOpen,
    bool? lockOnProtectedModule,
    int? relockAfterMinutes,
    List<String>? protectedModuleIds,
  }) {
    return AppLockSettings(
      enabled: enabled ?? this.enabled,
      lockOnAppOpen: lockOnAppOpen ?? this.lockOnAppOpen,
      lockOnProtectedModule:
          lockOnProtectedModule ?? this.lockOnProtectedModule,
      relockAfterMinutes: relockAfterMinutes ?? this.relockAfterMinutes,
      protectedModuleIds: protectedModuleIds ?? this.protectedModuleIds,
    );
  }
}

class AppLockSettingsStore {
  static const String _enabledKey = 'app_lock_enabled';
  static const String _lockOnAppOpenKey = 'app_lock_on_open';
  static const String _lockOnProtectedModuleKey =
      'app_lock_on_protected_module';
  static const String _relockAfterMinutesKey = 'app_lock_relock_after_minutes';
  static const String _protectedModuleIdsKey = 'app_lock_protected_modules';

  Future<AppLockSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    final enabled =
        prefs.getBool(_enabledKey) ?? AppLockSettings.defaults.enabled;
    final lockOnAppOpen = prefs.getBool(_lockOnAppOpenKey) ??
        AppLockSettings.defaults.lockOnAppOpen;
    final lockOnProtectedModule = prefs.getBool(_lockOnProtectedModuleKey) ??
        AppLockSettings.defaults.lockOnProtectedModule;
    final relockAfterMinutes =
        _normalizeRelockMinutes(prefs.getInt(_relockAfterMinutesKey));
    final protectedModules =
        _normalizeModuleIds(prefs.getStringList(_protectedModuleIdsKey));

    return AppLockSettings(
      enabled: enabled,
      lockOnAppOpen: lockOnAppOpen,
      lockOnProtectedModule: lockOnProtectedModule,
      relockAfterMinutes: relockAfterMinutes,
      protectedModuleIds: protectedModules,
    );
  }

  Future<void> save(AppLockSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setBool(_lockOnAppOpenKey, settings.lockOnAppOpen);
    await prefs.setBool(
      _lockOnProtectedModuleKey,
      settings.lockOnProtectedModule,
    );
    await prefs.setInt(
      _relockAfterMinutesKey,
      _normalizeRelockMinutes(settings.relockAfterMinutes),
    );
    await prefs.setStringList(
      _protectedModuleIdsKey,
      _normalizeModuleIds(settings.protectedModuleIds),
    );
  }

  Future<void> reset() async {
    await save(AppLockSettings.defaults);
  }

  int _normalizeRelockMinutes(int? value) {
    final minutes = value ?? AppLockSettings.defaults.relockAfterMinutes;
    return minutes > 0 ? minutes : AppLockSettings.defaults.relockAfterMinutes;
  }

  List<String> _normalizeModuleIds(List<String>? source) {
    final normalized = <String>[];
    for (final raw in source ?? AppLockSettings.defaultProtectedModuleIds) {
      final value = raw.trim();
      if (value.isEmpty || normalized.contains(value)) {
        continue;
      }
      normalized.add(value);
    }

    if (normalized.isEmpty) {
      return List<String>.from(AppLockSettings.defaultProtectedModuleIds);
    }

    return normalized;
  }
}
