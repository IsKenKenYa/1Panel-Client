// 状态切换按钮标注示例
// 本示例展示如何为状态切换按钮动态更新无障碍标注

import { AccessibilityRoleType } from '@kit.ArkUI';

const RESOURCE_STR_PLAY: Resource = $r('sys.media.ohos_ic_public_play');
const RESOURCE_STR_PAUSE: Resource = $r('sys.media.ohos_ic_public_pause');

@Entry
@Component
struct StatefulButtonAnnotation {
  title: string = '状态切换按钮示例';
  @State isPlaying: boolean = false;
  
  play() {
    console.info('开始播放音频');
  }
  
  pause() {
    console.info('暂停音频播放');
  }
  
  build() {
    NavDestination() {
      Column() {
        // 示例1: 播放/暂停按钮
        Text('示例1: 音乐播放器')
          .fontSize(16)
          .margin({ bottom: 20 })
        
        Flex({
          direction: FlexDirection.Column,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.Center,
        }) {
          Row() {
            // 播放/暂停按钮 - 根据状态动态更新标注
            Image(this.isPlaying ? RESOURCE_STR_PAUSE : RESOURCE_STR_PLAY)
              .width(50)
              .height(50)
              .onClick(() => {
                this.isPlaying = !this.isPlaying;
                if (this.isPlaying) {
                  this.play();
                } else {
                  this.pause();
                }
              })
              .accessibilityLevel('yes')
              .accessibilityRole(AccessibilityRoleType.BUTTON)
              .accessibilityText(this.isPlaying ? '暂停' : '播放')  // 根据状态动态更新
            
            Text('Good_morning.mp3')
              .fontSize(14)
              .margin({ left: 10 })
          }
          .padding(20)
          .backgroundColor('#F5F5F5')
          .borderRadius(10)
        }
        .width('100%')
        .height(200)
        
        Divider()
          .margin({ top: 20, bottom: 20 })
        
        // 示例2: 音量控制按钮
        Text('示例2: 音量控制')
          .fontSize(16)
          .margin({ bottom: 20 })
        
        Row() {
          // 音量增加按钮
          Image($r('sys.media.ohos_ic_public_volume_up'))
            .width(40)
            .height(40)
            .onClick(() => {
              console.info('音量增加');
            })
            .accessibilityLevel('yes')
            .accessibilityRole(AccessibilityRoleType.BUTTON)
            .accessibilityText('音量增加')
          
          Text('当前音量: 50')
            .fontSize(14)
            .margin({ left: 10, right: 10 })
          
          // 音量减少按钮
          Image($r('sys.media.ohos_ic_public_volume_down'))
            .width(40)
            .height(40)
            .onClick(() => {
              console.info('音量减少');
            })
            .accessibilityLevel('yes')
            .accessibilityRole(AccessibilityRoleType.BUTTON)
            .accessibilityText('音量减少')
        }
        .padding(15)
        .backgroundColor('#F5F5F5')
        .borderRadius(10)
        
        Divider()
          .margin({ top: 20, bottom: 20 })
        
        // 示例3: 喜欢按钮
        Text('示例3: 喜欢按钮')
          .fontSize(16)
          .margin({ bottom: 20 })
        
        Row() {
          // 喜欢按钮 - 状态切换
          Image(this.isLiked ? $r('sys.media.ohos_ic_public_favor_filled') : $r('sys.media.ohos_ic_public_favor'))
            .width(40)
            .height(40)
            .onClick(() => {
              this.isLiked = !this.isLiked;
              console.info(this.isLiked ? '已喜欢' : '取消喜欢');
            })
            .accessibilityLevel('yes')
            .accessibilityRole(AccessibilityRoleType.BUTTON)
            .accessibilityText(this.isLiked ? '取消喜欢' : '喜欢')  // 根据状态动态更新
          
          Text('点击切换喜欢状态')
            .fontSize(14)
            .margin({ left: 10 })
        }
        .padding(15)
        .backgroundColor('#F5F5F5')
        .borderRadius(10)
      }
      .width('100%')
      .padding(20)
    }
    .title(this.title)
  }
  
  @State isLiked: boolean = false;
}