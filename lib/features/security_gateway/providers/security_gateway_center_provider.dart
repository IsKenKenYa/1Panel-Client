import 'package:flutter/foundation.dart';
import 'package:onepanel_client/data/models/ssl_models.dart';
import 'package:onepanel_client/features/openresty/services/openresty_service.dart';
import 'package:onepanel_client/features/settings/panel_ssl/services/panel_ssl_service.dart';
import 'package:onepanel_client/features/websites/services/website_certificate_service.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';
import 'package:onepanel_client/shared/security_gateway/security_gateway_snapshot_store.dart';
import 'package:onepanel_client/shared/security_gateway/utils/security_gateway_utils.dart';

enum SecurityGatewaySection {
  panelTls,
  websiteCertificates,
  openresty,
}

class SecurityGatewayCenterProvider extends ChangeNotifier {
  SecurityGatewayCenterProvider({
    this.initialWebsiteId,
    PanelSslService? panelSslService,
    WebsiteCertificateService? websiteCertificateService,
    OpenRestyService? openRestyService,
    SecurityGatewaySnapshotStore? snapshotStore,
  })  : _panelSslService = panelSslService ?? PanelSslService(),
        _websiteCertificateService =
            websiteCertificateService ?? WebsiteCertificateService(),
        _openRestyService = openRestyService ?? OpenRestyService(),
        _snapshotStore = snapshotStore ?? SecurityGatewaySnapshotStore.instance;

  final int? initialWebsiteId;
  final PanelSslService _panelSslService;
  final WebsiteCertificateService _websiteCertificateService;
  final OpenRestyService _openRestyService;
  final SecurityGatewaySnapshotStore _snapshotStore;

  bool isLoading = false;
  String? error;
  Map<String, dynamic> panelSslInfo = const <String, dynamic>{};
  List<WebsiteSSL> certificates = const <WebsiteSSL>[];
  OpenRestySnapshot openRestySnapshot = const OpenRestySnapshot();

  bool get panelTlsEnabled => panelSslInfo.isNotEmpty;
  int get expiringCertificateCount => certificates
      .where(
          (certificate) => _isExpiringSoon(certificate.expireDate?.toString()))
      .length;
  bool get openRestyRunning =>
      ((openRestySnapshot.status['active'] as num?)?.toInt() ?? 0) > 0;
  List<ConfigRollbackSnapshot<Object>> get recentSnapshots =>
      _snapshotStore.recent(limit: 5);

  String get latestApplyResult => recentSnapshots.isEmpty
      ? 'No recent local snapshot'
      : recentSnapshots.first.title;

  List<RiskNotice> get riskNotices {
    final notices = <RiskNotice>[];
    final panelExpiry = panelSslInfo['expirationDate']?.toString() ??
        panelSslInfo['expiration']?.toString() ??
        panelSslInfo['expiresAt']?.toString();
    if (resolveCertificateHealthStatus(panelExpiry) ==
        CertificateHealthStatus.expired) {
      notices.add(
        const RiskNotice(
          level: RiskLevel.high,
          title: 'Panel TLS expired',
          message:
              'The panel TLS certificate is expired and should be replaced.',
        ),
      );
    }
    if (expiringCertificateCount > 0) {
      notices.add(
        RiskNotice(
          level: RiskLevel.medium,
          title: 'Website certificates expiring',
          message:
              '$expiringCertificateCount website certificate(s) expire within 30 days.',
        ),
      );
    }
    if (!openRestyRunning) {
      notices.add(
        const RiskNotice(
          level: RiskLevel.high,
          title: 'OpenResty status unavailable',
          message: 'The gateway is not reporting as active.',
        ),
      );
    }
    return notices;
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _snapshotStore.ensureInitialized();
      final results = await Future.wait<dynamic>([
        _panelSslService.getSslInfo(),
        _websiteCertificateService.searchCertificates(pageSize: 50),
        _openRestyService.loadSnapshot(),
      ]);
      panelSslInfo = results[0] as Map<String, dynamic>;
      certificates = results[1] as List<WebsiteSSL>;
      openRestySnapshot = results[2] as OpenRestySnapshot;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rollbackLatest() async {
    await _snapshotStore.ensureInitialized();
    final scopes = <String>[
      if (initialWebsiteId != null) 'website_https:$initialWebsiteId',
      'openresty_https',
      'openresty_modules',
      'openresty_config',
    ];
    final snapshot = _snapshotStore.latestForScopes(scopes);
    if (snapshot == null) {
      return false;
    }
    try {
      switch (snapshot.scope) {
        case 'openresty_https':
          await _openRestyService
              .updateHttps(Map<String, dynamic>.from(snapshot.data as Map));
          break;
        case 'openresty_modules':
          await _openRestyService
              .updateModules(Map<String, dynamic>.from(snapshot.data as Map));
          break;
        case 'openresty_config':
          await _openRestyService.updateConfigSource(snapshot.data as String);
          break;
        default:
          if (snapshot.scope.startsWith('website_https:') &&
              initialWebsiteId != null) {
            await _websiteCertificateService.updateHttpsConfig(
              websiteId: initialWebsiteId!,
              request: WebsiteHttpsUpdateRequest.fromJson(
                Map<String, dynamic>.from(snapshot.data as Map),
              ),
            );
          } else {
            return false;
          }
      }
      await load();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  String recentSnapshotSummary(String scopePrefix) {
    for (final snapshot in recentSnapshots) {
      if (snapshot.scope.startsWith(scopePrefix)) {
        return snapshot.summary;
      }
    }
    return 'No recent local snapshot';
  }

  bool _isExpiringSoon(String? expiration) {
    final days = daysUntilExpiration(expiration);
    return days != null && days >= 0 && days <= 30;
  }
}
