# macOS Server Delete Crash Fix

## Problem

When deleting a server on macOS, the application would crash with a Stack Overflow error. This issue was specific to macOS and did not occur on other platforms.

## Root Causes

The crash was caused by multiple issues working together:

### 1. Widget Tree Rebuild During Navigation

In `ServerDetailPage`, the page uses `context.watch<ServerProvider>()` which causes the entire page to rebuild whenever the provider updates. When deleting a server:

1. User confirms deletion
2. `_deleteServer()` calls `serverProvider.delete()`
3. `delete()` calls `load()` which triggers `notifyListeners()`
4. `context.watch<ServerProvider>()` detects the change and triggers `build()`
5. Meanwhile, `navigator.maybePop()` tries to close the page
6. These operations happen simultaneously, causing the widget tree to be in an inconsistent state
7. Result: Stack Overflow in `RenderObject.dropChild`

### 2. Listener Recursion in ServerListViewModel

The `ServerListViewModel` had a listener that could trigger recursive updates:

```dart
_serverProvider.addListener(() => _onProviderUpdated(context));
```

This listener would call `_onProviderUpdated()` which would then call `notifyListeners()`, potentially creating a feedback loop.

### 3. Metrics Timer Accessing Deleted Server

The `ServerProvider` had a periodic timer that would try to load metrics for servers, including potentially deleted ones, causing additional state inconsistencies.

### 4. Missing Dispose Protection

The provider didn't check if it was disposed before calling `notifyListeners()`, which could cause issues during cleanup.

## Solutions

### 1. Close Page Before Deletion

In `ServerDetailPage._deleteServer()`, now closes the page immediately after confirmation, before starting the deletion process:

```dart
// Close the page first to avoid widget tree issues during deletion
navigator.pop();

await serverProvider.delete(target.config.id);
```

This prevents the widget tree from trying to rebuild while being torn down.

### 2. Simplified Listener in ServerListViewModel

Removed the closure that captured `BuildContext` and replaced it with a simple forwarding listener:

```dart
void _onProviderChanged() {
  // Just notify listeners without triggering coach marks
  notifyListeners();
}
```

Coach marks are now only checked after initial load, not on every provider update.

### 3. Stop Metrics Timer During Deletion

The `delete()` method now stops the metrics refresh timer before deletion and only restarts it if there are remaining servers:

```dart
Future<void> delete(String id) async {
  stopMetricsAutoRefresh();
  
  try {
    await _repository.removeConfig(id);
    await load();
  } finally {
    if (_servers.isNotEmpty) {
      startMetricsAutoRefresh();
    }
  }
}
```

### 4. Added Dispose Protection

Added `_isDisposed` flag and checks throughout the provider to prevent operations after disposal:

```dart
bool _isDisposed = false;

Future<void> load() async {
  if (_isDisposed) return;
  // ...
  safeNotifyListeners();
}

@override
void dispose() {
  _isDisposed = true;
  stopMetricsAutoRefresh();
  super.dispose();
}
```

## Files Modified

- `lib/features/server/server_detail_page.dart` - Close page before deletion
- `lib/features/server/view_models/server_list_view_model.dart` - Simplified listener
- `lib/features/server/server_provider.dart` - Added dispose protection and timer management

## Testing

After applying these fixes:

1. Run the app on macOS
2. Add a server
3. Open server detail page
4. Delete the server from detail page
5. Verify the app does not crash
6. Verify you're returned to the server list
7. Add another server
8. Delete it from the server list page
9. Verify no crash occurs
10. Test file browsing and other features to ensure no regressions

## Why Only on macOS?

The issue was more likely to manifest on macOS due to:
- Different widget rebuild timing on desktop platforms
- macOS-specific render tree behavior
- Desktop layout complexity with multiple nested providers
- Timing differences in how Flutter handles navigation on macOS

## Prevention

To prevent similar issues in the future:

1. **Close pages before destructive operations**: When deleting items that the current page depends on, close the page first
2. **Avoid capturing BuildContext in listeners**: Use explicit method calls instead
3. **Always check dispose state**: Add `_isDisposed` flags to providers that perform async operations
4. **Stop timers before state changes**: Cancel periodic timers before operations that modify the data they depend on
5. **Use safeNotifyListeners()**: Use the SafeChangeNotifier mixin to prevent notifications after dispose
6. **Test on all platforms**: Desktop platforms may have different behavior than mobile
