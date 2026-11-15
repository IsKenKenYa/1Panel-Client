import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/website_template_models.dart';
import 'package:onepanel_client/features/firewall/firewall_v2_service.dart';
import 'package:onepanel_client/features/firewall/pages/firewall_v2_page.dart';
import 'package:onepanel_client/features/firewall/pages/firewall_v2_section_page.dart';
import 'package:onepanel_client/features/firewall/providers/firewall_v2_provider.dart';
import 'package:onepanel_client/features/firewall/widgets/firewall_v2_data_view.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/websites/pages/website_template_form_page.dart';
import 'package:onepanel_client/features/websites/pages/website_template_output_create_page.dart';
import 'package:onepanel_client/features/websites/pages/website_template_outputs_page.dart';
import 'package:onepanel_client/features/websites/pages/website_templates_page.dart';
import 'package:onepanel_client/features/websites/providers/website_template_provider.dart';
import 'package:onepanel_client/features/websites/services/website_template_service.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

void _noop() {}

class _FakeCurrentServerController extends CurrentServerController {
  _FakeCurrentServerController(this._currentServerId);

  final String _currentServerId;

  @override
  String? get currentServerId => _currentServerId;

  @override
  bool get hasServer => true;
}

class _FakeWebsiteTemplateService extends WebsiteTemplateService {
  _FakeWebsiteTemplateService() : super(api: null);

  @override
  Future<PageResult<WebsiteTemplateDto>> searchTemplates({
    String? name,
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    return PageResult<WebsiteTemplateDto>(
      items: <WebsiteTemplateDto>[
        const WebsiteTemplateDto(
          id: 3,
          name: 'nginx-basic',
          type: 'single',
          content: 'server {}',
          filePath: '/templates/nginx.zip',
          remark: 'demo',
          variables: '[]',
          createdAt: '2026-11-12 10:00:00',
          updatedAt: '2026-11-12 11:00:00',
        ),
      ],
      total: 1,
    );
  }

  @override
  Future<PageResult<WebsiteTemplateOutputDto>> searchOutputs({
    int? templateID,
    int page = 1,
    int pageSize = 20,
  }) async {
    return PageResult<WebsiteTemplateOutputDto>(
      items: <WebsiteTemplateOutputDto>[
        const WebsiteTemplateOutputDto(
          id: 8,
          name: 'prod-conf',
          templateID: 3,
          templateName: 'nginx-basic',
          templateType: 'single',
          outputPath: '/etc/nginx/prod.conf',
          variableValues: '{}',
          createdAt: '2026-11-12 10:00:00',
          updatedAt: '2026-11-12 11:00:00',
        ),
      ],
      total: 1,
    );
  }

  @override
  Future<WebsiteTemplateDto?> getTemplate(int id) async {
    return (await searchTemplates()).items.first;
  }

  @override
  Future<String> previewTemplate(WebsitePreviewReq request) async =>
      '<h1>preview</h1>';

  @override
  Future<void> createTemplate(WebsiteTemplateCreate request) async {}

  @override
  Future<void> updateTemplate(WebsiteTemplateUpdate request) async {}

  @override
  Future<void> deleteTemplate(int id) async {}

  @override
  Future<void> createOutput(WebsiteTemplateOutputCreate request) async {}

  @override
  Future<void> deleteOutput(int id) async {}
}

class _FakeFirewallV2Service extends FirewallV2Service {
  _FakeFirewallV2Service() : super(api: null);

  @override
  Future<Map<String, dynamic>> loadSettings() async =>
      <String, dynamic>{'ipv6Enabled': true, 'panelPort': '26314'};

  @override
  Future<Map<String, dynamic>> searchRuleInventory({
    int page = 1,
    int pageSize = 20,
    String? info,
  }) async =>
      <String, dynamic>{'total': 2, 'items': <dynamic>[]};

  @override
  Future<Map<String, dynamic>> loadForwardBase() async =>
      <String, dynamic>{'isActive': true};

  @override
  Future<Map<String, dynamic>> searchForwardRules({
    int page = 1,
    int pageSize = 20,
  }) async =>
      <String, dynamic>{'total': 1, 'items': <dynamic>[]};

  @override
  Future<Map<String, dynamic>> loadDockerPorts() async =>
      <String, dynamic>{'base': <String, dynamic>{'isActive': true}};

  @override
  Future<List<dynamic>> loadDockerEndpoints() async => <dynamic>[];
}

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<CurrentServerController>.value(
        value: _FakeCurrentServerController('server-1'),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('WebsiteTemplatesPage renders template list', (tester) async {
    final provider = WebsiteTemplateProvider(
      service: _FakeWebsiteTemplateService(),
    );
    await provider.loadTemplates();

    await tester.pumpWidget(
      _wrap(
        ChangeNotifierProvider<WebsiteTemplateProvider>.value(
          value: provider,
          child: const WebsiteTemplatesPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('nginx-basic'), findsOneWidget);
  });

  testWidgets('WebsiteTemplateFormPage renders create fields', (tester) async {
    final provider = WebsiteTemplateProvider(
      service: _FakeWebsiteTemplateService(),
    );

    await tester.pumpWidget(
      _wrap(
        ChangeNotifierProvider<WebsiteTemplateProvider>.value(
          value: provider,
          child: const WebsiteTemplateFormPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TextFormField), findsNWidgets(4));
  });

  testWidgets('WebsiteTemplateOutputsPage renders output list',
      (tester) async {
    final provider = WebsiteTemplateProvider(
      service: _FakeWebsiteTemplateService(),
    );
    await provider.loadOutputs();

    await tester.pumpWidget(
      _wrap(
        ChangeNotifierProvider<WebsiteTemplateProvider>.value(
          value: provider,
          child: const WebsiteTemplateOutputsPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('prod-conf'), findsOneWidget);
  });

  testWidgets('WebsiteTemplateOutputCreatePage renders generate form',
      (tester) async {
    final provider = WebsiteTemplateProvider(
      service: _FakeWebsiteTemplateService(),
    );

    await tester.pumpWidget(
      _wrap(
        ChangeNotifierProvider<WebsiteTemplateProvider>.value(
          value: provider,
          child: const WebsiteTemplateOutputCreatePage(templateId: 3),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('FirewallV2Page renders four section entries', (tester) async {
    await tester.pumpWidget(_wrap(const FirewallV2Page()));
    await tester.pump();

    expect(find.byType(ListTile), findsNWidgets(4));
  });

  testWidgets('FirewallV2SectionPage renders settings data', (tester) async {
    final provider = FirewallV2Provider(service: _FakeFirewallV2Service());
    await provider.loadSettings();

    await tester.pumpWidget(
      _wrap(
        ChangeNotifierProvider<FirewallV2Provider>.value(
          value: provider,
          child: const FirewallV2SectionPage(
            section: FirewallV2Section.settings,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('panelPort'), findsOneWidget);
    expect(find.text('26314'), findsOneWidget);
  });

  testWidgets('FirewallV2DataView renders empty state', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const FirewallV2DataView(
          data: <String, dynamic>{},
          onRetry: _noop,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No records'), findsOneWidget);
  });
}
