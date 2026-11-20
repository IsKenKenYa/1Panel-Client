import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';

void main() {
  group('Shell route target mapping', () {
    test('core shell modules are mapped without embedded route mode', () {
      final filesTarget = shellRouteTargetForRoute(AppRoutes.files);
      final containersTarget = shellRouteTargetForRoute(AppRoutes.containers);
      final settingsTarget = shellRouteTargetForRoute(AppRoutes.settings);

      expect(filesTarget, isNotNull);
      expect(filesTarget!.module, ClientModule.files);
      expect(filesTarget.embedRouteInShell, isFalse);

      expect(containersTarget, isNotNull);
      expect(containersTarget!.module, ClientModule.containers);
      expect(containersTarget.embedRouteInShell, isFalse);

      expect(settingsTarget, isNotNull);
      expect(settingsTarget!.module, ClientModule.settings);
      expect(settingsTarget.embedRouteInShell, isFalse);
    });

    test('operations and toolbox routes are mapped to server shell embed mode', () {
      final operationsTarget = shellRouteTargetForRoute(AppRoutes.operations);
      final commandTarget = shellRouteTargetForRoute(AppRoutes.commands);
      final toolboxTarget = shellRouteTargetForRoute(AppRoutes.toolboxHostTool);

      expect(operationsTarget, isNotNull);
      expect(operationsTarget!.module, ClientModule.servers);
      expect(operationsTarget.embedRouteInShell, isTrue);

      expect(commandTarget, isNotNull);
      expect(commandTarget!.module, ClientModule.servers);
      expect(commandTarget.embedRouteInShell, isTrue);

      expect(toolboxTarget, isNotNull);
      expect(toolboxTarget!.module, ClientModule.servers);
      expect(toolboxTarget.embedRouteInShell, isTrue);
    });

    test('vm is a first-class shell module and alert embeds in servers', () {
      final vmTarget = shellRouteTargetForRoute(AppRoutes.vm);
      final alertTarget = shellRouteTargetForRoute(AppRoutes.alert);

      expect(vmTarget, isNotNull);
      expect(vmTarget!.module, ClientModule.vm);
      expect(vmTarget.embedRouteInShell, isFalse);

      expect(alertTarget, isNotNull);
      expect(alertTarget!.module, ClientModule.servers);
      expect(alertTarget.embedRouteInShell, isTrue);
    });

    test('website template and firewall v2 routes are embedded in shell', () {
      final templateTarget =
          shellRouteTargetForRoute(AppRoutes.websiteTemplates);
      final outputTarget =
          shellRouteTargetForRoute(AppRoutes.websiteTemplateOutputs);
      final firewallV2Target = shellRouteTargetForRoute(AppRoutes.firewallV2);
      final firewallRulesTarget =
          shellRouteTargetForRoute(AppRoutes.firewallV2Rules);
      final firewallSettingsTarget =
          shellRouteTargetForRoute(AppRoutes.firewallV2Settings);

      expect(templateTarget, isNotNull);
      expect(templateTarget!.module, ClientModule.websites);
      expect(templateTarget.embedRouteInShell, isTrue);
      expect(outputTarget?.embedRouteInShell, isTrue);

      expect(firewallV2Target, isNotNull);
      expect(firewallV2Target!.embedRouteInShell, isTrue);
      expect(firewallRulesTarget, isNotNull);
      expect(firewallSettingsTarget, isNotNull);
    });

    test('v2.5.1 sub-pages are embedded in their owning module shell', () {
      final cases = <String, (ClientModule, String)>{
        'websiteHttps': (ClientModule.websites, AppRoutes.websiteHttps),
        'websiteLog': (ClientModule.websites, AppRoutes.websiteLog),
        'fileShare': (ClientModule.files, AppRoutes.fileShare),
        'fileHistory': (ClientModule.files, AppRoutes.fileHistory),
        'aiAccounts': (ClientModule.ai, AppRoutes.aiAccounts),
        'aiAgents': (ClientModule.ai, AppRoutes.aiAgents),
        'containerInspect': (ClientModule.containers, AppRoutes.containerInspect),
        'containerFiles': (ClientModule.containers, AppRoutes.containerFiles),
        'databaseMongodb': (ClientModule.servers, AppRoutes.databaseMongodb),
        'databaseSlowLog': (ClientModule.servers, AppRoutes.databaseSlowLog),
      };
      cases.forEach((name, expected) {
        final (module, route) = expected;
        final target = shellRouteTargetForRoute(route);
        expect(target, isNotNull, reason: '$name should map to a shell target');
        expect(target!.module, module, reason: '$name module mismatch');
        expect(target.embedRouteInShell, isTrue,
            reason: '$name should embed in shell');
      });
    });

    test('unknown routes are not mapped into shell target', () {
      final target = shellRouteTargetForRoute('/unmapped/route');
      expect(target, isNull);
    });
  });
}
