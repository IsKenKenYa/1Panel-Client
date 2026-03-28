import 'package:flutter/foundation.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/services/database_user_service.dart';

class DatabaseUsersState {
  const DatabaseUsersState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.context,
  });

  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final DatabaseUserContext? context;
}

class DatabaseUsersProvider extends ChangeNotifier {
  DatabaseUsersProvider({
    required this.item,
    DatabaseUserService? service,
  }) : _service = service ?? DatabaseUserService();

  final DatabaseListItem item;
  final DatabaseUserService _service;

  DatabaseUsersState _state = const DatabaseUsersState();
  DatabaseUsersState get state => _state;

  Future<void> load() async {
    _state = const DatabaseUsersState(isLoading: true);
    notifyListeners();
    try {
      final context = await _service.loadContext(item);
      _state = DatabaseUsersState(context: context);
    } catch (e) {
      _state = DatabaseUsersState(error: e.toString());
    }
    notifyListeners();
  }

  Future<bool> bindUser({
    required String username,
    required String password,
    String permission = '%',
    bool superUser = false,
  }) async {
    return _runMutation(() async {
      await _service.bindUser(
        item,
        username: username,
        password: password,
        permission: permission,
        superUser: superUser,
      );
      final nextContext =
          (_state.context ?? await _service.loadContext(item)).copyWith(
        currentUsername: username,
        superUser: superUser,
      );
      _state = DatabaseUsersState(context: nextContext);
      notifyListeners();
    });
  }

  Future<bool> updatePrivileges({
    required bool superUser,
  }) async {
    final currentUsername = _state.context?.currentUsername;
    if (currentUsername == null || currentUsername.isEmpty) {
      return false;
    }
    return _runMutation(() async {
      await _service.updatePrivileges(
        item,
        username: currentUsername,
        superUser: superUser,
      );
      _state = DatabaseUsersState(
        context: _state.context?.copyWith(superUser: superUser),
      );
      notifyListeners();
    });
  }

  Future<bool> _runMutation(Future<void> Function() action) async {
    _state = DatabaseUsersState(
      context: _state.context,
      isSubmitting: true,
    );
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _state = DatabaseUsersState(
        context: _state.context,
        error: e.toString(),
      );
      notifyListeners();
      return false;
    } finally {
      if (_state.isSubmitting) {
        _state = DatabaseUsersState(context: _state.context);
        notifyListeners();
      }
    }
  }
}
