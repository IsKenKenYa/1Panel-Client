import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct DynamicContentAnnouncementExample {
  @State message: string = '初始内容';
  @State updateCount: number = 0;

  async announceContentChange(content: string): Promise<void> {
    const eventInfo: accessibility.EventInfo = {
      type: 'announceForAccessibility',
      bundleName: 'com.example.myapp',
      triggerAction: 'common',
      textAnnouncedForAccessibility: content,
    };

    try {
      await accessibility.sendAccessibilityEvent(eventInfo);
      console.info(`播报成功: ${content}`);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`播报失败: Code=${err.code}, Message=${err.message}`);
      throw err;
    }
  }

  build() {
    Column({ space: 20 }) {
      Text(this.message)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 50 })

      Text(`更新次数: ${this.updateCount}`)
        .fontSize(16)

      Button('更新内容并播报')
        .width('80%')
        .onClick(async () => {
          this.updateCount++;
          const newMessage = `内容已更新 ${this.updateCount} 次`;
          this.message = newMessage;

          try {
            await this.announceContentChange(newMessage);
          } catch (error) {
            console.error('播报失败，降级处理:', error);
          }
        })

      Button('仅播报消息')
        .width('80%')
        .onClick(async () => {
          const notification = '这是一条重要通知';
          try {
            await this.announceContentChange(notification);
          } catch (error) {
            console.error('播报失败:', error);
          }
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}