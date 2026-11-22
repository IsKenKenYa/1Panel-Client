import { hilog } from '@kit.PerformanceAnalysisKit';
import testNapi from 'libentry.so';

const DOMAIN = 0x0000;
const TAG = 'FaultInjectionTest';

export function triggerMemoryLeak(): void {
  hilog.info(DOMAIN, TAG, 'Starting memory leak simulation');
  testNapi.leak();
}

export function triggerCPUHighload(): void {
  hilog.info(DOMAIN, TAG, 'Starting CPU highload simulation');
  testNapi.cpuHighload();
}

export function triggerThreadLeak(): void {
  hilog.info(DOMAIN, TAG, 'Starting thread leak simulation');
  testNapi.threadLeak();
}

export enum FaultType {
  MEMORY_LEAK = 'memory_leak',
  CPU_HIGHLOAD = 'cpu_highload',
  THREAD_LEAK = 'thread_leak'
}

export function triggerFault(faultType: FaultType): void {
  switch (faultType) {
    case FaultType.MEMORY_LEAK:
      triggerMemoryLeak();
      break;
    case FaultType.CPU_HIGHLOAD:
      triggerCPUHighload();
      break;
    case FaultType.THREAD_LEAK:
      triggerThreadLeak();
      break;
    default:
      hilog.warn(DOMAIN, TAG, `Unknown fault type: ${faultType}`);
  }
}