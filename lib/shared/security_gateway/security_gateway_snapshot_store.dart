import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';

class SecurityGatewaySnapshotStore {
  SecurityGatewaySnapshotStore._();

  static final SecurityGatewaySnapshotStore instance =
      SecurityGatewaySnapshotStore._();

  final Map<String, ConfigRollbackSnapshot<Object>> _snapshots =
      <String, ConfigRollbackSnapshot<Object>>{};

  void save<T>(ConfigRollbackSnapshot<T> snapshot) {
    _snapshots[snapshot.scope] = ConfigRollbackSnapshot<Object>(
      scope: snapshot.scope,
      title: snapshot.title,
      summary: snapshot.summary,
      data: snapshot.data as Object,
      createdAt: snapshot.createdAt,
    );
  }

  ConfigRollbackSnapshot<Object>? read(String scope) {
    return _snapshots[scope];
  }

  List<ConfigRollbackSnapshot<Object>> recent({int limit = 10}) {
    final items = _snapshots.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(limit).toList(growable: false);
  }

  ConfigRollbackSnapshot<Object>? latestForScopes(Iterable<String> scopes) {
    ConfigRollbackSnapshot<Object>? latest;
    for (final scope in scopes) {
      final snapshot = _snapshots[scope];
      if (snapshot == null) {
        continue;
      }
      if (latest == null || snapshot.createdAt.isAfter(latest.createdAt)) {
        latest = snapshot;
      }
    }
    return latest;
  }

  void clear() {
    _snapshots.clear();
  }
}
