# 画中画骨架：页面 XComponent（一镜到底）

结构对齐官方 WindowPip 的 XComponent 路径，视觉按 [ui-style.md](../references/engineering/ui-style.md)。`create(config)` **无第二参**。布局 `XComponent` 与 `componentController` 必须同一个。

进 PiP **不要**摘 `XComponent`，**不要**重建 / `release` 播放器。

改 `Page1` 里的 `tpl`（对照 [pip.md](pip.md)），`getControlGroups` / `onControlEvent` 必须同族。

落点：

| 文件 | 作用 |
|------|------|
| `ets/pages/PipHost.ets` | `@Entry` 宿主。Index 空着就能当宿主，不必再造这一页。必须进 `main_pages.json` |
| `ets/xcomponent/Page1.ets` | 根节点 `NavDestination()`；不是 `@Entry` |
| `ets/model/AVPlayer.ets` | 片源 `rawfile/test.mp4` |
| `EntryAbility` | `AppStorage.setOrCreate('UIContext', window.getUIContext())` 可选；骨架播放器直接拿 `getHostContext()` |

## `ets/pages/PipHost.ets`

```ts
import { Page1 } from '../xcomponent/Page1';

@Entry
@Component
struct PipHost {
  @Provide('pageInfos') pageInfos: NavPathStack = new NavPathStack();
  private navId: string = 'nav_pip';

  @Builder
  PageMap(name: string) {
    if (name === 'pageOne') {
      Page1({ navId: this.navId });
    }
  }

  build() {
    Navigation(this.pageInfos) {
      Column() {
        Text('画中画')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .width('100%')
        Text('进入视频页后再启动，小窗从画面飞出')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .margin({ top: 8 })
          .width('100%')
        Blank()
        Button('进入')
          .type(ButtonType.Capsule)
          .height(40)
          .width('100%')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
          .onClick(() => {
            this.pageInfos.pushPath({ name: 'pageOne' });
          })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16, top: 24, bottom: 24 })
      .backgroundColor($r('sys.color.ohos_id_color_background'))
    }
    .title('画中画')
    .navDestination(this.PageMap)
    .id(this.navId)
  }
}
```

`main_pages.json` 登记 `pages/PipHost`（或宿主就是 `pages/Index`）。Index 已是入口列表时：进宿主用 `this.getUIContext().getRouter().pushUrl({ url: 'pages/PipHost' })`（PiP **尚未** start）。不要把 `Page1` 并进 Index。`startPiP` 之后禁止再切页。

## `ets/xcomponent/Page1.ets`

```ts
import { PiPWindow } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AVPlayer } from '../model/AVPlayer';

function getControlGroups(tpl: PiPWindow.PiPTemplateType): Array<PiPWindow.PiPControlGroup> {
  switch (tpl) {
    case PiPWindow.PiPTemplateType.VIDEO_PLAY:
      return [PiPWindow.VideoPlayControlGroup.VIDEO_PREVIOUS_NEXT];
    case PiPWindow.PiPTemplateType.VIDEO_CALL:
      return [
        PiPWindow.VideoCallControlGroup.MICROPHONE_SWITCH,
        PiPWindow.VideoCallControlGroup.HANG_UP_BUTTON,
        PiPWindow.VideoCallControlGroup.CAMERA_SWITCH
      ];
    case PiPWindow.PiPTemplateType.VIDEO_MEETING:
      return [
        PiPWindow.VideoMeetingControlGroup.HANG_UP_BUTTON,
        PiPWindow.VideoMeetingControlGroup.CAMERA_SWITCH,
        PiPWindow.VideoMeetingControlGroup.MUTE_SWITCH
      ];
    case PiPWindow.PiPTemplateType.VIDEO_LIVE:
      return [
        PiPWindow.VideoLiveControlGroup.VIDEO_PLAY_PAUSE,
        PiPWindow.VideoLiveControlGroup.MUTE_SWITCH
      ];
    default:
      return [];
  }
}

@Component
export struct Page1 {
  navId: string = '';
  @State hint: string = '';
  private readonly tpl: PiPWindow.PiPTemplateType = PiPWindow.PiPTemplateType.VIDEO_PLAY;
  private mXComponentController: XComponentController = new XComponentController();
  private player?: AVPlayer = undefined;
  private pipController?: PiPWindow.PiPController = undefined;
  private started: boolean = false;
  private starting: boolean = false;
  private options: XComponentOptions = {
    type: XComponentType.SURFACE,
    controller: this.mXComponentController
  }

  build() {
    NavDestination() {
      Column() {
        XComponent(this.options)
          .onLoad(() => {
            this.player = new AVPlayer();
            this.player.surfaceID = this.mXComponentController.getXComponentSurfaceId();
            this.player.avPlayerFdSrc(this.getUIContext().getHostContext() as common.UIAbilityContext);
          })
          .width('100%')
          .height('800px')
          .margin({ top: 12 })
        Text('视频')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .margin({ top: 12 })
          .width('100%')
        if (this.hint.length > 0) {
          Text(this.hint)
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_warning'))
            .margin({ top: 8 })
            .width('100%')
        }
        Blank()
        Button('启动')
          .type(ButtonType.Capsule)
          .height(40)
          .width('100%')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
          .onClick(() => { this.startPip(); })
        Button('停止')
          .type(ButtonType.Capsule)
          .height(40)
          .width('100%')
          .fontSize(16)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .backgroundColor($r('sys.color.ohos_id_color_component_normal'))
          .margin({ top: 8 })
          .onClick(() => { this.stopPip(); })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16, top: 24, bottom: 24 })
      .backgroundColor($r('sys.color.ohos_id_color_background'))
    }
  }

  private startPip(): void {
    if (this.started || this.starting) {
      return;
    }
    if (!canIUse('SystemCapability.Window.SessionManager') || !PiPWindow.isPiPEnabled()) {
      this.hint = '当前设备不支持画中画';
      return;
    }
    this.starting = true;
    this.hint = '';
    if (this.pipController) {
      this.pipController.startPiP().catch((err: BusinessError) => {
        this.starting = false;
        this.hint = this.startFailHint(err.code);
      });
      return;
    }
    const config: PiPWindow.PiPConfiguration = {
      context: this.getUIContext().getHostContext() as common.UIAbilityContext,
      componentController: this.mXComponentController,
      navigationId: this.navId,
      templateType: this.tpl,
      controlGroups: getControlGroups(this.tpl),
      contentWidth: 1920,
      contentHeight: 1080
    };
    PiPWindow.create(config).then((controller: PiPWindow.PiPController) => {
      this.pipController = controller;
      this.pipController.setAutoStartEnabled(true);
      this.pipController.on('stateChange', (state: PiPWindow.PiPState, reason: string) => {
        if (state === PiPWindow.PiPState.STARTED) {
          this.started = true;
          this.starting = false;
          this.hint = '';
        } else if (state === PiPWindow.PiPState.STOPPED || state === PiPWindow.PiPState.ERROR) {
          this.started = false;
          this.starting = false;
          if (state === PiPWindow.PiPState.ERROR) {
            this.hint = `画中画异常 ${reason}`;
          }
        }
      });
      this.pipController.on('controlEvent', (control: PiPWindow.ControlEventParam) => {
        this.onControlEvent(control);
      });
      return this.pipController.startPiP();
    }).catch((err: BusinessError) => {
      this.starting = false;
      this.hint = this.startFailHint(err.code);
    });
  }

  private startFailHint(code: number): string {
    if (code === 1300034) {
      return '请先停止球窗';
    }
    return `启动失败 ${code}`;
  }

  private onControlEvent(control: PiPWindow.ControlEventParam): void {
    if (control.controlType === PiPWindow.PiPControlType.VIDEO_PLAY_PAUSE) {
      if (control.status === PiPWindow.PiPControlStatus.PAUSE) {
        this.player?.pause();
      } else if (control.status === PiPWindow.PiPControlStatus.PLAY) {
        this.player?.play();
      }
      return;
    }
    if (control.controlType === PiPWindow.PiPControlType.HANG_UP_BUTTON) {
      this.stopPip();
      return;
    }
    if (control.controlType === PiPWindow.PiPControlType.MUTE_SWITCH) {
      this.player?.setMuted(control.status === PiPWindow.PiPControlStatus.OPEN);
    }
  }

  private stopPip(): void {
    this.pipController?.stopPiP().then(() => {
      try {
        this.pipController?.off('stateChange');
        this.pipController?.off('controlEvent');
      } catch (e) {
        const err = e as BusinessError;
        console.error(`off pip ${err.code} ${err.message}`);
      }
      this.pipController = undefined;
      this.started = false;
      this.starting = false;
    }).catch((err: BusinessError) => {
      this.hint = `停止失败 ${err.code}`;
    });
  }
}
```

单页、无 Navigation：删掉 `navigationId`，把 `Page1` 的 `build` 根改成 `Column`（不要 `NavDestination`），宿主就是该页。

## `ets/model/AVPlayer.ets`

```ts
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { media } from '@kit.MediaKit';

export class AVPlayer {
  private avPlayer?: media.AVPlayer;
  public surfaceID: string = '';

  play(): void {
    try {
      this.avPlayer?.play();
    } catch (e) {
      const err = e as BusinessError;
      console.error(`play ${err.code} ${err.message}`);
    }
  }

  pause(): void {
    try {
      this.avPlayer?.pause();
    } catch (e) {
      const err = e as BusinessError;
      console.error(`pause ${err.code} ${err.message}`);
    }
  }

  setMuted(muted: boolean): void {
    try {
      this.avPlayer?.setVolume(muted ? 0 : 1);
    } catch (e) {
      const err = e as BusinessError;
      console.error(`setMuted ${err.code} ${err.message}`);
    }
  }

  async avPlayerFdSrc(ctx: common.UIAbilityContext): Promise<void> {
    try {
      this.avPlayer = await media.createAVPlayer();
      this.avPlayer.on('stateChange', (state: media.AVPlayerState) => {
        if (!this.avPlayer) {
          return;
        }
        if (state === 'initialized') {
          this.avPlayer.surfaceId = this.surfaceID;
          this.avPlayer.prepare();
        } else if (state === 'prepared') {
          this.avPlayer.play();
        }
      });
      const fd = await ctx.resourceManager.getRawFd('test.mp4');
      this.avPlayer.fdSrc = fd;
    } catch (e) {
      const err = e as BusinessError;
      console.error(`avPlayerFdSrc ${err.code} ${err.message}`);
    }
  }
}
```

不要传 `contentNode`。不要 `.clip(true)`。`ABOUT_TO_START` 不要摘 `XComponent`。
