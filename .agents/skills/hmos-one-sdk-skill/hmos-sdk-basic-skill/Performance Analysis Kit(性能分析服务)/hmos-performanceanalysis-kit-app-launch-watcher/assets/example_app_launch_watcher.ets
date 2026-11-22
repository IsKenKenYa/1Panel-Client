/**
 * 完整示例：订阅启动耗时事件（APP_LAUNCH）
 * 
 * 本示例演示如何使用HiAppEvent模块订阅应用启动耗时系统事件，
 * 实时接收启动性能数据并进行处理。
 * 
 * 适用场景：
 * - 应用启动性能监控
 * - 启动耗时分析优化
 * - 性能数据收集统计
 */

import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 启动耗时事件观察者管理类
 * 提供事件订阅、处理、移除等完整功能
 */
export class AppLaunchWatcher {
  private watcherName: string = "app_launch_watcher";
  private isWatching: boolean = false;
  
  /**
   * 添加启动耗时事件观察者
   * 开始订阅APP_LAUNCH系统事件
   */
  public startWatching(): void {
    if (this.isWatching) {
      hilog.warn(0x0000, 'AppLaunchWatcher', '观察者已存在，无需重复添加');
      return;
    }
    
    try {
      // 添加观察者订阅启动耗时事件
      hiAppEvent.addWatcher({
        // 观察者名称，用于唯一标识观察者
        name: this.watcherName,
        
        // 事件过滤条件：订阅系统事件领域的启动耗时事件
        appEventFilters: [
          {
            domain: hiAppEvent.domain.OS,  // 系统事件领域
            names: [hiAppEvent.event.APP_LAUNCH]  // 启动耗时事件名称
          }
        ],
        
        // 实时回调函数：监听到事件后立即触发
        onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
          this.handleLaunchEvent(domain, appEventGroups);
        }
      });
      
      this.isWatching = true;
      hilog.info(0x0000, 'AppLaunchWatcher', '启动耗时事件观察者添加成功');
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      hilog.error(0x0000, 'AppLaunchWatcher', 
        `观察者添加失败: code=${err.code}, message=${err.message}`);
      
      // 错误处理
      this.handleAddWatcherError(err);
    }
  }
  
  /**
   * 处理启动耗时事件回调
   * 注意：仅用于事件接收和简单记录，不建议执行复杂业务逻辑
   */
  private handleLaunchEvent(domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>): void {
    hilog.info(0x0000, 'AppLaunchWatcher', `收到事件回调: domain=${domain}`);
    
    // 遍历事件组
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'AppLaunchWatcher', `事件名称: ${eventGroup.name}`);
      
      // 遍历事件信息
      for (const eventInfo of eventGroup.appEventInfos) {
        // 解析并记录事件数据
        this.parseAndLogEventInfo(eventInfo);
      }
    }
  }
  
  /**
   * 解析并记录启动耗时事件详细信息
   */
  private parseAndLogEventInfo(eventInfo: hiAppEvent.AppEventInfo): void {
    hilog.info(0x0000, 'AppLaunchWatcher', 
      `事件完整数据: ${JSON.stringify(eventInfo)}`);
    
    // 解析params字段中的启动性能数据
    if (eventInfo.params) {
      const params = eventInfo.params as Record<string, number | string>;
      
      // 启动类型：0表示冷启动，1表示热启动
      const startType = params['start_type'];
      hilog.info(0x0000, 'AppLaunchWatcher', `启动类型: ${startType} (${startType === 0 ? '冷启动' : '热启动'})`);
      
      // 启动耗时（毫秒）
      const launchTime = params['time'];
      hilog.info(0x0000, 'AppLaunchWatcher', `启动耗时: ${launchTime}ms`);
      
      // 动画完成时间（毫秒）
      const animationTime = params['animation_finish_time'];
      hilog.info(0x0000, 'AppLaunchWatcher', `动画完成时间: ${animationTime}ms`);
      
      // 应用包名和版本
      const bundleName = params['bundle_name'];
      const bundleVersion = params['bundle_version'];
      hilog.info(0x0000, 'AppLaunchWatcher', 
        `应用包名: ${bundleName}, 版本: ${bundleVersion}`);
      
      // 进程名
      const processName = params['process_name'];
      hilog.info(0x0000, 'AppLaunchWatcher', `进程名: ${processName}`);
      
      // 扩展时间
      const extendTime = params['extend_time'];
      hilog.info(0x0000, 'AppLaunchWatcher', `扩展时间: ${extendTime}ms`);
      
      // 图标输入时间（时间戳）
      const iconInputTime = params['icon_input_time'];
      hilog.info(0x0000, 'AppLaunchWatcher', `图标输入时间: ${iconInputTime}`);
    }
  }
  
  /**
   * 处理添加观察者的错误
   */
  private handleAddWatcherError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        hilog.error(0x0000, 'AppLaunchWatcher', 
          '参数错误：检查必填参数name是否缺失或类型是否正确');
        break;
        
      case 11102001:
        hilog.error(0x0000, 'AppLaunchWatcher', 
          '观察者名称无效：检查名称格式和长度');
        break;
        
      case 11102002:
        hilog.error(0x0000, 'AppLaunchWatcher', 
          '事件领域无效：使用正确的系统事件领域常量hiAppEvent.domain.OS');
        break;
        
      default:
        hilog.error(0x0000, 'AppLaunchWatcher', 
          `未知错误: ${error.message}`);
    }
  }
  
  /**
   * 移除启动耗时事件观察者
   * 注意：不要在onReceive回调中调用此方法
   */
  public stopWatching(): void {
    if (!this.isWatching) {
      hilog.warn(0x0000, 'AppLaunchWatcher', '观察者不存在，无需移除');
      return;
    }
    
    try {
      // 定义观察者对象（用于移除）
      const watcher: hiAppEvent.Watcher = {
        name: this.watcherName
      };
      
      // 移除观察者
      hiAppEvent.removeWatcher(watcher);
      
      this.isWatching = false;
      hilog.info(0x0000, 'AppLaunchWatcher', '启动耗时事件观察者已移除');
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      hilog.error(0x0000, 'AppLaunchWatcher', 
        `观察者移除失败: code=${err.code}, message=${err.message}`);
    }
  }
  
  /**
   * 获取观察者状态
   */
  public isWatchingActive(): boolean {
    return this.isWatching;
  }
}

/**
 * 使用示例：在EntryAbility中集成
 */
export function setupLaunchWatcher(): AppLaunchWatcher {
  const watcher = new AppLaunchWatcher();
  
  // 在应用启动时添加观察者
  watcher.startWatching();
  
  return watcher;
}

/**
 * 降级方案示例1：使用triggerCondition和onTrigger回调
 * 适用于不需要实时处理的场景
 */
export function setupLaunchWatcherWithTrigger(): void {
  try {
    hiAppEvent.addWatcher({
      name: "launch_watcher_trigger",
      
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.APP_LAUNCH]
        }
      ],
      
      // 设置触发条件
      triggerCondition: {
        row: 5,      // 事件数量达到5个触发
        size: 1000,  // 事件大小达到1000byte触发
        timeOut: 2   // 超时60s触发（timeOut单位为30s）
      },
      
      // 触发回调函数
      onTrigger: (curRow: number, curSize: number, holder: hiAppEvent.AppEventPackageHolder) => {
        if (holder == null) {
          hilog.error(0x0000, 'LaunchWatcher', "holder is null");
          return;
        }
        
        hilog.info(0x0000, 'LaunchWatcher', 
          `onTrigger triggered: curRow=${curRow}, curSize=${curSize}`);
        
        // 通过holder主动获取事件数据
        let eventPkg: hiAppEvent.AppEventPackage | null = null;
        while ((eventPkg = holder.takeNext()) != null) {
          hilog.info(0x0000, 'LaunchWatcher', 
            `eventPkg.packageId=${eventPkg.packageId}, row=${eventPkg.row}`);
          
          // 处理事件数据
          for (const eventInfo of eventPkg.appEventInfos) {
            hilog.info(0x0000, 'LaunchWatcher', 
              `eventInfo=${JSON.stringify(eventInfo)}`);
          }
        }
      }
    });
    
    hilog.info(0x0000, 'LaunchWatcher', 'triggerCondition方式观察者添加成功');
    
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(0x0000, 'LaunchWatcher', 
      `观察者添加失败: code=${err.code}, message=${err.message}`);
  }
}

/**
 * 降级方案示例2：手动获取事件（不使用回调）
 */
export function setupLaunchWatcherManual(): hiAppEvent.AppEventPackageHolder | null {
  try {
    const holder: hiAppEvent.AppEventPackageHolder | null = hiAppEvent.addWatcher({
      name: "launch_watcher_manual",
      
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.APP_LAUNCH]
        }
      ]
    });
    
    if (holder != null) {
      hilog.info(0x0000, 'LaunchWatcher', '手动获取方式观察者添加成功');
      
      // 可以在合适的时机手动获取事件
      // 注意：启动耗时事件在应用启动完成时生成，建议延迟获取
      setTimeout(() => {
        let eventPkg: hiAppEvent.AppEventPackage | null = null;
        while ((eventPkg = holder.takeNext()) != null) {
          hilog.info(0x0000, 'LaunchWatcher', 
            `eventPkg.packageId=${eventPkg.packageId}`);
          
          for (const eventInfo of eventPkg.appEventInfos) {
            hilog.info(0x0000, 'LaunchWatcher', 
              `eventInfo=${JSON.stringify(eventInfo)}`);
          }
        }
      }, 30000);  // 延迟30秒后获取
      
      return holder;
    }
    
    return null;
    
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(0x0000, 'LaunchWatcher', 
      `观察者添加失败: code=${err.code}, message=${err.message}`);
    return null;
  }
}