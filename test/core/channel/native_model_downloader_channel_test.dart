import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:onepanel_client/core/channel/native_model_downloader_payloads.dart';
import 'package:onepanel_client/data/models/model_downloader_models.dart';
import 'package:onepanel_client/data/models/setting_models.dart';

void main() {
  group('modelDownloaderFeaturedPayload', () {
    test('默认来源与仓库标识由 Dart 侧给出', () {
      final model = FeaturedModel.fromJson(<String, dynamic>{
        'key': 'qwen',
        'repoID': 'Qwen/Qwen3',
        'family': 'Qwen',
        'weightGB': 8.5,
        'sources': <String>['modelScope', 'hf'],
        'sourceModelIds': <String, String>{
          'modelScope': 'Qwen/Qwen3-ms',
          'hf': 'Qwen/Qwen3-hf',
        },
        'description': <String, String>{
          'en': 'General model',
          'zh': '通用模型',
        },
      });

      final payload = modelDownloaderFeaturedPayload(model);

      expect(payload['preferredSource'], 'modelScope');
      expect(payload['preferredRepoID'], 'Qwen/Qwen3-ms');
      expect(payload['weightGB'], 8.5);
      expect((payload['description'] as Map)['zh'], '通用模型');
    });

    test('缺少来源时回落到 hf 与 repoID', () {
      final model = FeaturedModel.fromJson(<String, dynamic>{
        'repoID': 'org/model',
      });

      final payload = modelDownloaderFeaturedPayload(model);

      expect(payload['preferredSource'], 'hf');
      expect(payload['preferredRepoID'], 'org/model');
    });
  });

  group('modelDownloaderTaskPayload', () {
    test('进度量级兼容并返回状态分组', () {
      final percent = ModelDownloadTaskItem.fromJson(<String, dynamic>{
        'id': 4,
        'modelName': 'qwen',
        'status': 'running',
        'progress': 42,
        'canCancel': true,
      });
      final ratio = ModelDownloadTaskItem.fromJson(<String, dynamic>{
        'id': 5,
        'modelName': 'llama',
        'status': 'completed',
        'progress': 0.75,
      });

      final percentPayload = modelDownloaderTaskPayload(percent);
      final ratioPayload = modelDownloaderTaskPayload(ratio);

      expect(percentPayload['progressRatio'], 0.42);
      expect(percentPayload['statusTone'], 'info');
      expect(percentPayload['canCancel'], isTrue);
      expect(ratioPayload['progressRatio'], 0.75);
      expect(ratioPayload['statusTone'], 'positive');
    });

    test('失败与取消状态给出语义色分组', () {
      final failed = ModelDownloadTaskItem.fromJson(<String, dynamic>{
        'id': 6,
        'status': 'failed',
      });
      final cancelled = ModelDownloadTaskItem.fromJson(<String, dynamic>{
        'id': 7,
        'status': 'cancelled',
      });

      expect(modelDownloaderTaskPayload(failed)['statusTone'], 'negative');
      expect(modelDownloaderTaskPayload(cancelled)['statusTone'], 'neutral');
    });
  });

  group('modelDownloaderSettingsPayload', () {
    test('自动同步开关由字符串状态翻译为布尔值', () {
      final enabled = modelDownloaderSettingsPayload(
        const ModelDownloaderSetting(
          modelDir: '/models',
          featuredModelsSync: 'Enable',
          hfEndpoint: 'https://hf.example.test',
        ),
      );
      final disabled = modelDownloaderSettingsPayload(
        const ModelDownloaderSetting(
          modelDir: '/models',
          featuredModelsSync: 'Disable',
        ),
      );

      expect(enabled['featuredSyncEnabled'], isTrue);
      expect(enabled['modelDir'], '/models');
      expect(disabled['featuredSyncEnabled'], isFalse);
    });
  });

  group('modelDownloaderOptionsPayload', () {
    test('来源、排序、下载内容与任务状态齐备', () {
      final payload = modelDownloaderOptionsPayload();

      expect(payload['sources'], <String>['hf', 'modelScope']);
      expect(payload['downloadTypes'], <String>['all', 'tokenizer']);
      expect((payload['sorts'] as List).contains('trending'), isTrue);
      expect((payload['taskStatuses'] as List).contains('running'), isTrue);
    });
  });

  group('模型下载器通道入口', () {
    test('下载缺少 repoID 时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.downloadModel(
        <String, dynamic>{'repoID': ' ', 'source': 'hf'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('repoID'));
    });

    test('下载 dispatch 路由到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'downloadModel',
        <String, dynamic>{'repoID': '', 'source': 'hf'},
      );

      expect(result['success'], isFalse);
    });

    test('取消任务缺少 id 时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.cancelModelTask(
        <String, dynamic>{'id': 'x'},
      );

      expect(result['success'], isFalse);
    });

    test('保存设置缺少模型目录时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.updateModelDownloaderSettings(
        <String, dynamic>{'modelDir': ' '},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('modelDir'));
    });
  });
}