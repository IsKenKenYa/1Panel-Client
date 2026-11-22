/**
 * 多网发起和释放完整示例
 * 本示例演示如何使用HarmonyOS Network Boost Kit的多网并发功能
 * 
 * 功能：
 * 1. 查询多网配额使用情况
 * 2. 发起多网并发请求
 * 3. 监听多网状态变化
 * 4. 订阅系统多网推荐
 * 5. 释放多网并发资源
 * 
 * 注意事项：
 * - 需要申请 ohos.permission.LINKTURBO 权限
 * - 需要开启网络加速开关（设置->移动网络->网络加速）
 * - API版本要求：6.0.0(20)及以上
 */

import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 多网并发管理类
 * 封装多网请求、释放、状态监听等功能
 */
export class MultiPathManager {
  private isMultiPathActive: boolean = false;
  private isMonitoring: boolean = false;

  /**
   * 查询多网配额使用情况
   * @returns 多网配额信息，查询失败返回null
   */
  checkQuota(): netHandover.MultiPathQuota | null {
    try {
      const quota = netHandover.getMultiPathQuotaStats();
      console.info(`[MultiPath] 已使用次数: ${quota.used.count}, 已使用时长: ${quota.used.duration}秒`);
      console.info(`[MultiPath] 剩余次数: ${quota.remaining.count}, 剩余时长: ${quota.remaining.duration}秒`);
      
      if (quota.remaining.count <= 0) {
        console.warn('[MultiPath] 多网配额已用完，无法发起多网请求');
        return null;
      }
      
      return quota;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[MultiPath] 查询配额失败: errCode=${error.code}, errMessage=${error.message}`);
      return null;
    }
  }

  /**
   * 订阅多网状态变化事件
   */
  subscribeStateChange(): void {
    if (this.isMonitoring) {
      console.warn('[MultiPath] 已经订阅多网状态变化');
      return;
    }

    try {
      netHandover.on('multiPathStateChange', (data: netHandover.MultiPathStateInfo) => {
        console.info(`[MultiPath] 状态变化: state=${data.multiPathState}, cause=${data.cause}`);
        console.info(`[MultiPath] 链路类型: ${data.pathType}, 链路状态: ${data.pathState}`);
        
        this.handleStateChange(data);
      });
      
      this.isMonitoring = true;
      console.info('[MultiPath] 多网状态监听已启动');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[MultiPath] 订阅多网状态失败: errCode=${error.code}, errMessage=${error.message}`);
    }
  }

  /**
   * 取消订阅多网状态变化事件
   */
  unsubscribeStateChange(): void {
    if (!this.isMonitoring) {
      return;
    }

    try {
      netHandover.off('multiPathStateChange');
      this.isMonitoring = false;
      console.info('[MultiPath] 已取消订阅多网状态变化');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[MultiPath] 取消订阅失败: errCode=${error.code}, errMessage=${error.message}`);
    }
  }

  /**
   * 订阅系统多网推荐信息
   */
  subscribeRecommendation(): void {
    try {
      netHandover.on('multiPathRecommendation', (data: netHandover.MultiPathRecommendationInfo) => {
        console.info(`[MultiPath] 系统推荐: action=${data.action}`);
        
        if (data.action === netHandover.MultiPathAction.MULTIPATH_ACTION_REQUEST) {
          console.info('[MultiPath] 系统建议发起多网请求');
        } else if (data.action === netHandover.MultiPathAction.MULTIPATH_ACTION_RELEASE) {
          console.info('[MultiPath] 系统建议释放多网请求');
        }
      });
      console.info('[MultiPath] 多网推荐监听已启动');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[MultiPath] 订阅多网推荐失败: errCode=${error.code}, errMessage=${error.message}`);
    }
  }

  /**
   * 取消订阅系统多网推荐信息
   */
  unsubscribeRecommendation(): void {
    try {
      netHandover.off('multiPathRecommendation');
      console.info('[MultiPath] 已取消订阅多网推荐');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[MultiPath] 取消订阅失败: errCode=${error.code}, errMessage=${error.message}`);
    }
  }

  /**
   * 发起多网请求
   * @returns Promise<boolean> 是否发起成功
   */
  async request(): Promise<boolean> {
    if (this.isMultiPathActive) {
      console.warn('[MultiPath] 多网已经激活，无需重复请求');
      return true;
    }

    return new Promise((resolve) => {
      try {
        netHandover.requestMultiPath((data: netHandover.MultiPathRequestResult) => {
          console.info(`[MultiPath] 请求结果: ${JSON.stringify(data)}`);
          
          if (data.result === netHandover.MultiPathErrorResult.MULTIPATH_ERROR_NONE) {
            console.info('[MultiPath] 多网请求成功');
            this.isMultiPathActive = true;
            resolve(true);
          } else {
            this.handleRequestResult(data.result);
            resolve(false);
          }
        });
      } catch (err) {
        const error = err as BusinessError;
        console.error(`[MultiPath] 发起多网请求失败: errCode=${error.code}, errMessage=${error.message}`);
        this.handleRequestError(error.code);
        resolve(false);
      }
    });
  }

  /**
   * 释放多网请求
   */
  async release(): Promise<void> {
    if (!this.isMultiPathActive) {
      console.warn('[MultiPath] 多网未激活，无需释放');
      return;
    }

    try {
      netHandover.releaseMultiPath();
      this.isMultiPathActive = false;
      console.info('[MultiPath] 多网释放成功');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[MultiPath] 释放多网失败: errCode=${error.code}, errMessage=${error.message}`);
      
      if (error.code === 1013620100) {
        console.warn('[MultiPath] 多网已激活，但不是当前应用发起的');
      } else if (error.code === 1013620101) {
        console.warn('[MultiPath] 多网不在激活态');
        this.isMultiPathActive = false;
      }
    }
  }

  /**
   * 处理状态变化
   */
  private handleStateChange(data: netHandover.MultiPathStateInfo): void {
    switch (data.multiPathState) {
      case netHandover.MultiPathState.MULTIPATH_CREATING:
        console.info('[MultiPath] 多网正在建立中...');
        break;
      case netHandover.MultiPathState.MULTIPATH_CREATED:
        console.info('[MultiPath] 多网已建立，可以开始使用');
        this.isMultiPathActive = true;
        break;
      case netHandover.MultiPathState.MULTIPATH_RELEASING:
        console.info('[MultiPath] 多网正在释放中...');
        break;
      case netHandover.MultiPathState.MULTIPATH_IDLE:
        console.info('[MultiPath] 多网已释放，处于空闲状态');
        this.isMultiPathActive = false;
        break;
    }

    this.handleChangeCause(data.cause);
  }

  /**
   * 处理状态变化原因
   */
  private handleChangeCause(cause: netHandover.MultiPathChangeCause): void {
    const causeMap: Record<number, string> = {
      [netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_REQUEST_NORMAL]: '正常发起多网请求',
      [netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NORMAL]: '正常释放多网请求',
      [netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NETWORK]: '网络原因释放多网',
      [netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_USER_REFUSED]: '用户操作开关释放多网',
      [netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_NO_QUOTA]: '配额耗尽释放多网',
      [netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_POWER_CONSUMPTION]: '功耗原因释放多网',
      [netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_INSUFFICIENT_TRAFFIC]: '流量不足释放多网',
      [netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_CONFLICT]: '场景冲突释放多网',
      [netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_FUSING]: '应用使用不规范释放多网',
      [netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_RELEASE_SYS_DEFAULT]: '系统网络状态变化释放多网',
      [netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_SUSPEND_ENTER]: '多网进入挂起状态',
      [netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_SUSPEND_LEAVE]: '多网退出挂起状态',
      [netHandover.MultiPathChangeCause.MULTIPATH_CHANGE_CAUSE_CONN_PROPERTIES_UPDATE]: '多网链路属性信息更新'
    };

    const message = causeMap[cause] || `未知原因: ${cause}`;
    console.info(`[MultiPath] 状态变化原因: ${message}`);
  }

  /**
   * 处理请求结果
   */
  private handleRequestResult(result: netHandover.MultiPathErrorResult): void {
    const resultMap: Record<number, string> = {
      [netHandover.MultiPathErrorResult.MULTIPATH_ERROR_NETWORK_REFUSED]: '多网请求被网络拒绝',
      [netHandover.MultiPathErrorResult.MULTIPATH_ERROR_TIMEOUT]: '多网建立超时',
      [netHandover.MultiPathErrorResult.MULTIPATH_ERROR_LOCAL]: '多网建立过程中本地释放'
    };

    const message = resultMap[result] || `未知结果: ${result}`;
    console.error(`[MultiPath] 请求失败: ${message}`);
  }

  /**
   * 处理请求错误
   */
  private handleRequestError(errorCode: number): void {
    const errorMap: Record<number, string> = {
      1013620000: '多网功能没有使能',
      1013620001: '多网已经激活或正在激活中',
      1013620002: '应用多网请求已达到上限',
      1013620003: '功耗限制不允许发起多网',
      1013620004: '限额耗尽',
      1013620005: '多网请求场景冲突',
      1013620006: '多网发起太频繁',
      1013620007: '没有合适的多网链路可用',
      1013620008: '流量不足',
      1013620009: '不支持并发'
    };

    const message = errorMap[errorCode] || `未知错误: ${errorCode}`;
    console.error(`[MultiPath] 请求错误: ${message}`);
  }
}

/**
 * 使用示例
 */
export async function multiPathExample(): Promise<void> {
  console.info('=== 多网并发使用示例开始 ===');
  
  const manager = new MultiPathManager();
  
  // 1. 查询配额
  console.info('[Step 1] 查询多网配额');
  const quota = manager.checkQuota();
  if (!quota) {
    console.error('[MultiPath] 配额查询失败或配额不足，无法使用多网并发');
    return;
  }
  
  // 2. 订阅多网状态变化
  console.info('[Step 2] 订阅多网状态变化');
  manager.subscribeStateChange();
  
  // 3. 订阅系统推荐（可选）
  console.info('[Step 3] 订阅系统多网推荐');
  manager.subscribeRecommendation();
  
  // 4. 发起多网请求
  console.info('[Step 4] 发起多网请求');
  const success = await manager.request();
  if (!success) {
    console.error('[MultiPath] 多网请求失败');
    manager.unsubscribeStateChange();
    manager.unsubscribeRecommendation();
    return;
  }
  
  try {
    // 5. 执行业务逻辑
    console.info('[Step 5] 执行业务逻辑（多网并发模式）');
    await performBusinessTask();
    console.info('[MultiPath] 业务逻辑执行完成');
  } catch (err) {
    console.error('[MultiPath] 业务逻辑执行失败:', err);
  } finally {
    // 6. 释放多网资源
    console.info('[Step 6] 释放多网资源');
    await manager.release();
    
    // 7. 取消订阅
    console.info('[Step 7] 取消订阅');
    manager.unsubscribeStateChange();
    manager.unsubscribeRecommendation();
    
    console.info('=== 多网并发使用示例结束 ===');
  }
}

/**
 * 业务任务示例
 */
async function performBusinessTask(): Promise<void> {
  return new Promise((resolve) => {
    setTimeout(() => {
      console.info('[MultiPath] 业务任务执行中...');
      resolve();
    }, 3000);
  });
}

/**
 * 完整生命周期管理示例
 */
export class MultiPathLifecycle {
  private manager: MultiPathManager = new MultiPathManager();
  private isInitialized: boolean = false;

  /**
   * 初始化多网管理
   */
  async initialize(): Promise<boolean> {
    if (this.isInitialized) {
      console.warn('[Lifecycle] 已经初始化');
      return true;
    }

    console.info('[Lifecycle] 初始化多网管理');
    
    // 查询配额
    const quota = this.manager.checkQuota();
    if (!quota) {
      console.error('[Lifecycle] 配额不足，初始化失败');
      return false;
    }

    // 订阅状态变化
    this.manager.subscribeStateChange();
    
    // 订阅系统推荐
    this.manager.subscribeRecommendation();
    
    this.isInitialized = true;
    console.info('[Lifecycle] 初始化成功');
    return true;
  }

  /**
   * 启动多网并发
   */
  async startMultiPath(): Promise<boolean> {
    if (!this.isInitialized) {
      console.error('[Lifecycle] 未初始化，无法启动多网');
      return false;
    }

    console.info('[Lifecycle] 启动多网并发');
    return await this.manager.request();
  }

  /**
   * 停止多网并发
   */
  async stopMultiPath(): Promise<void> {
    if (!this.isInitialized) {
      return;
    }

    console.info('[Lifecycle] 停止多网并发');
    await this.manager.release();
  }

  /**
   * 清理资源
   */
  async cleanup(): Promise<void> {
    if (!this.isInitialized) {
      return;
    }

    console.info('[Lifecycle] 清理资源');
    
    // 释放多网
    await this.manager.release();
    
    // 取消订阅
    this.manager.unsubscribeStateChange();
    this.manager.unsubscribeRecommendation();
    
    this.isInitialized = false;
    console.info('[Lifecycle] 清理完成');
  }
}