# macOS Keychain Access Fix

## Problem

On macOS, the app was unable to reliably read API keys from FlutterSecureStorage, causing 401 Unauthorized errors even when valid API keys were configured. The symptoms were:

- Server list could display names and URLs
- Server switching UI worked
- But actual API requests failed with 401 errors
- API keys appeared to be empty when making requests

## Root Cause

The issue had two underlying causes:

### 1. Missing Keychain Entitlements

The macOS app was sandboxed (`com.apple.security.app-sandbox = true`) but lacked the required keychain access entitlement. Without `keychain-access-groups`, sandboxed macOS apps cannot access the keychain, causing all FlutterSecureStorage operations to silently fail or timeout.

### 2. Suboptimal FlutterSecureStorage Configuration

FlutterSecureStorage was initialized with default settings:
- Very short timeout (200ms) that could cause premature failures
- No platform-specific options for macOS
- No explicit accessibility settings for keychain items

## Solution

### 1. Added Keychain Entitlements

Updated both `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.onepanel.client</string>
</array>
```

This grants the app explicit permission to access its keychain group.

### 2. Enabled Code Signing

Updated `macos/Runner.xcodeproj/project.pbxproj` to change `CODE_SIGN_IDENTITY` from `"-"` (don't sign) to `"Apple Development"` for all build configurations (Debug, Release, Profile).

Keychain entitlements require the app to be properly signed. Using "Apple Development" enables automatic signing with your development certificate for local development.

### 3. Improved FlutterSecureStorage Configuration

Updated all FlutterSecureStorage initializations with proper platform-specific options:

```dart
const FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  ),
  mOptions: MacOsOptions(
    accessibility: KeychainAccessibility.first_unlock,
  ),
)
```

Key improvements:
- Increased timeout from 200ms to 5 seconds
- Set `KeychainAccessibility.first_unlock` for better reliability
- Ensures keychain items are accessible after device first unlock
- Consistent configuration across iOS and macOS
- Removed deprecated `encryptedSharedPreferences` option for Android

### 4. Removed Fallback Mechanism

The previous implementation had a complex fallback system using SharedPreferences and in-memory storage. This was removed because:
- It masked the real problem instead of fixing it
- Created security concerns (API keys in SharedPreferences)
- Added unnecessary complexity
- Made debugging harder

### 5. Added Migration

Created `ApiConfigMigration` to migrate any existing API keys from the old SharedPreferences fallback to proper secure storage. This ensures users who had the fallback active won't lose their configurations.

## Files Modified

1. `macos/Runner/DebugProfile.entitlements` - Added keychain entitlement
2. `macos/Runner/Release.entitlements` - Added keychain entitlement
3. `macos/Runner.xcodeproj/project.pbxproj` - Changed CODE_SIGN_IDENTITY from "-" to "Apple Development"
4. `lib/core/config/api_config.dart` - Improved storage configuration, removed fallback
5. `lib/features/auth/auth_session_store.dart` - Improved storage configuration
6. `lib/core/storage/hive_storage_service.dart` - Improved storage configuration
7. `lib/core/config/api_config_migration.dart` - New migration helper
8. `lib/main.dart` - Added migration call during app initialization

## Testing

After applying this fix:

1. Ensure you have an Apple Developer account or use a Personal Team (Xcode handles this automatically)
2. Clean build the macOS app: `flutter clean && flutter build macos`
3. Run the app
4. Configure a server with API key
5. Verify API requests succeed (no 401 errors)
6. Restart the app
7. Verify API key persists and requests still work

Note: On first run, Xcode may prompt you to select a development team. Choose your Apple ID or Personal Team.

## Technical Details

### Why `first_unlock` Accessibility?

`KeychainAccessibility.first_unlock` means:
- Items are accessible after the device is unlocked once after boot
- Provides good balance between security and availability
- More reliable than `unlocked` (which requires device to be currently unlocked)
- Appropriate for API keys that need to be available when app is running

### Why 5 Second Timeout?

The previous 200ms timeout was too aggressive:
- Keychain operations can take longer on first access
- macOS keychain may need to initialize
- Network-synced keychain items may need time
- 5 seconds provides reasonable buffer while still catching real failures

## Related Issues

This fix resolves the "macOS 下 API key 读取不稳定" issue where API keys would intermittently fail to load on macOS desktop.

## References

- [Apple Keychain Services Documentation](https://developer.apple.com/documentation/security/keychain_services)
- [flutter_secure_storage Package](https://pub.dev/packages/flutter_secure_storage)
- [macOS App Sandbox Entitlements](https://developer.apple.com/documentation/bundleresources/entitlements)
