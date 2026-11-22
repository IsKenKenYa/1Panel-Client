import { hidebug, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'HiDebugExample';
const DOMAIN = 0xFF00;

@Entry
@Component
struct HiDebugExample {
  build() {
    Column() {
      Text('HiDebug Debug Info')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 });

      // 系统CPU使用率
      Button('Get System CPU Usage')
        .width('80%')
        .height(50)
        .margin({ top: 20 })
        .onClick(() => {
          this.getSystemCpuUsage();
        });

      // 应用CPU使用率
      Button('Get App CPU Usage')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.getAppCpuUsage();
        });

      // 内存信息(异步)
      Button('Get App Memory Info (Async)')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(async () => {
          await this.getAppNativeMemInfoAsync();
        });

      // VM内存信息
      Button('Get VM Memory Info')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.getAppVMMemoryInfo();
        });

      // 系统内存信息
      Button('Get System Memory Info')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.getSystemMemInfo();
        });

      // 线程CPU使用情况
      Button('Get Thread CPU Usage')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.getAppThreadCpuUsage();
        });

      // GC统计信息
      Button('Get GC Stats')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.getVMRuntimeStats();
        });

      // JS CPU Profiling
      Button('Start JS CPU Profiling (5 seconds)')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.startProfilingDemo();
        });

      // VM堆快照转储
      Button('Dump Heap Snapshot')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.dumpHeapSnapshot();
        });

      // 应用Trace采集
      Button('Start App Trace Capture (5 seconds)')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.startTraceCaptureDemo();
        });

      // 内存限制信息
      Button('Get App Memory Limit')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.getAppMemoryLimit();
        });

      // 调试状态
      Button('Check Debug State')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.isDebugState();
        });
    }
    .width('100%')
    .height('100%');
  }

  private getSystemCpuUsage(): void {
    try {
      const cpuUsage: number = hidebug.getSystemCpuUsage();
      hilog.info(DOMAIN, TAG, `System CPU Usage: ${(cpuUsage * 100).toFixed(2)}%`);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
      if (err.code === 11400104) {
        hilog.error(DOMAIN, TAG, 'System CPU usage status is abnormal');
      }
    }
  }

  private getAppCpuUsage(): void {
    try {
      const cpuUsage: number = hidebug.getCpuUsage();
      hilog.info(DOMAIN, TAG, `App CPU Usage: ${(cpuUsage * 100).toFixed(2)}%`);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
    }
  }

  private async getAppNativeMemInfoAsync(): Promise<void> {
    try {
      const memInfo: hidebug.NativeMemInfo = await hidebug.getAppNativeMemInfoAsync();
      hilog.info(DOMAIN, TAG, `=== Application Native Memory Info ===`);
      hilog.info(DOMAIN, TAG, `PSS: ${memInfo.pss} KB`);
      hilog.info(DOMAIN, TAG, `VSS: ${memInfo.vss} KB`);
      hilog.info(DOMAIN, TAG, `RSS: ${memInfo.rss} KB`);
      hilog.info(DOMAIN, TAG, `Shared Dirty: ${memInfo.sharedDirty} KB`);
      hilog.info(DOMAIN, TAG, `Private Dirty: ${memInfo.privateDirty} KB`);
      hilog.info(DOMAIN, TAG, `Shared Clean: ${memInfo.sharedClean} KB`);
      hilog.info(DOMAIN, TAG, `Private Clean: ${memInfo.privateClean} KB`);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
    }
  }

  private getAppVMMemoryInfo(): void {
    try {
      const vmMemory: hidebug.VMMemoryInfo = hidebug.getAppVMMemoryInfo();
      hilog.info(DOMAIN, TAG, `=== VM Memory Info ===`);
      hilog.info(DOMAIN, TAG, `Total Heap: ${vmMemory.totalHeap} KB`);
      hilog.info(DOMAIN, TAG, `Heap Used: ${vmMemory.heapUsed} KB`);
      hilog.info(DOMAIN, TAG, `All Array Size: ${vmMemory.allArraySize} KB`);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
    }
  }

  private getSystemMemInfo(): void {
    try {
      const systemMem: hidebug.SystemMemInfo = hidebug.getSystemMemInfo();
      hilog.info(DOMAIN, TAG, `=== System Memory Info ===`);
      hilog.info(DOMAIN, TAG, `Total Memory: ${systemMem.totalMem} KB`);
      hilog.info(DOMAIN, TAG, `Free Memory: ${systemMem.freeMem} KB`);
      hilog.info(DOMAIN, TAG, `Available Memory: ${systemMem.availableMem} KB`);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
    }
  }

  private getAppThreadCpuUsage(): void {
    try {
      const threadCpuUsage: hidebug.ThreadCpuUsage[] = hidebug.getAppThreadCpuUsage();
      hilog.info(DOMAIN, TAG, `=== Thread CPU Usage ===`);
      hilog.info(DOMAIN, TAG, `Total threads: ${threadCpuUsage.length}`);
      threadCpuUsage.forEach((thread, index) => {
        hilog.info(DOMAIN, TAG, `Thread ${index + 1}: ID=${thread.threadId}, CPU Usage=${(thread.cpuUsage * 100).toFixed(2)}%`);
      });
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
    }
  }

  private getVMRuntimeStats(): void {
    try {
      const gcStats: hidebug.GcStats = hidebug.getVMRuntimeStats();
      hilog.info(DOMAIN, TAG, `=== GC Statistics ===`);
      hilog.info(DOMAIN, TAG, `GC Count: ${gcStats['ark.gc.gc-count']}`);
      hilog.info(DOMAIN, TAG, `GC Time: ${gcStats['ark.gc.gc-time']} ms`);
      hilog.info(DOMAIN, TAG, `Bytes Allocated: ${gcStats['ark.gc.gc-bytes-allocated']} B`);
      hilog.info(DOMAIN, TAG, `Bytes Freed: ${gcStats['ark.gc.gc-bytes-freed']} B`);
      hilog.info(DOMAIN, TAG, `Long Full GC Count: ${gcStats['ark.gc.fullgc-longtime-count']}`);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
    }
  }

  private startProfilingDemo(): void {
    try {
      hidebug.startJsCpuProfiling('cpu_profiling_demo');
      hilog.info(DOMAIN, TAG, 'JS CPU Profiling started for 5 seconds...');

      setTimeout(() => {
        try {
          hidebug.stopJsCpuProfiling();
          hilog.info(DOMAIN, TAG, 'JS CPU Profiling stopped. Check files directory for cpu_profiling_demo.json');
        } catch (error) {
          const err = error as BusinessError;
          hilog.error(DOMAIN, TAG, `Stop profiling error: code=${err.code}, message=${err.message}`);
        }
      }, 5000);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Start profiling error: code=${err.code}, message=${err.message}`);
    }
  }

  private dumpHeapSnapshot(): void {
    try {
      hidebug.dumpJsHeapData('heap_snapshot_demo');
      hilog.info(DOMAIN, TAG, 'Heap snapshot dumped. Check files directory for heap_snapshot_demo.heapsnapshot');
      hilog.warn(DOMAIN, TAG, 'Warning: This operation is time-consuming, avoid using in production version');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
    }
  }

  private startTraceCaptureDemo(): void {
    try {
      const tags: number[] = [hidebug.tags.ABILITY_MANAGER, hidebug.tags.ARKUI, hidebug.tags.GRAPHICS];
      const flag: hidebug.TraceFlag = hidebug.TraceFlag.ALL_THREADS;
      const limitSize: number = 5 * 1024 * 1024;

      const fileName: string = hidebug.startAppTraceCapture(tags, flag, limitSize);
      hilog.info(DOMAIN, TAG, `Trace capture started. Output file: ${fileName}`);
      hilog.info(DOMAIN, TAG, 'Trace will capture for 5 seconds...');

      setTimeout(() => {
        try {
          hidebug.stopAppTraceCapture();
          hilog.info(DOMAIN, TAG, 'Trace capture stopped');
        } catch (error) {
          const err = error as BusinessError;
          hilog.error(DOMAIN, TAG, `Stop trace error: code=${err.code}, message=${err.message}`);
        }
      }, 5000);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Start trace error: code=${err.code}, message=${err.message}`);
      if (err.code === 11400102) {
        hilog.error(DOMAIN, TAG, 'Trace capture already enabled, please stop first');
      } else if (err.code === 11400103) {
        hilog.error(DOMAIN, TAG, 'No write permission on the file');
      } else if (err.code === 11400104) {
        hilog.error(DOMAIN, TAG, 'Abnormal trace status');
      }
    }
  }

  private getAppMemoryLimit(): void {
    try {
      const memLimit: hidebug.MemoryLimit = hidebug.getAppMemoryLimit();
      hilog.info(DOMAIN, TAG, `=== Application Memory Limit ===`);
      hilog.info(DOMAIN, TAG, `RSS Limit: ${memLimit.rssLimit} KB`);
      hilog.info(DOMAIN, TAG, `VSS Limit: ${memLimit.vssLimit} KB`);
      hilog.info(DOMAIN, TAG, `VM Heap Limit: ${memLimit.vmHeapLimit} KB`);
      hilog.info(DOMAIN, TAG, `VM Total Heap Size: ${memLimit.vmTotalHeapSize} KB`);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
    }
  }

  private isDebugState(): void {
    try {
      const debugState: boolean = hidebug.isDebugState();
      hilog.info(DOMAIN, TAG, `Debug State: ${debugState ? 'In Debug Mode' : 'Not in Debug Mode'}`);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
    }
  }
}