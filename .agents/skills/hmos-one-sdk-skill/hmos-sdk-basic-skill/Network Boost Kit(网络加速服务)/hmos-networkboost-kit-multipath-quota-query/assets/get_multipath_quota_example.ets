/**
 * 多网配额查询完整示例代码
 * 功能：查询应用多网配额使用情况，包括已使用和剩余配额
 * API: netHandover.getMultiPathQuotaStats()
 * 权限: ohos.permission.LINKTURBO
 */

import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 多网配额管理器
 * 提供配额查询、分析和管理功能
 */
export class MultiPathQuotaManager {
  private static instance: MultiPathQuotaManager;
  
  // 配额状态枚举
  public enum QuotaStatus {
    SUFFICIENT = '充足',      // 剩余配额>50%
    MODERATE = '适中',        // 剩余配额20%-50%
    LOW = '不足',             // 剩余配额<20%
    EXHAUSTED = '耗尽'        // 剩余配额=0
  }
  
  private constructor() {}
  
  /**
   * 获取单例实例
   */
  public static getInstance(): MultiPathQuotaManager {
    if (!MultiPathQuotaManager.instance) {
      MultiPathQuotaManager.instance = new MultiPathQuotaManager();
    }
    return MultiPathQuotaManager.instance;
  }
  
  /**
   * 查询多网配额基本信息
   * @returns 配额信息对象
   */
  public queryQuota(): netHandover.MultiPathQuota | null {
    try {
      const quota = netHandover.getMultiPathQuotaStats();
      console.info('[QuotaManager] 配额查询成功');
      this.logQuotaInfo(quota);
      return quota;
    } catch (err) {
      const error = err as BusinessError;
      console.error('[QuotaManager] 配额查询失败 - 错误码: ' + error.code);
      this.handleError(error);
      return null;
    }
  }
  
  /**
   * 分析配额状态
   * @param quota 配额信息
   * @returns 配额状态评估
   */
  public analyzeQuotaStatus(quota: netHandover.MultiPathQuota): string {
    const totalCount = quota.used.count + quota.remaining.count;
    const totalDuration = quota.used.duration + quota.remaining.duration;
    
    if (totalCount === 0 && totalDuration === 0) {
      return this.QuotaStatus.EXHAUSTED;
    }
    
    // 计算剩余配额比例（次数和时长综合评估）
    const countRatio = quota.remaining.count / totalCount;
    const durationRatio = quota.remaining.duration / totalDuration;
    const avgRatio = (countRatio + durationRatio) / 2;
    
    if (avgRatio >= 0.5) {
      return this.QuotaStatus.SUFFICIENT;
    } else if (avgRatio >= 0.2) {
      return this.QuotaStatus.MODERATE;
    } else if (avgRatio > 0) {
      return this.QuotaStatus.LOW;
    } else {
      return this.QuotaStatus.EXHAUSTED;
    }
  }
  
  /**
   * 判断是否可以发起多网请求
   * @param quota 配额信息
   * @returns 是否建议发起多网请求
   */
  public canRequestMultiPath(quota: netHandover.MultiPathQuota): boolean {
    const status = this.analyzeQuotaStatus(quota);
    
    // 配额耗尽时不建议发起
    if (status === this.QuotaStatus.EXHAUSTED) {
      console.warn('[QuotaManager] 配额已耗尽，不建议发起多网请求');
      return false;
    }
    
    // 配额不足时谨慎发起
    if (status === this.QuotaStatus.LOW) {
      console.warn('[QuotaManager] 配额不足，建议谨慎使用多网请求');
      // 可根据业务优先级决定是否发起
      return false;
    }
    
    return true;
  }
  
  /**
   * 获取配额使用建议
   * @param quota 配额信息
   * @returns 使用建议字符串
   */
  public getQuotaRecommendation(quota: netHandover.MultiPathQuota): string {
    const status = this.analyzeQuotaStatus(quota);
    
    switch (status) {
      case this.QuotaStatus.SUFFICIENT:
        return '配额充足，可正常使用多网加速功能';
      case this.QuotaStatus.MODERATE:
        return '配额适中，建议合理规划多网使用频率';
      case this.QuotaStatus.LOW:
        return '配额不足，建议减少多网使用或等待配额刷新';
      case this.QuotaStatus.EXHAUSTED:
        return '配额已耗尽，请等待24小时后自动刷新';
      default:
        return '配额状态未知';
    }
  }
  
  /**
   * 生成配额报告
   * @returns 配额详细报告
   */
  public generateQuotaReport(): object {
    const quota = this.queryQuota();
    
    if (!quota) {
      return {
        status: '查询失败',
        timestamp: new Date().toISOString(),
        error: '无法获取配额信息'
      };
    }
    
    return {
      status: '查询成功',
      timestamp: new Date().toISOString(),
      quotaInfo: {
        used: {
          count: quota.used.count,
          duration: quota.used.duration,
          durationFormatted: this.formatDuration(quota.used.duration)
        },
        remaining: {
          count: quota.remaining.count,
          duration: quota.remaining.duration,
          durationFormatted: this.formatDuration(quota.remaining.duration)
        }
      },
      quotaStatus: this.analyzeQuotaStatus(quota),
      quotaRatio: this.calculateQuotaRatio(quota),
      recommendation: this.getQuotaRecommendation(quota),
      canRequestMultiPath: this.canRequestMultiPath(quota)
    };
  }
  
  /**
   * 记录配额信息日志
   */
  private logQuotaInfo(quota: netHandover.MultiPathQuota): void {
    console.info('[QuotaManager] 已使用配额次数: ' + quota.used.count);
    console.info('[QuotaManager] 已使用配额时长: ' + quota.used.duration + '秒');
    console.info('[QuotaManager] 剩余配额次数: ' + quota.remaining.count);
    console.info('[QuotaManager] 剩余配额时长: ' + quota.remaining.duration + '秒');
    console.info('[QuotaManager] 配额状态: ' + this.analyzeQuotaStatus(quota));
  }
  
  /**
   * 格式化时长显示
   */
  private formatDuration(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    
    if (hours > 0) {
      return `${hours}小时${minutes}分钟${secs}秒`;
    } else if (minutes > 0) {
      return `${minutes}分钟${secs}秒`;
    } else {
      return `${secs}秒`;
    }
  }
  
  /**
   * 计算配额使用比例
   */
  private calculateQuotaRatio(quota: netHandover.MultiPathQuota): string {
    const totalCount = quota.used.count + quota.remaining.count;
    const totalDuration = quota.used.duration + quota.remaining.duration;
    
    if (totalCount === 0) {
      return '0%';
    }
    
    const usedRatio = (quota.used.count / totalCount) * 100;
    return usedRatio.toFixed(1) + '%';
  }
  
  /**
   * 错误处理
   */
  private handleError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        console.error('[QuotaManager] 权限校验失败 - 需申请ohos.permission.LINKTURBO权限');
        this.showPermissionDialog();
        break;
      case 1013600001:
        console.error('[QuotaManager] 内部处理异常 - 请稍后重试');
        break;
      case 1013600002:
        console.error('[QuotaManager] 系统处理异常 - 请检查网络管理服务状态');
        break;
      case 801:
        console.error('[QuotaManager] 设备不支持该API - 请升级系统版本至6.0.0(20)');
        break;
      default:
        console.error('[QuotaManager] 未知错误: ' + error.message);
    }
  }
  
  /**
   * 显示权限申请对话框（UI层实现）
   */
  private showPermissionDialog(): void {
    // 这里应调用UI层显示权限申请对话框
    // 实际实现需要在UI组件中完成
    console.warn('[QuotaManager] 请在应用中申请ohos.permission.LINKTURBO权限');
  }
}

/**
 * 使用示例
 */
export function exampleUsage(): void {
  const quotaManager = MultiPathQuotaManager.getInstance();
  
  // 示例1：基本查询
  const quota = quotaManager.queryQuota();
  if (quota) {
    console.info('剩余配额次数: ' + quota.remaining.count);
    console.info('剩余配额时长: ' + quota.remaining.duration + '秒');
  }
  
  // 示例2：状态分析
  if (quota) {
    const status = quotaManager.analyzeQuotaStatus(quota);
    console.info('配额状态: ' + status);
    
    const recommendation = quotaManager.getQuotaRecommendation(quota);
    console.info('使用建议: ' + recommendation);
  }
  
  // 示例3：判断是否可以发起多网请求
  if (quota && quotaManager.canRequestMultiPath(quota)) {
    console.info('建议：可以发起多网请求');
    // 调用 netHandover.requestMultiPath()
  } else {
    console.warn('建议：不建议发起多网请求');
  }
  
  // 示例4：生成完整报告
  const report = quotaManager.generateQuotaReport();
  console.info('配额报告: ' + JSON.stringify(report, null, 2));
}

// 导出供外部使用
export default MultiPathQuotaManager;