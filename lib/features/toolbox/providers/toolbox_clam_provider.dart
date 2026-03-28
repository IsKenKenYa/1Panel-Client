import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/toolbox_models.dart';
import 'package:onepanel_client/features/toolbox/services/toolbox_clam_service.dart';

class ToolboxClamProvider extends ChangeNotifier {
  ToolboxClamProvider({ToolboxClamService? service})
      : _service = service ?? ToolboxClamService();

  final ToolboxClamService _service;

  bool _isLoading = false;
  String? _error;
  List<ClamBaseInfo> _tasks = const <ClamBaseInfo>[];
  List<ClamLogInfo> _records = const <ClamLogInfo>[];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ClamBaseInfo> get tasks => _tasks;
  List<ClamLogInfo> get records => _records;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final snapshot = await _service.loadSnapshot();
      _tasks = snapshot.tasks;
      _records = snapshot.records;
      _error = null;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_clam',
        'load clam failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
