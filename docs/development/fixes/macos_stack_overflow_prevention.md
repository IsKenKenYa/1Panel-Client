# macOS Stack Overflow Prevention Guide

## Overview

Stack Overflow errors on macOS desktop are typically caused by rapid, repeated widget tree rebuilds triggered by provider state changes. This document outlines the patterns that cause these issues and how to prevent them.

## Common Causes

### 1. Multiple Consecutive notifyListeners() Calls

**Problem:**
```dart
void someMethod() {
  _data = _data.copyWith(field1: value1);
  notifyListeners();  // First notification
  asyncMethod();      // This also calls notifyListeners()
}
```

**Solution:**
```dart
void someMethod() {
  _data = _data.copyWith(field1: value1);
  // Don't notify here, let asyncMethod() handle it
  asyncMethod();
}
```

### 2. Synchronous + Asynchronous Updates

**Problem:**
```dart
void onServerChanged() {
  _data = FilesData(currentPath: '/');
  _emitChange();           // Triggers rebuild
  unawaited(initialize()); // Also triggers rebuild during the first rebuild
}
```

**Solution:**
```dart
void onServerChanged() {
  _data = FilesData(currentPath: '/');
  // Don't emit change here, let initialize() handle it
  unawaited(initialize());
}
```

### 3. Widget Tree Rebuilds During Navigation

**Problem:**
```dart
// In a page that uses context.watch<Provider>()
await provider.delete(id);
await currentController.refresh();
navigator.maybePop();  // Page tries to rebuild while being popped
```

**Solution:**
```dart
// Close page first, then perform operations
navigator.pop();
await provider.delete(id);
await currentController.refresh();
```

### 4. Provider Updates During Dispose

**Problem:**
```dart
class MyProvider extends ChangeNotifier {
  Future<void> someAsyncMethod() async {
    // ... async work
    notifyListeners();  // Might be called after dispose
  }
}
```

**Solution:**
```dart
class MyProvider extends ChangeNotifier with SafeChangeNotifier {
  Future<void> someAsyncMethod() async {
    if (isDisposed) return;
    // ... async work
    notifyListeners();  // SafeChangeNotifier checks isDisposed
  }
}
```

## Best Practices

### 1. Use SafeChangeNotifier Mixin

Always use `SafeChangeNotifier` for providers that perform async operations:

```dart
class MyProvider extends ChangeNotifier with SafeChangeNotifier {
  // SafeChangeNotifier automatically checks isDisposed before notifying
}
```

### 2. Check Dispose State in Async Methods

```dart
Future<void> loadData() async {
  if (isDisposed) return;
  
  _isLoading = true;
  notifyListeners();
  
  try {
    final data = await fetchData();
    if (isDisposed) return;  // Check again after await
    
    _data = data;
  } finally {
    if (!isDisposed) {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### 3. Avoid Redundant Notifications

When chaining operations, only notify once at the end:

```dart
// Bad
void updateMultipleFields() {
  setField1(value1);  // notifies
  setField2(value2);  // notifies
  setField3(value3);  // notifies
}

// Good
void updateMultipleFields() {
  _field1 = value1;
  _field2 = value2;
  _field3 = value3;
  notifyListeners();  // Single notification
}
```

### 4. Stop Timers Before State Changes

```dart
Future<void> delete(String id) async {
  stopAutoRefresh();  // Stop timer first
  
  try {
    await repository.delete(id);
    await load();
  } finally {
    if (_items.isNotEmpty) {
      startAutoRefresh();  // Restart only if needed
    }
  }
}
```

### 5. Close Pages Before Destructive Operations

When deleting items that the current page depends on:

```dart
Future<void> deleteItem(BuildContext context, Item item) async {
  final confirmed = await showConfirmDialog(context);
  if (!confirmed) return;
  
  // Close page first
  Navigator.of(context).pop();
  
  // Then perform deletion
  await provider.delete(item.id);
}
```

## Debugging Stack Overflow Issues

### 1. Enable Logging

Add logging to track notification calls:

```dart
@override
void notifyListeners() {
  if (kDebugMode) {
    print('[$runtimeType] notifyListeners called');
    print(StackTrace.current);
  }
  super.notifyListeners();
}
```

### 2. Check for Circular Dependencies

Look for patterns like:
- Provider A updates → Widget rebuilds → Calls Provider B → Provider B updates → Widget rebuilds → Calls Provider A

### 3. Monitor Widget Rebuild Count

```dart
class MyWidget extends StatelessWidget {
  static int _buildCount = 0;
  
  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('MyWidget build count: ${++_buildCount}');
    }
    // ...
  }
}
```

## Platform-Specific Considerations

### Why More Common on macOS?

1. **Different Render Pipeline**: Desktop platforms have different widget tree management
2. **Timing Differences**: State updates may be processed differently on desktop
3. **Layout Complexity**: Desktop layouts often have more nested providers
4. **Navigation Behavior**: Page transitions work differently on desktop

### Testing on All Platforms

Always test provider changes on:
- iOS
- Android
- macOS
- Windows
- Linux

Desktop platforms may expose issues that don't appear on mobile.

## Checklist for New Providers

- [ ] Extends `ChangeNotifier with SafeChangeNotifier`
- [ ] Checks `isDisposed` in all async methods
- [ ] Stops timers in `dispose()`
- [ ] Avoids multiple consecutive `notifyListeners()` calls
- [ ] Doesn't call `notifyListeners()` before async operations that also notify
- [ ] Tested on macOS/Windows/Linux

## Related Fixes

- [macOS Server Delete Crash](./macos_server_delete_crash.md)
- [macOS Keychain Fix](./macos_keychain_fix.md)
