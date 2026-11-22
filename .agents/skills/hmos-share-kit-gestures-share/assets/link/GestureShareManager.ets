/**
 * Link-only gesturesShare manager. No FILE mode / getFileShareData.
 * Requires HarmonyOS SDK 6.0.0(20)+.
 *
 * Usage:
 * 1. Implement GestureShareProvider (link) in the host page.
 * 2. Call enable() on page shown, disable() on page hidden.
 *
 * 【整体流程】
 * 1. 页面显示时调用 enable()：能力检测 → 取当前窗口 windowId → 注册 gesturesShare 监听
 * 2. 用户做"一抓一放"手势 → 系统回调 onGesturesShare(target)，约 3 秒内必须 share 或 reject
 * 3. 页面隐藏时调用 disable() 注销监听
 */
import { harmonyShare, systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { GestureShareProvider } from './GestureShareProvider';

const TAG = 'GestureShareManager';
const DOMAIN = 0x0000;
/** 设备能力检测串：canIUse 为 false 表示设备不支持隔空传送（低版本/未开放），此时不注册监听 */
const CAPABILITY = 'SystemCapability.Collaboration.HarmonyShare';

/** Link-only mode marker (kept for call-site clarity / future incremental upgrade). */
export enum GestureShareMode {
  LINK = 1
}

export class GestureShareManager {
  /** 单例：一个窗口同一时刻只保留一条 gesturesShare 监听，避免重复注册 */
  private static instance: GestureShareManager | undefined = undefined;
  private context: common.UIAbilityContext | undefined = undefined;
  /** 业务侧数据提供者：由宿主页面实现，回答"现在有没有可分享链接、链接是什么" */
  private provider: GestureShareProvider | undefined = undefined;
  /** 监听绑定的窗口 id：多窗口/自由窗场景下只有焦点窗口会收到手势回调 */
  private windowId: number | undefined = undefined;
  /** 是否已注册监听（enable/disable 的幂等保护） */
  private listening: boolean = false;

  public static getInstance(): GestureShareManager {
    if (!GestureShareManager.instance) {
      GestureShareManager.instance = new GestureShareManager();
    }
    return GestureShareManager.instance;
  }

  /**
   * Register gesturesShare listener for the current window (link share only).
   * 页面显示时调用（@Entry 页 onPageShow / NavDestination 页 onShown）。
   */
  public enable(context: common.UIAbilityContext, provider: GestureShareProvider): void {
    this.context = context;
    this.provider = provider;

    // 能力降级：不支持的设备不注册，交给业务 onUnsupported 处理（隐藏入口/Toast 提示）
    if (!canIUse(CAPABILITY)) {
      hilog.warn(DOMAIN, TAG, 'HarmonyShare not supported on this device');
      if (provider.onUnsupported) {
        provider.onUnsupported();
      }
      return;
    }

    // 必须先拿到当前窗口 windowId 再注册：手势回调只派发给监听所绑定的那个窗口
    window.getLastWindow(context).then((win: window.Window) => {
      try {
        const windowId: number = win.getWindowProperties().id;
        // 幂等保护：重复 enable 时先注销旧监听，避免同一窗口注册出两条回调
        if (this.listening && this.windowId !== undefined) {
          try {
            harmonyShare.off('gesturesShare', { windowId: this.windowId });
          } catch (offErr) {
            const e = offErr as BusinessError;
            hilog.error(DOMAIN, TAG, `off before re-enable failed ${e.code} ${e.message}`);
          }
          this.listening = false;
        }
        this.windowId = windowId;
        // 核心注册：用户在窗口上做出"一抓一放"手势后，系统回调此 lambda
        harmonyShare.on('gesturesShare', { windowId: windowId }, (target: harmonyShare.SharableTarget) => {
          this.onGesturesShare(target);
        });
        this.listening = true;
        hilog.info(DOMAIN, TAG, `gesturesShare enabled windowId=${windowId} mode=LINK`);
      } catch (err) {
        const error = err as BusinessError;
        hilog.error(DOMAIN, TAG, `enable getWindowProperties failed ${error.code} ${error.message}`);
      }
    }).catch((error: BusinessError) => {
      hilog.error(DOMAIN, TAG, `enable getLastWindow failed ${error.code} ${error.message}`);
    });
  }

  /**
   * 页面隐藏时调用（onPageHide / NavDestination.onHidden）：注销监听；
   * 不注销会让已离开的页面仍能收到手势回调（串页/误触）。
   */
  public disable(): void {
    if (!canIUse(CAPABILITY)) {
      return;
    }
    if (!this.context) {
      return;
    }
    const cachedId = this.windowId; // 优先用 enable 时缓存的 windowId，取不到再从窗口反查
    window.getLastWindow(this.context).then((win: window.Window) => {
      try {
        const windowId: number = cachedId ?? win.getWindowProperties().id;
        harmonyShare.off('gesturesShare', { windowId: windowId });
        this.listening = false;
        hilog.info(DOMAIN, TAG, `gesturesShare disabled windowId=${windowId}`);
      } catch (err) {
        const error = err as BusinessError;
        hilog.error(DOMAIN, TAG, `disable failed ${error.code} ${error.message}`);
      }
    }).catch((error: BusinessError) => {
      hilog.error(DOMAIN, TAG, `disable getLastWindow failed ${error.code} ${error.message}`);
    });
  }

  /**
   * 手势回调：系统已捕获"一抓一放"，要求约 3 秒内给出 share 或 reject，
   * 否则本次分享超时失败。因此这里只做同步轻量组装，禁止下载等重 IO。
   */
  private onGesturesShare(target: harmonyShare.SharableTarget): void {
    const provider = this.provider;
    if (!provider) { // 页面未提供数据源 → 告知系统无内容
      target.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR).catch((e: BusinessError) => {
        hilog.error(DOMAIN, TAG, `reject without provider failed ${e.code} ${e.message}`);
      });
      return;
    }

    try {
      // 第一道闸：业务判定"当前无可分享链接"（内容为空）→ reject 无内容
      if (!provider.canShare()) {
        target.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR).catch((e: BusinessError) => {
          hilog.error(DOMAIN, TAG, `reject no content failed ${e.code} ${e.message}`);
        });
        return;
      }

      // 第二道闸：向业务要 SharedData（utd=HYPERLINK + content 由 Provider 组装好）；
      // 组装失败返回 undefined
      const shareData: systemShare.SharedData | undefined = provider.getLinkShareData();
      if (shareData === undefined) {
        hilog.error(DOMAIN, TAG, 'getLinkShareData returned undefined');
        target.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR).catch((e: BusinessError) => {
          hilog.error(DOMAIN, TAG, `reject undefined shareData failed ${e.code} ${e.message}`);
        });
        return;
      }
      // 内容就绪：交给系统发起隔空传送（对端弹出接收卡片）；share 是 Promise，失败仅记日志
      target.share(shareData).catch((e: BusinessError) => {
        hilog.error(DOMAIN, TAG, `share failed ${e.code} ${e.message}`);
      });
    } catch (err) { // Provider 抛出未捕获异常 → 兜底 reject，确保 3 秒内一定有应答
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, `onGesturesShare error ${error.code} ${error.message}`);
      target.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR).catch((e: BusinessError) => {
        hilog.error(DOMAIN, TAG, `reject after error failed ${e.code} ${e.message}`);
      });
    }
  }
}
