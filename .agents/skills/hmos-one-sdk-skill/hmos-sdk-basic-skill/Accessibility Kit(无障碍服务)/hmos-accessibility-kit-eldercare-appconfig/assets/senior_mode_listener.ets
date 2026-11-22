/**
 * 关怀模式状态监听示例
 * 
 * 本示例展示如何监听系统关怀模式状态变化
 * 以及监听应用关怀模式状态变化
 * 
 * API版本：26.0.0+
 */

import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct SeniorModeListenerDemo {
  @State systemSeniorModeState: boolean = false;
  @State appSeniorModeState: boolean = false;
  
  private systemModeCallback = (data: boolean) => {
    console.info(`[SeniorMode] System senior mode state changed: ${data}`);
    this.systemSeniorModeState = data;
    this.updateAppUI();
  }
  
  private appModeCallback = (data: boolean) => {
    console.info(`[SeniorMode] App senior mode state changed: ${data}`);
    this.appSeniorModeState = data;
    this.updateAppUI();
  }
  
  aboutToAppear(): void {
    console.info('[SeniorMode] aboutToAppear - Initialize senior mode listener');
    this.initSeniorModeListener();
  }
  
  aboutToDisappear(): void {
    console.info('[SeniorMode] aboutToDisappear - Cleanup senior mode listener');
    this.cleanupSeniorModeListener();
  }
  
  private async initSeniorModeListener(): void {
    try {
      const systemState = await accessibility.isSeniorModeEnabled();
      this.systemSeniorModeState = systemState;
      console.info(`[SeniorMode] Initial system state: ${systemState}`);
      
      accessibility.onSeniorModeStateChange(this.systemModeCallback);
      console.info('[SeniorMode] System mode listener registered');
      
      const appState = await accessibility.getSeniorModeStateForSelf();
      this.appSeniorModeState = appState;
      console.info(`[SeniorMode] Initial app state: ${appState}`);
      
      accessibility.onSeniorModeStateChangeForSelf(this.appModeCallback);
      console.info('[SeniorMode] App mode listener registered');
      
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[SeniorMode] Init failed: Code ${error.code}, Message ${error.message}`);
    }
  }
  
  private cleanupSeniorModeListener(): void {
    accessibility.offSeniorModeStateChange(this.systemModeCallback);
    console.info('[SeniorMode] System mode listener unregistered');
    
    accessibility.offSeniorModeStateChangeForSelf(this.appModeCallback);
    console.info('[SeniorMode] App mode listener unregistered');
  }
  
  private updateAppUI(): void {
    console.info('[SeniorMode] Updating app UI based on senior mode state');
    
    if (this.systemSeniorModeState) {
      this.applySeniorModeStyles();
    } else {
      this.applyNormalStyles();
    }
  }
  
  private applySeniorModeStyles(): void {
    console.info('[SeniorMode] Applying senior mode styles');
  }
  
  private applyNormalStyles(): void {
    console.info('[SeniorMode] Applying normal styles');
  }
  
  build() {
    Column() {
      Text('关怀模式状态监听示例')
        .fontSize(this.systemSeniorModeState ? 24 : 16)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })
      
      Divider()
        .margin({ bottom: 20 })
      
      Column() {
        Text('系统关怀模式状态')
          .fontSize(this.systemSeniorModeState ? 22 : 14)
          .margin({ bottom: 10 })
        
        Row() {
          Text(`状态: ${this.systemSeniorModeState ? '已开启' : '已关闭'}`)
            .fontSize(this.systemSeniorModeState ? 20 : 12)
          
          Toggle({ type: ToggleType.Switch, isOn: this.systemSeniorModeState })
            .enabled(false)
            .margin({ left: 10 })
        }
        .margin({ bottom: 20 })
        
        Divider()
          .margin({ bottom: 20 })
        
        Text('应用关怀模式状态')
          .fontSize(this.systemSeniorModeState ? 22 : 14)
          .margin({ bottom: 10 })
        
        Row() {
          Text(`状态: ${this.appSeniorModeState ? '已开启' : '已关闭'}`)
            .fontSize(this.systemSeniorModeState ? 20 : 12)
          
          Toggle({ type: ToggleType.Switch, isOn: this.appSeniorModeState })
            .onChange(async (isOn: boolean) => {
              console.info(`[SeniorMode] App toggle changed to: ${isOn}`);
              await this.setAppSeniorMode(isOn);
            })
            .margin({ left: 10 })
        }
        .margin({ bottom: 20 })
      }
      .width('100%')
      .padding(20)
      
      Divider()
        .margin({ bottom: 20 })
      
      Column() {
        Text('使用说明')
          .fontSize(this.systemSeniorModeState ? 20 : 14)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
        
        Text('1. 系统关怀模式状态由系统设置控制，不可在此修改')
          .fontSize(this.systemSeniorModeState ? 18 : 12)
          .margin({ bottom: 5 })
        
        Text('2. 应用关怀模式开关会同步到系统设置')
          .fontSize(this.systemSeniorModeState ? 18 : 12)
          .margin({ bottom: 5 })
        
        Text('3. 监听机制确保状态实时同步')
          .fontSize(this.systemSeniorModeState ? 18 : 12)
          .margin({ bottom: 5 })
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#F0F0F0')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.systemSeniorModeState ? '#FFF5E6' : '#FFFFFF')
  }
  
  private async setAppSeniorMode(state: boolean): void {
    try {
      await accessibility.setSeniorModeStateForSelf(state);
      this.appSeniorModeState = state;
      console.info(`[SeniorMode] App senior mode set to: ${state}`);
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[SeniorMode] Set app mode failed: Code ${error.code}, Message ${error.message}`);
    }
  }
}