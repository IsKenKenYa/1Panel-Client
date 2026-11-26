import {
  FlutterPlugin, FlutterPluginBinding, MethodCall, MethodCallHandler, MethodChannel, MethodResult,
} from '@ohos/flutter_ohos';

export type HarmonyContainerTerminalListener = (payload: Map<string, Object | null>) => void;

export class HarmonyContainerTerminalBridge implements FlutterPlugin, MethodCallHandler {
  static readonly instance: HarmonyContainerTerminalBridge = new HarmonyContainerTerminalBridge();
  private channel: MethodChannel | null = null;
  private listeners: Set<HarmonyContainerTerminalListener> = new Set<HarmonyContainerTerminalListener>();

  getUniqueClassName(): string { return 'HarmonyContainerTerminalBridge'; }
  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'com.onepanel.client/terminal');
    this.channel.setMethodCallHandler(this);
  }
  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
    this.listeners.clear();
  }
  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'terminalEvent') {
      const payload = call.args as Map<string, Object | null>;
      this.listeners.forEach((listener: HarmonyContainerTerminalListener): void => { listener(payload); });
      result.success(null);
      return;
    }
    result.notImplemented();
  }
  addListener(listener: HarmonyContainerTerminalListener): void { this.listeners.add(listener); }
  removeListener(listener: HarmonyContainerTerminalListener): void { this.listeners.delete(listener); }
  invoke<T>(method: string, args: Map<string, Object | null>): Promise<T> {
    const channel = this.channel;
    if (channel === null) return Promise.reject<T>(new Error('Terminal channel is unavailable'));
    return new Promise<T>((resolve: (reply: T | PromiseLike<T>) => void, reject: (reason?: Object) => void): void => {
      const result: MethodResult = {
        success: (reply: Object | null): void => { resolve(reply as T); },
        error: (code: string, message: string, details: Object | null): void => { reject(new Error(message)); },
        notImplemented: (): void => { reject(new Error(`Terminal method is unavailable: ${method}`)); },
      };
      channel.invokeMethod(method, args, result);
    });
  }
}
