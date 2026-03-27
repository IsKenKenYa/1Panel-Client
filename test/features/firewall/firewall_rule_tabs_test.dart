import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/firewall_models.dart';
import 'package:onepanel_client/features/firewall/firewall_ip_tab.dart';
import 'package:onepanel_client/features/firewall/firewall_port_tab.dart';
import 'package:onepanel_client/features/firewall/firewall_rules_tab.dart';
import 'package:onepanel_client/features/firewall/firewall_service.dart';
import 'package:onepanel_client/features/firewall/providers/firewall_rule_list_provider.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _FakeRuleTabService implements FirewallServiceInterface {
  final List<FirewallBatchRuleRequest> deleteRequests = [];
  final List<FirewallUpdateIpRequest> ipUpdates = [];
  final List<FirewallUpdatePortRequest> portUpdates = [];
  String? lastInfo;
  String? lastStrategy;
  String? lastType;

  @override
  Future<FirewallBaseInfo> loadBaseInfo({String tab = 'base'}) async {
    return const FirewallBaseInfo();
  }

  @override
  Future<PageResult<FirewallRule>> searchRules({
    required int page,
    required int pageSize,
    String? type,
    String? info,
    String? strategy,
  }) async {
    lastInfo = info;
    lastStrategy = strategy;
    lastType = type;
    if (type == 'address') {
      return const PageResult(
        items: [
          FirewallRule(id: 1, address: '1.1.1.1', strategy: 'accept'),
        ],
        total: 1,
      );
    }
    if (type == 'port') {
      return const PageResult(
        items: [
          FirewallRule(id: 2, address: '', port: '22', strategy: 'drop'),
        ],
        total: 1,
      );
    }
    return const PageResult(
      items: [
        FirewallRule(id: 1, address: '1.1.1.1', strategy: 'accept'),
        FirewallRule(id: 2, address: '', port: '22', strategy: 'drop'),
      ],
      total: 2,
    );
  }

  @override
  Future<void> operateFirewall({required FirewallOperation operation}) async {}

  @override
  Future<void> createIpRule(FirewallIpRulePayload payload) async {}

  @override
  Future<void> createPortRule(FirewallPortRulePayload payload) async {}

  @override
  Future<void> deleteRules(FirewallBatchRuleRequest request) async {
    deleteRequests.add(request);
  }

  @override
  Future<void> updateDescription(FirewallDescriptionUpdate request) async {}

  @override
  Future<void> updateIpRule(FirewallUpdateIpRequest request) async {
    ipUpdates.add(request);
  }

  @override
  Future<void> updatePortRule(FirewallUpdatePortRequest request) async {
    portUpdates.add(request);
  }
}

void main() {
  Future<void> pumpTab<T extends FirewallRuleListProvider>({
    required WidgetTester tester,
    required T provider,
    required Widget child,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<T>.value(
        value: provider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('FirewallRulesTab supports search/filter and batch delete split',
      (tester) async {
    final service = _FakeRuleTabService();
    final provider = FirewallRulesProvider(service: service);
    await pumpTab(
      tester: tester,
      provider: provider,
      child: const FirewallRulesTab(),
    );

    await tester.enterText(
        find.byKey(const Key('firewall.searchField')), 'ssh');
    await tester.tap(find.byKey(const Key('firewall.searchButton')));
    await tester.pumpAndSettle();
    expect(service.lastInfo, 'ssh');

    await tester.tap(find.byKey(const Key('firewall.strategyFilter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Drop').last);
    await tester.pumpAndSettle();
    expect(service.lastStrategy, 'drop');

    await tester.tap(find.byKey(const Key('firewall.selectionModeButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('firewall.bulkDeleteButton')));
    await tester.pumpAndSettle();
    expect(service.deleteRequests.map((e) => e.type),
        containsAll(['address', 'port']));
  });

  testWidgets('FirewallIpTab batch accept toggles strategy', (tester) async {
    final service = _FakeRuleTabService();
    final provider = FirewallIpProvider(service: service);
    await pumpTab(
      tester: tester,
      provider: provider,
      child: const FirewallIpTab(),
    );

    await tester.tap(find.byKey(const Key('firewall.selectionModeButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('firewall.bulkDropButton')));
    await tester.pumpAndSettle();
    expect(service.ipUpdates, isNotEmpty);
    expect(service.ipUpdates.last.newRule.strategy, 'drop');
  });

  testWidgets('FirewallPortTab batch accept toggles strategy', (tester) async {
    final service = _FakeRuleTabService();
    final provider = FirewallPortsProvider(service: service);
    await pumpTab(
      tester: tester,
      provider: provider,
      child: const FirewallPortTab(),
    );

    await tester.tap(find.byKey(const Key('firewall.selectionModeButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('firewall.bulkAcceptButton')));
    await tester.pumpAndSettle();
    expect(service.portUpdates, isNotEmpty);
    expect(service.portUpdates.last.newRule.strategy, 'accept');
  });
}
