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
        'architecture': 'Dense',
        'backboneParams': '8B',
        'activeParams': '8B',
        'engram': '',
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
        'sort': 1,
      });

      final payload = modelDownloaderFeaturedPayload(model);

      expect(payload['preferredSource'], 'modelScope');
      expect(payload['preferredRepoID'], 'Qwen/Qwen3-ms');
      expect(payload['weightGB'], 8.5);
      expect((payload['description'] as Map)['zh'], '通用模型');
    });

    test('缺少来源时回落到 hf 与 repoID', () {
      final model = FeaturedModel.fromJson(<String, dynamic>{
        'key': 'org-model',
        'repoID': 'org/model',
        'family': 'org',
        'architecture': 'Dense',
        'backboneParams': '7B',
        'activeParams': '7B',
        'engram': '',
        'weightGB': 14.0,
        'sources': <String>[],
        'sourceModelIds': <String, String>{},
        'description': <String, String>{},
        'sort': 0,
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
        'repoID': 'Qwen/Qwen3-8B',
        'revision': 'main',
        'downloadType': 'all',
        'source': 'hf',
        'status': 'running',
        'progress': 42,
        'downloadedSize': 6764573491,
        'totalSize': 16106127360,
        'targetDir': '/opt/models/Qwen3-8B',
        'createdAt': '2026-05-12T08:20:03+08:00',
        'startedAt': '2026-05-12T08:31:07+08:00',
        'canCancel': true,
        'canRetry': false,
        'canRemoveRecord': false,
      });
      final ratio = ModelDownloadTaskItem.fromJson(<String, dynamic>{
        'id': 5,
        'modelName': 'llama',
        'repoID': 'meta-llama/Llama-3.1-8B',
        'revision': 'main',
        'downloadType': 'all',
        'source': 'modelScope',
        'status': 'completed',
        'progress': 0.75,
        'downloadedSize': 12075024384,
        'totalSize': 16100032512,
        'targetDir': '/opt/models/Llama-3.1-8B',
        'createdAt': '2026-05-12T07:44:19+08:00',
        'startedAt': '2026-05-12T07:45:02+08:00',
        'completedAt': '2026-05-12T08:52:31+08:00',
        'canCancel': false,
        'canRetry': true,
        'canRemoveRecord': true,
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
        'modelName': 'mistral',
        'repoID': 'mistralai/Mistral-7B-v0.3',
        'revision': 'main',
        'downloadType': 'all',
        'source': 'hf',
        'status': 'failed',
        'progress': 18.4,
        'downloadedSize': 2687106560,
        'totalSize': 14602888806,
        'targetDir': '/opt/models/Mistral-7B-v0.3',
        'errorMessage': 'network connection reset by peer',
        'createdAt': '2026-05-12T06:18:44+08:00',
        'startedAt': '2026-05-12T06:19:05+08:00',
        'canCancel': false,
        'canRetry': true,
        'canRemoveRecord': true,
      });
      final cancelled = ModelDownloadTaskItem.fromJson(<String, dynamic>{
        'id': 7,
        'modelName': 'deepseek',
        'repoID': 'deepseek-ai/DeepSeek-V3',
        'revision': 'main',
        'downloadType': 'tokenizer',
        'source': 'modelScope',
        'status': 'cancelled',
        'progress': 2.5,
        'downloadedSize': 109051904,
        'totalSize': 4362076160,
        'targetDir': '/opt/models/DeepSeek-V3',
        'createdAt': '2026-05-12T05:02:11+08:00',
        'canCancel': false,
        'canRetry': true,
        'canRemoveRecord': true,
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