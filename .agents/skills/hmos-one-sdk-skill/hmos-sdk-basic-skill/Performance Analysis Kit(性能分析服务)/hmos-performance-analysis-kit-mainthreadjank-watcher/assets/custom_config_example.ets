// 自定义主线程超时采样参数配置示例
// 本示例演示如何使用setEventConfig自定义设置采样栈参数

import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct CustomConfigPage {
  // 自定义设置采样栈参数
  setCustomSamplingConfig(): void {
    let params: Record<string, hiAppEvent.ParamType> = {
      // 事件类型定义
      // 0 - 默认值：主线程连续两次超时150ms~450ms采集调用栈；超时450ms采集trace
      // 1 - 仅采集调用栈，触发检测阈值由用户自定义
      // 2 - 仅采集trace
      "log_type": "1",
      
      // 主线程超时检测间隔和采样间隔（单位：毫秒）
      // 取值范围：[50, 500]，默认值：150
      "sample_interval": "100",
      
      // 应用启动期间忽略主线程超时检测的时间（单位：秒）
      // 最小值：3，默认值：10
      "ignore_startup_time": "11",
      
      // 主线程超时采样次数（单位：次）
      // 最小值：1，默认值：10
      // 最大值需满足公式：sampleCount <= (2500 / sampleInterval - 4)
      // 示例：sampleInterval=100时，sampleCount <= (2500/100-4) = 21
      "sample_count": "21",
      
      // 同一个应用的PID一个生命周期内，主线程超时采样上报次数（单位：次/分钟）
      // 范围：[1, 3]，默认值：1
      "report_times_per_app": "3"
    };
    
    hiAppEvent.setEventConfig(hiAppEvent.event.MAIN_THREAD_JANK, params).then(() => {
      hilog.info(0x0000, 'CustomConfig', 'Successfully set sampling stack parameters.');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, 'CustomConfig', 
        `Failed to set sample stack value. Code: ${err.code}, message: ${err.message}`);
    });
  }

  // 使用默认配置（仅设置autoStopSampling）
  setDefaultConfig(): void {
    let params: Record<string, hiAppEvent.ParamType> = {
      // log_type=0时，仅需配置autoStopSampling参数
      // 其他参数均取默认值，无需设置
      "log_type": "0",
      
      // 主线程超时结束时，是否自动停止采样主线程堆栈
      // true - 超时结束或达到设置的采样次数，停止采样
      // false - 达到设置的采样次数时停止采样
      // 默认值：false
      "auto_stop_sampling": "true"
    };
    
    hiAppEvent.setEventConfig(hiAppEvent.event.MAIN_THREAD_JANK, params).then(() => {
      hilog.info(0x0000, 'CustomConfig', 'Successfully set default config with auto stop.');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, 'CustomConfig', 
        `Failed to set default config. Code: ${err.code}, message: ${err.message}`);
    });
  }

  // 仅采集trace配置
  setTraceOnlyConfig(): void {
    let params: Record<string, hiAppEvent.ParamType> = {
      // log_type=2时，其他参数均不生效，无需设置
      "log_type": "2"
    };
    
    hiAppEvent.setEventConfig(hiAppEvent.event.MAIN_THREAD_JANK, params).then(() => {
      hilog.info(0x0000, 'CustomConfig', 'Successfully set trace only config.');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, 'CustomConfig', 
        `Failed to set trace config. Code: ${err.code}, message: ${err.message}`);
    });
  }

  build() {
    Column() {
      Text('自定义采样参数配置示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });
      
      Button('设置自定义采样栈参数')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.setCustomSamplingConfig();
        });
      
      Button('使用默认配置（自动停止采样）')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.setDefaultConfig();
        });
      
      Button('仅采集trace配置')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.setTraceOnlyConfig();
        });
      
      // 模拟超时触发按钮
      Button('触发150ms超时')
        .width('80%')
        .height(50)
        .margin({ top: 20 })
        .onClick(() => {
          let t = Date.now();
          while (Date.now() - t <= 150) {}
        });
      
      Button('触发500ms超时')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          let t = Date.now();
          while (Date.now() - t <= 500) {}
        });
    }
    .width('100%')
    .height('100%');
  }
}