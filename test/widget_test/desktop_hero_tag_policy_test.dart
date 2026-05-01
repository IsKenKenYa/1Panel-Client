import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('desktop cached-module pages and FAB pages follow hero policy', () async {
    final desktopContentHost = await File(
      'lib/ui/desktop/common/widgets/desktop_content_host.dart',
    ).readAsString();

    expect(desktopContentHost.contains('HeroMode('), isTrue);

    final fabFiles = <String>[
      'lib/features/files/files_page/files_page_scaffold_part.dart',
      'lib/features/group/pages/group_center_page.dart',
      'lib/features/websites/pages/website_domain_management_page.dart',
      'lib/features/websites/pages/website_list_page_body.dart',
      'lib/features/websites/pages/website_ssl_center_page.dart',
      'lib/features/commands/pages/commands_page.dart',
      'lib/features/host_assets/pages/host_assets_page.dart',
      'lib/features/backups/pages/backup_accounts_page.dart',
      'lib/features/cronjobs/pages/cronjobs_page.dart',
      'lib/features/ssh/pages/ssh_certs_page.dart',
      'lib/features/settings/snapshot_page.dart',
      'lib/features/files/file_preview_page.dart',
      'lib/shared/widgets/log_viewer/log_theme_editor.dart',
      'lib/features/orchestration/orchestration_page.dart',
      'lib/features/containers/containers_page/containers_page_actions_part.dart',
    ];

    for (final path in fabFiles) {
      final source = await File(path).readAsString();
      expect(
        source.contains('heroTag:'),
        isTrue,
        reason: '$path should declare an explicit heroTag',
      );
    }
  });
}
