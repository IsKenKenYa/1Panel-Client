/**
 * Worker线程CPU加压死循环
 * 功能：在Worker线程中执行死循环，触发CPU高负载
 */

import { worker } from '@kit.ArkTS';

let workerPort = worker.workerPort;

// 监听主线程消息
workerPort.onmessage = (message) => {
  const data = message.data;
  
  if (data === 'start') {
    // 开始执行死循环，触发CPU高负载
    eatCpu();
  } else if (data === 'stop') {
    // 停止死循环（通过抛出异常强制终止）
    throw new Error('Stop CPU stress');
  }
};

/**
 * 执行死循环，占用CPU资源
 */
function eatCpu(): void {
  let val: number = 0;
  let iteration: number = 0;
  
  // 无限循环，持续占用CPU
  while (true) {
    val++;
    iteration++;
    
    // 每隔100万次迭代打印一次日志（避免日志过多）
    if (iteration % 1000000 === 0) {
      // 注意：Worker线程中不能使用hilog，这里仅作为计数标记
      // 实际运行时会持续占用CPU直到收到stop消息
    }
  }
}

// 监听错误事件
workerPort.onerror = (error) => {
  // Worker线程错误处理
  console.error(`Worker error: ${error.message}`);
};

// 注意事项：
// 1. 该Worker文件应放在 entry/ets/workers/ 目录下
// 2. Worker线程会持续占用CPU，建议仅在测试时使用
// 3. 通过发送'stop'消息或terminate()方法停止Worker
// 4. Worker线程创建后会立即开始执行死循环
// 5. 多个Worker线程同时运行会显著提高CPU使用率