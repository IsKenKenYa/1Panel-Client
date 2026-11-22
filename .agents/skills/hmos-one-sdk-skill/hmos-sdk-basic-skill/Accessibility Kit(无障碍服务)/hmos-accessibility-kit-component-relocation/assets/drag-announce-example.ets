import { accessibility } from '@kit.AccessibilityKit';

class DragAccessibilityHelper {
  private bundleName: string = 'com.samples.uiextensionandaccessibility';
  private lastAnnounceTime: number = 0;
  private announceCount: number = 0;
  private readonly MAX_FREQUENCY: number = 5;
  private readonly MIN_INTERVAL: number = 200;
  
  async announceDragStart(componentName: string): Promise<boolean> {
    const text = `${componentName}已托起`;
    return await this.safeAnnounce(text);
  }
  
  async announceDragMove(position: string): Promise<boolean> {
    const text = `移动到${position}`;
    return await this.safeAnnounce(text);
  }
  
  async announceDragEnd(finalPosition: string): Promise<boolean> {
    const text = `已放置到${finalPosition}`;
    return await this.safeAnnounce(text);
  }
  
  private async safeAnnounce(text: string): Promise<boolean> {
    if (!this.checkFrequency()) {
      console.warn('[DragAccessibility] 调用频次超限，跳过播报');
      return false;
    }
    
    if (!text || text.trim().length === 0) {
      console.warn('[DragAccessibility] 播报文本为空');
      return false;
    }
    
    if (text.length > 100) {
      text = text.substring(0, 100);
      console.warn('[DragAccessibility] 文本过长，已截断');
    }
    
    const eventInfo: accessibility.EventInfo = {
      type: 'announceForAccessibility',
      bundleName: this.bundleName,
      triggerAction: 'common',
      textAnnouncedForAccessibility: text
    };
    
    try {
      await accessibility.sendAccessibilityEvent(eventInfo);
      console.info(`[DragAccessibility] 播报成功: ${text}`);
      this.updateAnnounceTime();
      return true;
    } catch (error) {
      console.error('[DragAccessibility] 播报失败:', error.message);
      return false;
    }
  }
  
  private checkFrequency(): boolean {
    const now = Date.now();
    const elapsed = now - this.lastAnnounceTime;
    
    if (elapsed < this.MIN_INTERVAL) {
      this.announceCount++;
      if (this.announceCount >= this.MAX_FREQUENCY) {
        return false;
      }
    } else {
      this.announceCount = 1;
    }
    
    return true;
  }
  
  private updateAnnounceTime(): void {
    this.lastAnnounceTime = Date.now();
  }
}

@Entry
@Component
struct DragAnnounceExample {
  private dragHelper: DragAccessibilityHelper = new DragAccessibilityHelper();
  private offsetX: number = 0;
  private offsetY: number = 0;
  private targetPosition: string = '目标区域';
  
  build() {
    NavDestination() {
      Column() {
        Text('拖拽无障碍播报示例')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 20 })
        
        Button('可拖拽按钮')
          .width(150)
          .height(60)
          .accessibilityText('拖拽测试按钮')
          .fontSize(18)
          .backgroundColor('#007DFF')
          .gesture(
            GestureGroup(GestureMode.Parallel,
              PanGesture({ fingers: 1 })
                .onActionStart(() => {
                  this.dragHelper.announceDragStart('测试按钮');
                  console.info('[Drag] 开始拖拽');
                })
                .onActionUpdate((event: GestureEvent) => {
                  this.offsetX = event.offsetX;
                  this.offsetY = event.offsetY;
                  const position = this.calculateRelativePosition();
                  this.dragHelper.announceDragMove(position);
                })
                .onActionEnd(() => {
                  const finalPosition = this.calculateFinalPosition();
                  this.dragHelper.announceDragEnd(finalPosition);
                  console.info(`[Drag] 结束拖拽，最终位置: ${finalPosition}`);
                })
            )
          )
        
        Text(`当前位置: X=${this.offsetX.toFixed(0)}, Y=${this.offsetY.toFixed(0)}`)
          .fontSize(16)
          .margin({ top: 30 })
          .accessibilityText(`当前位置偏移: 横向${this.offsetX.toFixed(0)}像素，纵向${this.offsetY.toFixed(0)}像素`)
        
        Divider()
          .margin({ top: 20, bottom: 20 })
        
        Text('使用说明')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        
        Text('1. 拖拽开始时播报"测试按钮已托起"')
          .fontSize(14)
          .margin({ top: 10 })
        
        Text('2. 拖拽移动时播报相对位置信息')
          .fontSize(14)
          .margin({ top: 5 })
        
        Text('3. 拖拽结束时播报最终放置位置')
          .fontSize(14)
          .margin({ top: 5 })
        
        Text('4. 新播报会自动打断旧播报')
          .fontSize(14)
          .margin({ top: 5 })
        
        Text('5. 调用频次限制: 每秒最多5次')
          .fontSize(14)
          .margin({ top: 5 })
      }
      .width('100%')
      .height('100%')
      .padding(20)
    }
    .title('控件位置调整播报')
  }
  
  private calculateRelativePosition(): string {
    const threshold = 50;
    
    if (this.offsetY < -threshold) {
      return `${this.targetPosition}上方`;
    } else if (this.offsetY > threshold) {
      return `${this.targetPosition}下方`;
    } else if (this.offsetX < -threshold) {
      return `${this.targetPosition}左侧`;
    } else if (this.offsetX > threshold) {
      return `${this.targetPosition}右侧`;
    } else {
      return `${this.targetPosition}中心位置`;
    }
  }
  
  private calculateFinalPosition(): string {
    const quadrantThreshold = 100;
    
    if (Math.abs(this.offsetX) < quadrantThreshold && Math.abs(this.offsetY) < quadrantThreshold) {
      return `${this.targetPosition}中心区域`;
    } else if (this.offsetY < -quadrantThreshold) {
      if (this.offsetX < -quadrantThreshold) {
        return `${this.targetPosition}左上角`;
      } else if (this.offsetX > quadrantThreshold) {
        return `${this.targetPosition}右上角`;
      } else {
        return `${this.targetPosition}上方区域`;
      }
    } else if (this.offsetY > quadrantThreshold) {
      if (this.offsetX < -quadrantThreshold) {
        return `${this.targetPosition}左下角`;
      } else if (this.offsetX > quadrantThreshold) {
        return `${this.targetPosition}右下角`;
      } else {
        return `${this.targetPosition}下方区域`;
      }
    } else {
      if (this.offsetX < -quadrantThreshold) {
        return `${this.targetPosition}左侧区域`;
      } else {
        return `${this.targetPosition}右侧区域`;
      }
    }
  }
}

export { DragAccessibilityHelper, DragAnnounceExample };