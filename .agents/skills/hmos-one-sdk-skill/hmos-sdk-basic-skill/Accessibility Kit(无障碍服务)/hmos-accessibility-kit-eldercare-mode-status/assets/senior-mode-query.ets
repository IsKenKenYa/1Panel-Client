/**
 * 查询系统关怀模式状态示例
 * API Version: 26.0.0+
 */

import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct SeniorModeQueryDemo {
  @State isSeniorModeEnabled: boolean = false;
  @State queryStatus: string = '正在查询...';

  aboutToAppear(): void {
    this.querySeniorModeStatus();
  }

  private async querySeniorModeStatus(): void {
    try {
      const isEnabled: boolean = await accessibility.isSeniorModeEnabled();
      console.info(`success data:isSeniorModeEnabled : ${JSON.stringify(isEnabled)}`);
      this.isSeniorModeEnabled = isEnabled;
      this.queryStatus = '查询成功';
    } catch (error) {
      const err = error as BusinessError;
      console.error(`failed to call isSeniorModeEnabled, Code is ${err.code}, message is ${err.message}`);
      this.queryStatus = `查询失败: Code ${err.code}`;
      this.handleQueryError(err);
    }
  }

  private handleQueryError(err: BusinessError): void {
    switch (err.code) {
      case 9300003:
        this.queryStatus = '权限不足，请开启无障碍权限';
        break;
      case 9300006:
        this.queryStatus = '连接失败，请稍后重试';
        break;
      default:
        this.queryStatus = '未知错误，使用默认模式';
        break;
    }
  }

  build() {
    Column() {
      Text('查询关怀模式状态')
        .fontSize(20)
        .margin(20)

      Text(this.queryStatus)
        .fontSize(16)
        .margin(10)

      if (this.isSeniorModeEnabled) {
        Text('系统关怀模式已开启')
          .fontSize(24)
          .fontColor(Color.Green)
          .margin(10)
      } else {
        Text('系统关怀模式已关闭')
          .fontSize(24)
          .fontColor(Color.Red)
          .margin(10)
      }

      Button('重新查询')
        .onClick(() => {
          this.queryStatus = '正在查询...';
          this.querySeniorModeStatus();
        })
        .margin(20)
    }
    .width('100%')
    .height('100%')
  }
}