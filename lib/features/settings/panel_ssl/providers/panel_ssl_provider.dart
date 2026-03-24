import 'package:flutter/foundation.dart';
import 'package:onepanel_client/features/settings/panel_ssl/services/panel_ssl_service.dart';

class PanelSslProvider extends ChangeNotifier {
  final PanelSslService _service;

  PanelSslProvider({PanelSslService? service}) : _service = service ?? PanelSslService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  Map<String, dynamic> _sslInfo = const <String, dynamic>{};

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  Map<String, dynamic> get sslInfo => _sslInfo;
  bool get hasData => _sslInfo.isNotEmpty;

  String get domain => _readValue(const ['domain', 'bindDomain']);
  String get status => _readValue(const ['status', 'ssl']);
  String get sslType => _readValue(const ['sslType', 'type']);
  String get provider => _readValue(const ['provider', 'issuer']);
  String get expiration => _readValue(const ['expirationDate', 'expiration', 'expiresAt']);

  Future<void> loadSslInfo({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _sslInfo = await _service.getSslInfo();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadSsl({
    required String domain,
    required String sslType,
    required String cert,
    required String key,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateSsl(
        domain: domain,
        sslType: sslType,
        cert: cert,
        key: key,
      );
      await loadSslInfo(silent: true);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> downloadSsl() async {
    try {
      await _service.downloadSsl();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  String _readValue(List<String> keys) {
    for (final key in keys) {
      final value = _sslInfo[key];
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '-';
  }
}
