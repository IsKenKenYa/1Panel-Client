import {
  FlutterPlugin,
  FlutterPluginBinding,
  Log,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { uiMaterial } from '@kit.ArkUI';
import { ConfigurationConstant, common } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';

const TAG = 'HarmonyNativeBridge';

/** 半模态与弹出层按官方沉浸光感规范使用 ULTRA_THICK，保证复杂内容可读。 */
export const sheetMaterial: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.ULTRA_THICK,
});

/** 临时菜单按官方规范使用 THICK，短时呈现且需覆盖下层内容。 */
export const menuMaterial: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.THICK,
});

/** 顶部浮动标题栏按官方规范使用 ULTRA_THIN，需配合 STACK 布局叠在滚动内容之上。 */
export const titleBarMaterial: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
  colorInvert: true,
  interactive: true,
  lightEffect: {},
});

export class HarmonyNativeBridge implements FlutterPlugin, MethodCallHandler {
  static readonly instance: HarmonyNativeBridge = new HarmonyNativeBridge();

  private businessChannel: MethodChannel | null = null;
  private presentationChannel: MethodChannel | null = null;
  private applicationContext: common.ApplicationContext | null = null;
  private translations: Map<string, string> = new Map<string, string>();
  private language: string = '';
  private themeMode: string = '';
  private presentationRevision: number = -1;
  private nativePageHandler: ((route: string, args: Map<string, Object | null>) => Promise<void>) | null = null;
  private methodListeners: Array<(method: string, args: Object | null) => void> = [];

  getUniqueClassName(): string {
    return 'HarmonyNativeBridge';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.applicationContext = binding.getApplicationContext() as common.ApplicationContext;
    this.businessChannel = new MethodChannel(
      binding.getBinaryMessenger(),
      'com.onepanel.client/method',
    );
    this.presentationChannel = new MethodChannel(
      binding.getBinaryMessenger(),
      'com.onepanel.client/harmony_ui',
    );
    this.presentationChannel.setMethodCallHandler(this);
    this.businessChannel.setMethodCallHandler({
      onMethodCall: (call: MethodCall, result: MethodResult): void => {
        this.methodListeners.forEach((listener: (method: string, args: Object | null) => void): void => {
          listener(call.method, call.args);
        });
        result.success(null);
      },
    });
    AppStorage.setOrCreate<boolean>('harmonyNativeVisible', false);
    AppStorage.setOrCreate<number>('harmonyNativeRefresh', 0);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.presentationChannel?.setMethodCallHandler(null);
    this.businessChannel?.setMethodCallHandler(null);
    this.methodListeners = [];
    this.nativePageHandler = null;
    this.businessChannel = null;
    this.presentationChannel = null;
    this.applicationContext = null;
    this.translations.clear();
    AppStorage.setOrCreate<boolean>('harmonyNativeVisible', false);
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'setEntryPresentation') {
      const available = deviceInfo.apiAvailable('26.0.0');
      if (available) {
        AppStorage.setOrCreate<string>('harmonyEntryTitle', call.argument('title') as string ?? '');
        AppStorage.setOrCreate<string>('harmonyEntryMessage', call.argument('message') as string ?? '');
        AppStorage.setOrCreate<boolean>('harmonyEntryRequireConsent', call.argument('requireConsent') === true);
        AppStorage.setOrCreate<string>('harmonyEntryPage', call.argument('page') as string);
      }
      result.success(available);
      return;
    }
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
        this.applyColorMode(this.themeMode);
        AppStorage.setOrCreate<number>(
          'harmonyNativeRefresh',
          (AppStorage.get<number>('harmonyNativeRefresh') ?? 0) + 1,
        );
      }
      if (deviceInfo.apiAvailable('26.0.0')) {
        AppStorage.setOrCreate<string>('harmonyRootRoute', call.argument('rootRoute') as string ?? '');
        AppStorage.setOrCreate<boolean>('harmonyAppLockBusy', call.argument('appLockBusy') === true);
        AppStorage.setOrCreate<string>('harmonyAppLockError', call.argument('appLockError') as string ?? '');
        AppStorage.setOrCreate<boolean>('harmonyAppLockVisible', call.argument('appLockVisible') === true);
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

  private applyColorMode(themeMode: string): void {
    const context = this.applicationContext;
    if (context === null) {
      return;
    }
    let colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    if (themeMode === 'light') {
      colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    } else if (themeMode === 'dark') {
      colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    }
    try {
      context.setColorMode(colorMode);
    } catch (error) {
      Log.e(TAG, `Failed to set color mode: ${error}`);
    }
  }

  setNativePageHandler(handler: ((route: string, args: Map<string, Object | null>) => Promise<void>) | null): void {
    this.nativePageHandler = handler;
  }

  async openNativePage(route: string, args?: Map<string, Object | null>): Promise<void> {
    const handler = this.nativePageHandler;
    if (handler === null) {
      throw new Error(`Native page is unavailable: ${route}`);
    }
    await handler(route, args ?? new Map<string, Object | null>());
  }

  addMethodListener(listener: (method: string, args: Object | null) => void): void {
    this.methodListeners.push(listener);
  }

  removeMethodListener(listener: (method: string, args: Object | null) => void): void {
    this.methodListeners = this.methodListeners.filter((item: (method: string, args: Object | null) => void): boolean =>
      item !== listener);
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

  async setActiveRoute(route: string | null): Promise<void> {
    await this.invokeChannel<boolean>(this.presentationChannel, 'setActiveRoute', route);
  }

  async entryAction(page: string, action: string): Promise<void> {
    const args = new Map<string, Object | null>([['page', page], ['action', action]]);
    await this.invokeChannel<Object | null>(this.presentationChannel, 'entryAction', args);
  }

  async getPinnedModules(): Promise<string[]> {
    const pins = await this.invokeChannel<string[]>(this.presentationChannel, 'getPinnedModules', null);
    AppStorage.setOrCreate<string[]>('harmonyPinnedModules', pins);
    return pins;
  }

  async setPinnedModules(primary?: string, secondary?: string): Promise<string[]> {
    const args = primary === undefined || secondary === undefined ? null :
      new Map<string, Object | null>([['primary', primary], ['secondary', secondary]]);
    const pins = await this.invokeChannel<string[]>(this.presentationChannel, 'setPinnedModules', args);
    AppStorage.setOrCreate<string[]>('harmonyPinnedModules', pins);
    return pins;
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
    args: Map<string, Object | null> | string | null,
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
