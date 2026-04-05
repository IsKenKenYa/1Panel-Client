import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import '../services/website_account_service.dart';

class WebsiteSslAccountsProvider extends ChangeNotifier
    with SafeChangeNotifier {
  WebsiteSslAccountsProvider({WebsiteAccountService? service})
      : _service = service;

  WebsiteAccountService? _service;

  bool isLoading = false;
  bool get isOperating => _operationKeys.isNotEmpty;

  String? error;
  String? operationError;

  final Set<String> _operationKeys = <String>{};

  List<Map<String, dynamic>> dnsAccounts = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> acmeAccounts = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> certificateAuthorities =
      const <Map<String, dynamic>>[];

  Future<void> _ensureService() async {
    _service ??= WebsiteAccountService();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    operationError = null;
    notifyListeners();
    try {
      await _ensureService();
      final results = await Future.wait([
        _service!.loadDnsAccounts(),
        _service!.loadAcmeAccounts(),
        _service!.loadCertificateAuthorities(),
      ]);
      dnsAccounts = results[0];
      acmeAccounts = results[1];
      certificateAuthorities = results[2];
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool isOperatingKey(String key) {
    return _operationKeys.contains(key);
  }

  Future<bool> createDnsAccount({
    required String name,
    required String type,
    required Map<String, dynamic> authorization,
  }) {
    return _runMutation(
      key: 'dns:create',
      action: () => _service!.createDnsAccount(
        name: name,
        type: type,
        authorization: authorization,
      ),
    );
  }

  Future<bool> updateDnsAccount({
    required int id,
    required String name,
    required String type,
    required Map<String, dynamic> authorization,
  }) {
    return _runMutation(
      key: 'dns:update:$id',
      action: () => _service!.updateDnsAccount(
        id: id,
        name: name,
        type: type,
        authorization: authorization,
      ),
    );
  }

  Future<bool> deleteDnsAccount(int id) {
    return _runMutation(
      key: 'dns:delete:$id',
      action: () => _service!.deleteDnsAccount(id),
    );
  }

  Future<bool> createAcmeAccount({
    required String email,
    String type = 'letsencrypt',
    String keyType = '2048',
    bool useProxy = false,
    String? eabKid,
    String? eabHmacKey,
    String? caDirUrl,
    bool useEab = false,
  }) {
    return _runMutation(
      key: 'acme:create',
      action: () => _service!.createAcmeAccount(
        email: email,
        type: type,
        keyType: keyType,
        useProxy: useProxy,
        eabKid: eabKid,
        eabHmacKey: eabHmacKey,
        caDirUrl: caDirUrl,
        useEab: useEab,
      ),
    );
  }

  Future<bool> updateAcmeAccount({
    required int id,
    required bool useProxy,
  }) {
    return _runMutation(
      key: 'acme:update:$id',
      action: () => _service!.updateAcmeAccount(
        id: id,
        useProxy: useProxy,
      ),
    );
  }

  Future<bool> deleteAcmeAccount(int id) {
    return _runMutation(
      key: 'acme:delete:$id',
      action: () => _service!.deleteAcmeAccount(id),
    );
  }

  Future<bool> createCertificateAuthority({
    required String name,
    required String commonName,
    required String country,
    required String organization,
    required String keyType,
    String? organizationUint,
    String? province,
    String? city,
  }) {
    return _runMutation(
      key: 'ca:create',
      action: () => _service!.createCertificateAuthority(
        name: name,
        commonName: commonName,
        country: country,
        organization: organization,
        keyType: keyType,
        organizationUint: organizationUint,
        province: province,
        city: city,
      ),
    );
  }

  Future<bool> deleteCertificateAuthority(int id) {
    return _runMutation(
      key: 'ca:delete:$id',
      action: () => _service!.deleteCertificateAuthority(id),
    );
  }

  Future<bool> obtainCertificateByAuthority({
    required int id,
    required String domains,
    String keyType = '2048',
    int time = 1,
    String unit = 'year',
  }) {
    return _runMutation(
      key: 'ca:obtain:$id',
      action: () => _service!.obtainCertificateByAuthority(
        id: id,
        domains: domains,
        keyType: keyType,
        time: time,
        unit: unit,
      ),
      reload: false,
    );
  }

  Future<bool> renewCertificateByAuthority(int sslId) {
    return _runMutation(
      key: 'ca:renew:$sslId',
      action: () => _service!.renewCertificateByAuthority(sslId),
      reload: false,
    );
  }

  Future<String?> downloadCertificateAuthorityFile(int id) async {
    final key = 'ca:download:$id';
    await _ensureService();
    operationError = null;
    _operationKeys.add(key);
    notifyListeners();
    try {
      return await _service!.downloadCertificateAuthorityFile(id);
    } catch (e) {
      operationError = e.toString();
      return null;
    } finally {
      _operationKeys.remove(key);
      notifyListeners();
    }
  }

  int? resolveAccountId(Map<String, dynamic> item) {
    final raw = item['id'];
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw);
    }
    return null;
  }

  int? resolveCertificateSslId(Map<String, dynamic> item) {
    final keys = <String>[
      'sslID',
      'SSLID',
      'sslId',
      'SSLId',
      'websiteSSLId',
      'websiteSSLID',
    ];
    for (final key in keys) {
      final raw = item[key];
      if (raw is int) {
        return raw;
      }
      if (raw is num) {
        return raw.toInt();
      }
      if (raw is String) {
        final parsed = int.tryParse(raw);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  Future<bool> _runMutation({
    required String key,
    required Future<void> Function() action,
    bool reload = true,
  }) async {
    await _ensureService();
    operationError = null;
    _operationKeys.add(key);
    notifyListeners();
    try {
      await action();
      if (reload) {
        await load();
      }
      return true;
    } catch (e) {
      operationError = e.toString();
      notifyListeners();
      return false;
    } finally {
      _operationKeys.remove(key);
      notifyListeners();
    }
  }
}
