// 基础按钮标注示例
// 本示例展示如何为Image组件设置无障碍标注

import { AccessibilityRoleType } from '@kit.ArkUI';

@Entry
@Component
struct BasicButtonAnnotation {
  build() {
    NavDestination() {
      Column() {
        // 示例1: 图片播放按钮标注
        Text('示例1: 图片播放按钮')
          .fontSize(16)
          .margin({ bottom: 10 })
        
        Image($r('sys.media.ohos_ic_public_play'))
          .width(50)
          .height(50)
          .onClick(() => {
            console.info('播放按钮被点击');
          })
          .accessibilityLevel('yes')  // 设置无障碍重要性为可识别
          .accessibilityRole(AccessibilityRoleType.BUTTON)  // 设置为按钮类型
          .accessibilityText('播放')  // 设置标注文本
        
        Divider()
          .margin({ top: 20, bottom: 20 })
        
        // 示例2: 图片暂停按钮标注
        Text('示例2: 图片暂停按钮')
          .fontSize(16)
          .margin({ bottom: 10 })
        
        Image($r('sys.media.ohos_ic_public_pause'))
          .width(50)
          .height(50)
          .onClick(() => {
            console.info('暂停按钮被点击');
          })
          .accessibilityLevel('yes')
          .accessibilityRole(AccessibilityRoleType.BUTTON)
          .accessibilityText('暂停')
        
        Divider()
          .margin({ top: 20, bottom: 20 })
        
        // 示例3: 图片设置按钮标注
        Text('示例3: 图片设置按钮')
          .fontSize(16)
          .margin({ bottom: 10 })
        
        Image($r('sys.media.ohos_ic_public_settings'))
          .width(50)
          .height(50)
          .onClick(() => {
            console.info('设置按钮被点击');
          })
          .accessibilityLevel('yes')
          .accessibilityRole(AccessibilityRoleType.BUTTON)
          .accessibilityText('设置')
        
        Divider()
          .margin({ top: 20, bottom: 20 })
        
        // 示例4: 图片删除按钮标注
        Text('示例4: 图片删除按钮')
          .fontSize(16)
          .margin({ bottom: 10 })
        
        Image($r('sys.media.ohos_ic_public_delete'))
          .width(50)
          .height(50)
          .onClick(() => {
            console.info('删除按钮被点击');
          })
          .accessibilityLevel('yes')
          .accessibilityRole(AccessibilityRoleType.BUTTON)
          .accessibilityText('删除')
      }
      .width('100%')
      .padding(20)
    }
    .title('基础按钮标注示例')
  }
}