import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

class SeniorModeManager {
  private isListening: boolean = false;
  private callBack: (data: boolean) => void;
  private queryInterval: number = -1;
  private onModeChange: (isEnabled: boolean) => void;

  constructor(onModeChange: (isEnabled: boolean) => void) {
    this.onModeChange = onModeChange;
    this.callBack = (data: boolean) => {
      this.handleModeChange(data);
    };
  }

  async initialize(): Promise<void> {
    try {
      accessibility.onSeniorModeStateChange(this.callBack);
      this.isListening = true;
      console.info('关怀模式监听注册成功');
    } catch (error) {
      const err = error as BusinessError;
      console.warn(`监听注册失败: ${err.message}, 降级为定时查询方式`);
      this.isListening = false;
      this.startPeriodicQuery();
    }
  }

  private startPeriodicQuery(): void {
    this.queryInterval = setInterval(async () => {
      try {
        const isEnabled = await accessibility.isSeniorModeEnabled();
        this.handleModeChange(isEnabled);
      } catch (error) {
        const err = error as BusinessError;
        console.error(`定时查询失败: ${err.message}`);
      }
    }, 5000);
    console.info('降级定时查询已启动，查询间隔5秒');
  }

  private handleModeChange(isEnabled: boolean): void {
    console.info(`关怀模式状态更新: ${isEnabled ? '已开启' : '已关闭'}`);
    this.onModeChange(isEnabled);
  }

  async queryCurrentStatus(): Promise<boolean> {
    try {
      const isEnabled = await accessibility.isSeniorModeEnabled();
      console.info(`当前关怀模式状态: ${isEnabled}`);
      return isEnabled;
    } catch (error) {
      const err = error as BusinessError;
      console.error(`查询失败: ${err.message}`);
      return false;
    }
  }

  cleanup(): void {
    if (this.isListening) {
      accessibility.offSeniorModeStateChange(this.callBack);
      console.info('关怀模式监听已注销');
    }
    if (this.queryInterval !== -1) {
      clearInterval(this.queryInterval);
      console.info('定时查询已停止');
    }
  }
}

@Entry
@Component
struct SeniorModeManagerExample {
  @State seniorModeStatus: string = '初始化中...';
  @State isEnabled: boolean = false;
  private manager: SeniorModeManager | null = null;

  aboutToAppear(): void {
    this.manager = new SeniorModeManager((isEnabled: boolean) => {
      this.isEnabled = isEnabled;
      this.seniorModeStatus = isEnabled ? '系统关怀模式已开启' : '系统关怀模式已关闭';
    });
    this.manager.initialize();
  }

  aboutToDisappear(): void {
    if (this.manager) {
      this.manager.cleanup();
    }
  }

  build() {
    Column() {
      Text('关怀模式综合管理示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 });

      Text(`状态: ${this.seniorModeStatus}`)
        .fontSize(18)
        .margin({ bottom: 10 });

      Button('查询当前状态')
        .onClick(async () => {
          if (this.manager) {
            const status = await this.manager.queryCurrentStatus();
            this.isEnabled = status;
          }
        })
        .margin({ top: 20 });

      if (this.isEnabled) {
        Column() {
          Text('关怀模式已开启')
            .fontSize(16)
            .fontColor('#FF0000');
          Text('应用应调整界面为长辈友好模式')
            .fontSize(14)
            .margin({ top: 5 });
        }
        .margin({ top: 10 });
      } else {
        Column() {
          Text('关怀模式未开启')
            .fontSize(16)
            .fontColor('#00FF00');
          Text('应用应使用标准界面模式')
            .fontSize(14)
            .margin({ top: 5 });
        }
        .margin({ top: 10 });
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}