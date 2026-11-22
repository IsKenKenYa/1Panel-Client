/**
 * Combined knockShare manager (FILE + LINK modes).
 * Use when Q1 = 两者都要, or replace file/link-only Manager during incremental upgrade.
 * Same window still uses one mode per enable(); do not mix file+link in one SharedData.
 * pcReceive / preciseKnock apply only when mode is FILE.
 * canShare() true may still run precise first (FILE); miss must fall back to getFileShareData.
 */
import { harmonyShare, systemShare } from '@kit.ShareKit';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { fileUri } from '@kit.CoreFileKit';
import { KnockShareProvider, KnockReceiveCapability } from './KnockShareProvider';

const TAG = 'KnockShareManager';
const DOMAIN = 0x0000;
const CAPABILITY = 'SystemCapability.Collaboration.HarmonyShare';

export enum KnockShareMode {
  FILE = 0,
  LINK = 1
}

export interface KnockShareEnableOptions {
  pcReceive?: boolean;
  preciseKnock?: boolean;
}

export class KnockShareManager {
  private static instance: KnockShareManager | undefined = undefined;
  private context: common.UIAbilityContext | undefined = undefined;
  private provider: KnockShareProvider | undefined = undefined;
  private mode: KnockShareMode = KnockShareMode.FILE;
  private windowId: number | undefined = undefined;
  private listening: boolean = false;
  private receiveListening: boolean = false;
  private pcReceive: boolean = false;
  private preciseKnock: boolean = false;
  private receiveCapabilities: KnockReceiveCapability[] = [];

  public static getInstance(): KnockShareManager {
    if (!KnockShareManager.instance) {
      KnockShareManager.instance = new KnockShareManager();
    }
    return KnockShareManager.instance;
  }

  /**
   * Register knockShare. options.pcReceive / preciseKnock are honored only for FILE mode.
   */
  public enable(context: common.UIAbilityContext, mode: KnockShareMode, provider: KnockShareProvider,
    options?: KnockShareEnableOptions): void {
    this.context = context;
    this.mode = mode;
    this.provider = provider;
    const fileMode = mode === KnockShareMode.FILE;
    this.pcReceive = fileMode && options !== undefined && options.pcReceive === true;
    this.preciseKnock = fileMode && options !== undefined && options.preciseKnock === true;
    if (!fileMode && options !== undefined &&
      (options.pcReceive === true || options.preciseKnock === true)) {
      hilog.warn(DOMAIN, TAG, 'pcReceive/preciseKnock ignored in LINK mode');
    }

    if (!canIUse(CAPABILITY)) {
      hilog.warn(DOMAIN, TAG, 'HarmonyShare not supported on this device');
      if (provider.onUnsupported) {
        provider.onUnsupported();
      }
      return;
    }

    if (this.is2in1()) {
      this.enableWithWindow(context, provider);
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
    hilog.info(DOMAIN, TAG, `knockShare enabled (phone) mode=${this.mode}`);
    if (this.pcReceive) {
      hilog.warn(DOMAIN, TAG, 'pcReceive ignored on non-2in1');
    }
    if (this.preciseKnock) {
      hilog.warn(DOMAIN, TAG, 'preciseKnock ignored on non-2in1');
    }
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

  private enableWithWindow(context: common.UIAbilityContext, provider: KnockShareProvider): void {
    window.getLastWindow(context).then((win: window.Window) => {
      try {
        const windowId: number = win.getWindowProperties().id;
        this.unregisterWindow(windowId);
        this.windowId = windowId;
        harmonyShare.on('knockShare', { windowId: windowId }, (target: harmonyShare.SharableTarget) => {
          this.onKnockShare(target);
        });
        this.listening = true;
        hilog.info(DOMAIN, TAG, `knockShare enabled windowId=${windowId} mode=${this.mode}`);
        if (this.pcReceive) {
          this.enableDataReceive(windowId, provider);
        }
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
    if (this.listening) {
      try {
        harmonyShare.off('knockShare', { windowId: windowId });
      } catch (offErr) {
        const e = offErr as BusinessError;
        hilog.error(DOMAIN, TAG, `off knockShare window failed ${e.code} ${e.message}`);
      }
      this.listening = false;
    }
    if (this.receiveListening) {
      try {
        harmonyShare.off('dataReceive', {
          windowId: windowId,
          capabilities: this.receiveCapabilities
        });
      } catch (offErr) {
        const e = offErr as BusinessError;
        hilog.error(DOMAIN, TAG, `off dataReceive failed ${e.code} ${e.message}`);
      }
      this.receiveListening = false;
    }
  }

  private enableDataReceive(windowId: number, provider: KnockShareProvider): void {
    this.receiveCapabilities = this.resolveReceiveCapabilities(provider);
    if (this.receiveCapabilities.length === 0) {
      hilog.warn(DOMAIN, TAG,
        'pcReceive skipped: getReceiveCapabilities must use the same utd as send');
      return;
    }
    harmonyShare.on('dataReceive', {
      windowId: windowId,
      capabilities: this.receiveCapabilities
    }, (receiveTarget: harmonyShare.ReceivableTarget) => {
      this.onDataReceive(receiveTarget, provider);
    });
    this.receiveListening = true;
    hilog.info(DOMAIN, TAG, `dataReceive enabled windowId=${windowId}`);
  }

  private resolveReceiveCapabilities(provider: KnockShareProvider): KnockReceiveCapability[] {
    if (provider.getReceiveCapabilities === undefined) {
      return [];
    }
    return provider.getReceiveCapabilities();
  }

  private onKnockShare(target: harmonyShare.SharableTarget): void {
    const provider = this.provider;
    if (!provider) {
      this.finishNoContent(target);
      return;
    }

    try {
      if (this.mode === KnockShareMode.LINK) {
        if (!provider.canShare()) {
          this.finishNoContent(target);
          return;
        }
        this.shareOrReject(target, provider.getLinkShareData());
        return;
      }

      // Q8=yes：2in1 先按列表项精准分享；未命中再走全量。
      // 不要把 canShare() 写成 !is2in1() 来“逼出”本分支。
      // apiAvailable 只能传字符串字面量，不能用变量/常量，否则 Invalid parameters for apiAvailable
      if (this.preciseKnock && this.is2in1() && deviceInfo.apiAvailable('26.0.0') &&
        provider.getFileShareDataAt !== undefined) {
        const coordinate = target.getInfo().coordinate;
        if (coordinate) {
          const preciseData = provider.getFileShareDataAt(coordinate.screenX, coordinate.screenY);
          if (preciseData !== undefined) {
            this.shareOrReject(target, preciseData);
            return;
          }
        }
      }

      if (provider.canShare()) {
        this.shareOrReject(target, provider.getFileShareData());
        return;
      }

      this.finishNoContent(target);
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, `onKnockShare error ${error.code} ${error.message}`);
      this.finishNoContent(target);
    }
  }

  private shareOrReject(target: harmonyShare.SharableTarget, shareData: systemShare.SharedData | undefined): void {
    if (shareData === undefined) {
      hilog.error(DOMAIN, TAG, 'shareData undefined');
      this.finishNoContent(target);
      return;
    }
    target.share(shareData).catch((e: BusinessError) => {
      hilog.error(DOMAIN, TAG, `share failed ${e.code} ${e.message}`);
    });
  }

  private finishNoContent(target: harmonyShare.SharableTarget): void {
    const hint = this.mode === KnockShareMode.LINK ? '当前无可分享链接' : '当前无可分享文件';
    target.clarifyNonShare({ message: hint }).catch((e: BusinessError) => {
      hilog.error(DOMAIN, TAG, `clarifyNonShare failed ${e.code} ${e.message}`);
      target.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR).catch((re: BusinessError) => {
        hilog.error(DOMAIN, TAG, `reject after clarify failed ${re.code} ${re.message}`);
      });
    });
  }

  private onDataReceive(receiveTarget: harmonyShare.ReceivableTarget, provider: KnockShareProvider): void {
    if (!this.context) {
      hilog.error(DOMAIN, TAG, 'dataReceive skipped: context missing');
      return;
    }

    let insertIndex: number = -1;
    // insertIndex 只表示命中项（-1 未命中）。如何插入由 provider.onDataReceived 按确认策略做。
    if (this.preciseKnock && deviceInfo.apiAvailable('26.0.0') &&
      provider.hitTestReceiveIndex !== undefined) {
      const info = receiveTarget.getInfo();
      if (info.coordinate) {
        insertIndex = provider.hitTestReceiveIndex(info.coordinate.screenX, info.coordinate.screenY);
      }
    }

    const dirUri: string = provider.getReceiveDirUri !== undefined ?
      provider.getReceiveDirUri() : fileUri.getUriFromPath(this.context.filesDir);

    receiveTarget.receive(dirUri, {
      onDataReceived: (shareData: systemShare.SharedData) => {
        if (provider.onDataReceived !== undefined) {
          try {
            provider.onDataReceived(shareData, insertIndex);
          } catch (err) {
            hilog.error(DOMAIN, TAG, `onDataReceived failed ${JSON.stringify(err)}`);
          }
        }
      },
      onResult: (resultCode: harmonyShare.ShareResultCode) => {
        if (resultCode === harmonyShare.ShareResultCode.SHARE_SUCCESS) {
          hilog.info(DOMAIN, TAG, 'receive file success');
        } else {
          hilog.error(DOMAIN, TAG, `receive failed ${resultCode}`);
        }
      }
    });
  }
}
