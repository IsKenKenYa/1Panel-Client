import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/files_service.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/server_directory_picker_dialog.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

import '../../files/files_provider_test.mocks.dart';

void main() {
  FileInfo directory(String name, String path) => FileInfo(
        name: name,
        path: path,
        type: 'dir',
        isDir: true,
        size: 0,
        modifiedAt: DateTime(2026, 1, 1),
      );

  FileInfo file(String name, String path) => FileInfo(
        name: name,
        path: path,
        type: 'file',
        isDir: false,
        size: 10,
        modifiedAt: DateTime(2026, 1, 1),
      );

  testWidgets('只列出目录，文件不出现', (tester) async {
    final service = MockFilesService();
    when(service.getFiles(path: '/', search: null, page: 1, pageSize: 100, expand: true))
        .thenAnswer((_) async => [directory('etc', '/etc'), file('a.txt', '/a.txt')]);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: ServerDirectoryPickerDialog(
          filesService: service,
          initialPath: '/',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('etc'), findsOneWidget);
    expect(find.text('a.txt'), findsNothing);
  });

  testWidgets('点目录进入子目录，确认后返回该路径', (tester) async {
    final service = MockFilesService();
    when(service.getFiles(path: '/', search: null, page: 1, pageSize: 100, expand: true))
        .thenAnswer((_) async => [directory('opt', '/opt')]);
    when(service.getFiles(path: '/opt', search: null, page: 1, pageSize: 100, expand: true))
        .thenAnswer((_) async => [directory('apps', '/opt/apps')]);

    String? selected;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: Builder(builder: (context) {
          return TextButton(
            onPressed: () async {
              selected = await ServerDirectoryPickerDialog.show(
                context,
                filesService: service,
                initialPath: '/',
              );
            },
            child: const Text('open'),
          );
        }),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('opt'));
    await tester.pumpAndSettle();

    expect(find.text('/opt'), findsOneWidget);
    expect(find.text('apps'), findsOneWidget);

    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();

    expect(selected, '/opt');
  });

  testWidgets('根目录不显示上一级入口', (tester) async {
    final service = MockFilesService();
    when(service.getFiles(path: '/', search: null, page: 1, pageSize: 100, expand: true))
        .thenAnswer((_) async => [directory('etc', '/etc')]);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: ServerDirectoryPickerDialog(
          filesService: service,
          initialPath: '/',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('上一级目录'), findsNothing);
  });

  testWidgets('加载失败时展示错误与重试', (tester) async {
    final service = MockFilesService();
    when(service.getFiles(path: '/', search: null, page: 1, pageSize: 100, expand: true))
        .thenThrow(Exception('network down'));

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: ServerDirectoryPickerDialog(
          filesService: service,
          initialPath: '/',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('network down'), findsOneWidget);
  });
}
