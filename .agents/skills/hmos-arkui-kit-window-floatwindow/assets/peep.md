# 闪控窗 + 防窥（本地）

往已有 Index / FloatPanel / EntryAbility **里加**，不是单独一页。先有闪控窗（或绑定）骨架，再抄本文件。

指导：[guide-float-view.md](../references/guides/guide-float-view.md) 组合节、[guide-dlp-anti-peep.md](../references/guides/guide-dlp-anti-peep.md)。权威：[闪控窗开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/float-view-guide#%E5%A4%8D%E6%9D%82%E5%9C%BA%E6%99%AF%E4%B8%8E%E9%98%B2%E7%AA%A5%E4%BF%9D%E6%8A%A4%E7%BB%84%E5%90%88%E4%BD%BF%E7%94%A8)「复杂场景：与防窥保护组合使用」。

**防窥 = 系统蒙层。** 系统「防窥提醒」和蒙层是两件事：提醒可以自己出来，蒙层必须应用在 `antiPeepCB` 里加。`HIDE` 时按官网拿 **主窗** `AppStorage.get('MAIN_WINDOW').getUIContext().getWindowId()`，走 `showSystemMaskLayer`（内部 `setAntiPeepMaskLayer`）。不要用 `FloatViewProperties.windowId`，不要改 `FloatPanel` 文案，不要 `updateFloatingBall` 换成 `****`。

一人看屏是 `PASS`，**不会出蒙层**。须有非机主同时看屏，或 demo 页「拉起蒙层」主动调同一套 windowId。失败码要上屏：`201` 多半是签名 ACL 没加 `DLP_GET_HIDE_STATUS`。

开关（ACL ≠ 防窥保护）见 [guide-dlp-anti-peep.md](../references/guides/guide-dlp-anti-peep.md)；下面抄代码，不要静默 `return`。

落点：

1. `EntryAbility` `loadContent` 成功后 `AppStorage.setOrCreate('MAIN_WINDOW', windowStage.getMainWindowSync())`
2. Index `aboutToAppear` 就 `initAntiPeepStatus` + `listenOnAntiPeepStatus(this.antiPeepCB)`，**不要等闪控窗 STARTED**
3. 闪控窗页 `FloatPanel.aboutToAppear` 再存一份 `FLOAT_WINDOW_ID`（同样 `getWindowId()`，先判空），HIDE 时主窗和闪控窗一起蒙
4. 可放 `ets/float/PeepGuard.ets`。页面销毁才 `off`，不要在闪控窗 `STOPPED` 时 `off`

`getWindowId()` 返回 `number | undefined`。官网示例写成 `as number` 再传给 `setAntiPeepMaskLayer`，ArkTS 会 `10605999`。骨架必须先 `!== undefined` 再 `showSystemMaskLayer`，不要 `as number`。

```ts
import { dlpAntiPeep } from '@kit.DeviceSecurityKit';
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export interface AntiPeepCallback {
  onStatusChanged: (status: dlpAntiPeep.DlpAntiPeepStatus) => Promise<void>;
}

export function canUseAntiPeep(): boolean {
  return canIUse('SystemCapability.Security.DlpAntiPeep');
}

export async function isAntiPeepOn(): Promise<boolean> {
  try {
    return await dlpAntiPeep.isDlpAntiPeepSwitchOn();
  } catch (e) {
    const err = e as BusinessError;
    console.error(`isAntiPeepOn ${err.code} ${err.message}`);
    return false;
  }
}

export function getAntiPeepInfo(): dlpAntiPeep.DlpAntiPeepStatus | undefined {
  try {
    return dlpAntiPeep.getDlpAntiPeepInfo();
  } catch (e) {
    const err = e as BusinessError;
    console.error(`getAntiPeepInfo ${err.code} ${err.message}`);
    return undefined;
  }
}

export function showSystemMaskLayer(windowId: number): Promise<boolean> {
  return new Promise((resolve: (value: boolean) => void) => {
    try {
      if (!canUseAntiPeep()) {
        resolve(false);
        return;
      }
      dlpAntiPeep.setAntiPeepMaskLayer(windowId).then(() => {
        resolve(true);
      }).catch((err: BusinessError) => {
        console.error(`mask ${err.code} ${err.message}`);
        resolve(false);
      });
    } catch (e) {
      const err = e as BusinessError;
      console.error(`mask ${err.code} ${err.message}`);
      resolve(false);
    }
  });
}

export function listenOnAntiPeepStatus(antiPeepCB: AntiPeepCallback): boolean {
  try {
    dlpAntiPeep.on('dlpAntiPeep', (status: dlpAntiPeep.DlpAntiPeepStatus) => {
      antiPeepCB.onStatusChanged(status);
    });
    return true;
  } catch (e) {
    const err = e as BusinessError;
    console.error(`on dlpAntiPeep ${err.code} ${err.message}`);
    return false;
  }
}

function takeWindowId(win: window.Window): number | undefined {
  try {
    const id: number | undefined = win.getUIContext().getWindowId();
    if (id === undefined) {
      return undefined;
    }
    return id;
  } catch (e) {
    const err = e as BusinessError;
    console.error(`getWindowId ${err.code} ${err.message}`);
    return undefined;
  }
}

export async function handleAntiPeepStatus(status: dlpAntiPeep.DlpAntiPeepStatus): Promise<void> {
  if (status !== dlpAntiPeep.DlpAntiPeepStatus.HIDE) {
    return;
  }
  const mainWin: window.Window | undefined = AppStorage.get('MAIN_WINDOW');
  if (mainWin !== undefined) {
    const windowId: number | undefined = takeWindowId(mainWin);
    if (windowId !== undefined) {
      await showSystemMaskLayer(windowId);
    }
  }
  const floatId: number | undefined = AppStorage.get('FLOAT_WINDOW_ID');
  if (floatId !== undefined) {
    await showSystemMaskLayer(floatId);
  }
}

export function offAntiPeepStatus(): void {
  try {
    dlpAntiPeep.off('dlpAntiPeep');
  } catch (e) {
    const err = e as BusinessError;
    console.error(`off ${err.code} ${err.message}`);
  }
}

export async function askOpenAntiPeep(ctx: common.UIAbilityContext): Promise<void> {
  try {
    await dlpAntiPeep.requestAntiPeepOptions(ctx);
  } catch (e) {
    const err = e as BusinessError;
    console.error(`requestAntiPeepOptions ${err.code} ${err.message}`);
  }
}
```

页面侧按官网声明回调，不要等 `STARTED` 再 attach。`hint` 必须进 `build()`，不要只写在注释里：

```ts
@State hint: string = '';
antiPeepCB: AntiPeepCallback = {
  onStatusChanged: (status: dlpAntiPeep.DlpAntiPeepStatus): Promise<void> => {
    return handleAntiPeepStatus(status);
  }
};

aboutToAppear(): void {
  this.initAntiPeepStatus();
}

aboutToDisappear(): void {
  offAntiPeepStatus();
}

private initAntiPeepStatus(): void {
  if (!canUseAntiPeep()) {
    this.hint = '当前设备不支持防窥';
    return;
  }
  isAntiPeepOn().then((opened: boolean) => {
    if (!opened) {
      this.hint = '请到设置 → 隐私与安全 → 防窥保护 打开本应用';
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      askOpenAntiPeep(ctx);
      return;
    }
    const info = getAntiPeepInfo();
    if (info !== undefined) {
      handleAntiPeepStatus(info);
    }
    listenOnAntiPeepStatus(this.antiPeepCB);
  });
}

build() {
  Column() {
    if (this.hint.length > 0) {
      Text(this.hint)
        .fontSize(14)
        .fontColor($r('sys.color.ohos_id_color_warning'))
        .width('100%')
    }
  }
}
```

禁止：`fv.setAntiPeep(...)`；`setAntiPeepMaskLayer` 用 `getLastWindow` / `FloatViewProperties.windowId`；等 `STARTED` 才 `on('dlpAntiPeep')`；`getWindowId()` 直接赋给 `number` 或 `as number`（10605999）；页面/球文案改 `****` 当防窥；开关未开静默 `return`。

`FloatPanel` 存 id、以及手动「拉起蒙层」，同样先判空：

```ts
aboutToAppear(): void {
  const windowId: number | undefined = this.getUIContext().getWindowId();
  if (windowId !== undefined) {
    AppStorage.setOrCreate('FLOAT_WINDOW_ID', windowId);
  }
}

private pullMask(): void {
  const mainWin: window.Window | undefined = AppStorage.get('MAIN_WINDOW');
  if (mainWin === undefined) {
    return;
  }
  let windowId: number | undefined = undefined;
  try {
    windowId = mainWin.getUIContext().getWindowId();
  } catch (e) {
    const err = e as BusinessError;
    console.error(`getWindowId ${err.code} ${err.message}`);
    return;
  }
  if (windowId === undefined) {
    return;
  }
  showSystemMaskLayer(windowId);
}
```
