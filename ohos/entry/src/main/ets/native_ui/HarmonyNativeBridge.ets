import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { deviceInfo } from '@kit.BasicServicesKit';

export class HarmonyNativeBridge implements FlutterPlugin, MethodCallHandler {
  static readonly instance: HarmonyNativeBridge = new HarmonyNativeBridge();

  private businessChannel: MethodChannel | null = null;
  private presentationChannel: MethodChannel | null = null;
  private translations: Map<string, string> = new Map<string, string>();
  private language: string = '';
  private themeMode: string = '';
  private presentationRevision: number = -1;

  getUniqueClassName(): string {
    return 'HarmonyNativeBridge';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.businessChannel = new MethodChannel(
      binding.getBinaryMessenger(),
      'com.onepanel.client/method',
    );
    this.presentationChannel = new MethodChannel(
      binding.getBinaryMessenger(),
      'com.onepanel.client/harmony_ui',
    );
    this.presentationChannel.setMethodCallHandler(this);
    AppStorage.setOrCreate<boolean>('harmonyNativeVisible', false);
    AppStorage.setOrCreate<number>('harmonyNativeRefresh', 0);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.presentationChannel?.setMethodCallHandler(null);
    this.businessChannel = null;
    this.presentationChannel = null;
    this.translations.clear();
    AppStorage.setOrCreate<boolean>('harmonyNativeVisible', false);
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'setPresentation') {
      const language = call.argument('locale') as string | null;
      const themeMode = call.argument('themeMode') as string | null;
      const revision = call.argument('refresh') as number | null;
      if ((language !== null && language !== this.language) ||
        (themeMode !== null && themeMode !== this.themeMode) ||
        (revision !== null && revision !== this.presentationRevision)) {
        this.language = language ?? this.language;
        this.themeMode = themeMode ?? this.themeMode;
        this.presentationRevision = revision ?? this.presentationRevision;
        AppStorage.setOrCreate<string>('harmonyThemeMode', this.themeMode);
        AppStorage.setOrCreate<number>(
          'harmonyNativeRefresh',
          (AppStorage.get<number>('harmonyNativeRefresh') ?? 0) + 1,
        );
      }
      if (deviceInfo.apiAvailable('26.0.0')) {
        AppStorage.setOrCreate<boolean>('harmonyNativeVisible', call.argument('visible') as boolean);
      } else {
        AppStorage.setOrCreate<boolean>('harmonyNativeVisible', false);
      }
      result.success(null);
      return;
    }
    result.notImplemented();
  }

  invoke<T>(method: string, args?: Map<string, Object | null>): Promise<T> {
    return this.invokeChannel<T>(this.businessChannel, method, args ?? null);
  }

  async openFlutterPage(route: string, args?: Map<string, Object | null>): Promise<void> {
    const payload = new Map<string, Object | null>();
    payload.set('route', route);
    if (args !== undefined) {
      payload.set('arguments', args);
    }
    await this.invokeChannel<Object | null>(this.presentationChannel, 'openRoute', payload);
  }

  async refreshSettings(): Promise<void> {
    await this.invokeChannel<Object | null>(this.presentationChannel, 'refreshSettings', null);
  }

  async setActiveModule(module: string): Promise<void> {
    const payload = new Map<string, Object | null>();
    payload.set('module', module);
    await this.invokeChannel<Object | null>(this.presentationChannel, 'setActiveModule', payload);
  }

  async loadTranslations(): Promise<void> {
    this.translations = await this.invoke<Map<string, string>>('getTranslations');
  }

  text(key: string): string {
    return this.translations.get(key) ?? key;
  }

  private invokeChannel<T>(
    channel: MethodChannel | null,
    method: string,
    args: Map<string, Object | null> | null,
  ): Promise<T> {
    if (channel === null) {
      return Promise.reject<T>(new Error('Native channel is not attached'));
    }
    return new Promise<T>((
      resolve: (reply: T | PromiseLike<T>) => void,
      reject: (reason?: Object) => void,
    ): void => {
      const callback: MethodResult = {
        success: (reply: Object | null): void => {
          resolve(reply as T);
        },
        error: (code: string, message: string, details: Object | null): void => {
          reject(new Error(`${code}: ${message}`));
        },
        notImplemented: (): void => {
          reject(new Error(`Native method is not implemented: ${method}`));
        },
      };
      channel.invokeMethod(method, args, callback);
    });
  }
}
