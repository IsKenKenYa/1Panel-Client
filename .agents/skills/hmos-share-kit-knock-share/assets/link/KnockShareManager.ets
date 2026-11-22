/**
 * Link-only knockShare manager. No FILE mode / getFileShareData / dataReceive / preciseKnock.
 * Template targets HarmonyOS SDK 6.0.2(22)+ (clarifyNonShare). On 6.0.0(20) use reject(NO_CONTENT_ERROR).
 *
 * Usage:
 * 1. Implement KnockShareProvider (link) in the host page.
 * 2. Call enable() on page shown, disable() on page hidden.
 */
import { harmonyShare, systemShare } from '@kit.ShareKit';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { KnockShareProvider } from './KnockShareProvider';

const TAG = 'KnockShareManager';
const DOMAIN = 0x0000;
const CAPABILITY = 'SystemCapability.Collaboration.HarmonyShare';
const NO_CONTENT_HINT = '当前无可分享链接';

export enum KnockShareMode {
  LINK = 1
}

export class KnockShareManager {
  private static instance: KnockShareManager | undefined = undefined;
  private context: common.UIAbilityContext | undefined = undefined;
  private provider: KnockShareProvider | undefined = undefined;
  private windowId: number | undefined = undefined;
  private listening: boolean = false;

  public static getInstance(): KnockShareManager {
    if (!KnockShareManager.instance) {
      KnockShareManager.instance = new KnockShareManager();
    }
    return KnockShareManager.instance;
  }

  public enable(context: common.UIAbilityContext, provider: KnockShareProvider): void {
    this.context = context;
    this.provider = provider;

    if (!canIUse(CAPABILITY)) {
      hilog.warn(DOMAIN, TAG, 'HarmonyShare not supported on this device');
      if (provider.onUnsupported) {
        provider.onUnsupported();
      }
      return;
    }

    if (this.is2in1()) {
      this.enableWithWindow(context);
    } else {
      this.enablePhone();
    }
  }

  public disable(): void {
    if (!canIUse(CAPABILITY)) {
      return;
    }
    if (this.is2in1()) {
      this.disableWithWindow();
    } else {
      this.disablePhone();
    }
  }

  private is2in1(): boolean {
    return deviceInfo.deviceType === '2in1';
  }

  private enablePhone(): void {
    this.unregisterPhone();
    harmonyShare.on('knockShare', (target: harmonyShare.SharableTarget) => {
      this.onKnockShare(target);
    });
    this.listening = true;
    hilog.info(DOMAIN, TAG, 'knockShare enabled (phone) mode=LINK');
  }

  private disablePhone(): void {
    this.unregisterPhone();
    hilog.info(DOMAIN, TAG, 'knockShare disabled (phone)');
  }

  private unregisterPhone(): void {
    if (!this.listening) {
      return;
    }
    try {
      harmonyShare.off('knockShare');
    } catch (offErr) {
      const e = offErr as BusinessError;
      hilog.error(DOMAIN, TAG, `off knockShare phone failed ${e.code} ${e.message}`);
    }
    this.listening = false;
  }

  private enableWithWindow(context: common.UIAbilityContext): void {
    window.getLastWindow(context).then((win: window.Window) => {
      try {
        const windowId: number = win.getWindowProperties().id;
        this.unregisterWindow(windowId);
        this.windowId = windowId;
        harmonyShare.on('knockShare', { windowId: windowId }, (target: harmonyShare.SharableTarget) => {
          this.onKnockShare(target);
        });
        this.listening = true;
        hilog.info(DOMAIN, TAG, `knockShare enabled windowId=${windowId} mode=LINK`);
      } catch (err) {
        const error = err as BusinessError;
        hilog.error(DOMAIN, TAG, `enable getWindowProperties failed ${error.code} ${error.message}`);
      }
    }).catch((error: BusinessError) => {
      hilog.error(DOMAIN, TAG, `enable getLastWindow failed ${error.code} ${error.message}`);
    });
  }

  private disableWithWindow(): void {
    if (!this.context) {
      return;
    }
    const cachedId = this.windowId;
    window.getLastWindow(this.context).then((win: window.Window) => {
      try {
        const windowId: number = cachedId ?? win.getWindowProperties().id;
        this.unregisterWindow(windowId);
        hilog.info(DOMAIN, TAG, `knockShare disabled windowId=${windowId}`);
      } catch (err) {
        const error = err as BusinessError;
        hilog.error(DOMAIN, TAG, `disable failed ${error.code} ${error.message}`);
      }
    }).catch((error: BusinessError) => {
      hilog.error(DOMAIN, TAG, `disable getLastWindow failed ${error.code} ${error.message}`);
    });
  }

  private unregisterWindow(windowId: number): void {
    if (!this.listening) {
      return;
    }
    try {
      harmonyShare.off('knockShare', { windowId: windowId });
    } catch (offErr) {
      const e = offErr as BusinessError;
      hilog.error(DOMAIN, TAG, `off knockShare window failed ${e.code} ${e.message}`);
    }
    this.listening = false;
  }

  private onKnockShare(target: harmonyShare.SharableTarget): void {
    const provider = this.provider;
    if (!provider) {
      this.finishNoContent(target);
      return;
    }

    try {
      if (!provider.canShare()) {
        this.finishNoContent(target);
        return;
      }
      this.shareOrReject(target, provider.getLinkShareData());
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, `onKnockShare error ${error.code} ${error.message}`);
      this.finishNoContent(target);
    }
  }

  private shareOrReject(target: harmonyShare.SharableTarget, shareData: systemShare.SharedData | undefined): void {
    if (shareData === undefined) {
      hilog.error(DOMAIN, TAG, 'getLinkShareData returned undefined');
      this.finishNoContent(target);
      return;
    }
    target.share(shareData).catch((e: BusinessError) => {
      hilog.error(DOMAIN, TAG, `share failed ${e.code} ${e.message}`);
    });
  }

  private finishNoContent(target: harmonyShare.SharableTarget): void {
    target.clarifyNonShare({ message: NO_CONTENT_HINT }).catch((e: BusinessError) => {
      hilog.error(DOMAIN, TAG, `clarifyNonShare failed ${e.code} ${e.message}`);
      target.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR).catch((re: BusinessError) => {
        hilog.error(DOMAIN, TAG, `reject after clarify failed ${re.code} ${re.message}`);
      });
    });
  }
}
