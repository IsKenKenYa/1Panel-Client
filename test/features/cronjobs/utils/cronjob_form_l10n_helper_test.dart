import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/cronjobs/utils/cronjob_form_l10n_helper.dart';
import 'package:onepanel_client/l10n/generated/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('unknown backup type is localized', () {
    expect(
      cronjobBackupTypeLabel(l10n, 'custom-backup'),
      'Unknown backup type: custom-backup',
    );
  });

  test('unknown database type is localized', () {
    expect(
      cronjobDatabaseTypeLabel(l10n, 'custom-db'),
      'Unknown database type: custom-db',
    );
  });

  test('unknown alert method is localized', () {
    expect(
      cronjobAlertMethodLabel(l10n, 'pagerduty'),
      'Unknown alert method: pagerduty',
    );
  });

  test('unknown provider error is localized', () {
    expect(
      localizeCronjobFormError(l10n, 'cronjob.unexpectedFailure'),
      'Unexpected cronjob form error: cronjob.unexpectedFailure',
    );
  });
}
