import 'package:flutter/foundation.dart';
import 'package:onepanel_client/data/models/ssl_models.dart';
import 'package:onepanel_client/features/websites/services/website_certificate_service.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';
import 'package:onepanel_client/shared/security_gateway/security_gateway_snapshot_store.dart';
import 'package:onepanel_client/shared/security_gateway/utils/security_gateway_utils.dart';

class WebsiteSiteSslProvider extends ChangeNotifier {
  WebsiteSiteSslProvider({
    required this.websiteId,
    this.expectedDomain,
    WebsiteCertificateService? service,
    SecurityGatewaySnapshotStore? snapshotStore,
  })  : _service = service,
        _snapshotStore = snapshotStore ?? SecurityGatewaySnapshotStore.instance;

  final int websiteId;
  final String? expectedDomain;
  WebsiteCertificateService? _service;
  final SecurityGatewaySnapshotStore _snapshotStore;

  bool isLoading = false;
  bool isSaving = false;
  String? error;
  WebsiteHttpsConfig? httpsConfig;
  WebsiteSSL? boundCertificate;
  List<WebsiteSSL> certificates = const <WebsiteSSL>[];
  WebsiteSSL? selectedCertificate;
  ConfigDraftState<WebsiteHttpsUpdateRequest>? strategyDraft;
  ConfigRollbackSnapshot<Object>? rollbackSnapshot;

  bool get hasPendingChanges => strategyDraft?.hasChanges ?? false;
  bool get canRollback => rollbackSnapshot != null;
  List<RiskNotice> get currentRisks =>
      _buildRisks(currentStrategy, boundCertificate);
  List<RiskNotice> get pendingRisks =>
      strategyDraft?.risks ?? const <RiskNotice>[];
  String get snapshotScope => 'website_https:$websiteId';

  Future<void> _ensureService() async {
    _service ??= WebsiteCertificateService();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _ensureService();
      final results = await Future.wait<dynamic>([
        _service!.getHttpsConfig(websiteId),
        _service!.getBoundCertificate(websiteId),
        _service!.searchCertificates(),
      ]);
      httpsConfig = results[0] as WebsiteHttpsConfig;
      boundCertificate = results[1] as WebsiteSSL?;
      certificates = results[2] as List<WebsiteSSL>;
      selectedCertificate = boundCertificate ?? httpsConfig?.ssl;
      rollbackSnapshot = _snapshotStore.read(snapshotScope);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  WebsiteHttpsUpdateRequest get currentStrategy {
    return WebsiteHttpsUpdateRequest(
      websiteId: websiteId,
      enable: httpsConfig?.enable ?? false,
      httpConfig: httpsConfig?.httpConfig ?? 'HTTPAlso',
      type: 'existed',
      websiteSSLId: boundCertificate?.id ?? httpsConfig?.ssl?.id,
      hsts: httpsConfig?.hsts,
      hstsIncludeSubDomains: httpsConfig?.hstsIncludeSubDomains,
      http3: httpsConfig?.http3,
      sslProtocol: httpsConfig?.sslProtocol,
      algorithm: httpsConfig?.algorithm,
    );
  }

  void selectCertificate(WebsiteSSL? certificate) {
    selectedCertificate = certificate;
    stageHttpsStrategy(certificate: certificate);
  }

  void stageHttpsStrategy({
    bool? enable,
    String? httpConfig,
    WebsiteSSL? certificate,
    bool clearCertificate = false,
  }) {
    final nextCertificate = clearCertificate
        ? null
        : certificate ?? selectedCertificate ?? boundCertificate;
    selectedCertificate = nextCertificate;
    final next = WebsiteHttpsUpdateRequest(
      websiteId: websiteId,
      enable: enable ?? currentStrategy.enable,
      httpConfig: httpConfig ?? currentStrategy.httpConfig,
      type: 'existed',
      websiteSSLId: nextCertificate?.id,
      hsts: currentStrategy.hsts,
      hstsIncludeSubDomains: currentStrategy.hstsIncludeSubDomains,
      http3: currentStrategy.http3,
      sslProtocol: currentStrategy.sslProtocol,
      algorithm: currentStrategy.algorithm,
    );
    strategyDraft = ConfigDraftState<WebsiteHttpsUpdateRequest>(
      currentValue: currentStrategy,
      draftValue: next,
      diffItems: _buildDiff(currentStrategy, next, nextCertificate),
      risks: _buildRisks(next, nextCertificate),
    );
    notifyListeners();
  }

  void discardDraft() {
    strategyDraft = null;
    selectedCertificate = boundCertificate;
    notifyListeners();
  }

  Future<bool> applyHttpsStrategy() async {
    final draft = strategyDraft;
    if (draft == null || !draft.hasChanges) {
      return false;
    }

    isSaving = true;
    error = null;
    notifyListeners();
    try {
      final snapshot = ConfigRollbackSnapshot<Map<String, dynamic>>(
        scope: snapshotScope,
        title: 'Website HTTPS Strategy',
        summary:
            'Rollback to the previous successful HTTPS binding for website #$websiteId',
        data: currentStrategy.toJson(),
        createdAt: DateTime.now(),
      );
      _snapshotStore.save(snapshot);
      rollbackSnapshot = _snapshotStore.read(snapshotScope);

      httpsConfig = await _service!.updateHttpsConfig(
        websiteId: websiteId,
        request: draft.draftValue,
      );
      boundCertificate = await _service!.getBoundCertificate(websiteId) ??
          _findCertificateById(draft.draftValue.websiteSSLId);
      selectedCertificate = boundCertificate;
      strategyDraft = null;
      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> rollbackLastSuccessful() async {
    final snapshot = rollbackSnapshot;
    if (snapshot == null || snapshot.data is! Map) {
      return false;
    }

    isSaving = true;
    error = null;
    notifyListeners();
    try {
      final request = WebsiteHttpsUpdateRequest.fromJson(
        Map<String, dynamic>.from(snapshot.data as Map),
      );
      httpsConfig = await _service!.updateHttpsConfig(
        websiteId: websiteId,
        request: request,
      );
      boundCertificate = await _service!.getBoundCertificate(websiteId) ??
          _findCertificateById(request.websiteSSLId);
      selectedCertificate = boundCertificate;
      strategyDraft = null;
      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  List<ConfigDiffItem> _buildDiff(
    WebsiteHttpsUpdateRequest current,
    WebsiteHttpsUpdateRequest next,
    WebsiteSSL? nextCertificate,
  ) {
    final currentCertificate = boundCertificate ?? httpsConfig?.ssl;
    return buildLabeledDiff(
      current: <String, Object?>{
        'enable': current.enable,
        'httpConfig': current.httpConfig,
        'certificate': currentCertificate?.primaryDomain,
        'expireDate': currentCertificate?.expireDate,
        'provider': currentCertificate?.provider,
      },
      next: <String, Object?>{
        'enable': next.enable,
        'httpConfig': next.httpConfig,
        'certificate': nextCertificate?.primaryDomain,
        'expireDate': nextCertificate?.expireDate,
        'provider': nextCertificate?.provider,
      },
      labels: const <String, String>{
        'enable': 'HTTPS',
        'httpConfig': 'HTTP Mode',
        'certificate': 'Certificate',
        'expireDate': 'Expiration',
        'provider': 'Provider',
      },
    );
  }

  List<RiskNotice> _buildRisks(
    WebsiteHttpsUpdateRequest request,
    WebsiteSSL? certificate,
  ) {
    final notices = <RiskNotice>[];

    if (request.enable == true && certificate == null) {
      notices.add(
        const RiskNotice(
          level: RiskLevel.high,
          title: 'HTTPS enabled without certificate',
          message: 'Enable HTTPS only after selecting a valid certificate.',
        ),
      );
    }

    if (!domainsRoughlyMatch(
      expectedDomain: expectedDomain,
      certificateDomain: certificate?.primaryDomain,
    )) {
      notices.add(
        const RiskNotice(
          level: RiskLevel.high,
          title: 'Domain mismatch',
          message:
              'The selected certificate primary domain does not match the current website domain.',
        ),
      );
    }

    final health = resolveCertificateHealthStatus(certificate?.expireDate);
    if (health == CertificateHealthStatus.expired) {
      notices.add(
        const RiskNotice(
          level: RiskLevel.high,
          title: 'Expired certificate',
          message: 'The selected certificate is already expired.',
        ),
      );
    } else if (health == CertificateHealthStatus.expiringSoon) {
      notices.add(
        const RiskNotice(
          level: RiskLevel.medium,
          title: 'Certificate expiring soon',
          message: 'The selected certificate should be rotated soon.',
        ),
      );
    }

    return notices;
  }

  WebsiteSSL? _findCertificateById(int? id) {
    if (id == null) {
      return null;
    }
    for (final certificate in certificates) {
      if (certificate.id == id) {
        return certificate;
      }
    }
    return null;
  }
}
