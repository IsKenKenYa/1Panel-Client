import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/firewall_models.dart';
import 'package:onepanel_client/features/firewall/firewall_rule_form_page.dart';
import 'package:onepanel_client/features/firewall/firewall_service.dart';
import 'package:onepanel_client/features/firewall/firewall_status_tab.dart';
import 'package:onepanel_client/features/firewall/providers/firewall_status_provider.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

class _FakeFirewallInteractionService implements FirewallServiceInterface {
  _FakeFirewallInteractionService([this.status = const FirewallBaseInfo()]);

  final FirewallBaseInfo status;

  @override
  Future<FirewallBaseInfo> loadBaseInfo({String tab = 'base'}) async => status;

  @override
  Future<PageResult<FirewallRule>> searchRules({
    required int page,
    required int pageSize,
    String? type,
    String? info,
    String? strategy,
  }) async {
    return const PageResult(items: [], total: 0);
  }

  @override
  Future<void> operateFirewall({required FirewallOperation operation}) async {}

  @override
  Future<void> createIpRule(FirewallIpRulePayload payload) async {}

  @override
  Future<void> createPortRule(FirewallPortRulePayload payload) async {}

  @override
  Future<void> deleteRules(FirewallBatchRuleRequest request) async {}

  @override
  Future<void> updateDescription(FirewallDescriptionUpdate request) async {}

  @override
  Future<void> updateIpRule(FirewallUpdateIpRequest request) async {}

  @override
  Future<void> updatePortRule(FirewallUpdatePortRequest request) async {}
}

void main() {
  testWidgets('FirewallStatusTab asks for confirmation before restart',
      (tester) async {
    final provider = FirewallStatusProvider(
      service: _FakeFirewallInteractionService(
        const FirewallBaseInfo(
          name: 'firewalld',
          isActive: true,
        ),
      ),
    );
    await provider.load();

    await tester.pumpWidget(
      ChangeNotifierProvider<FirewallStatusProvider>.value(
        value: provider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: FirewallStatusTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restart'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm firewall change'), findsOneWidget);
    expect(
      find.text(
        'Restart the firewall service? Existing connections may be interrupted briefly.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('FirewallRuleFormPage validates required address for ip rule',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FirewallRuleFormPage(
          arguments: FirewallRuleFormArguments(kind: FirewallRuleKind.ip),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Address is required.'), findsOneWidget);
  });
}
