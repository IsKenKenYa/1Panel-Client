/**
 * 测试应用示例：包含触发丢帧的列表页面
 * 功能：演示如何在应用中触发滑动丢帧事件
 * 用途：配合滑动丢帧事件订阅测试
 */

import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct ScrollJankTestApp {
  private TAG = 'ScrollJankTest';
  private DOMAIN = 0x0000;
  
  // 测试数据数组
  private testData: number[] = Array.from({length: 100}, (_, i) => i);
  
  // 观察者对象
  private scrollJankWatcher: hiAppEvent.Watcher = {
    name: 'testAppWatcher',
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.SCROLL_JANK]
      }
    ],
    onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
      hilog.info(this.DOMAIN, this.TAG, `Test app received event: domain=${domain}`);
      
      for (const eventGroup of appEventGroups) {
        hilog.info(this.DOMAIN, this.TAG, `Event name=${eventGroup.name}`);
        
        for (const eventInfo of eventGroup.appEventInfos) {
          const params = eventInfo.params as Record<string, any>;
          const duration = params['duration'] as number;
          const missedFrames = params['total_app_missed_frames'] as number;
          
          hilog.warn(this.DOMAIN, this.TAG,
            `Test app detected jank: duration=${duration}ms, missed_frames=${missedFrames}`);
        }
      }
    }
  };

  aboutToAppear(): void {
    // 页面加载时添加观察者
    const holder = hiAppEvent.addWatcher(this.scrollJankWatcher);
    if (holder !== null) {
      hilog.info(this.DOMAIN, this.TAG, 'Test app watcher added successfully');
    } else {
      hilog.error(this.DOMAIN, this.TAG, 'Test app watcher failed to add');
    }
  }

  aboutToDisappear(): void {
    // 页面销毁时移除观察者
    hiAppEvent.removeWatcher(this.scrollJankWatcher);
    hilog.info(this.DOMAIN, this.TAG, 'Test app watcher removed');
  }

  build() {
    Column() {
      // 标题区域
      Row() {
        Text('Scroll Jank Test App')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width('100%')
      .height(60)
      .backgroundColor(0x007DFF)
      .justifyContent(FlexAlign.Center)
      
      // 说明文本
      Text('滚动列表以触发丢帧事件（系统会检测超过50ms的卡顿）')
        .fontSize(14)
        .fontColor(Color.Gray)
        .margin({top: 10, bottom: 10})
        .textAlign(TextAlign.Center)
      
      // 测试列表（滚动时触发丢帧）
      List({ space: 10 }) {
        ForEach(this.testData, (item: number) => {
          ListItem() {
            Row() {
              Text(`Item ${item}`)
                .fontSize(18)
                .fontColor(Color.White)
                .width('60%')
              
              Text(`${item * 10} ms`)
                .fontSize(16)
                .fontColor(Color.Yellow)
                .width('40%')
                .textAlign(TextAlign.End)
            }
            .width('100%')
            .height(80)
            .padding({left: 20, right: 20})
            .backgroundColor(this.getItemColor(item))
            .borderRadius(10)
            .justifyContent(FlexAlign.SpaceBetween)
          }
        }, (item: number) => item.toString())
      }
      .width('100%')
      .height('70%')
      .backgroundColor(0xF5F5F5)
      .onScrollIndex((firstIndex: number, lastIndex: number) => {
        // 滑动事件回调：模拟耗时操作触发丢帧
        hilog.info(this.DOMAIN, this.TAG,
          `Scrolling: first=${firstIndex}, last=${lastIndex}`);
        
        // 模拟耗时逻辑（触发丢帧）
        this.simulateHeavyWork(firstIndex);
      })
      
      // 操作按钮区域
      Row() {
        Button('清除数据')
          .fontSize(16)
          .width('45%')
          .onClick(() => {
            hiAppEvent.clearData();
            hilog.info(this.DOMAIN, this.TAG, 'Test app data cleared');
          })
        
        Button('查看统计')
          .fontSize(16)
          .width('45%')
          .onClick(() => {
            hilog.info(this.DOMAIN, this.TAG, 'Test app statistics: events captured');
          })
      }
      .width('100%')
      .height(60)
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({top: 10})
    }
    .width('100%')
    .height('100%')
    .backgroundColor(0xFFFFFF)
  }

  /**
   * 获取列表项颜色
   * @param index 列表项索引
   * @returns 背景颜色
   */
  private getItemColor(index: number): number {
    const colors = [
      0x007DFF, 0x00BCD4, 0x4CAF50, 0xFF9800, 0xE91E63,
      0x9C27B0, 0x673AB7, 0x3F51B5, 0x2196F3, 0x03A9F4
    ];
    return colors[index % colors.length];
  }

  /**
   * 模拟耗时操作（触发丢帧）
   * @param currentIndex 当前滚动索引
   */
  private simulateHeavyWork(currentIndex: number): void {
    // 根据索引动态调整耗时程度
    let workload = 10000;
    if (currentIndex % 10 === 0) {
      workload = 20000; // 每10个项增加一次重度耗时
    }
    
    let i = 1;
    const startTime = Date.now();
    while (i < workload) {
      // 模拟复杂计算（不要在实际应用中这样做）
      const temp = Math.sqrt(i) * Math.sin(i);
      i++;
    }
    const duration = Date.now() - startTime;
    
    if (duration > 20) {
      hilog.warn(this.DOMAIN, this.TAG,
        `Heavy work detected: duration=${duration}ms, index=${currentIndex}`);
    }
  }
}

/**
 * 轻量级测试应用（不包含耗时操作）
 * 用途：测试正常滑动场景，不触发丢帧
 */
@Entry
@Component
struct LightScrollTestApp {
  private lightData: string[] = [
    'Apple', 'Banana', 'Cherry', 'Date', 'Elderberry',
    'Fig', 'Grape', 'Honeydew', 'Kiwi', 'Lemon',
    'Mango', 'Nectarine', 'Orange', 'Papaya', 'Quince'
  ];

  build() {
    Column() {
      Text('Light Scroll Test (No Jank)')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({top: 20, bottom: 20})
      
      List({ space: 10 }) {
        ForEach(this.lightData, (item: string) => {
          ListItem() {
            Text(item)
              .fontSize(18)
              .fontColor(Color.Black)
              .width('100%')
              .height(60)
              .textAlign(TextAlign.Center)
              .backgroundColor(0xF0F0F0)
              .borderRadius(5)
          }
        }, (item: string) => item)
      }
      .width('100%')
      .height('80%')
      // 不添加耗时操作，滑动流畅
    }
    .width('100%')
    .height('100%')
  }
}