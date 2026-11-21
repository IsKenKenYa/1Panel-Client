import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/platform/services/platform_file_service.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/features/settings/panel_ssl/services/panel_ssl_service.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';
import 'package:onepanel_client/shared/security_gateway/utils/security_gateway_utils.dart';

enum PanelSslHistoryAction { loaded, uploaded, downloaded }

typedef PanelSslHistoryEntry = ({
  PanelSslHistoryAction action,
  DateTime createdAt,
  String? domain,
  int? bytes,
});

class PanelSslProvider extends ChangeNotifier with SafeChangeNotifier {
  PanelSslProvider.forServer(ApiConfig server)
      : _service = PanelSslService.forServer(server);

  final PanelSslService _service;
  Map<String, dynamic>? _info;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _loadError;
  final List<PanelSslHistoryEntry> _history = [];

  bool get busy => _isLoading || _isSubmitting;
  bool get hasData => _info != null;
  bool get hasCertificate => _info?.isNotEmpty ?? false;
  String? get loadError => _loadError;
  String? get domain => _info?['domain'] as String?;
  String? get expiration => _info?['timeout'] as String?;
  String? get certificatePath => _info?['rootPath'] as String?;
  CertificateHealthStatus get health =>
      resolveCertificateHealthStatus(expiration);
  int? get daysRemaining => daysUntilExpiration(expiration);
  List<PanelSslHistoryEntry> get history => List.unmodifiable(_history);

  Future<void> loadSslInfo() async {
    if (busy) return;
    await _readSslInfo();
  }

  Future<void> _readSslInfo() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      _info = await _service.getSslInfo();
      if (_history.isEmpty && hasCertificate) {
        _record(PanelSslHistoryAction.loaded);
      }
    } catch (error, trace) {
      _loadError = ErrorMessageUtils.normalize(error);
      appLogger.eWithPackage(
        'panel_ssl',
        '加载面板证书失败',
        error: error,
        stackTrace: trace,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadSsl({required String cert, required String key}) async {
    if (busy) throw StateError('面板证书操作正在进行');
    _isSubmitting = true;
    notifyListeners();
    try {
      await _service.updateSsl(cert: cert, key: key);
      await _readSslInfo();
      _record(PanelSslHistoryAction.uploaded);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<SaveOutcome> downloadSsl() async {
    if (busy) throw StateError('面板证书操作正在进行');
    _isSubmitting = true;
    notifyListeners();
    try {
      final result = await _service.downloadSsl();
      if (!result.file.isCancelled) {
        _record(PanelSslHistoryAction.downloaded, bytes: result.size);
      }
      return result.file;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void _record(PanelSslHistoryAction action, {int? bytes}) {
    _history.insert(0, (
      action: action,
      domain: domain,
      bytes: bytes,
      createdAt: DateTime.now(),
    ));
    if (_history.length > 5) _history.removeLast();
  }
}
