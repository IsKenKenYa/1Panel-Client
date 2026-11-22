/**
 * 监听系统关怀模式状态变化示例
 * API Version: 26.0.0+
 */

import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct SeniorModeListenerDemo {
  @State isSeniorModeEnabled: boolean = false;
  @State message: string = '监听关怀模式状态变化';

  private callBack = (data: boolean) => {
    console.info(`subscribe senior mode state change, result: ${JSON.stringify(data)}`);
    this.isSeniorModeEnabled = data;
    if (data) {
      this.message = '系统关怀模式已开启';
    } else {
      this.message = '系统关怀模式已关闭';
    }
  }

  aboutToAppear(): void {
    accessibility.onSeniorModeStateChange(this.callBack);
  }

  aboutToDisappear(): void {
    accessibility.offSeniorModeStateChange(this.callBack);
  }

  build() {
    Column() {
      Text(this.message)
        .fontSize(20)
        .margin(20)

      if (this.isSeniorModeEnabled) {
        Text('应用内关怀模式已启用')
          .fontSize(24)
          .fontColor(Color.Green)
          .margin(10)
      } else {
        Text('应用内关怀模式未启用')
          .fontSize(24)
          .fontColor(Color.Red)
          .margin(10)
      }
    }
    .width('100%')
    .height('100%')
  }
}