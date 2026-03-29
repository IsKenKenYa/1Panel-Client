import 'package:flutter/foundation.dart';

import '../services/website_config_service.dart';

class RoutingBatchResult {
  const RoutingBatchResult({
    required this.succeeded,
    required this.failed,
  });

  final int succeeded;
  final int failed;

  bool get hasFailure => failed > 0;
}

class WebsiteRoutingRulesProvider extends ChangeNotifier {
  final int websiteId;
  final WebsiteConfigService _service;

  WebsiteRoutingRulesProvider({
    required this.websiteId,
    WebsiteConfigService? service,
  }) : _service = service ?? WebsiteConfigService();

  bool isLoading = false;
  bool isSubmitting = false;
  String? error;
  String rewriteName = 'default';
  String proxyName = 'default';
  String redirectName = 'default';
  String loadBalancerName = 'default';
  String proxyStatus = 'Enable';
  String rewriteContent = '';
  String proxyContent = '';
  String redirectContent = '';
  String loadBalancerContent = '';

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final rewrite =
          _service.loadRewrite(websiteId: websiteId, name: rewriteName);
      final proxy = _service.loadProxy(websiteId: websiteId, name: proxyName);
      final result = await Future.wait([rewrite, proxy]);
      rewriteContent = result[0];
      proxyContent = result[1];
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveRewrite(String content) async {
    await _service.updateRewrite(
      websiteId: websiteId,
      name: rewriteName,
      content: content,
    );
    rewriteContent = content;
    notifyListeners();
  }

  Future<void> saveProxy(String content, {String? name}) async {
    final targetName = _normalizeName(name, proxyName);
    await _service.updateProxy(
      websiteId: websiteId,
      name: targetName,
      content: content,
    );
    proxyName = targetName;
    proxyContent = content;
    notifyListeners();
  }

  Future<void> updateProxyStatus({
    required bool enabled,
    String? name,
  }) async {
    final targetName = _normalizeName(name, proxyName);
    final status = enabled ? 'Enable' : 'Disable';
    await _service.updateProxyStatus(<String, dynamic>{
      'id': websiteId,
      'name': targetName,
      'status': status,
    });
    proxyName = targetName;
    proxyStatus = status;
    notifyListeners();
  }

  Future<void> deleteProxy({String? name}) async {
    final targetName = _normalizeName(name, proxyName);
    await _service.deleteProxy(<String, dynamic>{
      'id': websiteId,
      'name': targetName,
    });
    proxyName = targetName;
    proxyContent = '';
    notifyListeners();
  }

  Future<void> saveRedirectFile(String content, {String? name}) async {
    final targetName = _normalizeName(name, redirectName);
    await _service.updateRedirectFile(<String, dynamic>{
      'websiteID': websiteId,
      'name': targetName,
      'content': content,
    });
    redirectName = targetName;
    redirectContent = content;
    notifyListeners();
  }

  Future<void> saveLoadBalancerFile(String content, {String? name}) async {
    final targetName = _normalizeName(name, loadBalancerName);
    await _service.updateLoadBalancerFile(<String, dynamic>{
      'websiteID': websiteId,
      'name': targetName,
      'content': content,
    });
    loadBalancerName = targetName;
    loadBalancerContent = content;
    notifyListeners();
  }

  Future<RoutingBatchResult> batchUpdateProxyStatus({
    required List<int> websiteIds,
    required bool enabled,
    String? name,
  }) async {
    final targetName = _normalizeName(name, proxyName);
    final status = enabled ? 'Enable' : 'Disable';
    return _runBatch(websiteIds, (id) {
      return _service.updateProxyStatus(<String, dynamic>{
        'id': id,
        'name': targetName,
        'status': status,
      });
    });
  }

  Future<RoutingBatchResult> batchDeleteProxy({
    required List<int> websiteIds,
    String? name,
  }) async {
    final targetName = _normalizeName(name, proxyName);
    return _runBatch(websiteIds, (id) {
      return _service.deleteProxy(<String, dynamic>{
        'id': id,
        'name': targetName,
      });
    });
  }

  Future<RoutingBatchResult> batchSaveRedirectFile({
    required List<int> websiteIds,
    required String content,
    String? name,
  }) async {
    final targetName = _normalizeName(name, redirectName);
    return _runBatch(websiteIds, (id) {
      return _service.updateRedirectFile(<String, dynamic>{
        'websiteID': id,
        'name': targetName,
        'content': content,
      });
    });
  }

  Future<RoutingBatchResult> batchSaveLoadBalancerFile({
    required List<int> websiteIds,
    required String content,
    String? name,
  }) async {
    final targetName = _normalizeName(name, loadBalancerName);
    return _runBatch(websiteIds, (id) {
      return _service.updateLoadBalancerFile(<String, dynamic>{
        'websiteID': id,
        'name': targetName,
        'content': content,
      });
    });
  }

  String _normalizeName(String? candidate, String fallback) {
    final raw = candidate?.trim() ?? '';
    if (raw.isNotEmpty) {
      return raw;
    }
    final base = fallback.trim();
    if (base.isNotEmpty) {
      return base;
    }
    return 'default';
  }

  Future<RoutingBatchResult> _runBatch(
    List<int> websiteIds,
    Future<void> Function(int websiteId) action,
  ) async {
    if (websiteIds.isEmpty) {
      return const RoutingBatchResult(succeeded: 0, failed: 0);
    }
    isSubmitting = true;
    error = null;
    notifyListeners();

    var succeeded = 0;
    var failed = 0;
    for (final id in websiteIds.toSet()) {
      try {
        await action(id);
        succeeded++;
      } catch (_) {
        failed++;
      }
    }

    if (failed > 0) {
      error = 'Batch failed for $failed website(s).';
    }
    isSubmitting = false;
    notifyListeners();

    return RoutingBatchResult(succeeded: succeeded, failed: failed);
  }
}
