# 控件状态变化场景
---
# 控件状态变化场景
#### 开发实例
例如下图，播放暂停按钮对应着两种状态，在状态切换时需要实时变化对应的标注信息。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/f1/v3/NuQqneZ5TnS7U7EpKj-wcg/zh-cn_image_0000002659219299.png?HW-CC-KV=V1&HW-CC-Date=20260701T104518Z&HW-CC-Expire=86400&HW-CC-Sign=41E81495FBD83229C611B7D9622669A6F2FBD4324B05E0E1402D9DA01A1575F9)
```
import { PromptAction } from "@kit.ArkUI"
const RESOURCE_STR_PLAY: Resource = $r('sys.media.ohos_ic_public_play');
const RESOURCE_STR_PAUSE: Resource = $r('sys.media.ohos_ic_public_pause');
@Entry
@Component
export struct Rule_2_1_8 {
  title: string = 'Rule 2.1.8';
  @State isPlaying: boolean = true;
  uiContext: UIContext = this.getUIContext();
  promptAction: PromptAction = this.uiContext.getPromptAction();
  play() {
    console.info('play audio file');
  }
  pause() {
    console.info('pause playing of audio file');
  }
  build() {
    NavDestination() {
      Column() {
        Flex({
          direction: FlexDirection.Column,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.Center,
        }) {
          Row() {
            Image(this.isPlaying ? RESOURCE_STR_PAUSE : RESOURCE_STR_PLAY)
              .width(50)
              .height(50)
              .onClick(() => {
                this.promptAction.showToast({
                  message :this.isPlaying ? 'Play' : 'Pause'
                })
                this.isPlaying = !this.isPlaying;
                if (this.isPlaying) {
                  this.play();
                } else {
                  this.pause();
                }
              })
              .accessibilityText(this.isPlaying ? 'Pause' : 'Play') // 设置可访问性框架的注释信息。
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)
      }
    }.title(this.title)
  }
}
```