import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct SeniorModeQueryExample {
  @State seniorModeStatus: string = '查询中...';
  @State isEnabled: boolean = false;

  aboutToAppear(): void {
    this.querySeniorModeStatus();
  }

  async querySeniorModeStatus(): Promise<void> {
    try {
      const data: boolean = await accessibility.isSeniorModeEnabled();
      this.isEnabled = data;
      this.seniorModeStatus = data ? '系统关怀模式已开启' : '系统关怀模式未开启';
      console.info(`success data:isSeniorModeEnabled : ${JSON.stringify(data)}`);
    } catch (error) {
      const err = error as BusinessError;
      this.seniorModeStatus = `查询失败: ${err.message}`;
      console.error(`failed to call isSeniorModeEnabled, Code is ${err.code}, message is ${err.message}`);
    }
  }

  build() {
    Column() {
      Text('关怀模式状态查询示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 });

      Text(`状态: ${this.seniorModeStatus}`)
        .fontSize(18)
        .margin({ bottom: 10 });

      Button('重新查询')
        .onClick(() => {
          this.querySeniorModeStatus();
        })
        .margin({ top: 20 });

      if (this.isEnabled) {
        Text('应用应开启关怀模式功能')
          .fontSize(16)
          .fontColor('#FF0000')
          .margin({ top: 10 });
      } else {
        Text('应用应关闭关怀模式功能')
          .fontSize(16)
          .fontColor('#00FF00')
          .margin({ top: 10 });
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}