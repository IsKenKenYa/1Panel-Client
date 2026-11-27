import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/file_operation_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/rename_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/extract_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/compress_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/delete_confirm_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/search_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/sort_options_dialog.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:provider/provider.dart';

void main() {
  late FilesProvider provider;
  setUp(() {
    provider = FilesProvider()
      ..toggleSelection('/home/test.txt')
      ..toggleSelection('/home/test2.txt');
  });
  tearDown(() => provider.dispose());

  void expectDestinationField(WidgetTester tester, {FileInfo? file}) {
    final l10n = tester.element(find.byType(AlertDialog)).l10n;
    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.controller!.text, provider.data.currentPath);
    if (file == null) {
      expect(find.text('${l10n.filesSelected}: 2'), findsOneWidget);
      expect(find.byTooltip(l10n.filesSelectPath), findsNothing);
    } else {
      expect(find.text('${l10n.filesNameLabel}: ${file.name}'), findsOneWidget);
      expect(find.byTooltip(l10n.filesSelectPath), findsOneWidget);
    }
  }

  group('Create Directory Dialog Tests', () {
    testWidgets('shows dialog with title', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: ChangeNotifierProvider.value(
          value: provider,
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showFileOperationDialog(
                    context, provider, FileOperation.createDirectory),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      final l10n = tester.element(find.byType(AlertDialog)).l10n;
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text(l10n.commonCreate).last);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('Create File Dialog Tests', () {
    testWidgets('shows dialog with title', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: ChangeNotifierProvider.value(
          value: provider,
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showFileOperationDialog(
                    context, provider, FileOperation.createFile),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('Rename Dialog Tests', () {
    testWidgets('shows dialog with file name', (WidgetTester tester) async {
      final file = FileInfo(
        name: 'test.txt',
        path: '/home/test.txt',
        type: 'file',
        size: 100,
      );

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showRenameDialog(
                context,
                provider,
                file,
                AppLocalizations.of(context),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('Move Dialog Tests', () {
    testWidgets('shows dialog with file name', (WidgetTester tester) async {
      final file = FileInfo(
        name: 'test.txt',
        path: '/home/test.txt',
        type: 'file',
        size: 100,
      );

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showFileOperationDialog(
                context,
                provider,
                FileOperation.move,
                file: file,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expectDestinationField(tester, file: file);
    });
  });

  group('Copy Dialog Tests', () {
    testWidgets('shows dialog with file name', (WidgetTester tester) async {
      final file = FileInfo(
        name: 'test.txt',
        path: '/home/test.txt',
        type: 'file',
        size: 100,
      );

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showFileOperationDialog(
                context,
                provider,
                FileOperation.copy,
                file: file,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expectDestinationField(tester, file: file);
    });
  });

  group('Extract Dialog Tests', () {
    testWidgets('shows dialog for zip file', (WidgetTester tester) async {
      final file = FileInfo(
        name: 'test.zip',
        path: '/home/test.zip',
        type: 'file',
        size: 1000,
      );

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showExtractDialog(
                context,
                provider,
                file,
                AppLocalizations.of(context),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('Compress Dialog Tests', () {
    testWidgets('shows dialog with name and type fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showCompressDialog(
                context,
                provider,
                ['/home/test.txt'],
                AppLocalizations.of(context),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('Delete Confirm Dialog Tests', () {
    testWidgets('shows dialog with selection count',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDeleteConfirmDialog(
                context,
                provider,
                AppLocalizations.of(context),
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('Batch Move Dialog Tests', () {
    testWidgets('shows dialog with selection count',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showFileOperationDialog(
                context,
                provider,
                FileOperation.move,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expectDestinationField(tester);
    });
  });

  group('Batch Copy Dialog Tests', () {
    testWidgets('shows dialog with selection count',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showFileOperationDialog(
                context,
                provider,
                FileOperation.copy,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expectDestinationField(tester);
    });
  });

  group('Search Dialog Tests', () {
    testWidgets('shows dialog with search field', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: ChangeNotifierProvider.value(
          value: provider,
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSearchDialog(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('Sort Options Dialog Tests', () {
    testWidgets('shows dialog with sort options', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: ChangeNotifierProvider.value(
          value: provider,
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSortOptionsDialog(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });
}
