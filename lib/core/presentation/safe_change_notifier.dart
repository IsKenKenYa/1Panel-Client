import 'package:flutter/foundation.dart';

/// Guards [notifyListeners] against late async callbacks after disposal.
///
/// This is especially important on desktop where shell/module switching can
/// dispose providers while in-flight network requests are still completing.
mixin SafeChangeNotifier on ChangeNotifier {
  bool _isDisposed = false;

  bool get isDisposed => _isDisposed;

  @override
  void notifyListeners() {
    if (_isDisposed) {
      return;
    }
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
