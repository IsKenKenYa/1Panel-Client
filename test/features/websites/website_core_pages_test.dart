import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/file/file_info.dart';
import 'package:onepanel_client/data/models/website_group_models.dart';
import 'package:onepanel_client/data/models/website_models.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/websites/pages/website_config_center_page.dart';
import 'package:onepanel_client/features/websites/pages/website_create_flow_page.dart';
import 'package:onepanel_client/features/websites/pages/website_domain_management_page.dart';
import 'package:onepanel_client/features/websites/pages/websites_page.dart';
import 'package:onepanel_client/features/websites/providers/website_config_center_provider.dart';
import 'package:onepanel_client/features/websites/providers/website_domain_provider.dart';
import 'package:onepanel_client/features/websites/providers/website_lifecycle_provider.dart';
import 'package:onepanel_client/features/websites/providers/websites_provider.dart';
import 'package:onepanel_client/features/websites/services/website_domain_service.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

import 'website_core_provider_test.dart';

class _FakeWebsiteDomainService extends WebsiteDomainService {
  _FakeWebsiteDomainService(this._domains);

  final List<WebsiteDomain> _domains;

  @override
  Future<List<WebsiteDomain>> fetchDomains(int websiteId) async => _domains;

  @override
  Future<void> addDomain({
    required int websiteId,
    required String domain,
    required int port,
    bool ssl = false,
  }) async {}
}

class _FakeWebsiteConfigCenterProvider extends WebsiteConfigCenterProvider {
  _FakeWebsiteConfigCenterProvider()
      : super(
          websiteId: 1,
        );

  @override
  Future<void> load() async {
    website = const WebsiteInfo(
      id: 1,
      primaryDomain: 'example.com',
      sitePath: '/opt/www/example',
      runtimeName: 'php-8.2',
      remark: 'prod',
      dbType: 'mysql',
    );
    configFile = const FileInfo(
      name: 'example.conf',
      path: '/etc/nginx/conf.d/example.conf',
      type: 'file',
      size: 0,
    );
    httpsSummary = const {'enable': true};
    notifyListeners();
  }
}

class _FakeCurrentServerController extends CurrentServerController {
  _FakeCurrentServerController(this._currentServerId);

  final String _currentServerId;

  @override
  String? get currentServerId => _currentServerId;

  @override
  bool get hasServer => true;
}

void main() {
  testWidgets('WebsitesPage supports search and selection mode',
      (tester) async {
    final provider = WebsitesProvider(
      service: FakeWebsiteService(
        searchResult: const PageResult(
          items: [
            WebsiteInfo(
              id: 1,
              primaryDomain: 'example.com',
              type: 'runtime',
              group: 'prod',
            ),
          ],
          total: 1,
        ),
        groupResult: const [WebsiteGroup(id: 1, name: 'prod')],
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController('server-1'),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WebsitesPage(provider: provider),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'example');
    await tester.tap(find.byIcon(Icons.search).first);
    await tester.pumpAndSettle();

    expect(find.text('example.com'), findsOneWidget);

    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('WebsiteCreateFlowPage renders create form', (tester) async {
    final provider = WebsiteLifecycleProvider(
      mode: WebsiteLifecycleMode.create,
      service: FakeWebsiteService(
        groupResult: const [WebsiteGroup(id: 1, name: 'prod')],
      ),
    );
    await provider.load();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WebsiteCreateFlowPage(provider: provider),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create Website'), findsOneWidget);
    expect(find.text('Alias'), findsOneWidget);
    expect(find.text('Primary domain'), findsOneWidget);
  });

  testWidgets('WebsiteDomainManagementPage validates duplicate domains',
      (tester) async {
    final provider = WebsiteDomainProvider(
      websiteId: 1,
      service: _FakeWebsiteDomainService(
        const [WebsiteDomain(id: 1, domain: 'example.com', port: 80)],
      ),
    );
    await provider.loadDomains();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WebsiteDomainManagementPage(
          websiteId: 1,
          provider: provider,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'example.com');
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();

    expect(find.text('This domain already exists.'), findsOneWidget);
  });

  testWidgets('WebsiteConfigCenterPage shows structured entry cards',
      (tester) async {
    final provider = _FakeWebsiteConfigCenterProvider();
    await provider.load();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WebsiteConfigCenterPage(
          websiteId: 1,
          provider: provider,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Basic'), findsOneWidget);
    expect(find.textContaining('Proxy'), findsOneWidget);
    expect(find.text('Nginx config file'), findsOneWidget);
  });
}
