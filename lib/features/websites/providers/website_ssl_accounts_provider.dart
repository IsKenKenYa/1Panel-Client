import 'package:flutter/foundation.dart';
import '../services/website_account_service.dart';

class WebsiteSslAccountsProvider extends ChangeNotifier {
  WebsiteSslAccountsProvider({WebsiteAccountService? service}) : _service = service;

  WebsiteAccountService? _service;

  bool isLoading = false;
  String? error;
  List<Map<String, dynamic>> dnsAccounts = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> acmeAccounts = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> certificateAuthorities = const <Map<String, dynamic>>[];

  Future<void> _ensureService() async {
    _service ??= WebsiteAccountService();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
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
}
