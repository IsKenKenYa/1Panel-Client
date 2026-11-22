import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ResourceAnnounceExample {
  @State status: string = '准备中';
  
  async announceWithResource(): Promise<void> {
    try {
      const eventInfo: accessibility.EventInfo = {
        type: 'announceForAccessibility',
        bundleName: 'com.example.myapp',
        triggerAction: 'common',
        textResourceAnnouncedForAccessibility: $r('app.string.update_success')
      };
      
      await accessibility.sendAccessibilityEvent(eventInfo);
      console.info(`Succeeded in sending accessibility event with Resource`);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to send accessibility event, Code: ${err.code}, Message: ${err.message}`);
    }
  }
  
  build() {
    Column() {
      Text(this.status)
        .fontSize(20)
        .margin(20)
      
      Button('更新状态')
        .onClick(() => {
          this.status = '已完成';
          this.announceWithResource();
        })
        .margin(10)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}