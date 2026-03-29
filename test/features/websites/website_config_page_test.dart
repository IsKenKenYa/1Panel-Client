import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/data/models/file/file_info.dart';
import 'package:onepanel_client/data/models/openresty_models.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/data/models/website_models.dart';
import 'package:onepanel_client/features/websites/pages/website_config_page.dart';
import 'package:onepanel_client/features/websites/providers/website_config_provider.dart';
import 'package:onepanel_client/features/websites/services/website_config_service.dart';
import 'package:onepanel_client/features/websites/services/website_service.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

class _FakeWebsiteService extends WebsiteService {
  _FakeWebsiteService({
    required this.currentRuntimeId,
    required this.runtimes,
  });

  int? currentRuntimeId;
  final List<RuntimeInfo> runtimes;

  @override
  Future<WebsiteInfo> getWebsiteDetail(int id) async {
    RuntimeInfo? runtime;
    for (final item in runtimes) {
      if (item.id == currentRuntimeId) {
        runtime = item;
        break;
      }
    }

    return WebsiteInfo(
      id: id,
      primaryDomain: 'example.com',
      runtimeId: currentRuntimeId,
      runtimeName: runtime?.name,
    );
  }

  @override
  Future<List<RuntimeInfo>> listPhpRuntimes() async {
    return runtimes;
  }

  void switchRuntime(int? runtimeId) {
    currentRuntimeId = runtimeId;
  }
}

class _FakeWebsiteConfigService extends WebsiteConfigService {
  _FakeWebsiteConfigService({
    required this.onUpdatePhpVersion,
  });

  final void Function(int? runtimeId) onUpdatePhpVersion;

  int? lastRuntimeId;

  @override
  Future<FileInfo> fetchNginxConfigFile(int websiteId) async {
    return const FileInfo(
      name: 'example.conf',
      path: '/etc/nginx/conf.d/example.conf',
      type: 'file',
      content: 'server {}',
      size: 0,
    );
  }

  @override
  Future<WebsiteNginxScopeResponse> loadScope({
    required int websiteId,
    required NginxKey scope,
  }) async {
    return const WebsiteNginxScopeResponse();
  }

  @override
  Future<void> updatePhpVersion({
    required int websiteId,
    int? runtimeId,
  }) async {
    lastRuntimeId = runtimeId;
    onUpdatePhpVersion(runtimeId);
  }
}

void main() {
  testWidgets('WebsiteConfigPage switches php runtime through dropdown',
      (tester) async {
    final websiteService = _FakeWebsiteService(
      currentRuntimeId: 11,
      runtimes: const [
        RuntimeInfo(id: 11, name: 'php-8.2'),
        RuntimeInfo(id: 12, name: 'php-8.3'),
      ],
    );
    final configService = _FakeWebsiteConfigService(
      onUpdatePhpVersion: websiteService.switchRuntime,
    );

    final provider = WebsiteConfigProvider(
      websiteId: 1,
      service: configService,
      websiteService: websiteService,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WebsiteConfigPage(
          websiteId: 1,
          provider: provider,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    final dropdowns = find.byWidgetPredicate(
      (widget) => widget is DropdownButtonFormField,
    );
    expect(dropdowns, findsNWidgets(2));
    final runtimeDropdown = dropdowns.last;

    await tester.ensureVisible(runtimeDropdown);
    await tester.pumpAndSettle();
    await tester.tap(runtimeDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('php-8.3').last);
    await tester.pumpAndSettle();

    final saveButtons = find.byIcon(Icons.save);
    await tester.ensureVisible(saveButtons.last);
    await tester.tap(saveButtons.last);
    await tester.pumpAndSettle();

    expect(configService.lastRuntimeId, 12);
    expect(provider.website?.runtimeName, 'php-8.3');
  });
}
