import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';

import 'dpanel_adapter.dart';
import 'one_panel_adapter.dart';
import 'panel_adapter.dart';

class PanelRegistry {
  PanelRegistry(Iterable<PanelAdapter> adapters) {
    for (final adapter in adapters) {
      register(adapter);
    }
  }

  static final instance = PanelRegistry([
    OnePanelAdapter(clientManager: ApiClientManager.instance),
    const DPanelAdapter(),
  ]);

  final _adapters = <String, PanelAdapter>{};
  final _sessions = <String, ({ApiConfig config, PanelSession session})>{};
  final _opening = <(String, String), Future<PanelSession?>>{};

  Iterable<String> get panelTypes => _adapters.keys;

  void register(PanelAdapter adapter) {
    final type = adapter.panelType;
    if (type.isEmpty || type != type.trim()) {
      throw ArgumentError.value(type, 'panelType');
    }
    if (supports(type)) throw StateError('Panel already registered: $type');
    _adapters[type] = adapter;
  }

  bool supports(String panelType) => _adapters.containsKey(panelType);

  PanelAdapter adapterFor(String panelType) =>
      _adapters[panelType] ??
      (throw UnsupportedError('Unknown panel: $panelType'));

  PanelSession sessionFor(ApiConfig config) {
    final existing = _sessions[config.id];
    if (existing != null && existing.config.sameConnectionAs(config)) {
      if (existing.config.revision != config.revision) {
        _sessions[config.id] = (config: config, session: existing.session);
      }
      return existing.session;
    }
    _sessions.remove(config.id)?.session.close();
    final session = adapterFor(config.panelType).open(config);
    _sessions[config.id] = (config: config, session: session);
    return session;
  }

  Future<PanelSession?> savedSessionFor(ApiConfig metadata) {
    final entry = _sessions[metadata.id];
    if (metadata.revision.isNotEmpty &&
        entry?.config.revision == metadata.revision) {
      return Future.value(entry!.session);
    }
    final key = (metadata.id, metadata.revision);
    final pending = _opening[key];
    if (pending != null) return pending;
    late final Future<PanelSession?> opening;
    opening = ApiConfigManager.getConfig(metadata.id).then((config) {
      if (config.revision != metadata.revision || _opening[key] != opening) {
        return null;
      }
      return sessionFor(config);
    }, onError: (Object error, StackTrace trace) {
      if (_opening[key] != opening) return null;
      Error.throwWithStackTrace(error, trace);
    }).whenComplete(() {
      if (_opening[key] == opening) _opening.remove(key);
    });
    return _opening[key] = opening;
  }

  void release(String serverId) {
    _opening.removeWhere((key, _) => key.$1 == serverId);
    _sessions.remove(serverId)?.session.close();
  }

  void invalidateIfChanged(ApiConfig config) {
    _opening.removeWhere((key, _) => key.$1 == config.id);
    final entry = _sessions[config.id];
    if (entry != null && !entry.config.sameConnectionAs(config)) {
      release(config.id);
    }
  }

  void clear() {
    _opening.clear();
    for (final id in _sessions.keys.toList()) {
      release(id);
    }
  }
}
