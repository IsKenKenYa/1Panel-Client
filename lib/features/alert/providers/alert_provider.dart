import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import '../../../data/models/alert_models.dart';
import '../alert_service.dart';

/// 告警中心状态。
///
/// 三块（任务、日志、渠道）各自持有分页数据与筛选条件；写操作统一经
/// [_mutate] 标记变更中状态，错误向上抛出供界面展示。
class AlertProvider extends ChangeNotifier with SafeChangeNotifier {
  AlertProvider({AlertService? service})
      : _service = service ?? AlertService();

  final AlertService _service;

  // ==================== 任务 ====================

  List<AlertInfo> _rules = const <AlertInfo>[];
  int _ruleTotal = 0;
  int _rulePage = 1;
  String? _ruleType;
  String? _ruleStatus;
  bool _ruleLoading = false;
  String? _ruleError;

  // ==================== 日志 ====================

  List<AlertLog> _logs = const <AlertLog>[];
  int _logTotal = 0;
  int _logPage = 1;
  String? _logStatus;
  bool _logLoading = false;
  String? _logError;

  // ==================== 渠道 ====================

  List<AlertConfigInfo> _channels = const <AlertConfigInfo>[];
  bool _channelLoading = false;
  String? _channelError;

  // ==================== 目标选项 ====================

  List<AlertDisk> _disks = const <AlertDisk>[];
  List<AlertClam> _clams = const <AlertClam>[];
  List<AlertCronJob> _cronJobs = const <AlertCronJob>[];

  bool _isMutating = false;

  List<AlertInfo> get rules => _rules;
  int get ruleTotal => _ruleTotal;
  int get rulePage => _rulePage;
  String? get ruleType => _ruleType;
  String? get ruleStatus => _ruleStatus;
  bool get ruleLoading => _ruleLoading;
  String? get ruleError => _ruleError;

  List<AlertLog> get logs => _logs;
  int get logTotal => _logTotal;
  int get logPage => _logPage;
  String? get logStatus => _logStatus;
  bool get logLoading => _logLoading;
  String? get logError => _logError;

  List<AlertConfigInfo> get channels => _channels;
  bool get channelLoading => _channelLoading;
  String? get channelError => _channelError;

  List<AlertDisk> get disks => _disks;
  List<AlertClam> get clams => _clams;
  List<AlertCronJob> get cronJobs => _cronJobs;

  bool get isMutating => _isMutating;

  /// 渠道配置按类型分组；告警任务的告警方式下拉直接使用该集合。
  List<AlertConfigInfo> get enabledChannels =>
      _channels.where((channel) => channel.status != 'Disable').toList();

  Future<void> onServerChanged() async {
    _service.resetForServerChange();
    _rules = const <AlertInfo>[];
    _logs = const <AlertLog>[];
    _channels = const <AlertConfigInfo>[];
    _disks = const <AlertDisk>[];
    _clams = const <AlertClam>[];
    _cronJobs = const <AlertCronJob>[];
    _ruleError = null;
    _logError = null;
    _channelError = null;
    notifyListeners();
    await loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait(<Future<void>>[
      loadRules(),
      loadLogs(),
      loadChannels(),
    ]);
  }

  // ==================== 任务 ====================

  Future<void> loadRules({int page = 1}) async {
    if (isDisposed) return;
    _ruleLoading = true;
    _ruleError = null;
    _rulePage = page;
    notifyListeners();
    try {
      final result = await _service.searchAlerts(
        page: page,
        type: _ruleType,
        status: _ruleStatus,
      );
      _rules = result.items;
      _ruleTotal = result.total;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.alert.provider',
        'loadRules failed',
        error: error,
        stackTrace: stackTrace,
      );
      _rules = const <AlertInfo>[];
      _ruleError = ErrorMessageUtils.userFacingMessage(error);
    } finally {
      if (!isDisposed) {
        _ruleLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> setRuleType(String? type) async {
    _ruleType = type;
    await loadRules();
  }

  Future<void> setRuleStatus(String? status) async {
    _ruleStatus = status;
    await loadRules();
  }

  Future<void> createRule(AlertCreate request) async {
    await _mutate(() async {
      await _service.createAlert(request);
      await loadRules();
    });
  }

  Future<void> updateRule(AlertUpdate request) async {
    await _mutate(() async {
      await _service.updateAlert(request);
      await loadRules();
    });
  }

  Future<void> deleteRule(int id) async {
    await _mutate(() async {
      await _service.deleteAlert(id);
      await loadRules();
    });
  }

  Future<void> toggleRule(int id, bool enable) async {
    await _mutate(() async {
      await _service.updateAlertStatus(id, enable ? 'Enable' : 'Disable');
      await loadRules();
    });
  }

  // ==================== 目标选项 ====================

  Future<void> loadTargetOptions() async {
    try {
      final results = await Future.wait(<Future<Object>>[
        _service.listDisks(),
        _service.listClams(),
        _service.listCronJobs(),
      ]);
      if (isDisposed) return;
      _disks = results[0] as List<AlertDisk>;
      _clams = results[1] as List<AlertClam>;
      _cronJobs = results[2] as List<AlertCronJob>;
      notifyListeners();
    } catch (error, stackTrace) {
      appLogger.wWithPackage(
        'features.alert.provider',
        'loadTargetOptions failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ==================== 日志 ====================

  Future<void> loadLogs({int page = 1}) async {
    if (isDisposed) return;
    _logLoading = true;
    _logError = null;
    _logPage = page;
    notifyListeners();
    try {
      final result = await _service.searchLogs(page: page, status: _logStatus);
      _logs = result.items;
      _logTotal = result.total;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.alert.provider',
        'loadLogs failed',
        error: error,
        stackTrace: stackTrace,
      );
      _logs = const <AlertLog>[];
      _logError = ErrorMessageUtils.userFacingMessage(error);
    } finally {
      if (!isDisposed) {
        _logLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> setLogStatus(String? status) async {
    _logStatus = status;
    await loadLogs();
  }

  Future<void> cleanLogs() async {
    await _mutate(() async {
      await _service.cleanLogs();
      await loadLogs();
    });
  }

  // ==================== 渠道 ====================

  Future<void> loadChannels() async {
    if (isDisposed) return;
    _channelLoading = true;
    _channelError = null;
    notifyListeners();
    try {
      _channels = await _service.listConfigs();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.alert.provider',
        'loadChannels failed',
        error: error,
        stackTrace: stackTrace,
      );
      _channels = const <AlertConfigInfo>[];
      _channelError = ErrorMessageUtils.userFacingMessage(error);
    } finally {
      if (!isDisposed) {
        _channelLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> saveChannel(AlertConfigUpdate request) async {
    await _mutate(() async {
      await _service.saveConfig(request);
      await loadChannels();
    });
  }

  Future<void> deleteChannel(int id) async {
    await _mutate(() async {
      await _service.deleteConfig(id);
      await loadChannels();
    });
  }

  Future<void> toggleChannel(int id, bool enable) async {
    await _mutate(() async {
      await _service.updateConfigStatus(id, enable ? 'Enable' : 'Disable');
      await loadChannels();
    });
  }

  Future<AlertConfigTestResult> testChannel(AlertConfigTest request) async {
    return _service.testConfig(request);
  }

  Future<T> _mutate<T>(Future<T> Function() action) async {
    if (isDisposed) throw StateError('Provider 已释放');
    _isMutating = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      if (!isDisposed) {
        _isMutating = false;
        notifyListeners();
      }
    }
  }
}
