/**
 * 多线程CPU加压测试示例
 * 功能：使用Worker线程执行死循环，触发CPU高负载事件
 */

import { worker } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

export class CpuStressTester {
  private workerInstances: Array<worker.ThreadWorker> = [];
  
  /**
   * 启动多线程CPU加压
   * @param threadNum 线程数量
   */
  public start(threadNum: number): void {
    hilog.info(0x0000, 'CpuTester', `Starting CPU stress test with ${threadNum} threads`);
    
    // 清空旧的worker实例
    this.stop();
    
    // 创建多个worker线程执行死循环
    for (let index = 0; index < threadNum; index++) {
      let workerInstance = new worker.ThreadWorker('entry/ets/workers/worker_cpu_stress.ets');
      workerInstance.postMessage('start');
      this.workerInstances.push(workerInstance);
      
      hilog.info(0x0000, 'CpuTester', `Worker thread ${index + 1} started`);
    }
    
    hilog.info(0x0000, 'CpuTester', 'CPU stress test started, wait for CPU_USAGE_HIGH event');
  }
  
  /**
   * 停止所有CPU加压线程
   */
  public stop(): void {
    for (const workerInstance of this.workerInstances) {
      workerInstance.postMessage('stop');
      workerInstance.terminate();
    }
    
    this.workerInstances = [];
    hilog.info(0x0000, 'CpuTester', 'CPU stress test stopped');
  }
  
  /**
   * 获取当前运行的线程数量
   */
  public getThreadCount(): number {
    return this.workerInstances.length;
  }
}

/**
 * UI组件：CPU加压测试页面
 */
import CpuStressTester from './CpuStressTester';

@Entry
@Component
struct CpuStressTestPage {
  @State message: string = 'CPU Stress Test';
  @State isRunning: boolean = false;
  @State threadNum: number = 5;
  private cpuTester: CpuStressTester = new CpuStressTester();
  
  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20 })
        
        Text(`Thread Count: ${this.threadNum}`)
          .fontSize(20)
          .margin({ top: 10 })
        
        Button(this.isRunning ? 'Stop' : 'Start CPU Stress')
          .fontSize(18)
          .margin({ top: 20 })
          .fontWeight(FontWeight.Bold)
          .enabled(true)
          .onClick(() => {
            if (this.isRunning) {
              this.cpuTester.stop();
              this.isRunning = false;
              this.message = 'CPU Stress Test Stopped';
            } else {
              this.cpuTester.start(this.threadNum);
              this.isRunning = true;
              this.message = 'CPU Stress Test Running';
            }
          })
        
        Button('Add Thread')
          .fontSize(16)
          .margin({ top: 10 })
          .enabled(!this.isRunning)
          .onClick(() => {
            this.threadNum++;
          })
        
        Button('Remove Thread')
          .fontSize(16)
          .margin({ top: 10 })
          .enabled(!this.isRunning && this.threadNum > 1)
          .onClick(() => {
            this.threadNum--;
          })
        
        Text('Tips: Wait 5-10 minutes after starting to see CPU_USAGE_HIGH event in logs')
          .fontSize(14)
          .margin({ top: 30 })
          .fontColor('#666666')
      }
      .width('100%')
    }
    .height('100%')
  }
}

// 导出测试函数
export function testCpuStress(): void {
  let tester = new CpuStressTester();
  
  // 启动5个线程的CPU加压测试
  tester.start(5);
  
  // 10分钟后停止测试
  setTimeout(() => {
    tester.stop();
    hilog.info(0x0000, 'TestTag', 'CPU stress test completed');
  }, 600000); // 10分钟 = 600000毫秒
}