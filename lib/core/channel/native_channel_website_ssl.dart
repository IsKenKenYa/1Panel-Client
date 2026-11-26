import 'dart:convert';
import 'dart:typed_data';

import '../../data/models/paged_query.dart';
import '../../data/models/ssl_models.dart';
import '../../features/websites/pages/website_dns_template_form.dart';
import '../../features/websites/providers/website_certificate_detail_provider.dart';
import '../../features/websites/providers/website_site_ssl_provider.dart';
import '../../features/websites/providers/website_ssl_accounts_provider.dart';
import '../../features/websites/providers/website_ssl_center_provider.dart';
import '../../features/websites/services/website_account_service.dart';
import '../../features/websites/services/website_certificate_service.dart';
import '../config/api_config.dart';
import '../platform/services/platform_file_service.dart';

class NativeChannelWebsiteSslHandlers {
  static String? _serverIdentity;
  static WebsiteSslCenterProvider? _center;
  static WebsiteSslAccountsProvider? _accounts;
  static WebsiteSiteSslProvider? _site;

  static Future<dynamic> dispatch(String method, dynamic arguments) async {
    final args = arguments == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(arguments as Map);
    if (method == 'releaseNativeWebsiteSsl') {
      _release();
      return null;
    }
    await _ensureServer();
    switch (method) {
      case 'getNativeWebsiteSslCenter':
        final provider = await _centerProvider();
        if (args['refresh'] == true) await provider.load();
        if (args.containsKey('search')) {
          provider.setSearchQuery(args['search'] as String);
        }
        if (args.containsKey('provider')) {
          provider.setProviderFilter(args['provider'] as String);
        }
        if (args.containsKey('expiry')) {
          provider.setExpiryWindow(CertificateExpiryWindow.values.byName(
            args['expiry'] as String,
          ));
        }
        return _centerState(provider);
      case 'getNativeWebsiteCertificate':
        final certificateId = args['id'] as int;
        final provider = WebsiteCertificateDetailProvider(
          certificateId: certificateId,
        );
        try {
          await provider.load();
          final certificate = provider.certificate;
          final domain = certificate?.primaryDomain;
          final payload = certificate?.toJson();
          if (payload != null &&
              domain != null &&
              domain.isNotEmpty &&
              certificate?.websites == null) {
            final service = WebsiteCertificateService();
            for (var page = 1; ; page++) {
              final certificates = await service.searchCertificates(
                page: page,
                domain: domain,
              );
              final match = certificates
                  .where((item) => item.id == certificateId)
                  .firstOrNull;
              if (match != null) {
                payload['websites'] =
                    match.websites?.map((item) => item.toJson()).toList();
                payload['logPath'] = match.logPath;
                break;
              }
              if (certificates.length < PagedQuery.searchPageSize) break;
            }
          }
          return {
            'error': provider.error,
            'certificate': payload,
          };
        } finally {
          provider.dispose();
        }
      case 'performNativeWebsiteSslAction':
        return _certificateAction(args);
      case 'pickNativeWebsiteSslFile':
        final kind = args['kind'] as String;
        final extensions = kind == 'certificate'
            ? <String>['pem', 'crt', 'cer']
            : <String>['pem', 'key'];
        final files = await PlatformFileService().selectFiles(
          allowedExtensions: extensions,
          withData: true,
        );
        final file = files?.files.single;
        if (file == null) return null;
        return {'name': file.name, 'pem': utf8.decode(file.bytes!)};
      case 'getNativeWebsiteSslAccounts':
        final provider = await _accountsProvider();
        if (args['refresh'] == true) await provider.load();
        return _accountsState(provider);
      case 'performNativeWebsiteSslAccountAction':
        return _accountAction(args);
      case 'getNativeWebsiteHttps':
        final provider = await _siteProvider(args);
        if (args['refresh'] == true) await provider.load();
        return _siteState(provider);
      case 'performNativeWebsiteHttpsAction':
        return _siteAction(args);
      default:
        throw ArgumentError.value(method, 'method');
    }
  }

  static Future<void> _ensureServer() async {
    final config = await ApiConfigManager.getCurrentConfig();
    if (config == null) throw StateError('No active server configured');
    final identity = '${config.id}:${config.revision}';
    if (_serverIdentity != identity) {
      _release();
      _serverIdentity = identity;
    }
  }

  static void _release() {
    _center?.dispose();
    _accounts?.dispose();
    _site?.dispose();
    _center = null;
    _accounts = null;
    _site = null;
    _serverIdentity = null;
  }

  static Future<WebsiteSslCenterProvider> _centerProvider() async {
    if (_center == null) {
      _center = WebsiteSslCenterProvider();
      await _center!.load();
    }
    return _center!;
  }

  static Future<WebsiteSslAccountsProvider> _accountsProvider() async {
    if (_accounts == null) {
      _accounts = WebsiteSslAccountsProvider();
      await _accounts!.load();
    }
    return _accounts!;
  }

  static Map<String, dynamic> _centerState(WebsiteSslCenterProvider provider) => {
        'error': provider.error,
        'search': provider.searchQuery,
        'provider': provider.providerFilter,
        'expiry': provider.expiryWindow.name,
        'providerOptions': provider.providerOptions,
        'expiredCount': provider.expiredCount,
        'within7DaysCount': provider.within7DaysCount,
        'within30DaysCount': provider.within30DaysCount,
        'groups': provider.groupedCertificates.entries
            .map((group) => {
                  'name': group.key,
                  'certificates': group.value.map((cert) => cert.toJson()).toList(),
                })
            .toList(),
      };

  static Future<Map<String, dynamic>> _certificateAction(
    Map<String, dynamic> args,
  ) async {
    final provider = await _centerProvider();
    final service = WebsiteCertificateService();
    Map<String, dynamic>? download;
    List<Map<String, dynamic>>? dnsRecords;
    switch (args['action'] as String) {
      case 'create':
        await provider.createCertificate(WebsiteSSLCreate(
          acmeAccountId: args['acmeAccountId'] as int,
          primaryDomain: args['primaryDomain'] as String,
          provider: args['provider'] as String,
          apply: args['apply'] as bool?,
          autoRenew: args['autoRenew'] as bool?,
          description: args['description'] as String?,
          dnsAccountId: args['dnsAccountId'] as int?,
          keyType: args['keyType'] as String?,
          otherDomains: args['otherDomains'] as String?,
          nameserver1: args['nameserver1'] as String?,
          nameserver2: args['nameserver2'] as String?,
          disableCNAME: args['disableCNAME'] as bool?,
          skipDNS: args['skipDNS'] as bool?,
          isIp: args['isIp'] as bool?,
          pushDir: args['pushDir'] as bool?,
          dir: args['dir'] as String?,
          pushNode: args['pushNode'] as bool?,
          nodes: args['nodes'] as String?,
          execShell: args['execShell'] as bool?,
          shell: args['shell'] as String?,
        ));
        break;
      case 'update':
        await provider.updateCertificate(WebsiteSSLUpdate(
          id: args['id'] as int,
          primaryDomain: args['primaryDomain'] as String,
          provider: args['provider'] as String,
          acmeAccountId: args['acmeAccountId'] as int?,
          apply: args['apply'] as bool?,
          autoRenew: args['autoRenew'] as bool?,
          description: args['description'] as String?,
          dnsAccountId: args['dnsAccountId'] as int?,
          keyType: args['keyType'] as String?,
          otherDomains: args['otherDomains'] as String?,
          nameserver1: args['nameserver1'] as String?,
          nameserver2: args['nameserver2'] as String?,
          disableCNAME: args['disableCNAME'] as bool?,
          skipDNS: args['skipDNS'] as bool?,
          pushDir: args['pushDir'] as bool?,
          dir: args['dir'] as String?,
          pushNode: args['pushNode'] as bool?,
          nodes: args['nodes'] as String?,
          execShell: args['execShell'] as bool?,
          shell: args['shell'] as String?,
        ));
        break;
      case 'upload':
        await provider.uploadCertificate(WebsiteSSLUpload(
          sslID: args['id'] as int?,
          type: args['type'] as String,
          certificate: args['certificate'] as String?,
          privateKey: args['privateKey'] as String?,
          certificatePath: args['certificatePath'] as String?,
          privateKeyPath: args['privateKeyPath'] as String?,
          description: args['description'] as String?,
        ));
        break;
      case 'apply':
        await service.applyCertificate(WebsiteSSLApply(
          id: args['id'] as int,
          disableLog: args['disableLog'] as bool?,
          skipDNSCheck: args['skipDNSCheck'] as bool?,
          nameservers: (args['nameservers'] as List?)?.cast<String>(),
        ));
        await provider.load();
        break;
      case 'resolve':
        dnsRecords = await service.resolveCertificate(WebsiteSSLResolve(
          acmeAccountId: args['acmeAccountId'] as int,
          websiteSSLId: args['id'] as int,
        ));
        break;
      case 'delete':
        await provider.deleteCertificate(args['id'] as int);
        break;
      case 'download':
        final bytes = await service.downloadCertificateBytes(args['id'] as int);
        download = await _saveDownload(bytes, args['fileName'] as String);
        break;
      default:
        throw ArgumentError.value(args['action'], 'action');
    }
    return {
      ..._centerState(provider),
      'download': download,
      if (dnsRecords != null) 'dnsRecords': dnsRecords,
    };
  }

  static Map<String, dynamic> _accountsState(
    WebsiteSslAccountsProvider provider,
  ) {
    Map<String, dynamic> account(Map<String, dynamic> item) => {
          ...item,
          'id': provider.resolveAccountId(item),
          'renewSslId': provider.resolveCertificateSslId(item),
        };
    return {
      'error': provider.error ?? provider.operationError,
      'dns': provider.dnsAccounts.map(account).toList(),
      'acme': provider.acmeAccounts.map(account).toList(),
      'ca': provider.certificateAuthorities.map(account).toList(),
      'dnsTemplates': kDnsProviderTemplates
          .map((template) => {
                'type': template.type,
                'fields': template.fields
                    .map((field) => {
                          'key': field.key,
                          'label': field.label,
                          'sensitive': field.sensitive,
                        })
                    .toList(),
              })
          .toList(),
    };
  }

  static Future<Map<String, dynamic>> _accountAction(
    Map<String, dynamic> args,
  ) async {
    final provider = await _accountsProvider();
    bool? applied;
    Map<String, dynamic>? download;
    Map<String, dynamic>? detail;
    switch (args['action'] as String) {
      case 'createDns':
        applied = await provider.createDnsAccount(
          name: args['name'] as String,
          type: args['type'] as String,
          authorization: Map<String, dynamic>.from(args['authorization'] as Map),
        );
        break;
      case 'updateDns':
        applied = await provider.updateDnsAccount(
          id: args['id'] as int,
          name: args['name'] as String,
          type: args['type'] as String,
          authorization: Map<String, dynamic>.from(args['authorization'] as Map),
        );
        break;
      case 'deleteDns':
        applied = await provider.deleteDnsAccount(args['id'] as int);
        break;
      case 'createAcme':
        applied = await provider.createAcmeAccount(
          email: args['email'] as String,
          type: args['type'] as String,
          keyType: args['keyType'] as String,
          useProxy: args['useProxy'] as bool,
          eabKid: args['eabKid'] as String?,
          eabHmacKey: args['eabHmacKey'] as String?,
          caDirUrl: args['caDirURL'] as String?,
          useEab: args['useEAB'] as bool,
        );
        break;
      case 'updateAcme':
        applied = await provider.updateAcmeAccount(
          id: args['id'] as int,
          useProxy: args['useProxy'] as bool,
        );
        break;
      case 'deleteAcme':
        applied = await provider.deleteAcmeAccount(args['id'] as int);
        break;
      case 'createCa':
        applied = await provider.createCertificateAuthority(
          name: args['name'] as String,
          commonName: args['commonName'] as String,
          country: args['country'] as String,
          organization: args['organization'] as String,
          keyType: args['keyType'] as String,
          organizationUint: args['organizationUint'] as String?,
          province: args['province'] as String?,
          city: args['city'] as String?,
        );
        break;
      case 'deleteCa':
        applied = await provider.deleteCertificateAuthority(args['id'] as int);
        break;
      case 'obtainCa':
        applied = await provider.obtainCertificateByAuthority(
          id: args['id'] as int,
          domains: args['domains'] as String,
          keyType: args['keyType'] as String,
          time: args['time'] as int,
          unit: args['unit'] as String,
        );
        break;
      case 'renewCa':
        applied = await provider.renewCertificateByAuthority(args['sslId'] as int);
        break;
      case 'downloadCa':
        final bytes = await WebsiteAccountService()
            .downloadCertificateAuthorityBytes(args['id'] as int);
        download = await _saveDownload(bytes, args['fileName'] as String);
        break;
      case 'detailCa':
        detail = await WebsiteAccountService().getCertificateAuthority(args['id'] as int);
        break;
      default:
        throw ArgumentError.value(args['action'], 'action');
    }
    return {
      ..._accountsState(provider),
      'applied': applied,
      'download': download,
      'detail': detail,
    };
  }

  static Future<Map<String, dynamic>> _saveDownload(
    List<int> bytes,
    String fileName,
  ) async {
    final result = await PlatformFileService().saveBytesStructured(
      fileName: fileName,
      bytes: Uint8List.fromList(bytes),
      mimeType: 'application/zip',
    );
    return {
      'cancelled': result.isCancelled,
      'uri': result.uri,
      'fileName': result.displayName,
    };
  }

  static Future<WebsiteSiteSslProvider> _siteProvider(
    Map<String, dynamic> args,
  ) async {
    final websiteId = args['websiteId'] as int;
    if (_site?.websiteId != websiteId) {
      _site?.dispose();
      _site = WebsiteSiteSslProvider(
        websiteId: websiteId,
        expectedDomain: args['displayName'] as String?,
      );
      await _site!.load();
    }
    return _site!;
  }

  static Map<String, dynamic> _siteState(WebsiteSiteSslProvider provider) => {
        'error': provider.error,
        'https': provider.httpsConfig?.toJson(),
        'boundCertificate': provider.boundCertificate?.toJson(),
        'selectedCertificate': provider.selectedCertificate?.toJson(),
        'certificates': provider.certificates.map((cert) => cert.toJson()).toList(),
        'strategy': (provider.strategyDraft?.draftValue ?? provider.currentStrategy).toJson(),
        'hasChanges': provider.hasPendingChanges,
        'canRestore': provider.canRollback,
        'diffs': provider.strategyDraft?.diffItems
            .map((diff) => {
                  'field': diff.field,
                  'label': diff.label,
                  'currentValue': diff.currentValue,
                  'nextValue': diff.nextValue,
                })
            .toList(),
        'risks': (provider.hasPendingChanges ? provider.pendingRisks : provider.currentRisks)
            .map((risk) => {'title': risk.title, 'message': risk.message})
            .toList(),
      };

  static Future<Map<String, dynamic>> _siteAction(
    Map<String, dynamic> args,
  ) async {
    final provider = await _siteProvider(args);
    bool? applied;
    switch (args['action'] as String) {
      case 'stage':
        final certificateId = args['certificateId'] as int?;
        provider.stageHttpsStrategy(
          enable: args['enable'] as bool,
          httpConfig: args['httpConfig'] as String,
          certificate: certificateId == null
              ? null
              : provider.certificates.firstWhere((cert) => cert.id == certificateId),
          clearCertificate: certificateId == null,
        );
        break;
      case 'apply':
        applied = await provider.applyHttpsStrategy();
        break;
      case 'discard':
        provider.discardDraft();
        break;
      case 'restore':
        applied = await provider.rollbackLastSuccessful();
        break;
      case 'saveAdvanced':
        await WebsiteCertificateService().updateHttpsConfig(
          websiteId: provider.websiteId,
          request: WebsiteHttpsUpdateRequest(
            websiteId: provider.websiteId,
            enable: args['enable'] as bool,
            httpConfig: args['httpConfig'] as String,
            type: args['type'] as String,
            websiteSSLId: args['certificateId'] as int?,
            certificate: args['certificate'] as String?,
            privateKey: args['privateKey'] as String?,
            certificatePath: args['certificatePath'] as String?,
            privateKeyPath: args['privateKeyPath'] as String?,
            importType: args['type'] == 'manual' ? 'paste' : null,
            sslProtocol: (args['SSLProtocol'] as List?)?.cast<String>(),
            hsts: args['hsts'] as bool?,
            hstsIncludeSubDomains: args['hstsIncludeSubDomains'] as bool?,
            http3: args['http3'] as bool?,
            algorithm: args['algorithm'] as String?,
          ),
        );
        await provider.load();
        provider.discardDraft();
        applied = provider.error == null;
        break;
      default:
        throw ArgumentError.value(args['action'], 'action');
    }
    return {..._siteState(provider), 'applied': applied};
  }
}
