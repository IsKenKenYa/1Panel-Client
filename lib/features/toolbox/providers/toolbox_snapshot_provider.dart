import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';

abstract class ToolboxSnapshotProvider extends ChangeNotifier
    with SafeChangeNotifier {
  int _generation = 0;
  bool _isLoading = false;
  bool _hasSnapshot = false;
  String? _loadError;

  bool get isLoading => _isLoading;
  bool get hasSnapshot => _hasSnapshot;
  String? get loadError => _loadError;

  @protected
  Future<void> loadSnapshot<T>({
    required Future<T> Function() fetch,
    required void Function(T) apply,
    required String logPackage,
    bool silent = false,
  }) async {
    if (isDisposed) return;
    final generation = ++_generation;
    _isLoading = !silent;
    _loadError = null;
    notifyListeners();
    try {
      final snapshot = await fetch();
      if (isDisposed || generation != _generation) return;
      apply(snapshot);
      _hasSnapshot = true;
    } catch (error, stackTrace) {
      if (isDisposed || generation != _generation) return;
      appLogger.eWithPackage(
        logPackage,
        '读取工具数据失败',
        error: error,
        stackTrace: stackTrace,
      );
      _loadError = ErrorMessageUtils.userFacingMessage(error);
    } finally {
      if (!isDisposed && generation == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
