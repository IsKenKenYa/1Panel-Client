import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/data/repositories/group_repository.dart';
import 'package:onepanel_client/features/group/pages/group_center_page.dart';
import 'package:onepanel_client/features/group/providers/group_center_provider.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _FakeGroupCenterProvider extends GroupCenterProvider {
  _FakeGroupCenterProvider() : super();

  final bool _isLoading = false;
  @override
  bool get isLoading => _isLoading;

  @override
  GroupApiScope get scope => GroupApiScope.core;

  @override
  String get groupType => 'command';

  @override
  List<GroupInfo> get groups => const <GroupInfo>[
        GroupInfo(id: 1, name: 'Default', type: 'command', isDefault: true),
        GroupInfo(id: 2, name: 'Ops', type: 'command'),
      ];

  @override
  Future<void> load({bool forceRefresh = false}) async {}

  @override
  Future<void> changeScope(GroupApiScope value) async {}

  @override
  Future<void> changeGroupType(String value) async {}
}

class _FakeCurrentServerController extends CurrentServerController {
  final ApiConfig _config = ApiConfig(
    id: 'server-1',
    name: 'Demo',
    url: 'https://demo.example.com',
    apiKey: 'key',
  );

  @override
  bool get hasServer => true;

  @override
  String? get currentServerId => _config.id;

  @override
  ApiConfig? get currentServer => _config;

  @override
  Future<void> refresh() async {}
}

void main() {
  testWidgets('GroupCenterPage renders namespace selector and group list',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<CurrentServerController>.value(
        value: _FakeCurrentServerController(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: GroupCenterPage(provider: _FakeGroupCenterProvider()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Group Center'), findsOneWidget);
    expect(find.text('Core'), findsOneWidget);
    expect(find.text('Default'), findsWidgets);
    expect(find.text('Ops'), findsOneWidget);
  });
}
