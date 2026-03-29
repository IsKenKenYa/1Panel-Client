import '../../../api/v2/website_v2.dart';
import '../../../core/network/api_client_manager.dart';

class WebsiteAccountService {
  WebsiteAccountService({WebsiteV2Api? api}) : _api = api;

  WebsiteV2Api? _api;

  static const int _defaultPage = 1;
  static const int _defaultPageSize = 50;

  Future<WebsiteV2Api> _ensureApi() async {
    _api ??= await ApiClientManager.instance.getWebsiteApi();
    return _api!;
  }

  Future<List<Map<String, dynamic>>> loadDnsAccounts() async {
    final api = await _ensureApi();
    return api.searchDnsAccounts({
      'page': _defaultPage,
      'pageSize': _defaultPageSize,
    });
  }

  Future<void> createDnsAccount({
    required String name,
    required String type,
    required Map<String, dynamic> authorization,
  }) async {
    final api = await _ensureApi();
    await api.createDnsAccount({
      'name': name,
      'type': type,
      'authorization': authorization,
    });
  }

  Future<void> updateDnsAccount({
    required int id,
    required String name,
    required String type,
    required Map<String, dynamic> authorization,
  }) async {
    final api = await _ensureApi();
    await api.updateDnsAccount({
      'id': id,
      'name': name,
      'type': type,
      'authorization': authorization,
    });
  }

  Future<void> deleteDnsAccount(int id) async {
    final api = await _ensureApi();
    await api.deleteDnsAccount(id);
  }

  Future<List<Map<String, dynamic>>> loadAcmeAccounts() async {
    final api = await _ensureApi();
    return api.searchAcmeAccounts({
      'page': _defaultPage,
      'pageSize': _defaultPageSize,
    });
  }

  Future<void> createAcmeAccount({
    required String email,
    String type = 'letsencrypt',
    String keyType = '2048',
    bool useProxy = false,
    String? eabKid,
    String? eabHmacKey,
    String? caDirUrl,
    bool useEab = false,
  }) async {
    final api = await _ensureApi();
    await api.createAcmeAccount({
      'email': email,
      'type': type,
      'keyType': keyType,
      'useProxy': useProxy,
      if (eabKid != null && eabKid.isNotEmpty) 'eabKid': eabKid,
      if (eabHmacKey != null && eabHmacKey.isNotEmpty) 'eabHmacKey': eabHmacKey,
      if (caDirUrl != null && caDirUrl.isNotEmpty) 'caDirURL': caDirUrl,
      'useEAB': useEab,
    });
  }

  Future<void> updateAcmeAccount({
    required int id,
    required bool useProxy,
  }) async {
    final api = await _ensureApi();
    await api.updateAcmeAccount({
      'id': id,
      'useProxy': useProxy,
    });
  }

  Future<void> deleteAcmeAccount(int id) async {
    final api = await _ensureApi();
    await api.deleteAcmeAccount(id);
  }

  Future<List<Map<String, dynamic>>> loadCertificateAuthorities() async {
    final api = await _ensureApi();
    return api.searchCertificateAuthorities({
      'page': _defaultPage,
      'pageSize': _defaultPageSize,
    });
  }

  Future<void> createCertificateAuthority({
    required String name,
    required String commonName,
    required String country,
    required String organization,
    required String keyType,
    String? organizationUint,
    String? province,
    String? city,
  }) async {
    final api = await _ensureApi();
    await api.createCertificateAuthority({
      'name': name,
      'commonName': commonName,
      'country': country,
      'organization': organization,
      'keyType': keyType,
      if (organizationUint != null && organizationUint.isNotEmpty)
        'organizationUint': organizationUint,
      if (province != null && province.isNotEmpty) 'province': province,
      if (city != null && city.isNotEmpty) 'city': city,
    });
  }

  Future<Map<String, dynamic>> getCertificateAuthority(int id) async {
    final api = await _ensureApi();
    return api.getCertificateAuthority(id);
  }

  Future<void> deleteCertificateAuthority(int id) async {
    final api = await _ensureApi();
    await api.deleteCertificateAuthority(id);
  }

  Future<void> obtainCertificateByAuthority({
    required int id,
    required String domains,
    String keyType = '2048',
    int time = 1,
    String unit = 'year',
  }) async {
    final api = await _ensureApi();
    await api.obtainCertificateByAuthority({
      'id': id,
      'domains': domains,
      'keyType': keyType,
      'time': time,
      'unit': unit,
    });
  }

  Future<void> renewCertificateByAuthority(int sslId) async {
    final api = await _ensureApi();
    await api.renewCertificateByAuthority(sslId);
  }

  Future<String> downloadCertificateAuthorityFile(int id) async {
    final api = await _ensureApi();
    return api.downloadCertificateAuthorityFile(id);
  }
}
