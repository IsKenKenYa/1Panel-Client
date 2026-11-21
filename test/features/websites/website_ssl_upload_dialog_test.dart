import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/ssl_models.dart';
import 'package:onepanel_client/features/websites/widgets/website_ssl_upload_dialog.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

void main() {
  for (final usePath in [true, false]) {
    testWidgets('submit certificate from ${usePath ? 'files' : 'text'}', (tester) async {
      WebsiteSSLUpload? submitted;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => WebsiteSslUploadDialog(
                  includeDescription: !usePath,
                  onUpload: (request) async {
                    submitted = request;
                  },
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final dialog = find.byType(WebsiteSslUploadDialog);
      final l10n = AppLocalizations.of(tester.element(dialog));
      final fields = find.descendant(of: dialog, matching: find.byType(TextField));
      await tester.enterText(fields.at(0), 'certificate text');
      await tester.enterText(fields.at(1), 'private key text');
      if (usePath) {
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.websitesSslUploadTypeLocal).last);
        await tester.pumpAndSettle();
        await tester.enterText(fields.at(0), '/cert.pem');
        await tester.enterText(fields.at(1), '/key.pem');
      } else {
        await tester.enterText(fields.at(2), 'site certificate');
      }

      await tester.tap(find.text(l10n.commonUpload));
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
      expect(submitted?.type, usePath ? 'local' : 'paste');
      expect(submitted?.certificate, usePath ? null : 'certificate text');
      expect(submitted?.privateKey, usePath ? null : 'private key text');
      expect(submitted?.certificatePath, usePath ? '/cert.pem' : null);
      expect(submitted?.privateKeyPath, usePath ? '/key.pem' : null);
      expect(submitted?.description, usePath ? null : 'site certificate');
    });
  }
}
