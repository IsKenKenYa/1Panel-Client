// 文件模块端到端夹具集成测试（真服务器联调）。
//
// 用途：在真实 1Panel 服务器上对 /tmp 下的自建夹具执行完整文件 CRUD 流程：
// 建目录 → 搜索确认 → 建文件 → 读内容 → 写内容 → 再读断言 → 改名 → 删除。
//
// 危险面边界：本文件只在 /tmp 下创建、修改、重命名、删除
// `onepanel-e2e-files-<6位随机>` 前缀的自有夹具，删除操作仅针对夹具路径，
// 不触碰面板/系统其他文件，不调用任何面板基础配置修改接口。
import 'package:flutter_test/flutter_test.dart';
import '../test_helper.dart';
import 'package:onepanel_client/api/v2/file_v2.dart';
import 'package:onepanel_client/data/models/file_models.dart';

Future<void> main() async {
  // 注意：真服务器集成测试禁止使用 TestWidgetsFlutterBinding（会劫持 HttpClient，
  // 所有请求返回假 400）。TestConfig.initialize() 仅读取 .env，无需绑定层。
  await TestConfig.initialize();

  late final TestApiClient apiClient;
  late final FileV2Api fileApi;

  final hasApiKey = SkipConditions.skipNoApiKey() == null;
  if (hasApiKey) {
    apiClient = TestApiClient(
      baseUrl: TestConfig.baseUrl,
      apiKey: TestConfig.apiKey,
    );
    fileApi = FileV2Api(apiClient.client);
  }

  tearDownAll(() async {
    if (hasApiKey) apiClient.dispose();
    await teardownTestEnvironment();
  });

  group('文件模块 E2E 夹具测试', () {
    test(
      '应该能够在/tmp下完成目录与文件的创建-读写-改名-删除全流程',
      skip: SkipConditions.skipIntegration() ?? SkipConditions.skipNoApiKey(),
      () async {
        final suffix = TestDataGenerator.randomString(6);
        final dirPath = '/tmp/onepanel-e2e-files-$suffix';
        final fileName = 'note.txt';
        final filePath = '$dirPath/$fileName';
        final renamedName = 'note-renamed-$suffix.txt';
        final renamedPath = '$dirPath/$renamedName';

        // 幂等清理：无论测试走到哪一步失败，都尝试删除改名前后文件与目录。
        Future<void> cleanup() async {
          for (final delete in <FileDelete>[
            FileDelete(path: renamedPath, isDir: false, forceDelete: true),
            FileDelete(path: filePath, isDir: false, forceDelete: true),
            FileDelete(path: dirPath, isDir: true, forceDelete: true),
          ]) {
            try {
              await fileApi.deleteFile(delete);
            } catch (e) {
              // ignore: avoid_print
              print('清理失败（忽略）: ${delete.path} -> $e');
            }
          }
        }

        try {
          // 1. 创建目录
          final createDirResponse =
              await fileApi.createFile(FileCreate(path: dirPath, isDir: true));
          expect(createDirResponse.statusCode, 200);

          // 2. searchFiles 确认目录存在
          // 服务端仅在 expand=true 时填充 items（listChildren 分支）。
          final searchDirResponse = await fileApi.searchFiles(
            FileSearch(
              path: '/tmp',
              search: 'onepanel-e2e-files-$suffix',
              expand: true,
            ),
          );
          expect(searchDirResponse.statusCode, 200);
          expect(searchDirResponse.data, isA<FileSearchResponse>());
          expect(
            searchDirResponse.data!.items.any(
              (item) => item.path == dirPath && item.isDir,
            ),
            isTrue,
            reason: '目录 $dirPath 应在 /tmp 搜索结果中',
          );

          // 3. 在目录下创建文件
          final createFileResponse = await fileApi
              .createFile(FileCreate(path: filePath, isDir: false));
          expect(createFileResponse.statusCode, 200);

          // 4. 读取文件内容（空文件）
          final firstRead = await fileApi.getFileContent(filePath);
          expect(firstRead.statusCode, 200);
          expect(firstRead.data, isA<String>());

          // 5. 写入内容
          final content = 'onepanel-e2e content';
          final saveResponse = await fileApi
              .updateFileContent(FileContent(path: filePath, content: content));
          expect(saveResponse.statusCode, 200);

          // 6. 再读断言内容
          final secondRead = await fileApi.getFileContent(filePath);
          expect(secondRead.statusCode, 200);
          expect(secondRead.data, equals(content));
          final editor = await fileApi.readFile(FileRead(path: filePath));
          expect(editor.data, content);
          final preview = await fileApi.previewFile(
            FilePreviewRequest(path: filePath),
          );
          expect(preview.data, content);

          // 7. 重命名文件
          final renameResponse = await fileApi.renameFile(
            FileRename(oldPath: filePath, newPath: renamedPath),
          );
          expect(renameResponse.statusCode, 200);

          // 8. 搜索确认改名后的文件存在、旧名不存在
          final searchFileResponse = await fileApi.searchFiles(
            FileSearch(path: dirPath, expand: true),
          );
          expect(searchFileResponse.statusCode, 200);
          final names =
              searchFileResponse.data!.items.map((item) => item.name).toList();
          expect(names, contains(renamedName));
          expect(names, isNot(contains(fileName)));

          // 9. 删除改名后的文件与目录
          final deleteFileResponse = await fileApi.deleteFile(
            FileDelete(path: renamedPath, isDir: false, forceDelete: true),
          );
          expect(deleteFileResponse.statusCode, 200);

          final deleteDirResponse = await fileApi.deleteFile(
            FileDelete(path: dirPath, isDir: true, forceDelete: true),
          );
          expect(deleteDirResponse.statusCode, 200);
        } finally {
          await cleanup();
        }
      },
    );

    test(
      '应该能够搜索/tmp目录文件列表',
      skip: SkipConditions.skipIntegration() ?? SkipConditions.skipNoApiKey(),
      () async {
        final response = await fileApi.searchFiles(
          const FileSearch(path: '/tmp', expand: true),
        );

        expect(response.statusCode, 200);
        expect(response.data, isA<FileSearchResponse>());
        expect(response.data, isNotNull);
      },
    );
  });
}
