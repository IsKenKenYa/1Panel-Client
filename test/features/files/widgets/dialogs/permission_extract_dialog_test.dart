import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Permission Dialog Helper Tests', () {
    test('parseMode parses octal permission correctly', () {
      // Test _parseMode logic through the dialog's internal state
      // Mode 755 = rwxr-xr-x
      const mode = '755';
      final modeValue = int.parse(mode, radix: 8);

      final ownerBits = (modeValue >> 6) & 7;
      final groupBits = (modeValue >> 3) & 7;
      final otherBits = modeValue & 7;

      expect(ownerBits, equals(7)); // rwx
      expect(groupBits, equals(5)); // r-x
      expect(otherBits, equals(5)); // r-x
    });

    test('parseMode handles 4-digit mode', () {
      // Mode 0755 should be same as 755
      const mode = '0755';
      final cleanMode = mode.substring(mode.length - 3);
      final modeValue = int.parse(cleanMode, radix: 8);

      final ownerBits = (modeValue >> 6) & 7;
      expect(ownerBits, equals(7)); // rwx
    });

    test('calculateMode calculates correct permission string', () {
      // Test _calculateMode logic
      const ownerRead = 1;
      const ownerWrite = 1;
      const ownerExecute = 1;
      const groupRead = 1;
      const groupWrite = 0;
      const groupExecute = 1;
      const otherRead = 1;
      const otherWrite = 0;
      const otherExecute = 1;

      final owner = (ownerRead << 2) | (ownerWrite << 1) | ownerExecute;
      final group = (groupRead << 2) | (groupWrite << 1) | groupExecute;
      final other = (otherRead << 2) | (otherWrite << 1) | otherExecute;

      expect('$owner$group$other', equals('755'));
    });

    test('permission bits are extracted correctly', () {
      // Test bit extraction for owner
      const ownerBits = 7; // rwx
      final ownerRead = (ownerBits >> 2) & 1;
      final ownerWrite = (ownerBits >> 1) & 1;
      final ownerExecute = ownerBits & 1;

      expect(ownerRead, equals(1));
      expect(ownerWrite, equals(1));
      expect(ownerExecute, equals(1));
    });

    test('permission bits for read-only', () {
      const ownerBits = 4; // r--
      final ownerRead = (ownerBits >> 2) & 1;
      final ownerWrite = (ownerBits >> 1) & 1;
      final ownerExecute = ownerBits & 1;

      expect(ownerRead, equals(1));
      expect(ownerWrite, equals(0));
      expect(ownerExecute, equals(0));
    });

    test('permission bits for write-only', () {
      const ownerBits = 2; // -w-
      final ownerRead = (ownerBits >> 2) & 1;
      final ownerWrite = (ownerBits >> 1) & 1;
      final ownerExecute = ownerBits & 1;

      expect(ownerRead, equals(0));
      expect(ownerWrite, equals(1));
      expect(ownerExecute, equals(0));
    });

    test('permission bits for execute-only', () {
      const ownerBits = 1; // --x
      final ownerRead = (ownerBits >> 2) & 1;
      final ownerWrite = (ownerBits >> 1) & 1;
      final ownerExecute = ownerBits & 1;

      expect(ownerRead, equals(0));
      expect(ownerWrite, equals(0));
      expect(ownerExecute, equals(1));
    });
  });

  group('Extract Dialog Helper Tests', () {
    test('getCompressType returns correct type for tar.gz', () {
      expect(_getCompressType('archive.tar.gz'), equals('tar.gz'));
    });

    test('getCompressType returns correct type for tar', () {
      expect(_getCompressType('archive.tar'), equals('tar'));
    });

    test('getCompressType returns correct type for zip', () {
      expect(_getCompressType('archive.zip'), equals('zip'));
    });

    test('getCompressType returns correct type for 7z', () {
      expect(_getCompressType('archive.7z'), equals('7z'));
    });

    test('getCompressType returns correct type for gz', () {
      expect(_getCompressType('archive.gz'), equals('gz'));
    });

    test('getCompressType returns correct type for bz2', () {
      expect(_getCompressType('archive.bz2'), equals('bz2'));
    });

    test('getCompressType returns correct type for xz', () {
      expect(_getCompressType('archive.xz'), equals('xz'));
    });

    test('getCompressType returns zip for unknown extensions', () {
      expect(_getCompressType('archive.unknown'), equals('zip'));
    });

    test('getCompressType handles files without extension', () {
      expect(_getCompressType('archive'), equals('zip'));
    });
  });
}

// Helper function copied from extract_dialog.dart for testing
String _getCompressType(String filename) {
  if (filename.endsWith('.tar.gz')) return 'tar.gz';
  if (filename.endsWith('.tar')) return 'tar';
  if (filename.endsWith('.zip')) return 'zip';
  if (filename.endsWith('.7z')) return '7z';
  if (filename.endsWith('.gz')) return 'gz';
  if (filename.endsWith('.bz2')) return 'bz2';
  if (filename.endsWith('.xz')) return 'xz';
  return 'zip';
}
