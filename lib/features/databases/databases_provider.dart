import 'package:flutter/foundation.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/databases_service.dart';

class DatabasesState {
  const DatabasesState({
    this.page = const PageResult<DatabaseListItem>(items: [], total: 0),
    this.isLoading = false,
    this.error,
    this.query = '',
  });

  final PageResult<DatabaseListItem> page;
  final bool isLoading;
  final String? error;
  final String query;

  List<DatabaseListItem> get items => page.items;
}

class DatabasesProvider extends ChangeNotifier {
  DatabasesProvider({
    required this.scope,
    DatabasesService? service,
  }) : _service = service ?? DatabasesService();

  final DatabaseScope scope;
  final DatabasesService _service;

  DatabasesState _state = const DatabasesState();
  DatabasesState get state => _state;

  Future<void> load({String? query}) async {
    _state = DatabasesState(
      page: _state.page,
      isLoading: true,
      query: query ?? _state.query,
    );
    notifyListeners();

    try {
      final page = await _service.loadPage(
        scope: scope,
        query: query ?? _state.query,
      );
      _state = DatabasesState(
        page: page,
        isLoading: false,
        query: query ?? _state.query,
      );
    } catch (e) {
      _state = DatabasesState(
        page: _state.page,
        isLoading: false,
        error: e.toString(),
        query: query ?? _state.query,
      );
    }
    notifyListeners();
  }

  Future<void> refresh() => load(query: _state.query);
}

class DatabaseDetailProvider extends ChangeNotifier {
  DatabaseDetailProvider({
    required this.item,
    DatabasesService? service,
  }) : _service = service ?? DatabasesService();

  final DatabaseListItem item;
  final DatabasesService _service;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  DatabaseDetailData? _detail;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  DatabaseDetailData? get detail => _detail;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _detail = await _service.loadDetail(item);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateDescription(String description) async {
    return _runSubmit(() async {
      await _service.updateDescription(item, description);
      await load();
    });
  }

  Future<bool> changePassword(String password) async {
    return _runSubmit(() async {
      await _service.changePassword(item, password);
      await load();
    });
  }

  Future<bool> bindUser({
    required String username,
    required String password,
  }) async {
    return _runSubmit(() async {
      await _service.bindUser(
        item,
        username: username,
        password: password,
      );
      await load();
    });
  }

  Future<bool> updateRedisConfig(Map<String, dynamic> payload) async {
    return _runSubmit(() async {
      await _service.updateRedisConfig(
        database: item.lookupName,
        payload: payload,
      );
      await load();
    });
  }

  Future<bool> updateRedisPersistence(Map<String, dynamic> payload) async {
    return _runSubmit(() async {
      await _service.updateRedisPersistence(
        database: item.lookupName,
        payload: payload,
      );
      await load();
    });
  }

  Future<bool> _runSubmit(Future<void> Function() action) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}

class DatabaseFormProvider extends ChangeNotifier {
  DatabaseFormProvider({DatabasesService? service})
      : _service = service ?? DatabasesService();

  final DatabasesService _service;

  bool _isSubmitting = false;
  String? _error;

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  Future<bool> submit(DatabaseFormInput input) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await _service.submitForm(input);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> testRemote(DatabaseFormInput input) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      return await _service.testRemoteConnection(input);
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
