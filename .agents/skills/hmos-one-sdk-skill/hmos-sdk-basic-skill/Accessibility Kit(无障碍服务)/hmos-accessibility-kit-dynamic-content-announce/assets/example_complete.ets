import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct CompleteExample {
  @State dataCount: number = 0;
  @State lastUpdateTime: string = '';
  
  async announceUpdate(message: string): Promise<void> {
    try {
      const eventInfo: accessibility.EventInfo = {
        type: 'announceForAccessibility',
        bundleName: 'com.samples.uiextensionandaccessibility',
        triggerAction: 'common',
        textAnnouncedForAccessibility: message
      };
      
      await accessibility.sendAccessibilityEvent(eventInfo);
      console.info(`Succeeded in send event, eventInfo is: ${JSON.stringify(eventInfo)}`);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to send event, Code: ${err.code}, Message: ${err.message}`);
    }
  }
  
  refreshData() {
    this.dataCount += 1;
    this.lastUpdateTime = new Date().toLocaleTimeString();
    this.announceUpdate(`数据已刷新，当前共${this.dataCount}条记录`);
  }
  
  build() {
    NavDestination() {
      Column() {
        Blank()
        
        Text(`数据条数: ${this.dataCount}`)
          .fontSize(20)
          .margin(10)
        
        Text(`最后更新: ${this.lastUpdateTime}`)
          .fontSize(16)
          .margin(10)
        
        Button('刷新数据')
          .accessibilityText('刷新数据并播报')
          .fontSize(18)
          .margin(20)
          .onClick(() => {
            this.refreshData();
          })
        
        Blank()
      }
      .width('100%')
      .height('100%')
    }
    .title('内容动态变化示例')
  }
}