import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/ssh_cert_models.dart';
import 'package:onepanel_client/features/ssh/services/ssh_service.dart';

class SshCertsProvider extends ChangeNotifier with AsyncStateNotifier {
  SshCertsProvider({
    SSHService? service,
  }) : _service = service ?? SSHService();

  final SSHService _service;

  List<SshCertInfo> _items = const <SshCertInfo>[];
  bool _isMutating = false;

  List<SshCertInfo> get items => _items;
  bool get isMutating => _isMutating;

  Future<void> load() async {
    setLoading();
    try {
      final result = await _service.searchCerts();
      _items = result.items;
      setSuccess(isEmpty: _items.isEmpty);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ssh.providers.certs',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _items = const <SshCertInfo>[];
      setError(error);
    }
  }

  Future<bool> createCert(SshCertOperate request) => _runMutation(() async {
        await _service.createCert(request);
        await load();
      });

  Future<bool> updateCert(SshCertOperate request) => _runMutation(() async {
        await _service.updateCert(request);
        await load();
      });

  Future<bool> deleteCert(SshCertInfo item) => _runMutation(() async {
        await _service.deleteCerts(<int>[item.id]);
        await load();
      });

  Future<bool> syncCerts() => _runMutation(() async {
        await _service.syncCerts();
        await load();
      });

  Future<bool> _runMutation(Future<void> Function() action) async {
    _isMutating = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await action();
      setSuccess(isEmpty: _items.isEmpty, notify: false);
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ssh.providers.certs',
        'mutation failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}
