import { netQuality } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 网络质量订阅管理类
 * 提供网络质量QoS信息的订阅和取消订阅功能
 */
export class NetworkQualityManager {
  private static instance: NetworkQualityManager;
  private qosCallback: ((list: Array<netQuality.NetworkQos>) => void) | undefined;
  private isSubscribed: boolean = false;

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): NetworkQualityManager {
    if (!NetworkQualityManager.instance) {
      NetworkQualityManager.instance = new NetworkQualityManager();
    }
    return NetworkQualityManager.instance;
  }

  /**
   * 订阅网络质量QoS信息变化
   * @param onQosChanged 网络质量变化回调函数
   * @returns 是否订阅成功
   */
  subscribe(onQosChanged?: (qos: netQuality.NetworkQos) => void): boolean {
    try {
      // 避免重复订阅
      if (this.isSubscribed) {
        console.warn('已经订阅网络质量信息，请勿重复订阅');
        return false;
      }

      // 定义回调函数
      this.qosCallback = (list: Array<netQuality.NetworkQos>) => {
        if (!list || list.length === 0) {
          console.warn('网络质量数据为空');
          return;
        }

        list.forEach((qos) => {
          // 数据有效性验证
          if (!this.validateQosData(qos)) {
            console.warn('网络质量数据无效，跳过处理');
            return;
          }

          // 打印网络质量信息
          this.logQosInfo(qos);

          // 调用用户回调
          if (onQosChanged) {
            onQosChanged(qos);
          }
        });
      };

      // 订阅网络质量变化事件
      netQuality.on('netQosChange', this.qosCallback);
      this.isSubscribed = true;
      console.info('网络质量订阅成功');
      return true;
    } catch (err) {
      const error = err as BusinessError;
      this.handleSubscribeError(error);
      return false;
    }
  }

  /**
   * 取消订阅网络质量变化
   */
  unsubscribe(): void {
    try {
      if (!this.isSubscribed) {
        console.warn('未订阅网络质量信息，无需取消');
        return;
      }

      if (this.qosCallback) {
        netQuality.off('netQosChange', this.qosCallback);
      } else {
        netQuality.off('netQosChange');
      }

      this.isSubscribed = false;
      this.qosCallback = undefined;
      console.info('网络质量订阅已取消');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`取消订阅失败，错误码: ${error.code}, 错误信息: ${error.message}`);
    }
  }

  /**
   * 验证网络质量数据有效性
   * @param qos 网络质量数据
   * @returns 是否有效
   */
  private validateQosData(qos: netQuality.NetworkQos): boolean {
    if (qos.pathType === undefined || qos.pathType === null) {
      return false;
    }

    if (qos.linkUpBandwidth < 0 || qos.linkDownBandwidth < 0) {
      return false;
    }

    if (qos.rttMs < 0) {
      return false;
    }

    return true;
  }

  /**
   * 打印网络质量信息
   * @param qos 网络质量数据
   */
  private logQosInfo(qos: netQuality.NetworkQos): void {
    const linkType = this.getLinkTypeName(qos.pathType);
    const upBandwidthMbps = qos.linkUpBandwidth / 1000000;
    const downBandwidthMbps = qos.linkDownBandwidth / 1000000;
    const upRateKBps = qos.linkUpRate / 8000;
    const downRateKBps = qos.linkDownRate / 8000;
    const totalRate = (qos.linkUpRate + qos.linkDownRate) / 8;

    console.info(`[${linkType}] 网络质量信息:`);
    console.info(`  上行带宽: ${upBandwidthMbps.toFixed(2)} Mbps`);
    console.info(`  下行带宽: ${downBandwidthMbps.toFixed(2)} Mbps`);
    console.info(`  上行速率: ${upRateKBps.toFixed(2)} KB/s`);
    console.info(`  下行速率: ${downRateKBps.toFixed(2)} KB/s`);
    console.info(`  实时总速率: ${totalRate.toFixed(2)} B/s`);
    console.info(`  RTT时延: ${qos.rttMs} ms`);
    console.info(`  上行缓冲时延: ${qos.linkUpBufferDelayMs} ms`);
  }

  /**
   * 获取链路类型名称
   * @param pathType 路径类型枚举值
   * @returns 链路类型名称
   */
  private getLinkTypeName(pathType: netQuality.PathType): string {
    const typeMap: Record<number, string> = {
      [netQuality.PathType.CELLULAR_PRIMARY]: '蜂窝主卡',
      [netQuality.PathType.CELLULAR_SECONDARY]: '蜂窝副卡',
      [netQuality.PathType.WIFI_PRIMARY]: '主WiFi',
      [netQuality.PathType.WIFI_SECONDARY]: '辅WiFi'
    };
    return typeMap[pathType] || '未知链路';
  }

  /**
   * 处理订阅错误
   * @param error 错误对象
   */
  private handleSubscribeError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        console.error('权限校验失败，请检查是否申请了ohos.permission.GET_NETWORK_INFO权限');
        break;
      case 401:
        console.error('参数检查失败，请检查参数类型和格式');
        break;
      case 801:
        console.error('设备不支持该API，当前设备可能不支持网络质量评估功能');
        break;
      default:
        console.error(`未知错误，错误码: ${error.code}, 错误信息: ${error.message}`);
        break;
    }
  }

  /**
   * 检查订阅状态
   * @returns 是否已订阅
   */
  isSubscribedStatus(): boolean {
    return this.isSubscribed;
  }
}

/**
 * 使用示例
 */
export function exampleUsage(): void {
  const manager = NetworkQualityManager.getInstance();

  // 订阅网络质量
  manager.subscribe((qos) => {
    console.info(`收到网络质量变化，链路类型: ${qos.pathType}`);

    // 根据网络质量调整业务策略
    const totalRate = (qos.linkUpRate + qos.linkDownRate) / 8;
    if (totalRate < 100000) { // < 100 KB/s
      console.warn('网络速度较低，建议降低视频清晰度');
    } else if (totalRate > 1000000) { // > 1 MB/s
      console.info('网络速度良好，可以使用高清视频');
    }
  });

  // 业务结束后取消订阅
  setTimeout(() => {
    manager.unsubscribe();
  }, 60000); // 60秒后取消订阅
}