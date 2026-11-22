# 控件位置调整场景
---
# 控件位置调整场景
#### 设计场景
移动过程中需要实时播报即将移动到的位置，新位置的播报会打断老位置的播报，放置到确定位置后，需要再播报已经放置的位置信息，尽量保证视障用户耳朵听到的信息和我们通过眼睛看到的信息是一致的。
#### 开发实例
例如，当前展示的网页书签被托起时，会播报"华为专区已托起"，移动的过程中，根据即将放置的位置播报"移动到华为手机服务|华为官网上面"。应用可调用主动播报的接口来进行主动播报。
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/ad/v3/tIlF1kVCQAKr8bAFLHeoLw/zh-cn_image_0000002659099335.png?HW-CC-KV=V1&HW-CC-Date=20260701T104518Z&HW-CC-Expire=86400&HW-CC-Sign=40E66F3212D97CF4B51E469BF9B4FF3FB061359DAC62DB33639597666CDCA47D)
```
import { accessibility } from '@kit.AccessibilityKit'
@Entry
@Component
export struct Rule_2_1_11 {
  title: string = 'Rule 2.1.11';
  eventInfo: accessibility.EventInfo = ({
    type: 'announceForAccessibility',
    bundleName: 'com.samples.uiextensionandaccessibility',
    triggerAction: 'common',
    textAnnouncedForAccessibility: '移动到华为手机服务|华为官网上面'
  });
  build() {
    NavDestination() {
      Column() {
        Blank()
        Button('button')
          .accessibilityText('主动播报')
          .align(Alignment.Center)
          .fontSize(20)
          .id('button1')
          .onClick(() => {
            accessibility.sendAccessibilityEvent(this.eventInfo).then(() => {
              console.info(`Succeeded in send event, eventInfo is ${JSON.stringify(this.eventInfo)}`);
            });
          })
        Blank()
      }
      .width('100%')
      .height('100%')
    }
    .title(this.title)
  }
}
```