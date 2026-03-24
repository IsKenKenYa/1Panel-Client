import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/files_provider.dart';
import 'package:onepanel_client/features/files/widgets/dialogs/path_selector_dialog.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Removed

@GenerateMocks([FilesProvider])
import 'path_selector_dialog_test.mocks.dart';

void main() {
  late MockFilesProvider mockProvider;

  setUp(() {
    mockProvider = MockFilesProvider();
  });

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

  testWidgets('PathSelectorDialog shows current path and subfolders', (tester) async {
    // Arrange
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
    
    when(mockProvider.fetchFiles(any)).thenAnswer((_) async => subfolders);

    // Act
    await tester.pumpWidget(createTestWidget(Builder(
      builder: (context) {
        return TextButton(
          onPressed: () {
            showPathSelectorDialog(
               context,
               mockProvider,
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

    // Assert
    expect(find.text('subfolder1'), findsOneWidget);
    expect(find.text('/'), findsOneWidget);
  });

  testWidgets('PathSelectorDialog navigates to subfolder on tap', (tester) async {
    // Arrange
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
    final subFiles = <FileInfo>[]; // Empty subfolder

    when(mockProvider.fetchFiles('/')).thenAnswer((_) async => rootFolders);
    when(mockProvider.fetchFiles('/subfolder1')).thenAnswer((_) async => subFiles);

    // Act
    await tester.pumpWidget(createTestWidget(Builder(
      builder: (context) {
        return TextButton(
          onPressed: () {
            showPathSelectorDialog(
              context,
              mockProvider,
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

    // Assert
    // Verify that the title updated to /subfolder1
    expect(find.text('/subfolder1'), findsOneWidget);
    verify(mockProvider.fetchFiles('/subfolder1')).called(1);
  });
}
