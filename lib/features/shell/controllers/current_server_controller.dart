import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/config/api_config.dart';

class CurrentServerController extends ChangeNotifier with SafeChangeNotifier {
  bool _hasLoaded = false;
  ({String? selection, Future<void> done})? _pending;
  ServerDirectory? _confirmed;
  List<ApiConfig> _servers = const [];
  ApiConfig? _currentServer;

  bool get hasLoaded => _hasLoaded;
  bool get isLoading => !_hasLoaded && _pending != null;
  List<ApiConfig> get servers => _servers;
  ApiConfig? get currentServer => _currentServer;
  String? get currentServerId => _currentServer?.id;
  bool get hasServer => _currentServer != null;
  bool get hasAvailableServers => _servers.isNotEmpty;

  Future<void> ensureLoaded() =>
      _pending?.done ?? (_hasLoaded ? Future<void>.value() : load());

  Future<void> load() => _update();

  Future<void> refresh() => load();

  Future<void> selectServer(String id) {
    if (_pending == null && _hasLoaded && currentServerId == id) {
      return Future<void>.value();
    }
    return _update(selection: id);
  }

  Future<void> _update({String? selection}) {
    final active = _pending;
    if (active != null && active.selection == selection) return active.done;
    final read = selection == null
        ? ApiConfigManager.getServerDirectory()
        : ApiConfigManager.setCurrentConfig(selection);
    // 存储操作按调用顺序完成。连续切换时，发布最后确认的目录。
    late final Future<void> done;
    done = read.then<void>((directory) {
      _confirmed = directory;
    }).whenComplete(() {
      if (isDisposed || _pending?.done != done) return;
      _pending = null;
      final directory = _confirmed;
      _confirmed = null;
      if (directory == null) {
        if (!_hasLoaded) notifyListeners();
        return;
      }
      _publish(directory);
    });
    _pending = (selection: selection, done: done);
    if (!_hasLoaded && active == null) notifyListeners();
    return done;
  }

  void _publish(ServerDirectory directory) {
    final previous = {for (final config in _servers) config.id: config};
    final next = <ApiConfig>[];
    for (final config in directory.servers) {
      final saved = previous[config.id];
      next.add(
          saved != null && saved.revision == config.revision ? saved : config);
    }
    final changed = !listEquals(_servers, next);
    if (changed) _servers = List.unmodifiable(next);
    final selected =
        _servers.where((s) => s.id == directory.selectedId).firstOrNull;
    final notify =
        !_hasLoaded || changed || !identical(selected, _currentServer);
    _currentServer = selected;
    _hasLoaded = true;
    if (notify) notifyListeners();
  }
}
