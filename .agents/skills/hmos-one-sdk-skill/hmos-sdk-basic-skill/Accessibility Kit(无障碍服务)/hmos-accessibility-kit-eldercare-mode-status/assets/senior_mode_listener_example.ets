import { accessibility } from '@kit.AccessibilityKit';

@Entry
@Component
struct SeniorModeListenerExample {
  @State seniorModeStatus: string = '监听中...';
  @State isEnabled: boolean = false;
  @State changeCount: number = 0;

  callBack = (data: boolean) => {
    this.isEnabled = data;
    this.changeCount++;
    this.seniorModeStatus = data ? '系统关怀模式已开启' : '系统关怀模式已关闭';
    console.info(`subscribe senior mode state change, result: ${JSON.stringify(data)}, change count: ${this.changeCount}`);
  };

  aboutToAppear(): void {
    accessibility.onSeniorModeStateChange(this.callBack);
    console.info('关怀模式监听已注册');
  }

  aboutToDisappear(): void {
    accessibility.offSeniorModeStateChange(this.callBack);
    console.info('关怀模式监听已注销');
  }

  build() {
    Column() {
      Text('关怀模式状态监听示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 });

      Text(`当前状态: ${this.seniorModeStatus}`)
        .fontSize(18)
        .margin({ bottom: 10 });

      Text(`变化次数: ${this.changeCount}`)
        .fontSize(16)
        .margin({ bottom: 10 });

      if (this.isEnabled) {
        Text('关怀模式已开启')
          .fontSize(16)
          .fontColor('#FF0000')
          .margin({ top: 10 });
      } else {
        Text('关怀模式未开启')
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