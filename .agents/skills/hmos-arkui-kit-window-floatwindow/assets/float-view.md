# 闪控窗骨架（本地）

步骤：[guide-float-view.md](../references/guides/guide-float-view.md)。签名：[js-apis-floatView.md](../references/apis/js-apis-floatView.md)。权限：[permissions.md](permissions.md)。

拆成：`pages/Index.ets`（启动）+ `pages/FloatPanel.ets`（窗内容，须进 `main_pages.json`）。`setUIContext` 加载的是**另一份** `@Entry` 实例，不要把启动逻辑写进 FloatPanel。可点控件避开 `getWindowProperties().avoidArea`。

`create` 只做一次。等 `STARTED` 才算起来。退后台要继续展示：不要在 `aboutToDisappear` / `onPageHide` 里 `stop`。

## `pages/Index.ets`

```ts
import { floatView } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  private fv?: floatView.FloatViewController;
  private started: boolean = false;
  private starting: boolean = false;

  private async start(): Promise<void> {
    if (this.started || this.starting) {
      return;
    }
    if (!canIUse('SystemCapability.Window.SessionManager') || !floatView.isFloatViewEnabled()) {
      return;
    }
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    if (!await requestPerms(ctx, ['ohos.permission.FLOAT_VIEW'])) {
      return;
    }
    this.starting = true;
    try {
      if (!this.fv) {
        const ctrl = await floatView.create({
          context: ctx,
          templateType: floatView.FloatViewTemplateType.ROUNDED_RECTANGLE
        });
        ctrl.onStateChange((info: floatView.FloatViewStateChangeInfo) => {
          if (info.state === floatView.FloatViewState.STARTED) {
            this.started = true;
            this.starting = false;
          } else if (info.state === floatView.FloatViewState.STOPPED) {
            this.started = false;
            this.starting = false;
          }
        });
        await ctrl.setUIContext('pages/FloatPanel');
        this.fv = ctrl;
      }
      await this.fv.start();
    } catch (e) {
      this.starting = false;
      const err = e as BusinessError;
      console.error(`fv ${err.code} ${err.message}`);
    }
  }

  aboutToDisappear(): void {
    try {
      this.fv?.offStateChange();
    } catch (e) {
      const err = e as BusinessError;
      console.error(`off fv ${err.code} ${err.message}`);
    }
  }

  build() {
    Column() {
      Text('闪控窗')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .width('100%')
      Text('退后台后继续显示应用页面')
        .fontSize(14)
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .margin({ top: 8 })
        .width('100%')
      Blank()
      Button('启动')
        .type(ButtonType.Capsule)
        .height(40)
        .width('100%')
        .fontSize(16)
        .fontColor(Color.White)
        .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
        .onClick(() => { this.start(); })
      Button('停止')
        .type(ButtonType.Capsule)
        .height(40)
        .width('100%')
        .fontSize(16)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .backgroundColor($r('sys.color.ohos_id_color_component_normal'))
        .margin({ top: 8 })
        .onClick(() => {
          this.fv?.stop().catch((err: BusinessError) => {
            console.error(`stop fv ${err.code} ${err.message}`);
          });
        })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 24, bottom: 24 })
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
```

`requestPerms` 见 [permissions.md](permissions.md)。横条：只改 `HORIZONTAL_BAR`。

## `pages/FloatPanel.ets`

```ts
@Entry
@Component
struct FloatPanel {
  build() {
    Column() {
      Text('盯盘')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
      Text('沪指 +0.8%')
        .fontSize(14)
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }
}
```
