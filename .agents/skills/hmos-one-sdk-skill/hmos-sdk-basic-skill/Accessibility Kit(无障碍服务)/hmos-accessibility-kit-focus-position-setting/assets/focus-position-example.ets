import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct FocusPositionExample {
  title: string = '焦点位置设置示例';
  
  eventInfo: accessibility.EventInfo = ({
    type: 'requestFocusForAccessibility',
    bundleName: 'com.samples.uiextensionandaccessibility',
    triggerAction: 'common',
    customId: 'button1'
  });
  
  build() {
    NavDestination() {
      Column() {
        Text('重新设置焦点位置示例')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 20 })
        
        Text('说明：当按钮被点击时，焦点会转移到另一个按钮')
          .fontSize(16)
          .margin({ bottom: 30 })
        
        Blank()
        
        Button('button1 - 点击聚焦到button2')
          .accessibilityText('第一个按钮，点击后会聚焦到第二个按钮')
          .align(Alignment.Center)
          .fontSize(20)
          .width('80%')
          .height(60)
          .id('button1')
          .onClick(() => {
            this.eventInfo.customId = 'button2';
            accessibility.sendAccessibilityEvent(this.eventInfo).then(() => {
              console.info(`Succeeded in send event, eventInfo is: ${JSON.stringify(this.eventInfo)}`);
            }).catch((err: BusinessError) => {
              console.error(`Failed to send event, Code is ${err.code}, message is ${err.message}`);
            });
          })
        
        Blank()
          .height(20)
        
        Button('button2 - 点击聚焦到button1')
          .accessibilityText('第二个按钮，点击后会聚焦到第一个按钮')
          .align(Alignment.Center)
          .fontSize(20)
          .width('80%')
          .height(60)
          .id('button2')
          .onClick(() => {
            this.eventInfo.customId = 'button1';
            accessibility.sendAccessibilityEvent(this.eventInfo).then(() => {
              console.info(`Succeeded in send event, eventInfo is: ${JSON.stringify(this.eventInfo)}`);
            }).catch((err: BusinessError) => {
              console.error(`Failed to send event, Code is ${err.code}, message is ${err.message}`);
            });
          })
        
        Blank()
        
        Divider()
          .margin({ top: 30, bottom: 20 })
        
        Text('高级用法示例')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })
        
        Button('检查无障碍服务状态')
          .onClick(() => {
            let status: boolean = accessibility.isOpenAccessibilitySync();
            console.info(`Accessibility status = ${status}`);
            if (!status) {
              console.info('Screen reader not enabled.');
            } else {
              console.info('Screen reader is enabled.');
            }
          })
          .width('80%')
          .height(50)
      }
      .width('100%')
      .height('100%')
    }
    .title(this.title)
  }
}