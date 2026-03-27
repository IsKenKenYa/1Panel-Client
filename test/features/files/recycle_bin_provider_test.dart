import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/providers/recycle_bin_provider.dart';
import 'package:onepanel_client/features/files/services/file_recycle_service.dart';

class _FakeFileRecycleService extends FileRecycleService {
  List<FileInfo> recycleFiles;
  int restoreCalls = 0;
  int deleteCalls = 0;
  int clearCalls = 0;

  _FakeFileRecycleService({
    required this.recycleFiles,
  });

  @override
  Future<void> ensureServer() async {}

  @override
  Future<List<FileInfo>> searchRecycleBin({
    required String path,
    int page = 1,
    int pageSize = 100,
  }) async {
    return recycleFiles;
  }

  @override
  Future<void> restoreFiles(List<RecycleBinReduceRequest> requests) async {
    restoreCalls += requests.length;
  }

  @override
  Future<void> deleteRecycleBinFiles(List<RecycleBinItem> files) async {
    deleteCalls += files.length;
  }

  @override
  Future<void> clearRecycleBin() async {
    clearCalls += 1;
    recycleFiles = <FileInfo>[];
  }
}

void main() {
  test('RecycleBinProvider loads, filters and selects items', () async {
    final provider = RecycleBinProvider(
      service: _FakeFileRecycleService(
        recycleFiles: <FileInfo>[
          FileInfo(name: 'a.txt', path: '/a.txt', size: 10, type: 'file'),
          FileInfo(
            name: 'folder',
            path: '/folder',
            isDir: true,
            size: 0,
            type: 'dir',
          ),
        ],
      ),
    );

    await provider.initialize();

    expect(provider.files, hasLength(2));

    provider.filterFiles('a.');
    expect(provider.filteredFiles, hasLength(1));

    provider.toggleSelection(provider.filteredFiles.first.rName);
    expect(provider.selectedIds, hasLength(1));
  });

  test('RecycleBinProvider delegates restore/delete/clear', () async {
    final service = _FakeFileRecycleService(
      recycleFiles: <FileInfo>[
        FileInfo(name: 'a.txt', path: '/a.txt', size: 10, type: 'file'),
      ],
    );
    final provider = RecycleBinProvider(service: service);

    await provider.initialize();
    provider.selectAll();
    await provider.restoreSelected();
    provider.selectAll();
    await provider.deletePermanentlySelected();
    await provider.clearRecycleBin();

    expect(service.restoreCalls, 1);
    expect(service.deleteCalls, 1);
    expect(service.clearCalls, 1);
  });
}
