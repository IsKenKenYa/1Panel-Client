import 'package:onepanel_client/api/v2/database_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/database_models.dart';

class DatabaseUserRepository {
  DatabaseUserRepository({ApiClientManager? clientManager})
      : _clientManager = clientManager ?? ApiClientManager.instance;

  final ApiClientManager _clientManager;

  Future<DatabaseV2Api> _getApi() => _clientManager.getDatabaseApi();

  Future<void> bindMysqlUser(
    DatabaseListItem item, {
    required String username,
    required String password,
    String permission = '%',
  }) async {
    final api = await _getApi();
    await api.bindMysqlUser({
      'database': item.lookupName,
      'db': item.name,
      'username': username,
      'password': password,
      'permission': permission,
    });
  }

  Future<void> bindPostgresqlUser(
    DatabaseListItem item, {
    required String username,
    required String password,
    required bool superUser,
  }) async {
    final api = await _getApi();
    await api.bindPostgresqlUser({
      'name': item.name,
      'database': item.lookupName,
      'username': username,
      'password': password,
      'superUser': superUser,
    });
  }

  Future<void> updatePostgresqlPrivileges(
    DatabaseListItem item, {
    required String username,
    required bool superUser,
  }) async {
    final api = await _getApi();
    await api.changePostgresqlPrivileges({
      'name': item.name,
      'database': item.lookupName,
      'username': username,
      'superUser': superUser,
    });
  }
}
