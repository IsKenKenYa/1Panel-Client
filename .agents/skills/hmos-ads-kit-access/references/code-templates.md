# 核心代码模板

> 文档ID: code-templates
> 来源: code-templates.md

---

## 1. AdType 枚举定义

```typescript
export enum AdType {
  SPLASH = 1,
  NATIVE = 3,
  REWARD = 7,
  BANNER = 8,
  INTERSTITIAL = 12,
  ROLL = 60
}
```

## 2. AdStatus 枚举定义

```typescript
export enum AdStatus {
  AD_OPEN = 'onAdOpen',
  AD_CLOSED = 'onAdClose',
  AD_CLICKED = 'onAdClick',
  AD_LOAD = 'onAdLoad',
  AD_FAIL = 'onAdFail',
  AD_REWARDED = 'onAdReward',
  VIDEO_PLAY_BEGIN = 'onVideoPlayBegin',
  VIDEO_PLAY_END = 'onVideoPlayEnd',
  MEDIA_PROGRESS = 'onMediaProgress',
  MEDIA_START = 'onMediaStart',
  MEDIA_PAUSE = 'onMediaPause',
  MEDIA_STOP = 'onMediaStop',
  MEDIA_COMPLETE = 'onMediaComplete',
  MEDIA_ERROR = 'onMediaError',
  MEDIA_COUNTDOWN = 'onMediaCountdown',
  LANDSCAPE = 'onLandscape',
  PORTRAIT = 'onPortrait',
  BACK_CLICKED = 'onBackClicked',
}
```

## 3. OAID 获取（所有广告通用前置步骤）

```typescript
import { abilityAccessCtrl, common, PermissionRequestResult } from '@kit.AbilityKit';
import { identifier } from '@kit.AdsKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

async function requestOAID(context: Context): Promise<string | undefined> {
  let isPermissionGranted: boolean = false;
  try {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    const result: PermissionRequestResult =
      await atManager.requestPermissionsFromUser(context, ['ohos.permission.APP_TRACKING_CONSENT']);
    isPermissionGranted = result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  } catch (err) {
    hilog.error(0x0000, 'testTag', `Failed to request permission. Code is ${err.code}, message is ${err.message}`);
  }
  if (isPermissionGranted) {
    try {
      return await identifier.getOAID();
    } catch (err) {
      hilog.error(0x0000, 'testTag', `Failed to get OAID. Code is ${err.code}, message is ${err.message}`);
    }
  }
  return undefined;
}
```

## 4. 统一广告 ViewModel 模式

```typescript
// AdsViewModel.ets - 统一管理广告请求和展示
import { common } from '@kit.AbilityKit';  // 必须导入 common
import { advertising, AutoAdComponent, AdComponent } from '@kit.AdsKit';
import { AdType } from '../constant/AdType';

@ObservedV2
export class AdsViewModel {
  @Trace ads: advertising.Advertisement[] = [];
  adOptions: advertising.AdOptions = {};
  adDisplayOptions: advertising.AdDisplayOptions = { mute: true, refreshTime: 30000 };
  oaid: string = '';  // 存储获取到的 OAID

  private context: common.UIAbilityContext;  // 必须使用 UIAbilityContext 类型

  constructor(context: common.UIAbilityContext) {  // 参数类型为 UIAbilityContext
    this.context = context;
  }

  async requestOAID(): Promise<void> {
    // 参见上文「OAID 获取」模板
    // 获取后赋值 this.oaid
  }

  async loadAd(adRequestParams: advertising.AdRequestParams): Promise<void> {
    if (!this.oaid) { await this.requestOAID(); }
    adRequestParams.oaid = this.oaid;

    const adType = adRequestParams.adType;
    const adLoader: advertising.AdLoader = new advertising.AdLoader(this.context);
    const adLoadListener: advertising.AdLoadListener = {
      onAdLoadFailure: (errorCode: number, errorMsg: string) => { /* 错误处理 */ },
      onAdLoadSuccess: (ads: Array<advertising.Advertisement>) => {
        // 激励/插屏 → showAd 模式
        if (adType === AdType.REWARD || adType === AdType.INTERSTITIAL) {
          // 注册事件订阅后调用 advertising.showAd()
          advertising.showAd(ads[0], this.adDisplayOptions, this.context);
          return;
        }
        // 其他类型 → AdComponent 展示
        // 注意：原生广告应传 [ads[0]]（单条），而非整个 ads 数组
        this.ads = ads;
      }
    };
    adLoader.loadAd(adRequestParams, this.adOptions, adLoadListener);
  }
}
```

## 5. 公共事件订阅（激励/插屏广告必须）

### 激励广告 — 订阅 `com.huawei.hms.pps.action.PPS_REWARD_STATUS_CHANGED`

```typescript
import { BusinessError, commonEventManager } from '@kit.BasicServicesKit';

// ArkTS 合规：回调参数必须先声明 interface
export interface RewardAdCallbacks {
  onReward?: (rewardType: string, rewardAmount: number) => void;
  onAdClose?: () => void;
}

export class RewardAdStatusHandler {
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;
  private onReward?: (rewardType: string, rewardAmount: number) => void;
  private onAdClose?: () => void;

  constructor(callbacks?: RewardAdCallbacks) {
    if (callbacks) {
      this.onReward = callbacks.onReward;
      this.onAdClose = callbacks.onAdClose;
    }
  }

  registerPPSReceiver(): void {
    if (this.subscriber) { this.unRegisterPPSReceiver(); }
    const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: ['com.huawei.hms.pps.action.PPS_REWARD_STATUS_CHANGED'],
      publisherBundleName: 'com.huawei.hms.adsservice'  // 安全：只接收广告服务事件
    };
    commonEventManager.createSubscriber(subscribeInfo, (err, subscriber) => {
      if (err) { return; }
      this.subscriber = subscriber;
      commonEventManager.subscribe(this.subscriber, (err, data) => {
        if (err) { return; }
        const status = data?.parameters?.['reward_ad_status'];
        switch (status) {
          case 'onAdReward':
            const rewardData = data?.parameters?.['reward_ad_data'];
            if (rewardData && this.onReward) {
              this.onReward(rewardData.rewardType as string, rewardData.rewardAmount as number);
            }
            break;
          case 'onAdClose':
            if (this.onAdClose) { this.onAdClose(); }
            this.unRegisterPPSReceiver();
            break;
        }
      });
    });
  }

  unRegisterPPSReceiver(): void {
    if (this.subscriber) {
      commonEventManager.unsubscribe(this.subscriber, () => { this.subscriber = null; });
    }
  }
}
```

### 插屏广告 — 订阅 `com.huawei.hms.pps.action.PPS_INTERSTITIAL_STATUS_CHANGED`

模式相同，key 为 `interstitial_ad_status`。同样需要先声明 interface：

```typescript
export interface InterstitialAdCallbacks {
  onAdClose?: () => void;
}

export class InterstitialAdStatusHandler {
  // 使用 InterstitialAdCallbacks 而非对象字面量类型
  constructor(callbacks?: InterstitialAdCallbacks) { ... }
}
```

## 6. 开屏广告超时处理

```typescript
export class TimeOutHandler {
  isTimeOut: boolean = false;
  private timeOutIndex: number;

  constructor(handler: () => void, timeout: number = 1000) {
    this.timeOutIndex = setTimeout(() => {
      this.isTimeOut = true;
      handler();
    }, timeout);
  }

  clear(): void { clearTimeout(this.timeOutIndex); }
}
```
