import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ResourceAnnouncementExample {
  @State statusText: string = '订单状态：待处理';

  announceWithResource(): void {
    const eventInfo: accessibility.EventInfo = {
      type: 'announceForAccessibility',
      bundleName: 'com.example.myapp',
      triggerAction: 'common',
      textResourceAnnouncedForAccessibility: $r('app.string.update_message'),
    };

    accessibility.sendAccessibilityEvent(eventInfo, (err: BusinessError) => {
      if (err) {
        console.error(`Resource播报失败: Code=${err.code}, Message=${err.message}`);
        return;
      }
      console.info('Resource播报成功');
    });
  }

  announceOrderStatusChange(newStatus: string): void {
    const statusMessage = `订单状态已更新为：${newStatus}`;
    
    const eventInfo: accessibility.EventInfo = {
      type: 'announceForAccessibility',
      bundleName: 'com.example.myapp',
      triggerAction: 'common',
      textAnnouncedForAccessibility: statusMessage,
    };

    accessibility.sendAccessibilityEvent(eventInfo, (err: BusinessError) => {
      if (err) {
        console.error(`订单状态播报失败: Code=${err.code}, Message=${err.message}`);
        return;
      }
      console.info(`订单状态播报成功: ${statusMessage}`);
    });
  }

  build() {
    Column({ space: 20 }) {
      Text(this.statusText)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 50 })

      Button('更新订单状态')
        .width('80%')
        .onClick(() => {
          const newStatus = '已发货';
          this.statusText = `订单状态：${newStatus}`;
          this.announceOrderStatusChange(newStatus);
        })

      Button('使用Resource播报')
        .width('80%')
        .onClick(() => {
          this.announceWithResource();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}