/**
 * 完整的关怀模式状态管理示例
 * API Version: 26.0.0+
 * 功能：查询状态 + 监听状态变化 + 降级处理
 */

import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

class SeniorModeManager {
  private isMonitoring: boolean = false;
  private queryInterval: number = 5000;
  private intervalId: number = -1;
  private lastStatus: boolean = false;

  private handleStateChange = (isEnabled: boolean): void => {
    console.info(`Senior mode state changed: ${isEnabled}`);
    if (this.lastStatus !== isEnabled) {
      this.lastStatus = isEnabled;
      this.updateAppMode(isEnabled);
    }
  };

  startMonitoring(): void {
    try {
      accessibility.onSeniorModeStateChange(this.handleStateChange);
      this.isMonitoring = true;
      console.info('Successfully registered senior mode state change listener');
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to register listener, Code: ${err.code}, Message: ${err.message}`);
      this.startPeriodicQuery();
    }
  }

  stopMonitoring(): void {
    if (this.isMonitoring) {
      accessibility.offSeniorModeStateChange(this.handleStateChange);
      this.isMonitoring = false;
    }
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId);
      this.intervalId = -1;
    }
  }

  async queryStatus(): Promise<boolean> {
    try {
      const isEnabled = await accessibility.isSeniorModeEnabled();
      console.info(`Query result: ${isEnabled}`);
      return isEnabled;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Query failed: ${err.code}, ${err.message}`);
      return false;
    }
  }

  private startPeriodicQuery(): void {
    console.warn('Fallback to periodic query mode');
    this.intervalId = setInterval(async () => {
      try {
        const isEnabled = await this.queryStatus();
        if (this.lastStatus !== isEnabled) {
          this.lastStatus = isEnabled;
          this.updateAppMode(isEnabled);
        }
      } catch (error) {
        console.error('Periodic query failed');
      }
    }, this.queryInterval);
  }

  private updateAppMode(isEnabled: boolean): void {
    console.info(`Update app mode: ${isEnabled ? 'enabled' : 'disabled'}`);
  }
}

@Entry
@Component
struct SeniorModeCompleteDemo {
  @State isSeniorModeEnabled: boolean = false;
  @State mode: string = 'default';
  @State statusText: string = '初始化中...';

  private seniorModeManager: SeniorModeManager = new SeniorModeManager();

  aboutToAppear(): void {
    this.initSeniorMode();
  }

  aboutToDisappear(): void {
    this.seniorModeManager.stopMonitoring();
  }

  private async initSeniorMode(): void {
    const status = await this.seniorModeManager.queryStatus();
    this.isSeniorModeEnabled = status;
    this.updateModeText();

    this.seniorModeManager.startMonitoring();
  }

  private updateModeText(): void {
    if (this.isSeniorModeEnabled) {
      this.mode = '关怀模式';
      this.statusText = '系统关怀模式已开启，应用已启用关怀模式';
    } else {
      this.mode = '标准模式';
      this.statusText = '系统关怀模式已关闭，应用使用标准模式';
    }
  }

  build() {
    Column() {
      Text('关怀模式状态管理')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin(20)

      Text(this.statusText)
        .fontSize(16)
        .margin(10)

      Divider()
        .margin(20)

      Row() {
        Text('当前模式:')
          .fontSize(18)
        Text(this.mode)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isSeniorModeEnabled ? Color.Green : Color.Blue)
          .margin({ left: 10 })
      }
      .margin(10)

      Button('重新查询状态')
        .onClick(async () => {
          const status = await this.seniorModeManager.queryStatus();
          this.isSeniorModeEnabled = status;
          this.updateModeText();
        })
        .margin(20)

      Text('说明：')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 })

      Text('1. 应用启动时自动查询系统关怀模式状态')
        .fontSize(14)
        .margin(5)

      Text('2. 应用运行期间监听系统关怀模式变化')
        .fontSize(14)
        .margin(5)

      Text('3. 如果监听失败，自动降级为定时查询')
        .fontSize(14)
        .margin(5)

      Text('4. 仅支持 API version 26.0.0 及以上')
        .fontSize(14)
        .fontColor(Color.Red)
        .margin(5)
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
}