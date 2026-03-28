import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityGatewaySnapshotStore {
  SecurityGatewaySnapshotStore._();

  static const String _storageKey = 'security_gateway_snapshots_v1';

  static final SecurityGatewaySnapshotStore instance =
      SecurityGatewaySnapshotStore._();

  final Map<String, ConfigRollbackSnapshot<Object>> _snapshots =
      <String, ConfigRollbackSnapshot<Object>>{};
  bool _initialized = false;
  Future<void>? _initializing;
  Future<void> _writeQueue = Future<void>.value();

  Future<void> ensureInitialized() async {
    if (_initialized) {
      return;
    }
    if (_initializing != null) {
      await _initializing;
      return;
    }

    _initializing = _loadFromStorage();
    await _initializing;
    _initializing = null;
    _initialized = true;
  }

  void save<T>(ConfigRollbackSnapshot<T> snapshot) {
    _snapshots[snapshot.scope] = ConfigRollbackSnapshot<Object>(
      scope: snapshot.scope,
      title: snapshot.title,
      summary: snapshot.summary,
      data: snapshot.data as Object,
      createdAt: snapshot.createdAt,
    );
    _schedulePersist();
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
    _initialized = true;
    _initializing = null;
    _schedulePersist();
  }

  @visibleForTesting
  Future<void> flushPendingWrites() => _writeQueue;

  @visibleForTesting
  void resetForTest() {
    _snapshots.clear();
    _initialized = false;
    _initializing = null;
    _writeQueue = Future<void>.value();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.trim().isEmpty) {
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }

      for (final item in decoded) {
        final snapshot = _snapshotFromJson(item);
        if (snapshot == null) {
          continue;
        }
        _snapshots[snapshot.scope] = snapshot;
      }
    } catch (_) {
      _snapshots.clear();
    }
  }

  Future<void> _persistToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final payload =
        _snapshots.values.map(_snapshotToJson).toList(growable: false);
    await prefs.setString(_storageKey, jsonEncode(payload));
  }

  void _schedulePersist() {
    _writeQueue =
        _writeQueue.then((_) => _persistToStorage()).catchError((_) {});
  }

  Map<String, dynamic> _snapshotToJson(
    ConfigRollbackSnapshot<Object> snapshot,
  ) {
    return <String, dynamic>{
      'scope': snapshot.scope,
      'title': snapshot.title,
      'summary': snapshot.summary,
      'data': snapshot.data,
      'createdAt': snapshot.createdAt.toIso8601String(),
    };
  }

  ConfigRollbackSnapshot<Object>? _snapshotFromJson(dynamic value) {
    if (value is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(value);
    final scope = map['scope']?.toString().trim();
    final title = map['title']?.toString().trim();
    final summary = map['summary']?.toString().trim();
    final createdAtRaw = map['createdAt']?.toString();
    final createdAt =
        createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw);

    if (scope == null || scope.isEmpty) {
      return null;
    }
    if (title == null || title.isEmpty) {
      return null;
    }
    if (summary == null || summary.isEmpty) {
      return null;
    }
    if (createdAt == null) {
      return null;
    }

    return ConfigRollbackSnapshot<Object>(
      scope: scope,
      title: title,
      summary: summary,
      data: _normalizeStoredData(map['data']),
      createdAt: createdAt,
    );
  }

  Object _normalizeStoredData(dynamic value) {
    final normalized = _normalizeDynamic(value);
    if (normalized == null) {
      return '';
    }
    return normalized;
  }

  dynamic _normalizeDynamic(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, innerValue) =>
            MapEntry(key.toString(), _normalizeDynamic(innerValue)),
      );
    }
    if (value is List) {
      return value.map<dynamic>(_normalizeDynamic).toList(growable: false);
    }
    return value;
  }
}
