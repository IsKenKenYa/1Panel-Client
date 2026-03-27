import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/files/providers/transfer_manager_provider.dart';

void main() {
  test('TransferManagerProvider loads tasks and filters active/completed',
      () async {
    final tasks = <DownloadTask>[
      DownloadTask(
        taskId: '1',
        status: DownloadTaskStatus.running,
        progress: 30,
        url: 'https://example.com/a',
        filename: 'a.txt',
        savedDir: '/tmp',
        timeCreated: 1,
        allowCellular: true,
      ),
      DownloadTask(
        taskId: '2',
        status: DownloadTaskStatus.complete,
        progress: 100,
        url: 'https://example.com/b',
        filename: 'b.txt',
        savedDir: '/tmp',
        timeCreated: 2,
        allowCellular: true,
      ),
    ];

    final provider = TransferManagerProvider(
      loadTasksOverride: () async => tasks,
    );

    await provider.initialize();

    expect(provider.isLoading, isFalse);
    expect(provider.getActiveDownloads(), hasLength(1));
    expect(provider.getCompletedDownloads(), hasLength(1));

    provider.setChannel(TransferChannel.uploads);
    expect(provider.channel, TransferChannel.uploads);
  });

  test('TransferManagerProvider clears completed downloads', () async {
    var clearCompletedCalls = 0;
    final provider = TransferManagerProvider(
      loadTasksOverride: () async => const <DownloadTask>[],
      clearCompletedOverride: () async {
        clearCompletedCalls += 1;
      },
    );

    await provider.clearCompletedDownloads();

    expect(clearCompletedCalls, 1);
  });
}
