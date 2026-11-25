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
import preferences from '@ohos.data.preferences';
import OhosPreferenceStore from './OhosPreferenceStore';

const TAG = 'OhosSharedPreferencesPlugin';
const CHANNEL = 'plugins.flutter.io/shared_preferences';
const STORE_NAME = 'FlutterSharedPreferences';

export default class OhosSharedPreferencesPlugin
  implements FlutterPlugin, MethodCallHandler
{
  private channel: MethodChannel | null = null;
  private store: OhosPreferenceStore | null = null;

  getUniqueClassName(): string {
    return 'OhosSharedPreferencesPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.store = new OhosPreferenceStore(
      binding.getApplicationContext() as common.Context,
      STORE_NAME,
    );
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    this.store = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    this.handleMethodCall(call, result);
  }

  private async handleMethodCall(
    call: MethodCall,
    result: MethodResult,
  ): Promise<void> {
    if (this.store == null) {
      result.error('shared_preferences_unavailable', 'Store is not ready', null);
      return;
    }

    try {
      switch (call.method) {
        case 'getAll': {
          const all =
            (await this.store.getAll()) as Record<string, preferences.ValueType>;
          result.success(this.filterEntries(all, 'flutter.', null));
          return;
        }
        case 'getAllWithParameters': {
          const prefix = call.argument('prefix') as string | null;
          const allowList = call.argument('allowList') as Array<string> | null;
          const all =
            (await this.store.getAll()) as Record<string, preferences.ValueType>;
          const filter = this.filterEntries(
            all,
            prefix,
            allowList,
          );
          result.success(filter);
          return;
        }
        case 'setBool':
        case 'setInt':
        case 'setDouble':
        case 'setString':
        case 'setStringList': {
          const key = this.requireStringArgument(call, 'key');
          const value = call.argument('value') as preferences.ValueType;
          await this.store.put(key, value);
          result.success(true);
          return;
        }
        case 'remove': {
          const key = this.requireStringArgument(call, 'key');
          await this.store.delete(key);
          result.success(true);
          return;
        }
        case 'clear':
          await this.store.clear();
          result.success(true);
          return;
        case 'clearWithParameters': {
          const prefix = call.argument('prefix') as string | null;
          const allowList = call.argument('allowList') as Array<string> | null;
          const all =
            (await this.store.getAll()) as Record<string, preferences.ValueType>;
          const keys = Object.keys(
            this.filterEntries(
              all,
              prefix,
              allowList,
            ),
          );
          await this.store.deleteKeys(keys);
          result.success(true);
          return;
        }
        default:
          result.notImplemented();
      }
    } catch (error) {
      Log.e(TAG, `Failed to handle ${call.method}`, error);
      result.error(
        'shared_preferences_error',
        `${error}`,
        null,
      );
    }
  }

  private filterEntries(
    source: Record<string, preferences.ValueType>,
    prefix: string | null,
    allowList: Array<string> | null,
  ): Record<string, preferences.ValueType> {
    const filtered: Record<string, preferences.ValueType> = {};
    const entries = source;
    for (const key of Object.keys(entries)) {
      if (prefix != null && prefix.length > 0 && !key.startsWith(prefix)) {
        continue;
      }
      if (allowList != null && allowList.length > 0 && !allowList.includes(key)) {
        continue;
      }
      filtered[key] = entries[key];
    }
    return filtered;
  }

  private requireStringArgument(call: MethodCall, key: string): string {
    const rawValue = call.argument(key) as string | null;
    if (rawValue != null && rawValue.length > 0) {
      return rawValue;
    }
    throw new Error(`Missing required string argument: ${key}`);
  }
}
