import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/data/models/database_option_models.dart';
import 'package:onepanel_client/features/databases/databases_page.dart';
import 'package:onepanel_client/features/databases/databases_provider.dart';
import 'package:onepanel_client/features/databases/databases_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

class _FakeDatabasesService extends DatabasesService {
  _FakeDatabasesService({
    this.pageResult = const PageResult<DatabaseListItem>(items: [], total: 0),
    this.throwOnLoad = false,
  });

  final PageResult<DatabaseListItem> pageResult;
  final bool throwOnLoad;

  @override
  Future<PageResult<DatabaseListItem>> loadPage({
    required DatabaseScope scope,
    String? targetDatabase,
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (throwOnLoad) {
      throw Exception('boom');
    }
    return pageResult;
  }

  @override
  Future<List<DatabaseItemOption>> loadDatabaseItems(String type) async {
    return const <DatabaseItemOption>[];
  }

  @override
  Future<List<DatabaseListItem>> loadDatabaseTargets(
      DatabaseScope scope) async {
    return const <DatabaseListItem>[];
  }
}

void main() {
  group('DatabasesProvider', () {
    test('load fills state on success', () async {
      final provider = DatabasesProvider(
        scope: DatabaseScope.mysql,
        service: _FakeDatabasesService(
          pageResult: PageResult(
            items: const [
              DatabaseListItem(
                scope: DatabaseScope.mysql,
                name: 'demo',
                engine: 'mysql',
                source: 'local',
              ),
            ],
            total: 1,
          ),
        ),
      );

      await provider.load();

      expect(provider.state.items, hasLength(1));
      expect(provider.state.items.first.name, 'demo');
      expect(provider.state.isLoading, isFalse);
      expect(provider.state.error, isNull);
    });

    test('load surfaces service failures', () async {
      final provider = DatabasesProvider(
        scope: DatabaseScope.mysql,
        service: _FakeDatabasesService(throwOnLoad: true),
      );

      await provider.load();

      expect(provider.state.items, isEmpty);
      expect(provider.state.isLoading, isFalse);
      expect(provider.state.error, contains('boom'));
    });
  });

  testWidgets('DatabasesPage renders tabs and server-aware scaffold',
      (tester) async {
    final serverController = CurrentServerController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: serverController,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DefaultTabController(
            length: 4,
            child: DatabasesPage(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Databases'), findsOneWidget);
    expect(find.text('MySQL'), findsOneWidget);
    expect(find.text('PostgreSQL'), findsOneWidget);
    expect(find.text('Redis'), findsOneWidget);
    expect(find.text('Remote'), findsOneWidget);
  });
}
