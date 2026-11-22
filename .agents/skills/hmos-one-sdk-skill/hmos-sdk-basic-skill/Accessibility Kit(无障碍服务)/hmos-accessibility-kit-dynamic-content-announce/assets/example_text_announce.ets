import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct TextAnnounceExample {
  @State message: string = '初始内容';
  
  async announceContentChange(content: string): Promise<void> {
    try {
      const eventInfo: accessibility.EventInfo = {
        type: 'announceForAccessibility',
        bundleName: 'com.example.myapp',
        triggerAction: 'common',
        textAnnouncedForAccessibility: content
      };
      
      await accessibility.sendAccessibilityEvent(eventInfo);
      console.info(`Succeeded in sending accessibility event`);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to send accessibility event, Code: ${err.code}, Message: ${err.message}`);
    }
  }
  
  build() {
    Column() {
      Text(this.message)
        .fontSize(20)
        .margin(20)
      
      Button('更新内容')
        .onClick(() => {
          this.message = '内容已更新';
          this.announceContentChange('内容已成功更新');
        })
        .margin(10)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}