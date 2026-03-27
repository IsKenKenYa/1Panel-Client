import 'package:flutter/foundation.dart';
import '../../../data/models/ssl_models.dart';
import '../services/website_certificate_service.dart';
import 'package:onepanel_client/shared/security_gateway/utils/security_gateway_utils.dart';

enum CertificateExpiryWindow {
  all,
  expired,
  within7Days,
  within30Days,
}

class WebsiteSslCenterProvider extends ChangeNotifier {
  static const String providerFilterAll = '__all__';

  WebsiteSslCenterProvider({WebsiteCertificateService? service})
      : _service = service;

  WebsiteCertificateService? _service;

  bool isLoading = false;
  String? error;
  List<WebsiteSSL> certificates = const <WebsiteSSL>[];
  List<WebsiteSSL> _allCertificates = const <WebsiteSSL>[];
  String searchQuery = '';
  String providerFilter = providerFilterAll;
  CertificateExpiryWindow expiryWindow = CertificateExpiryWindow.all;

  Future<void> _ensureService() async {
    _service ??= WebsiteCertificateService();
  }

  List<String> get providerOptions {
    final providers = _allCertificates
        .map((certificate) => certificate.provider?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return <String>[providerFilterAll, ...providers];
  }

  int get expiredCount => _allCertificates
      .where((cert) => (daysUntilExpiration(cert.expireDate) ?? 1) < 0)
      .length;
  int get within7DaysCount => _allCertificates
      .where((cert) =>
          _matchesExpiryWindow(cert, CertificateExpiryWindow.within7Days))
      .length;
  int get within30DaysCount => _allCertificates
      .where((cert) =>
          _matchesExpiryWindow(cert, CertificateExpiryWindow.within30Days))
      .length;

  Map<String, List<WebsiteSSL>> get groupedCertificates {
    if (expiryWindow != CertificateExpiryWindow.all) {
      return <String, List<WebsiteSSL>>{
        _groupLabel(expiryWindow): certificates
      };
    }

    final expired = <WebsiteSSL>[];
    final within7 = <WebsiteSSL>[];
    final within30 = <WebsiteSSL>[];
    final healthy = <WebsiteSSL>[];

    for (final certificate in certificates) {
      final days = daysUntilExpiration(certificate.expireDate);
      if (days == null) {
        healthy.add(certificate);
      } else if (days < 0) {
        expired.add(certificate);
      } else if (days <= 7) {
        within7.add(certificate);
      } else if (days <= 30) {
        within30.add(certificate);
      } else {
        healthy.add(certificate);
      }
    }

    return <String, List<WebsiteSSL>>{
      'Expired': expired,
      'Within 7 days': within7,
      'Within 30 days': within30,
      'Healthy': healthy,
    }..removeWhere((_, value) => value.isEmpty);
  }

  Future<void> load({String? domain}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _ensureService();
      searchQuery = domain ?? searchQuery;
      _allCertificates = await _service!.searchCertificates(domain: domain);
      _applyFilters();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCertificate(int id) async {
    try {
      await _ensureService();
      await _service!.deleteCertificate(id);
      await load();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> createCertificate(WebsiteSSLCreate request) async {
    await _ensureService();
    await _service!.createCertificate(request);
    await load();
  }

  Future<void> obtainCertificate(int id) async {
    await _ensureService();
    await _service!.applyCertificate(WebsiteSSLApply(id: id));
    await load();
  }

  Future<void> updateCertificate(WebsiteSSLUpdate request) async {
    await _ensureService();
    await _service!.updateCertificate(request);
    await load();
  }

  Future<void> uploadCertificate(WebsiteSSLUpload request) async {
    await _ensureService();
    await _service!.uploadCertificate(request);
    await load();
  }

  void setSearchQuery(String value) {
    searchQuery = value.trim();
    _applyFilters();
    notifyListeners();
  }

  void setProviderFilter(String value) {
    providerFilter = value;
    _applyFilters();
    notifyListeners();
  }

  void setExpiryWindow(CertificateExpiryWindow value) {
    expiryWindow = value;
    _applyFilters();
    notifyListeners();
  }

  int affectedWebsiteCount(WebsiteSSL certificate) {
    return certificate.websites?.length ?? 0;
  }

  List<String> affectedWebsiteDomains(
    WebsiteSSL certificate, {
    int limit = 3,
  }) {
    final websites = certificate.websites ?? const <Website>[];
    final names = websites
        .map((website) => website.primaryDomain?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (limit <= 0 || names.length <= limit) {
      return names;
    }
    return names.take(limit).toList(growable: false);
  }

  bool hasHighImpact(WebsiteSSL certificate) {
    return affectedWebsiteCount(certificate) >= 3;
  }

  void _applyFilters() {
    final query = searchQuery.toLowerCase();
    final filtered = _allCertificates.where((certificate) {
      final providerMatches = providerFilter == providerFilterAll ||
          (certificate.provider ?? '') == providerFilter;
      final domains = <String>[
        certificate.primaryDomain ?? '',
        ...?certificate.domains,
      ].join(' ').toLowerCase();
      final queryMatches = query.isEmpty || domains.contains(query);
      final expiryMatches = _matchesExpiryWindow(certificate, expiryWindow);
      return providerMatches && queryMatches && expiryMatches;
    }).toList()
      ..sort((a, b) {
        final left = daysUntilExpiration(a.expireDate) ?? 999999;
        final right = daysUntilExpiration(b.expireDate) ?? 999999;
        return left.compareTo(right);
      });
    certificates = filtered;
  }

  bool _matchesExpiryWindow(
      WebsiteSSL certificate, CertificateExpiryWindow window) {
    final days = daysUntilExpiration(certificate.expireDate);
    switch (window) {
      case CertificateExpiryWindow.all:
        return true;
      case CertificateExpiryWindow.expired:
        return days != null && days < 0;
      case CertificateExpiryWindow.within7Days:
        return days != null && days >= 0 && days <= 7;
      case CertificateExpiryWindow.within30Days:
        return days != null && days >= 0 && days <= 30;
    }
  }

  String _groupLabel(CertificateExpiryWindow window) {
    switch (window) {
      case CertificateExpiryWindow.all:
        return 'All certificates';
      case CertificateExpiryWindow.expired:
        return 'Expired';
      case CertificateExpiryWindow.within7Days:
        return 'Within 7 days';
      case CertificateExpiryWindow.within30Days:
        return 'Within 30 days';
    }
  }
}
