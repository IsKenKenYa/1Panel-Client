import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/wget_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/upload_dialog.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/path_selector_dialog.dart';
import 'package:onepanel_client/features/files/models/models.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

class _MockFilesProvider extends FilesProvider {
  FilesData _mockData = const FilesData(
    currentPath: '/home',
    selectedFiles: {'/home/test.txt'},
  );

  @override
  FilesData get data => _mockData;

  void setMockData(FilesData data) {
    _mockData = data;
    notifyListeners();
  }

  @override
  Future<void> loadFiles({String? path}) async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> wgetDownload({required String url, required String name, bool? ignoreCertificate}) async {}

  @override
  Future<void> uploadFiles(List<String> filePaths) async {}

  @override
  Future<List<FileInfo>> fetchFiles(String path) async {
    return [
      FileInfo(
        name: 'test_folder',
        path: '$path/test_folder',
        isDir: true,
        size: 0,
        modifiedAt: DateTime.now(),
        mode: '0755',
        type: 'dir',
      ),
    ];
  }
}

void main() {
  group('Wget Dialog Tests', () {
    testWidgets('shows wget dialog with URL field', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showWgetDialog(context, _MockFilesProvider()),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });
  });

  group('Upload Dialog Tests', () {
    testWidgets('shows upload dialog', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showUploadDialog(context, _MockFilesProvider()),
              child: const Text('Show Upload'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Upload'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('Path Selector Dialog Tests', () {
    testWidgets('shows path selector dialog', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final l10n = AppLocalizations.of(context);
                await showPathSelectorDialog(
                  context,
                  _MockFilesProvider(),
                  '/home',
                  l10n,
                );
              },
              child: const Text('Show Path Selector'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Path Selector'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
