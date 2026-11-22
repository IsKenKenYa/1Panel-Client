/**
 * 关怀模式状态同步示例
 * 
 * 本示例展示如何实现应用内关怀模式与系统设置的双向同步
 * 
 * API版本：26.0.0+
 */

import { accessibility } from '@kit.AccessibilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct SeniorModeSyncDemo {
  @State seniorModeState: boolean = false;
  @State syncStatus: string = '未同步';
  @State lastUpdateTime: string = '';
  
  private modeStateCallback = (data: boolean) => {
    console.info(`[SyncDemo] Senior mode state changed: ${data}`);
    this.seniorModeState = data;
    this.updateSyncStatus('已同步', new Date().toLocaleTimeString());
    this.applySeniorModeUI();
  }
  
  async aboutToAppear(): Promise<void> {
    console.info('[SyncDemo] aboutToAppear - Initialize senior mode sync');
    await this.initializeSeniorModeSync();
  }
  
  aboutToDisappear(): void {
    console.info('[SyncDemo] aboutToDisappear - Cleanup senior mode sync');
    this.cleanupSeniorModeSync();
  }
  
  private async initializeSeniorModeSync(): Promise<void> {
    try {
      const initialState = await accessibility.getSeniorModeStateForSelf();
      this.seniorModeState = initialState;
      this.updateSyncStatus('初始同步完成', new Date().toLocaleTimeString());
      
      accessibility.onSeniorModeStateChangeForSelf(this.modeStateCallback);
      console.info('[SyncDemo] Registered senior mode state listener');
      
      this.applySeniorModeUI();
      
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[SyncDemo] Initialize failed: Code ${error.code}, Message ${error.message}`);
      this.updateSyncStatus('初始化失败', '');
    }
  }
  
  private cleanupSeniorModeSync(): void {
    accessibility.offSeniorModeStateChangeForSelf(this.modeStateCallback);
    console.info('[SyncDemo] Unregistered senior mode state listener');
  }
  
  private updateSyncStatus(status: string, time: string): void {
    this.syncStatus = status;
    this.lastUpdateTime = time;
  }
  
  private applySeniorModeUI(): void {
    if (this.seniorModeState) {
      console.info('[SyncDemo] Applying senior mode UI styles');
    } else {
      console.info('[SyncDemo] Applying normal UI styles');
    }
  }
  
  private async toggleSeniorMode(isOn: boolean): Promise<void> {
    console.info(`[SyncDemo] Toggle senior mode to: ${isOn}`);
    
    try {
      await accessibility.setSeniorModeStateForSelf(isOn);
      this.seniorModeState = isOn;
      this.updateSyncStatus('手动同步完成', new Date().toLocaleTimeString());
      this.applySeniorModeUI();
      
      console.info('[SyncDemo] Senior mode state synced successfully');
      
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[SyncDemo] Toggle failed: Code ${error.code}, Message ${error.message}`);
      this.updateSyncStatus('同步失败', '');
      
      this.seniorModeState = !isOn;
    }
  }
  
  build() {
    Column() {
      Column() {
        Text('关怀模式同步示例')
          .fontSize(this.seniorModeState ? 28 : 20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 30, bottom: 20 })
        
        Divider()
          .margin({ bottom: 20 })
        
        Row() {
          Text('关怀模式')
            .fontSize(this.seniorModeState ? 24 : 16)
            .fontWeight(FontWeight.Medium)
          
          Blank()
          
          Toggle({ type: ToggleType.Switch, isOn: this.seniorModeState })
            .selectedColor('#007DFF')
            .onChange(async (isOn: boolean) => {
              console.info(`[SyncDemo] User toggled to: ${isOn}`);
              await this.toggleSeniorMode(isOn);
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
        .margin({ bottom: 20 })
        
        Column() {
          Text(`状态: ${this.seniorModeState ? '已开启' : '已关闭'}`)
            .fontSize(this.seniorModeState ? 22 : 14)
            .fontColor(this.seniorModeState ? '#007DFF' : '#666666')
            .margin({ bottom: 10 })
          
          Text(`同步状态: ${this.syncStatus}`)
            .fontSize(this.seniorModeState ? 20 : 12)
            .fontColor('#999999')
            .margin({ bottom: 5 })
          
          if (this.lastUpdateTime) {
            Text(`更新时间: ${this.lastUpdateTime}`)
              .fontSize(this.seniorModeState ? 18 : 10)
              .fontColor('#999999')
          }
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .margin({ bottom: 30 })
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      
      Column() {
        Text('同步机制说明')
          .fontSize(this.seniorModeState ? 24 : 16)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 15 })
        
        Column() {
          this.InfoItem('双向同步', '应用内开关会同步到系统设置，系统设置变化也会同步到应用')
          this.InfoItem('实时监听', '通过监听机制确保状态实时同步，无需手动刷新')
          this.InfoItem('状态一致性', '应用启动时自动同步初始状态，确保一致性')
          this.InfoItem('错误处理', '同步失败时自动回滚状态，并提供错误提示')
        }
        .width('100%')
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ bottom: 30 })
      
      Column() {
        Text('使用场景')
          .fontSize(this.seniorModeState ? 24 : 16)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 15 })
        
        Column() {
          this.ScenarioItem('长辈关怀应用', '为长辈提供简化、放大界面的关怀模式')
          this.ScenarioItem('无障碍应用', '为视力障碍用户提供无障碍体验')
          this.ScenarioItem('大字版应用', '应用提供大字版界面选项')
          this.ScenarioItem('关爱版应用', '应用提供关爱版功能')
        }
        .width('100%')
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.seniorModeState ? '#FFF9F0' : '#F0F0F0')
    .padding(15)
  }
  
  @Builder
  InfoItem(title: string, description: string) {
    Row() {
      Column() {
        Text(title)
          .fontSize(this.seniorModeState ? 20 : 14)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 5 })
        
        Text(description)
          .fontSize(this.seniorModeState ? 18 : 12)
          .fontColor('#666666')
      }
      .align(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .border({ width: { bottom: 1 }, color: '#E5E5E5' })
  }
  
  @Builder
  ScenarioItem(title: string, description: string) {
    Row() {
      Column() {
        Text(title)
          .fontSize(this.seniorModeState ? 20 : 14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#007DFF')
          .margin({ bottom: 5 })
        
        Text(description)
          .fontSize(this.seniorModeState ? 18 : 12)
          .fontColor('#666666')
      }
      .align(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .border({ width: { bottom: 1 }, color: '#E5E5E5' })
  }
}