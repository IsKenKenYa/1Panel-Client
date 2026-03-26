import 'package:flutter/foundation.dart';

enum AsyncViewStatus {
  initial,
  loading,
  success,
  empty,
  error,
}

mixin AsyncStateNotifier on ChangeNotifier {
  AsyncViewStatus _status = AsyncViewStatus.initial;
  String? _errorMessage;

  AsyncViewStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AsyncViewStatus.loading;
  bool get hasError => _status == AsyncViewStatus.error;
  bool get isEmpty => _status == AsyncViewStatus.empty;

  @protected
  void setLoading({bool notify = true}) {
    _status = AsyncViewStatus.loading;
    _errorMessage = null;
    if (notify) {
      notifyListeners();
    }
  }

  @protected
  void setSuccess({bool isEmpty = false, bool notify = true}) {
    _status = isEmpty ? AsyncViewStatus.empty : AsyncViewStatus.success;
    _errorMessage = null;
    if (notify) {
      notifyListeners();
    }
  }

  @protected
  void setError(
    Object error, {
    bool notify = true,
  }) {
    _status = AsyncViewStatus.error;
    _errorMessage = _normalizeErrorMessage(error);
    if (notify) {
      notifyListeners();
    }
  }

  @protected
  void resetState({bool notify = true}) {
    _status = AsyncViewStatus.initial;
    _errorMessage = null;
    if (notify) {
      notifyListeners();
    }
  }

  @protected
  void clearError({bool notify = true}) {
    if (_status == AsyncViewStatus.error) {
      _status = AsyncViewStatus.initial;
    }
    _errorMessage = null;
    if (notify) {
      notifyListeners();
    }
  }

  String? _normalizeErrorMessage(Object error) {
    final message = error.toString().trim();
    if (message.isEmpty) {
      return null;
    }
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length).trim();
    }
    return message;
  }
}
