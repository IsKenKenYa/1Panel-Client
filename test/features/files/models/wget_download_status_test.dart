import 'package:flutter_test/flutter_test.dart';
import 'package:onepanelapp_app/features/files/models/wget_download_status.dart';

void main() {
  group('WgetDownloadStatus Model Tests', () {
    group('Constructor Tests', () {
      test('creates instance with all default values', () {
        const status = WgetDownloadStatus();

        expect(status.state, equals(WgetDownloadState.idle));
        expect(status.message, isNull);
        expect(status.filePath, isNull);
        expect(status.downloadedSize, isNull);
      });

      test('creates instance with all custom values', () {
        const status = WgetDownloadStatus(
          state: WgetDownloadState.success,
          message: 'Download completed successfully',
          filePath: '/home/user/downloads/file.zip',
          downloadedSize: 1048576,
        );

        expect(status.state, equals(WgetDownloadState.success));
        expect(status.message, equals('Download completed successfully'));
        expect(status.filePath, equals('/home/user/downloads/file.zip'));
        expect(status.downloadedSize, equals(1048576));
      });

      test('creates instance with partial values', () {
        const status = WgetDownloadStatus(
          state: WgetDownloadState.downloading,
          message: 'In progress',
        );

        expect(status.state, equals(WgetDownloadState.downloading));
        expect(status.message, equals('In progress'));
        expect(status.filePath, isNull);
        expect(status.downloadedSize, isNull);
      });
    });

    group('copyWith Tests', () {
      test('copyWith updates state only', () {
        const original = WgetDownloadStatus(
          state: WgetDownloadState.idle,
          message: 'Ready',
        );

        final updated = original.copyWith(state: WgetDownloadState.downloading);

        expect(updated.state, equals(WgetDownloadState.downloading));
        expect(updated.message, equals('Ready'));
        expect(original.state, equals(WgetDownloadState.idle));
      });

      test('copyWith updates message only', () {
        const original = WgetDownloadStatus(
          state: WgetDownloadState.downloading,
          message: 'Starting...',
        );

        final updated = original.copyWith(message: 'Downloading...');

        expect(updated.state, equals(WgetDownloadState.downloading));
        expect(updated.message, equals('Downloading...'));
        expect(original.message, equals('Starting...'));
      });

      test('copyWith updates filePath only', () {
        const original = WgetDownloadStatus();

        final updated = original.copyWith(filePath: '/downloads/file.zip');

        expect(updated.filePath, equals('/downloads/file.zip'));
        expect(updated.state, equals(WgetDownloadState.idle));
      });

      test('copyWith updates downloadedSize only', () {
        const original = WgetDownloadStatus();

        final updated = original.copyWith(downloadedSize: 2048);

        expect(updated.downloadedSize, equals(2048));
        expect(updated.state, equals(WgetDownloadState.idle));
      });

      test('copyWith updates multiple fields', () {
        const original = WgetDownloadStatus(
          state: WgetDownloadState.downloading,
          message: 'Starting',
          downloadedSize: 0,
        );

        final updated = original.copyWith(
          state: WgetDownloadState.success,
          message: 'Complete',
          filePath: '/file.zip',
          downloadedSize: 1024,
        );

        expect(updated.state, equals(WgetDownloadState.success));
        expect(updated.message, equals('Complete'));
        expect(updated.filePath, equals('/file.zip'));
        expect(updated.downloadedSize, equals(1024));
      });

      test('copyWith preserves unspecified fields', () {
        const original = WgetDownloadStatus(
          state: WgetDownloadState.downloading,
          message: 'In progress',
          filePath: '/downloads/file.zip',
          downloadedSize: 512,
        );

        final updated = original.copyWith(downloadedSize: 1024);

        expect(updated.state, equals(WgetDownloadState.downloading));
        expect(updated.message, equals('In progress'));
        expect(updated.filePath, equals('/downloads/file.zip'));
        expect(updated.downloadedSize, equals(1024));
      });
    });

    group('WgetDownloadState Enum Tests', () {
      test('has all expected states', () {
        expect(WgetDownloadState.values.length, equals(4));
      });

      test('idle state exists', () {
        expect(
          WgetDownloadState.values.contains(WgetDownloadState.idle),
          isTrue,
        );
      });

      test('downloading state exists', () {
        expect(
          WgetDownloadState.values.contains(WgetDownloadState.downloading),
          isTrue,
        );
      });

      test('success state exists', () {
        expect(
          WgetDownloadState.values.contains(WgetDownloadState.success),
          isTrue,
        );
      });

      test('error state exists', () {
        expect(
          WgetDownloadState.values.contains(WgetDownloadState.error),
          isTrue,
        );
      });

      test('states are in correct order', () {
        expect(WgetDownloadState.values[0], equals(WgetDownloadState.idle));
        expect(WgetDownloadState.values[1], equals(WgetDownloadState.downloading));
        expect(WgetDownloadState.values[2], equals(WgetDownloadState.success));
        expect(WgetDownloadState.values[3], equals(WgetDownloadState.error));
      });
    });

    group('State Transition Tests', () {
      test('typical download flow: idle -> downloading -> success', () {
        var status = const WgetDownloadStatus();
        expect(status.state, equals(WgetDownloadState.idle));

        status = status.copyWith(
          state: WgetDownloadState.downloading,
          message: 'Starting download...',
        );
        expect(status.state, equals(WgetDownloadState.downloading));

        status = status.copyWith(
          state: WgetDownloadState.success,
          message: 'Download complete',
          filePath: '/downloads/file.zip',
        );
        expect(status.state, equals(WgetDownloadState.success));
      });

      test('error flow: idle -> downloading -> error', () {
        var status = const WgetDownloadStatus();
        
        status = status.copyWith(
          state: WgetDownloadState.downloading,
          message: 'Downloading...',
        );
        expect(status.state, equals(WgetDownloadState.downloading));

        status = status.copyWith(
          state: WgetDownloadState.error,
          message: 'Connection timeout',
        );
        expect(status.state, equals(WgetDownloadState.error));
        expect(status.message, equals('Connection timeout'));
      });

      test('can reset to idle state', () {
        const reset = WgetDownloadStatus(
          state: WgetDownloadState.idle,
        );

        expect(reset.state, equals(WgetDownloadState.idle));
        expect(reset.message, isNull);
        expect(reset.filePath, isNull);
        expect(reset.downloadedSize, isNull);
      });
    });

    group('Edge Case Tests', () {
      test('handles large downloadedSize values', () {
        const status = WgetDownloadStatus(
          downloadedSize: 9223372036854775807, // Max int64
        );

        expect(status.downloadedSize, equals(9223372036854775807));
      });

      test('handles zero downloadedSize', () {
        const status = WgetDownloadStatus(downloadedSize: 0);

        expect(status.downloadedSize, equals(0));
      });

      test('handles empty message string', () {
        const status = WgetDownloadStatus(message: '');

        expect(status.message, equals(''));
      });

      test('handles long message string', () {
        final longMessage = 'A' * 10000;
        final status = WgetDownloadStatus(message: longMessage);

        expect(status.message, equals(longMessage));
      });

      test('handles special characters in filePath', () {
        const status = WgetDownloadStatus(
          filePath: '/path/with spaces/and-special_chars/file.zip',
        );

        expect(status.filePath, equals('/path/with spaces/and-special_chars/file.zip'));
      });

      test('handles unicode in message', () {
        const status = WgetDownloadStatus(
          message: '下载完成 🎉',
        );

        expect(status.message, equals('下载完成 🎉'));
      });
    });
  });
}
