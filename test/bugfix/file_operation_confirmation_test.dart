import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/file_editor_page.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/delete_confirm_dialog.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('leaving the editor keeps changes until saving completes',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (context) => const FileEditorPage(
                    filePath: '/notes.txt',
                    fileName: 'notes.txt',
                    initialContent: 'Original notes',
                  ),
                ),
              ),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Updated notes');
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Discard Changes'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Updated notes'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(FileEditorPage), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Updated notes'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('single-file confirmation identifies only the requested path',
      (tester) async {
    const target = FileInfo(
      name: 'target.txt',
      path: '/target.txt',
      type: 'file',
      size: 0,
    );
    final provider = FilesProvider()..toggleSelection('/other.txt');
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDeleteConfirmDialog(
                context,
                provider,
                AppLocalizations.of(context),
                file: target,
              ),
              child: const Text('Show confirmation'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show confirmation'));
    await tester.pumpAndSettle();
    expect(find.text(target.path), findsOneWidget);
    expect(find.text('/other.txt'), findsNothing);
    expect(find.text('Delete 1 selected items?'), findsNothing);
    expect(provider.data.selectedFiles, {'/other.txt'});

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text(target.path), findsNothing);
    expect(provider.data.selectedFiles, {'/other.txt'});
  });
}
