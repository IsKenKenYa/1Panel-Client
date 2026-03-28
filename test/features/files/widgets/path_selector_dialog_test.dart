import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/features/files/files_service.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/path_selector_dialog.dart';

class _FakeFilesService extends FilesService {
  _FakeFilesService(this._responses);

  final Map<String, List<FileInfo>> _responses;

  @override
  Future<List<FileInfo>> getFiles({
    required String path,
    String? search,
    int page = 1,
    int pageSize = 100,
    bool expand = true,
    String? sortBy,
    String? sortOrder,
    bool? showHidden,
  }) async {
    return _responses[path] ?? const <FileInfo>[];
  }
}

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => child,
        ),
      ),
    );
  }

  testWidgets('PathSelectorDialog shows current path and subfolders',
      (tester) async {
    final subfolders = [
      FileInfo(
        name: 'subfolder1',
        path: '/subfolder1',
        isDir: true,
        size: 0,
        modifiedAt: DateTime(2023, 1, 1),
        type: 'dir',
      ),
    ];
    final provider = FilesProvider(
      service: _FakeFilesService(<String, List<FileInfo>>{
        '/': subfolders,
      }),
    );

    await tester.pumpWidget(createTestWidget(Builder(
      builder: (context) {
        return TextButton(
          onPressed: () {
            showPathSelectorDialog(
              context,
              provider,
              '/',
              context.l10n,
            );
          },
          child: const Text('Open Dialog'),
        );
      },
    )));

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('subfolder1'), findsOneWidget);
    expect(find.text('/'), findsOneWidget);
  });

  testWidgets('PathSelectorDialog navigates to subfolder on tap',
      (tester) async {
    final rootFolders = [
      FileInfo(
        name: 'subfolder1',
        path: '/subfolder1',
        isDir: true,
        size: 0,
        modifiedAt: DateTime(2023, 1, 1),
        type: 'dir',
      ),
    ];
    final subFiles = <FileInfo>[];
    final provider = FilesProvider(
      service: _FakeFilesService(<String, List<FileInfo>>{
        '/': rootFolders,
        '/subfolder1': subFiles,
      }),
    );

    await tester.pumpWidget(createTestWidget(Builder(
      builder: (context) {
        return TextButton(
          onPressed: () {
            showPathSelectorDialog(
              context,
              provider,
              '/',
              AppLocalizations.of(context),
            );
          },
          child: const Text('Open Dialog'),
        );
      },
    )));

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('subfolder1'));
    await tester.pumpAndSettle();

    expect(find.text('/subfolder1'), findsOneWidget);
  });
}
