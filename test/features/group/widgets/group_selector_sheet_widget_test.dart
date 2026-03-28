import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/features/group/providers/group_options_provider.dart';
import 'package:onepanel_client/features/group/services/group_service.dart';
import 'package:onepanel_client/features/group/widgets/group_selector_sheet_widget.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockGroupService extends Mock implements GroupService {}

void main() {
  late _MockGroupService service;

  setUp(() {
    service = _MockGroupService();
    when(() =>
            service.listGroups(any(), forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer(
            (_) async => [GroupInfo(id: 7, name: 'Ops', type: 'command')]);
  });

  testWidgets('shows group option and allows selection', (tester) async {
    final provider = GroupOptionsProvider(service: service);
    await provider.initialize(groupType: 'command');

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: ChangeNotifierProvider<GroupOptionsProvider>.value(
          value: provider,
          child: const Scaffold(
            body: SizedBox(
              width: 400,
              height: 520,
              child: GroupSelectorSheetWidget(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select Group'), findsOneWidget);
    expect(find.text('Ops'), findsOneWidget);
  });

  testWidgets('shows all groups option when clear selection is enabled',
      (tester) async {
    final provider = GroupOptionsProvider(service: service);
    await provider.initialize(
      groupType: 'command',
      allowEmptySelection: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: ChangeNotifierProvider<GroupOptionsProvider>.value(
          value: provider,
          child: const Scaffold(
            body: SizedBox(
              width: 400,
              height: 520,
              child: GroupSelectorSheetWidget(
                allowClearSelection: true,
                clearOptionLabel: 'All groups',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All groups'), findsOneWidget);
    expect(provider.selectedGroupId, isNull);
  });
}
