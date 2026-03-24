import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/create_directory_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/create_file_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/rename_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/move_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/copy_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/extract_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/compress_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/delete_confirm_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/batch_move_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/batch_copy_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/search_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/sort_options_dialog.dart';
import 'package:onepanel_client/features/files/models/models.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockFilesProvider extends FilesProvider {
  FilesData _mockData = const FilesData(
    currentPath: '/home',
    selectedFiles: {'/home/test.txt', '/home/test2.txt'},
  );

  @override
  FilesData get data => _mockData;

  void setMockData(FilesData data) {
    _mockData = data;
    notifyListeners();
  }

  @override
  Future<void> createDirectory(String name) async {}

  @override
  Future<void> createFile(String name, {String? content}) async {}

  @override
  Future<void> renameFile(String oldPath, String newName) async {}

  @override
  Future<void> moveFile(String sourcePath, String targetPath) async {}

  @override
  Future<void> copyFile(String sourcePath, String targetPath) async {}

  @override
  Future<void> extractFile(String path, String dst, String type,
      {String? secret}) async {}

  @override
  Future<void> compressFiles(
      List<String> files, String dst, String name, String type,
      {String? secret}) async {}

  @override
  Future<void> deleteSelected() async {}

  @override
  Future<void> moveSelected(String targetPath) async {}

  @override
  Future<void> copySelected(String targetPath) async {}

  @override
  void setSearchQuery(String? query) {
    _mockData = _mockData.copyWith(searchQuery: query);
    notifyListeners();
  }

  @override
  void setSorting(String? sortBy, String? sortOrder) {
    _mockData = _mockData.copyWith(sortBy: sortBy, sortOrder: sortOrder);
    notifyListeners();
  }

  @override
  Future<void> loadFiles({String? path}) async {}

  @override
  Future<void> refresh() async {}
}

void main() {
  group('Create Directory Dialog Tests', () {
    testWidgets('shows dialog with title', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: ChangeNotifierProvider<_MockFilesProvider>(
          create: (_) => _MockFilesProvider(),
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showCreateDirectoryDialog(
                    context, context.read<_MockFilesProvider>()),
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
        home: ChangeNotifierProvider<_MockFilesProvider>(
          create: (_) => _MockFilesProvider(),
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showCreateFileDialog(
                    context, context.read<_MockFilesProvider>()),
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
                _MockFilesProvider(),
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
              onPressed: () => showMoveDialog(
                context,
                _MockFilesProvider(),
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
              onPressed: () => showCopyDialog(
                context,
                _MockFilesProvider(),
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
                _MockFilesProvider(),
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
                _MockFilesProvider(),
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
                _MockFilesProvider(),
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
              onPressed: () => showBatchMoveDialog(
                context,
                _MockFilesProvider(),
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
              onPressed: () => showBatchCopyDialog(
                context,
                _MockFilesProvider(),
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

  group('Search Dialog Tests', () {
    testWidgets('shows dialog with search field', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: ChangeNotifierProvider<_MockFilesProvider>(
          create: (_) => _MockFilesProvider(),
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
        home: ChangeNotifierProvider<_MockFilesProvider>(
          create: (_) => _MockFilesProvider(),
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

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
