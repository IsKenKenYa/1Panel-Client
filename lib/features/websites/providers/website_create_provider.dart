import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import '../../../data/models/website_group_models.dart';
import '../services/website_service.dart';

class WebsiteCreateProvider extends ChangeNotifier with SafeChangeNotifier {
  WebsiteCreateProvider({WebsiteService? service}) : _service = service;

  WebsiteService? _service;

  bool isLoading = false;
  bool isSubmitting = false;
  String? error;
  List<WebsiteGroup> groups = const <WebsiteGroup>[];

  Future<void> _ensureService() async {
    _service ??= WebsiteService();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _ensureService();
      groups = await _service!.listWebsiteGroups();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
