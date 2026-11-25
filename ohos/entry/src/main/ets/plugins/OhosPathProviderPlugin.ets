import {
  FlutterPlugin,
  FlutterPluginBinding,
  Log,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

const TAG = 'OhosPathProviderPlugin';
const CHANNEL = 'plugins.flutter.io/path_provider';

export default class OhosPathProviderPlugin
  implements FlutterPlugin, MethodCallHandler
{
  private channel: MethodChannel | null = null;
  private applicationContext: common.Context | null = null;

  getUniqueClassName(): string {
    return 'OhosPathProviderPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.applicationContext = binding.getApplicationContext() as common.Context;
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    this.applicationContext = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    try {
      const context = this.requireContext();
      switch (call.method) {
        case 'getTemporaryDirectory':
          result.success(context.tempDir);
          return;
        case 'getApplicationSupportDirectory':
        case 'getApplicationDocumentsDirectory':
        case 'getLibraryDirectory':
        case 'getStorageDirectory':
          // 持久数据统一放在 filesDir：Hive 库、日志与导出文件都不会被系统按缓存清理。
          result.success(context.filesDir);
          return;
        case 'getDownloadsDirectory':
          // 下载文件保存在应用持久目录。
          result.success(`${context.filesDir}/Download`);
          return;
        case 'getApplicationCacheDirectory':
          result.success(context.cacheDir);
          return;
        case 'getExternalCacheDirectories':
          result.success([context.cacheDir]);
          return;
        case 'getExternalStorageDirectories':
          result.success([context.filesDir]);
          return;
        default:
          result.notImplemented();
      }
    } catch (error) {
      Log.e(TAG, `Failed to handle ${call.method}`, error);
      result.error('path_provider_error', `${error}`, null);
    }
  }

  private requireContext(): common.Context {
    if (this.applicationContext == null) {
      throw new Error('Application context is not ready');
    }
    return this.applicationContext;
  }
}
