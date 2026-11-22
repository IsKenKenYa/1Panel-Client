# 闪控球骨架（本地）

只做贴边球时抄本文件。**绑定不要抄这一份**，改走 [bind.md](bind.md)。

签名：[js-apis-floatingBall.md](../references/apis/js-apis-floatingBall.md)。`USE_FLOAT_BALL` 只声明+ACL，不要弹窗。系统画球，不要新建球页、不要 `setUIContext`。

`create` 只做一次。等 `STARTED` 才算起来。不要在 `aboutToDisappear` 里 `stopFloatingBall`。

```ts
import { floatingBall } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  private fb?: floatingBall.FloatingBallController;
  private readonly tpl: floatingBall.FloatingBallTemplate = floatingBall.FloatingBallTemplate.EMPHATIC;
  private started: boolean = false;
  private starting: boolean = false;

  private async start(): Promise<void> {
    if (this.started || this.starting) {
      return;
    }
    if (!canIUse('SystemCapability.Window.SessionManager') || !floatingBall.isFloatingBallEnabled()) {
      return;
    }
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.starting = true;
    try {
      if (!this.fb) {
        this.fb = await floatingBall.create({ context: ctx });
        this.fb.on('stateChange', (state: floatingBall.FloatingBallState) => {
          if (state === floatingBall.FloatingBallState.STARTED) {
            this.started = true;
            this.starting = false;
          } else if (state === floatingBall.FloatingBallState.STOPPED) {
            this.started = false;
            this.starting = false;
          }
        });
        this.fb.on('click', () => {
          const host = this.getUIContext().getHostContext() as common.UIAbilityContext;
          this.fb?.restoreMainWindow({
            bundleName: host.abilityInfo.bundleName,
            abilityName: host.abilityInfo.name
          }).catch((err: BusinessError) => {
            console.error(`restore ${err.code} ${err.message}`);
          });
        });
      }
      await this.fb.startFloatingBall({
        template: this.tpl,
        title: '盯盘',
        content: '沪指 +0.8%'
      });
    } catch (e) {
      this.starting = false;
      const err = e as BusinessError;
      console.error(`fb ${err.code} ${err.message}`);
    }
  }

  private async refresh(text: string): Promise<void> {
    await this.fb?.updateFloatingBall({ template: this.tpl, title: '盯盘', content: text });
  }

  aboutToDisappear(): void {
    try {
      this.fb?.off('stateChange');
      this.fb?.off('click');
    } catch (e) {
      const err = e as BusinessError;
      console.error(`off fb ${err.code} ${err.message}`);
    }
  }

  build() {
    Column() {
      Text('闪控球')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .width('100%')
      Text('系统绘制贴边球，这里只负责启动')
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
          this.fb?.stopFloatingBall().catch((err: BusinessError) => {
            console.error(`stop fb ${err.code} ${err.message}`);
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

`STATIC`：title + icon，禁止走 `refresh`。`NORMAL` / `SIMPLE` 只改 `tpl` 和必传字段。
