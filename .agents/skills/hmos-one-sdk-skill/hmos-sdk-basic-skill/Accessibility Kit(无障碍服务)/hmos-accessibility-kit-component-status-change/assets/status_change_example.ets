import { PromptAction } from "@kit.ArkUI"

const RESOURCE_STR_PLAY: Resource = $r('sys.media.ohos_ic_public_play');
const RESOURCE_STR_PAUSE: Resource = $r('sys.media.ohos_ic_public_pause');

@Entry
@Component
export struct StatusChangeExample {
  title: string = '控件状态变化示例';
  @State isPlaying: boolean = true;
  uiContext: UIContext = this.getUIContext();
  promptAction: PromptAction = this.uiContext.getPromptAction();
  
  play() {
    console.info('播放音频文件');
  }
  
  pause() {
    console.info('暂停音频文件播放');
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
                  message: this.isPlaying ? '播放' : '暂停'
                })
                this.isPlaying = !this.isPlaying;
                if (this.isPlaying) {
                  this.play();
                } else {
                  this.pause();
                }
              })
              .accessibilityText(this.isPlaying ? '暂停' : '播放')
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)
      }
    }.title(this.title)
  }
}