import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/features/apps/app_store_page.dart';
import 'package:onepanel_client/features/apps/providers/app_store_provider.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

class _FakeAppStoreProvider extends AppStoreProvider {
  _FakeAppStoreProvider(this._ignoredApps);

  final List<AppInstallInfo> _ignoredApps;
  final List<int> canceledIds = <int>[];

  @override
  Future<void> loadApps({
    bool refresh = false,
    int pageSize = 20,
    String? name,
    String? type,
    String? resource,
    bool? recommend,
    List<String>? tags,
  }) async {
    // Keep empty state for this interaction test.
  }

  @override
  Future<void> syncLocalApps() async {
    // No-op for this test.
  }

  @override
  Future<List<AppInstallInfo>> loadIgnoredUpdates() async {
    return List<AppInstallInfo>.from(_ignoredApps);
  }

  @override
  Future<void> cancelIgnoreUpdate(int appInstallId) async {
    canceledIds.add(appInstallId);
  }
}

void main() {
  testWidgets('AppStorePage uses provider chain for ignored updates cancel',
      (tester) async {
    final provider = _FakeAppStoreProvider(
      <AppInstallInfo>[
        AppInstallInfo(id: 1, name: 'mysql', version: '8.0.0'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: AppStorePage(provider: provider),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ignored Updates').last);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('mysql'), findsOneWidget);

    await tester.tap(find.text('Cancel Ignore'));
    await tester.pumpAndSettle();

    expect(provider.canceledIds, <int>[1]);
  });
}
