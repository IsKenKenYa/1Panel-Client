import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/widgets/file_list_item.dart';

void main() {
  group('FileListItem Widget Tests', () {
    late FileInfo testFile;
    late FileInfo testDir;

    setUp(() {
      testFile = FileInfo(
        name: 'test.txt',
        path: '/home/test.txt',
        type: 'file',
        size: 1024,
        isDir: false,
        modifiedAt: DateTime(2024, 1, 15, 10, 30),
      );
      testDir = FileInfo(
        name: 'documents',
        path: '/home/documents',
        type: 'dir',
        size: 0,
        isDir: true,
        modifiedAt: DateTime(2024, 1, 15, 10, 30),
      );
    });

    Widget createTestWidget(FileListItem item) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: ListView(
            children: [item],
          ),
        ),
      );
    }

    testWidgets('renders file name correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        FileListItem(file: testFile),
      ));

      expect(find.text('test.txt'), findsOneWidget);
    });

    testWidgets('renders directory name correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        FileListItem(file: testDir),
      ));

      expect(find.text('documents'), findsOneWidget);
    });

    testWidgets('shows folder icon for directories', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        FileListItem(file: testDir),
      ));

      final iconFinder = find.byIcon(Icons.folder_outlined);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('shows file icon for files', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        FileListItem(file: testFile),
      ));

      final iconFinder = find.byIcon(Icons.description_outlined);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('shows favorite icon when isFavorite is true', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        FileListItem(file: testFile, isFavorite: true),
      ));

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('does not show favorite icon when isFavorite is false', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        FileListItem(file: testFile, isFavorite: false),
      ));

      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('applies selection styling when isSelected is true', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        FileListItem(file: testFile, isSelected: true),
      ));

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, isNotNull);
    });

    testWidgets('triggers onTap callback when tapped', (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(createTestWidget(
        FileListItem(
          file: testFile,
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('triggers onLongPress callback when long pressed', (WidgetTester tester) async {
      var longPressed = false;
      await tester.pumpWidget(createTestWidget(
        FileListItem(
          file: testFile,
          onLongPress: () => longPressed = true,
        ),
      ));

      await tester.longPress(find.byType(ListTile));
      await tester.pump();

      expect(longPressed, isTrue);
    });

    testWidgets('shows popup menu with actions', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        FileListItem(file: testFile),
      ));

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('shows extract option for compressed files', (WidgetTester tester) async {
      final zipFile = FileInfo(
        name: 'archive.zip',
        path: '/home/archive.zip',
        type: 'file',
        size: 2048,
        isDir: false,
      );

      await tester.pumpWidget(createTestWidget(
        FileListItem(file: zipFile),
      ));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Extract'), findsWidgets);
    });
  });

  group('FileUtils Tests', () {
    test('getFileIcon returns correct icon for PDF files', () {
      expect(
        FileUtils.getFileIcon('document.pdf'),
        equals(Icons.picture_as_pdf_outlined),
      );
    });

    test('getFileIcon returns correct icon for image files', () {
      expect(
        FileUtils.getFileIcon('image.jpg'),
        equals(Icons.image_outlined),
      );
      expect(
        FileUtils.getFileIcon('image.png'),
        equals(Icons.image_outlined),
      );
      expect(
        FileUtils.getFileIcon('image.gif'),
        equals(Icons.image_outlined),
      );
      expect(
        FileUtils.getFileIcon('image.webp'),
        equals(Icons.image_outlined),
      );
    });

    test('getFileIcon returns correct icon for video files', () {
      expect(
        FileUtils.getFileIcon('video.mp4'),
        equals(Icons.video_file_outlined),
      );
      expect(
        FileUtils.getFileIcon('video.avi'),
        equals(Icons.video_file_outlined),
      );
      expect(
        FileUtils.getFileIcon('video.mkv'),
        equals(Icons.video_file_outlined),
      );
    });

    test('getFileIcon returns correct icon for audio files', () {
      expect(
        FileUtils.getFileIcon('audio.mp3'),
        equals(Icons.audio_file_outlined),
      );
      expect(
        FileUtils.getFileIcon('audio.wav'),
        equals(Icons.audio_file_outlined),
      );
      expect(
        FileUtils.getFileIcon('audio.flac'),
        equals(Icons.audio_file_outlined),
      );
    });

    test('getFileIcon returns correct icon for compressed files', () {
      expect(
        FileUtils.getFileIcon('archive.zip'),
        equals(Icons.folder_zip_outlined),
      );
      expect(
        FileUtils.getFileIcon('archive.tar'),
        equals(Icons.folder_zip_outlined),
      );
      expect(
        FileUtils.getFileIcon('archive.gz'),
        equals(Icons.folder_zip_outlined),
      );
      expect(
        FileUtils.getFileIcon('archive.7z'),
        equals(Icons.folder_zip_outlined),
      );
      expect(
        FileUtils.getFileIcon('archive.rar'),
        equals(Icons.folder_zip_outlined),
      );
    });

    test('getFileIcon returns correct icon for code files', () {
      expect(
        FileUtils.getFileIcon('main.dart'),
        equals(Icons.code_outlined),
      );
      expect(
        FileUtils.getFileIcon('app.js'),
        equals(Icons.code_outlined),
      );
      expect(
        FileUtils.getFileIcon('app.ts'),
        equals(Icons.code_outlined),
      );
      expect(
        FileUtils.getFileIcon('script.py'),
        equals(Icons.code_outlined),
      );
      expect(
        FileUtils.getFileIcon('Main.java'),
        equals(Icons.code_outlined),
      );
      expect(
        FileUtils.getFileIcon('app.swift'),
        equals(Icons.code_outlined),
      );
      expect(
        FileUtils.getFileIcon('app.kt'),
        equals(Icons.code_outlined),
      );
    });

    test('getFileIcon returns correct icon for data files', () {
      expect(
        FileUtils.getFileIcon('data.json'),
        equals(Icons.data_object_outlined),
      );
      expect(
        FileUtils.getFileIcon('config.yaml'),
        equals(Icons.data_object_outlined),
      );
      expect(
        FileUtils.getFileIcon('config.yml'),
        equals(Icons.data_object_outlined),
      );
      expect(
        FileUtils.getFileIcon('data.xml'),
        equals(Icons.data_object_outlined),
      );
    });

    test('getFileIcon returns correct icon for document files', () {
      expect(
        FileUtils.getFileIcon('readme.md'),
        equals(Icons.description_outlined),
      );
      expect(
        FileUtils.getFileIcon('notes.txt'),
        equals(Icons.description_outlined),
      );
    });

    test('getFileIcon returns default icon for unknown extensions', () {
      expect(
        FileUtils.getFileIcon('unknown.xyz'),
        equals(Icons.insert_drive_file_outlined),
      );
      expect(
        FileUtils.getFileIcon('noextension'),
        equals(Icons.insert_drive_file_outlined),
      );
    });

    test('formatFileSize formats bytes correctly', () {
      expect(FileUtils.formatFileSize(0), equals('0 B'));
      expect(FileUtils.formatFileSize(100), equals('100 B'));
      expect(FileUtils.formatFileSize(1023), equals('1023 B'));
    });

    test('formatFileSize formats kilobytes correctly', () {
      expect(FileUtils.formatFileSize(1024), equals('1.0 KB'));
      expect(FileUtils.formatFileSize(1536), equals('1.5 KB'));
      expect(FileUtils.formatFileSize(1024 * 1023), equals('1023.0 KB'));
    });

    test('formatFileSize formats megabytes correctly', () {
      expect(FileUtils.formatFileSize(1024 * 1024), equals('1.0 MB'));
      expect(FileUtils.formatFileSize(1024 * 1024 * 512), equals('512.0 MB'));
    });

    test('formatFileSize formats gigabytes correctly', () {
      expect(FileUtils.formatFileSize(1024 * 1024 * 1024), equals('1.0 GB'));
      expect(FileUtils.formatFileSize(1024 * 1024 * 1024 * 2), equals('2.0 GB'));
    });

    test('formatModifiedAt returns null for null input', () {
      expect(FileUtils.formatModifiedAt(null), isNull);
    });

    test('formatModifiedAt formats date correctly', () {
      final date = DateTime(2024, 1, 15, 10, 30);
      expect(FileUtils.formatModifiedAt(date), equals('2024-01-15 10:30'));
    });

    test('formatModifiedAt pads single digits correctly', () {
      final date = DateTime(2024, 2, 5, 8, 5);
      expect(FileUtils.formatModifiedAt(date), equals('2024-02-05 08:05'));
    });

    test('isCompressedFile identifies compressed files correctly', () {
      expect(FileUtils.isCompressedFile('archive.zip'), isTrue);
      expect(FileUtils.isCompressedFile('archive.tar'), isTrue);
      expect(FileUtils.isCompressedFile('archive.gz'), isTrue);
      expect(FileUtils.isCompressedFile('archive.bz2'), isTrue);
      expect(FileUtils.isCompressedFile('archive.xz'), isTrue);
      expect(FileUtils.isCompressedFile('archive.7z'), isTrue);
      expect(FileUtils.isCompressedFile('archive.rar'), isTrue);
    });

    test('isCompressedFile returns false for non-compressed files', () {
      expect(FileUtils.isCompressedFile('document.txt'), isFalse);
      expect(FileUtils.isCompressedFile('image.jpg'), isFalse);
      expect(FileUtils.isCompressedFile('video.mp4'), isFalse);
    });

    test('getFileIconColor returns correct color for PDF files', () {
      final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
      expect(
        FileUtils.getFileIconColor('document.pdf', colorScheme),
        equals(colorScheme.error),
      );
    });

    test('getFileIconColor returns correct color for image files', () {
      final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
      expect(
        FileUtils.getFileIconColor('image.jpg', colorScheme),
        equals(colorScheme.primary),
      );
    });

    test('getFileIconColor returns correct color for video files', () {
      final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
      expect(
        FileUtils.getFileIconColor('video.mp4', colorScheme),
        equals(colorScheme.tertiary),
      );
    });

    test('getFileIconColor returns correct color for audio files', () {
      final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
      expect(
        FileUtils.getFileIconColor('audio.mp3', colorScheme),
        equals(colorScheme.secondary),
      );
    });

    test('getFileIconColor returns correct color for compressed files', () {
      final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
      expect(
        FileUtils.getFileIconColor('archive.zip', colorScheme),
        equals(colorScheme.tertiaryContainer),
      );
    });

    test('getFileIconColor returns default color for unknown extensions', () {
      final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
      expect(
        FileUtils.getFileIconColor('unknown.xyz', colorScheme),
        equals(colorScheme.onSurfaceVariant),
      );
    });
  });
}
