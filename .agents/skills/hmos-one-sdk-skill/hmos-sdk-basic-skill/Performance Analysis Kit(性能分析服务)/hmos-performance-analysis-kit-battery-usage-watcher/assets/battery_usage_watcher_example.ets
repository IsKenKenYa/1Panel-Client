/**
 * 订阅24h功耗器件分解统计事件完整示例
 * 
 * 本示例演示如何使用HiAppEvent API订阅系统级别的功耗统计事件（BATTERY_USAGE），
 * 实时获取应用在前台和后台运行时的各器件能耗数据。
 * 
 * 功能：
 * 1. 订阅BATTERY_USAGE系统事件
 * 2. 解析并展示功耗器件分解数据
 * 3. 提供错误处理和重试机制
 * 4. 支持取消订阅
 */

import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 功耗器件数据接口
 */
export interface BatteryUsageData {
  bundleName: string;              // 应用包名
  bundleVersion: string;            // 应用版本
  beginTime: number;                // 统计开始时间（毫秒时间戳）
  endTime: number;                  // 统计结束时间（毫秒时间戳）
  foregroundUsage: number[];        // 前台使用时长数组（24个小时段，单位：毫秒）
  backgroundUsage: number[];        // 后台使用时长数组（24个小时段，单位：毫秒）
  cpuForegroundEnergy: number[];    // CPU前台能耗数组（24个小时段）
  cpuBackgroundEnergy: number[];   // CPU后台能耗数组（24个小时段）
  gpuForegroundEnergy: number[];   // GPU前台能耗数组（24个小时段）
  gpuBackgroundEnergy: number[];   // GPU后台能耗数组（24个小时段）
  ddrForegroundEnergy: number[];   // DDR前台能耗数组（24个小时段）
  ddrBackgroundEnergy: number[];   // DDR后台能耗数组（24个小时段）
  displayForegroundEnergy: number[]; // Display前台能耗数组（24个小时段）
  displayBackgroundEnergy: number[]; // Display后台能耗数组（24个小时段）
  audioForegroundEnergy: number[];   // Audio前台能耗数组（24个小时段）
  audioBackgroundEnergy: number[];   // Audio后台能耗数组（24个小时段）
  wifiForegroundEnergy: number[];    // WiFi前台能耗数组（24个小时段）
  wifiBackgroundEnergy: number[];    // WiFi后台能耗数组（24个小时段）
  modemForegroundEnergy: number[];   // Modem前台能耗数组（24个小时段）
  modemBackgroundEnergy: number[];   // Modem后台能耗数组（24个小时段）
  gpsForegroundEnergy: number[];     // GPS前台能耗数组（24个小时段）
  gpsBackgroundEnergy: number[];     // GPS后台能耗数组（24个小时段）
  sensorForegroundEnergy: number[];  // Sensor前台能耗数组（24个小时段）
  sensorBackgroundEnergy: number[];  // Sensor后台能耗数组（24个小时段）
  romForegroundEnergy: number[];     // ROM前台能耗数组（24个小时段）
  romBackgroundEnergy: number[];     // ROM后台能耗数组（24个小时段）
  othersForegroundEnergy: number[];  // 其他器件前台能耗数组（24个小时段）
  othersBackgroundEnergy: number[];  // 其他器件后台能耗数组（24个小时段）
}

/**
 * 功耗器件分解统计事件订阅器
 */
export class BatteryUsageWatcher {
  private watcher: hiAppEvent.Watcher;
  private isSubscribed: boolean = false;
  private readonly TAG = 'BatteryUsage';
  private readonly DOMAIN = 0x0000;

  constructor() {
    this.watcher = {
      name: "batteryUsageWatcher",
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.BATTERY_USAGE]
        }
      ],
      onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
        this.handleBatteryUsageEvent(domain, appEventGroups);
      }
    };
  }

  /**
   * 订阅功耗事件
   */
  subscribe(): boolean {
    if (this.isSubscribed) {
      hilog.warn(this.DOMAIN, this.TAG, 'Already subscribed to battery usage events');
      return true;
    }

    try {
      const holder = hiAppEvent.addWatcher(this.watcher);
      
      if (!holder) {
        const error: BusinessError = {
          code: 11102001,
          name: 'InvalidWatcherName',
          message: 'Failed to create event holder, watcher name may be invalid'
        };
        throw error;
      }

      this.isSubscribed = true;
      hilog.info(this.DOMAIN, this.TAG, 'Successfully subscribed to battery usage events');
      return true;

    } catch (error) {
      this.handleSubscribeError(error as BusinessError);
      return false;
    }
  }

  /**
   * 订阅功耗事件（带重试机制）
   * @param retryCount 重试次数，默认3次
   * @param retryInterval 重试间隔，默认1000毫秒
   */
  subscribeWithRetry(retryCount: number = 3, retryInterval: number = 1000): Promise<boolean> {
    return new Promise((resolve) => {
      let attempts = 0;

      const attemptSubscribe = () => {
        attempts++;
        const success = this.subscribe();

        if (success) {
          resolve(true);
        } else if (attempts < retryCount) {
          hilog.info(this.DOMAIN, this.TAG, `Retrying to subscribe... (${attempts}/${retryCount})`);
          setTimeout(attemptSubscribe, retryInterval);
        } else {
          hilog.error(this.DOMAIN, this.TAG, `Failed to subscribe after ${retryCount} attempts`);
          resolve(false);
        }
      };

      attemptSubscribe();
    });
  }

  /**
   * 取消订阅功耗事件
   */
  unsubscribe(): void {
    if (!this.isSubscribed) {
      hilog.warn(this.DOMAIN, this.TAG, 'Not subscribed to battery usage events');
      return;
    }

    try {
      hiAppEvent.removeWatcher(this.watcher);
      this.isSubscribed = false;
      hilog.info(this.DOMAIN, this.TAG, 'Successfully unsubscribed from battery usage events');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(this.DOMAIN, this.TAG, 
        `Failed to unsubscribe: code=${err.code}, message=${err.message}`);
    }
  }

  /**
   * 获取订阅状态
   */
  getSubscriptionStatus(): boolean {
    return this.isSubscribed;
  }

  /**
   * 处理功耗事件回调
   */
  private handleBatteryUsageEvent(
    domain: string,
    appEventGroups: Array<hiAppEvent.AppEventGroup>
  ): void {
    hilog.info(this.DOMAIN, this.TAG, `Received event from domain: ${domain}`);

    for (const eventGroup of appEventGroups) {
      hilog.info(this.DOMAIN, this.TAG, `Event name: ${eventGroup.name}`);

      for (const eventInfo of eventGroup.appEventInfos) {
        try {
          const batteryData = this.parseBatteryUsageData(eventInfo);
          this.logBatteryUsageData(batteryData);
          this.onBatteryUsageReceived?.(batteryData);
        } catch (error) {
          hilog.error(this.DOMAIN, this.TAG, 
            `Failed to parse battery data: ${JSON.stringify(error)}`);
        }
      }
    }
  }

  /**
   * 解析功耗数据
   */
  private parseBatteryUsageData(eventInfo: hiAppEvent.AppEventInfo): BatteryUsageData {
    const params = eventInfo.params as Record<string, any>;

    if (!params) {
      throw new Error('Event params is null or undefined');
    }

    return {
      bundleName: params.bundle_name || '',
      bundleVersion: params.bundle_version || '',
      beginTime: params.begin_time || 0,
      endTime: params.end_time || 0,
      foregroundUsage: params.foreground_usage || [],
      backgroundUsage: params.background_usage || [],
      cpuForegroundEnergy: params.cpu_foreground_energy || [],
      cpuBackgroundEnergy: params.cpu_background_energy || [],
      gpuForegroundEnergy: params.gpu_foreground_energy || [],
      gpuBackgroundEnergy: params.gpu_background_energy || [],
      ddrForegroundEnergy: params.ddr_foreground_energy || [],
      ddrBackgroundEnergy: params.ddr_background_energy || [],
      displayForegroundEnergy: params.display_foreground_energy || [],
      displayBackgroundEnergy: params.display_background_energy || [],
      audioForegroundEnergy: params.audio_foreground_energy || [],
      audioBackgroundEnergy: params.audio_background_energy || [],
      wifiForegroundEnergy: params.wifi_foreground_energy || [],
      wifiBackgroundEnergy: params.wifi_background_energy || [],
      modemForegroundEnergy: params.modem_foreground_energy || [],
      modemBackgroundEnergy: params.modem_background_energy || [],
      gpsForegroundEnergy: params.gps_foreground_energy || [],
      gpsBackgroundEnergy: params.gps_background_energy || [],
      sensorForegroundEnergy: params.sensor_foreground_energy || [],
      sensorBackgroundEnergy: params.sensor_background_energy || [],
      romForegroundEnergy: params.rom_foreground_energy || [],
      romBackgroundEnergy: params.rom_background_energy || [],
      othersForegroundEnergy: params.others_foreground_energy || [],
      othersBackgroundEnergy: params.others_background_energy || []
    };
  }

  /**
   * 记录功耗数据日志
   */
  private logBatteryUsageData(data: BatteryUsageData): void {
    hilog.info(this.DOMAIN, this.TAG, '======== Battery Usage Data ========');
    hilog.info(this.DOMAIN, this.TAG, `App: ${data.bundleName} v${data.bundleVersion}`);
    hilog.info(this.DOMAIN, this.TAG, 
      `Time: ${new Date(data.beginTime).toISOString()} ~ ${new Date(data.endTime).toISOString()}`);

    // 计算总使用时长
    const totalForeground = data.foregroundUsage.reduce((sum, val) => sum + val, 0);
    const totalBackground = data.backgroundUsage.reduce((sum, val) => sum + val, 0);
    hilog.info(this.DOMAIN, this.TAG, 
      `Total Foreground: ${totalForeground}ms, Background: ${totalBackground}ms`);

    // 计算总能耗
    const totalCpuForeground = data.cpuForegroundEnergy.reduce((sum, val) => sum + val, 0);
    const totalCpuBackground = data.cpuBackgroundEnergy.reduce((sum, val) => sum + val, 0);
    const totalGpuForeground = data.gpuForegroundEnergy.reduce((sum, val) => sum + val, 0);
    const totalDisplayForeground = data.displayForegroundEnergy.reduce((sum, val) => sum + val, 0);

    hilog.info(this.DOMAIN, this.TAG, 
      `CPU Energy - Foreground: ${totalCpuForeground}, Background: ${totalCpuBackground}`);
    hilog.info(this.DOMAIN, this.TAG, 
      `GPU Energy - Foreground: ${totalGpuForeground}`);
    hilog.info(this.DOMAIN, this.TAG, 
      `Display Energy - Foreground: ${totalDisplayForeground}`);
    hilog.info(this.DOMAIN, this.TAG, '====================================');
  }

  /**
   * 处理订阅错误
   */
  private handleSubscribeError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        hilog.error(this.DOMAIN, this.TAG, 
          'Parameter error: Mandatory parameters are missing or incorrect parameter types');
        break;
      case 11102001:
        hilog.error(this.DOMAIN, this.TAG, 
          'Invalid watcher name: Contains invalid characters or length is invalid');
        break;
      case 11102002:
        hilog.error(this.DOMAIN, this.TAG, 
          'Invalid filtering event domain: Contains invalid characters or length is invalid');
        break;
      default:
        hilog.error(this.DOMAIN, this.TAG, 
          `Unknown error occurred: code=${error.code}, message=${error.message}`);
    }
  }

  /**
   * 功耗数据接收回调（外部可设置）
   */
  onBatteryUsageReceived?: (data: BatteryUsageData) => void;
}

/**
 * 使用示例
 */
export class BatteryUsageWatcherExample {
  private watcher: BatteryUsageWatcher;

  constructor() {
    this.watcher = new BatteryUsageWatcher();

    // 设置功耗数据接收回调
    this.watcher.onBatteryUsageReceived = (data: BatteryUsageData) => {
      console.log(`Received battery usage data for ${data.bundleName}`);
      // 在这里可以添加自定义的数据处理逻辑，例如：
      // 1. 上传到服务器
      // 2. 保存到本地数据库
      // 3. 更新UI显示
    };
  }

  /**
   * 启动功耗监控
   */
  async startMonitoring(): Promise<void> {
    console.log('Starting battery usage monitoring...');

    // 使用重试机制订阅
    const success = await this.watcher.subscribeWithRetry(3, 1000);

    if (success) {
      console.log('Battery usage monitoring started successfully');
    } else {
      console.error('Failed to start battery usage monitoring');
    }
  }

  /**
   * 停止功耗监控
   */
  stopMonitoring(): void {
    console.log('Stopping battery usage monitoring...');
    this.watcher.unsubscribe();
    console.log('Battery usage monitoring stopped');
  }
}

/**
 * 使用方式示例
 * 
 * // 在EntryAbility.ets中
 * import { BatteryUsageWatcherExample } from './watcher/BatteryUsageWatcher';
 * 
 * export default class EntryAbility extends UIAbility {
 *   private batteryMonitor: BatteryUsageWatcherExample;
 * 
 *   onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
 *     this.batteryMonitor = new BatteryUsageWatcherExample();
 *     this.batteryMonitor.startMonitoring();
 *   }
 * 
 *   onDestroy(): void {
 *     this.batteryMonitor.stopMonitoring();
 *   }
 * }
 */