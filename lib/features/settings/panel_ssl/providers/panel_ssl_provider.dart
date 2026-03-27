import 'package:flutter/foundation.dart';
import 'package:onepanel_client/features/settings/panel_ssl/services/panel_ssl_service.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';
import 'package:onepanel_client/shared/security_gateway/utils/security_gateway_utils.dart';

class PanelSslProvider extends ChangeNotifier {
  final PanelSslService _service;

  PanelSslProvider({PanelSslService? service})
      : _service = service ?? PanelSslService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  Map<String, dynamic> _sslInfo = const <String, dynamic>{};
  List<String> _history = const <String>[];
  int? _lastDownloadedBytes;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  Map<String, dynamic> get sslInfo => _sslInfo;
  bool get hasData => _sslInfo.isNotEmpty;
  List<String> get history => _history;
  int? get lastDownloadedBytes => _lastDownloadedBytes;

  String get domain => _readValue(const ['domain', 'bindDomain']);
  String get status => _readValue(const ['status', 'ssl']);
  String get sslType => _readValue(const ['sslType', 'type']);
  String get provider => _readValue(const ['provider', 'issuer']);
  String get expiration =>
      _readValue(const ['expirationDate', 'expiration', 'expiresAt']);
  String get updatedAt =>
      _readValue(const ['updatedAt', 'updateTime', 'updated_at']);
  String get certificatePath =>
      _readValue(const ['certPath', 'pemPath', 'certificatePath']);
  String get keyPath => _readValue(const ['keyPath', 'privateKeyPath']);
  String get issuer => _readValue(const ['issuer', 'provider']);
  String get serialNumber => _readValue(const ['serialNumber', 'serial']);

  CertificateHealthStatus get healthStatus =>
      resolveCertificateHealthStatus(expiration);

  List<RiskNotice> get riskNotices {
    final notices = <RiskNotice>[];
    final expiryDays = daysUntilExpiration(expiration);

    if (expiryDays == null) {
      notices.add(
        const RiskNotice(
          level: RiskLevel.medium,
          title: 'Certificate expiry unknown',
          message: 'The panel certificate expiration time could not be parsed.',
        ),
      );
    } else if (expiryDays < 0) {
      notices.add(
        const RiskNotice(
          level: RiskLevel.high,
          title: 'Certificate expired',
          message:
              'The panel TLS certificate has already expired and should be replaced immediately.',
        ),
      );
    } else if (expiryDays <= 30) {
      notices.add(
        RiskNotice(
          level: expiryDays <= 7 ? RiskLevel.high : RiskLevel.medium,
          title: 'Certificate expiring soon',
          message: 'The panel TLS certificate expires in $expiryDays day(s).',
        ),
      );
    }

    if (sslType.toLowerCase().contains('self')) {
      notices.add(
        const RiskNotice(
          level: RiskLevel.low,
          title: 'Self-signed certificate',
          message:
              'Self-signed certificates can trigger browser trust warnings.',
        ),
      );
    }

    return notices;
  }

  List<String> validateUploadFields({
    required String domain,
    required String cert,
    required String key,
  }) {
    final errors = <String>[];
    if (domain.trim().isEmpty) {
      errors.add('Domain is required.');
    }
    if (cert.trim().isEmpty) {
      errors.add('Certificate content is required.');
    } else if (!cert.contains('BEGIN CERTIFICATE')) {
      errors.add('Certificate must contain a PEM certificate block.');
    }
    if (key.trim().isEmpty) {
      errors.add('Private key content is required.');
    } else if (!key.contains('BEGIN')) {
      errors.add('Private key must contain a PEM key block.');
    }
    return errors;
  }

  String buildCertificateSummary() {
    return [
      'Domain: $domain',
      'Status: $status',
      'Type: $sslType',
      'Provider: $provider',
      'Issuer: $issuer',
      'Serial: $serialNumber',
      'Expiration: $expiration',
    ].join('\n');
  }

  Future<void> loadSslInfo({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _sslInfo = await _service.getSslInfo();
      _error = null;
      if (_history.isEmpty && hasData) {
        _appendHistory('Loaded current panel TLS status.');
      }
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
    final validationErrors = validateUploadFields(
      domain: domain,
      cert: cert,
      key: key,
    );
    if (validationErrors.isNotEmpty) {
      _error = validationErrors.join('\n');
      notifyListeners();
      return false;
    }

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
      _appendHistory('Uploaded a new panel TLS certificate for $domain.');
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
      final bytes = await _service.downloadSsl();
      _lastDownloadedBytes = bytes.length;
      _error = null;
      _appendHistory(
          'Downloaded panel TLS certificate bundle (${bytes.length} bytes).');
      notifyListeners();
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

  void _appendHistory(String entry) {
    _history = <String>[
      entry,
      ..._history,
    ].take(5).toList(growable: false);
  }
}
