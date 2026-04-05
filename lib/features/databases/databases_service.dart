import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/data/models/database_option_models.dart';
import 'package:onepanel_client/data/repositories/database_repository.dart';

class DatabasesService {
  DatabasesService({DatabaseRepository? repository})
      : _repository = repository ?? DatabaseRepository();

  final DatabaseRepository _repository;

  Future<PageResult<DatabaseListItem>> loadPage({
    required DatabaseScope scope,
    String? targetDatabase,
    String? query,
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.searchByScope(
      scope: scope,
      targetDatabase: targetDatabase,
      query: query,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<DatabaseDetailData> loadDetail(DatabaseListItem item) {
    return _repository.loadDetail(item);
  }

  Future<void> submitForm(DatabaseFormInput input) {
    return _repository.submitForm(input);
  }

  Future<List<DatabaseItemOption>> loadDatabaseItems(String type) {
    return _repository.loadDatabaseItems(type);
  }

  Future<List<DatabaseListItem>> loadDatabaseTargets(DatabaseScope scope) {
    return _repository.loadDatabaseTargets(scope);
  }

  Future<void> updateDescription(DatabaseListItem item, String description) {
    return _repository.updateDescription(item, description);
  }

  Future<void> changePassword(DatabaseListItem item, String password) {
    return _repository.changePassword(item, password);
  }

  Future<void> bindUser(
    DatabaseListItem item, {
    required String username,
    required String password,
  }) {
    return _repository.bindUser(
      item,
      username: username,
      password: password,
    );
  }

  Future<bool> testRemoteConnection(DatabaseFormInput input) {
    return _repository.testRemoteConnection(input);
  }

  Future<void> updateRedisConfig({
    required String database,
    required Map<String, dynamic> payload,
  }) {
    return _repository.updateRedisConfig(database: database, payload: payload);
  }

  Future<void> updateRedisPersistence({
    required String database,
    required Map<String, dynamic> payload,
  }) {
    return _repository.updateRedisPersistence(
      database: database,
      payload: payload,
    );
  }
}
