/**
 * CPU加压测试示例
 * 
 * 本示例用于构造高耗电测试场景，触发功耗数据上报。
 * 通过创建多个Worker线程执行死循环来模拟CPU高负载。
 * 
 * 注意：此代码仅用于测试目的，实际应用中不应使用。
 */

import { worker } from '@kit.ArkTS';

/**
 * CPU压力测试器
 * 用于构造高耗电场景，触发BATTERY_USAGE事件上报
 */
export default class CpuTester {
  private workerInstances: worker.ThreadWorker[] = [];
  private readonly MAX_THREADS = 10;

  /**
   * 启动CPU压力测试
   * @param threadNum 线程数量（1-10）
   */
  start(threadNum: number): void {
    if (threadNum < 1 || threadNum > this.MAX_THREADS) {
      console.error(`Invalid thread number: ${threadNum}. Must be between 1 and ${this.MAX_THREADS}`);
      return;
    }

    console.log(`Starting CPU stress test with ${threadNum} threads...`);

    for (let index = 0; index < threadNum; index++) {
      try {
        const workerInstance = new worker.ThreadWorker('entry/ets/workers/worker.ets');
        
        workerInstance.onmessage = (message) => {
          console.log(`Worker ${index} message: ${JSON.stringify(message.data)}`);
        };

        workerInstance.onerror = (error) => {
          console.error(`Worker ${index} error: ${error.message}`);
        };

        this.workerInstances.push(workerInstance);
        
        // 发送消息启动Worker中的死循环
        workerInstance.postMessage('start');
        console.log(`Worker ${index} started`);

      } catch (error) {
        console.error(`Failed to start worker ${index}: ${JSON.stringify(error)}`);
      }
    }

    console.log(`CPU stress test started with ${this.workerInstances.length} threads`);
  }

  /**
   * 停止CPU压力测试
   */
  stop(): void {
    console.log('Stopping CPU stress test...');

    for (let i = 0; i < this.workerInstances.length; i++) {
      try {
        this.workerInstances[i].terminate();
        console.log(`Worker ${i} terminated`);
      } catch (error) {
        console.error(`Failed to terminate worker ${i}: ${JSON.stringify(error)}`);
      }
    }

    this.workerInstances = [];
    console.log('CPU stress test stopped');
  }

  /**
   * 获取当前运行的线程数
   */
  getActiveThreadCount(): number {
    return this.workerInstances.length;
  }
}

/**
 * Worker线程实现（entry/ets/workers/worker.ets）
 * 
 * import { worker } from '@kit.ArkTS';
 * 
 * const workerPort = worker.workerPort;
 * 
 * workerPort.onmessage = (message) => {
 *   if (message.data === 'start') {
 *     eatCpu();
 *   }
 * }
 * 
 * function eatCpu(): void {
 *   let val: number = 0;
 *   while (true) {
 *     val++;
 *   }
 * }
 */

/**
 * 使用示例
 * 
 * // 在页面中使用
 * import CpuTester from '../tester/CpuTester';
 * 
 * @Entry
 * @Component
 * struct Index {
 *   @State message: string = 'Hello World';
 *   @State enable: boolean = true;
 *   @State threadNum: number = 5;
 *   private cpuTester: CpuTester = new CpuTester();
 * 
 *   build() {
 *     Row() {
 *       Column() {
 *         Text(this.message)
 *           .fontSize(50)
 *           .fontWeight(FontWeight.Bold)
 * 
 *         Button('CPU加压')
 *           .fontSize(18)
 *           .margin(12)
 *           .fontWeight(FontWeight.Bold)
 *           .enabled(this.enable)
 *           .onClick(() => {
 *             this.cpuTester.start(this.threadNum);
 *             this.enable = false;
 *           })
 * 
 *         Button('停止加压')
 *           .fontSize(18)
 *           .margin(12)
 *           .fontWeight(FontWeight.Bold)
 *           .enabled(!this.enable)
 *           .onClick(() => {
 *             this.cpuTester.stop();
 *             this.enable = true;
 *           })
 *       }
 *       .width('100%')
 *     }
 *     .height('100%')
 *   }
 * }
 */

/**
 * 测试步骤
 * 
 * 1. 安装运行测试应用到测试机上
 * 2. 断开USB（2in1设备还需要断开充电线）
 * 3. 打开测试应用，点击"CPU加压"按钮
 * 4. 持续运行10分钟以上，测试过程保持屏幕常亮
 * 5. 连接USB，等待0点后查看功耗数据
 * 
 * 快速触发上报方式：
 * hdc shell hidumper -s 1213 -a '--test 1'
 * 然后修改设备时间为23:58，加速触发数据上报
 */