import 'package:flutter/foundation.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/databases_service.dart';

class DatabasesState {
  const DatabasesState({
    this.page = const PageResult<DatabaseListItem>(items: [], total: 0),
    this.targets = const <DatabaseListItem>[],
    this.selectedTarget,
    this.isLoading = false,
    this.isLoadingTargets = false,
    this.error,
    this.query = '',
  });

  final PageResult<DatabaseListItem> page;
  final List<DatabaseListItem> targets;
  final DatabaseListItem? selectedTarget;
  final bool isLoading;
  final bool isLoadingTargets;
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
      targets: _state.targets,
      selectedTarget: _state.selectedTarget,
      isLoading: true,
      isLoadingTargets: _state.isLoadingTargets,
      query: query ?? _state.query,
    );
    notifyListeners();

    try {
      DatabaseListItem? selectedTarget = _state.selectedTarget;
      var targets = _state.targets;
      if (scope != DatabaseScope.remote &&
          scope != DatabaseScope.redis &&
          targets.isEmpty) {
        targets = await _service.loadDatabaseTargets(scope);
        selectedTarget = targets.isEmpty ? null : targets.first;
      }
      final page = await _service.loadPage(
        scope: scope,
        targetDatabase: selectedTarget?.lookupName,
        query: query ?? _state.query,
      );
      _state = DatabasesState(
        page: page,
        targets: targets,
        selectedTarget: selectedTarget,
        isLoading: false,
        query: query ?? _state.query,
      );
    } catch (e) {
      _state = DatabasesState(
        page: _state.page,
        targets: _state.targets,
        selectedTarget: _state.selectedTarget,
        isLoading: false,
        isLoadingTargets: _state.isLoadingTargets,
        error: e.toString(),
        query: query ?? _state.query,
      );
    }
    notifyListeners();
  }

  Future<void> refresh() => load(query: _state.query);

  Future<void> loadTargets() async {
    _state = DatabasesState(
      page: _state.page,
      targets: _state.targets,
      selectedTarget: _state.selectedTarget,
      isLoading: _state.isLoading,
      isLoadingTargets: true,
      query: _state.query,
    );
    notifyListeners();

    try {
      final targets = await _service.loadDatabaseTargets(scope);
      final selected = targets.isEmpty
          ? null
          : targets.firstWhere(
              (item) => item.lookupName == _state.selectedTarget?.lookupName,
              orElse: () => targets.first,
            );
      _state = DatabasesState(
        page: _state.page,
        targets: targets,
        selectedTarget: selected,
        isLoading: _state.isLoading,
        query: _state.query,
      );
    } catch (e) {
      _state = DatabasesState(
        page: _state.page,
        targets: _state.targets,
        selectedTarget: _state.selectedTarget,
        isLoading: _state.isLoading,
        error: e.toString(),
        query: _state.query,
      );
    }
    notifyListeners();
  }

  Future<void> selectTarget(DatabaseListItem? target) async {
    _state = DatabasesState(
      page: _state.page,
      targets: _state.targets,
      selectedTarget: target,
      isLoading: _state.isLoading,
      query: _state.query,
    );
    notifyListeners();
    await load(query: _state.query);
  }
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
  List<String> _errorMessages = const <String>[];
  bool _isLoadingOptions = false;
  List<DatabaseListItem> _databaseTargets = const <DatabaseListItem>[];

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  List<String> get errorMessages => _errorMessages;
  bool get isLoadingOptions => _isLoadingOptions;
  List<DatabaseListItem> get databaseTargets => _databaseTargets;

  Future<void> loadDatabaseTargets(DatabaseScope scope) async {
    if (scope == DatabaseScope.remote) {
      _databaseTargets = const <DatabaseListItem>[];
      notifyListeners();
      return;
    }

    _isLoadingOptions = true;
    _error = null;
    _errorMessages = const <String>[];
    notifyListeners();
    try {
      _databaseTargets = await _service.loadDatabaseTargets(scope);
    } catch (e) {
      _error = e.toString();
      _errorMessages = _friendlyErrorMessages(_error!);
    } finally {
      _isLoadingOptions = false;
      notifyListeners();
    }
  }

  Future<bool> submit(DatabaseFormInput input) async {
    _isSubmitting = true;
    _error = null;
    _errorMessages = const <String>[];
    notifyListeners();
    try {
      await _service.submitForm(input);
      return true;
    } catch (e) {
      _error = e.toString();
      _errorMessages = _friendlyErrorMessages(_error!);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> testRemote(DatabaseFormInput input) async {
    _isSubmitting = true;
    _error = null;
    _errorMessages = const <String>[];
    notifyListeners();
    try {
      return await _service.testRemoteConnection(input);
    } catch (e) {
      _error = e.toString();
      _errorMessages = _friendlyErrorMessages(_error!);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  List<String> _friendlyErrorMessages(String raw) {
    final fieldMappings = <String, String>{
      'Name': 'Name',
      'Username': 'Username',
      'Password': 'Password',
      'Format': 'Format',
      'Permission': 'Permission',
      'Address': 'Address',
      'Port': 'Port',
    };

    final regex = RegExp(
      r"Key: '.*?\.(\w+)' Error:Field validation for '.*?' failed on the '(\w+)' tag",
    );
    final matches = regex.allMatches(raw).toList(growable: false);
    if (matches.isEmpty) {
      return <String>[raw];
    }

    return matches.map((match) {
      final field = fieldMappings[match.group(1)] ?? match.group(1)!;
      final tag = match.group(2);
      if (tag == 'required') {
        return '$field is required.';
      }
      return '$field validation failed.';
    }).toList(growable: false);
  }
}
