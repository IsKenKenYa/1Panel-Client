import { rcp } from '@kit.RemoteCommunicationKit';
import { url } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 网络质量监测和优化示例
 * 功能：根据网络质量动态调整HTTP请求，优化用户体验
 */

/**
 * 网络质量级别定义
 */
export enum NetworkQualityLevel {
  EXCELLENT = 'excellent',  // 网络质量优秀，无需优化
  GOOD = 'good',           // 网络质量良好，可正常请求
  POOR = 'poor',           // 网络质量较差，启用优化策略
  BAD = 'bad'              // 网络质量很差，激进优化
}

/**
 * 网络质量监测类
 * 负责评估当前网络质量并决定优化策略
 */
export class NetworkQualityMonitor {
  private currentLevel: NetworkQualityLevel = NetworkQualityLevel.GOOD;
  private lastCheckTime: number = 0;
  private checkInterval: number = 60000; // 每60秒检查一次

  /**
   * 检测网络质量
   * 实际应用中应通过网络质量API或自定义检测逻辑
   */
  public checkNetworkQuality(): NetworkQualityLevel {
    const now = Date.now();
    
    // 避免频繁检测
    if (now - this.lastCheckTime < this.checkInterval) {
      return this.currentLevel;
    }

    this.lastCheckTime = now;

    // 模拟网络质量检测逻辑
    // 实际应用中应使用真实的网络质量检测API
    const simulatedQuality = this.simulateNetworkDetection();
    this.currentLevel = simulatedQuality;
    
    console.info(`[NetworkQualityMonitor] Current network quality: ${this.currentLevel}`);
    return this.currentLevel;
  }

  /**
   * 模拟网络质量检测
   * 实际应用中替换为真实检测逻辑
   */
  private simulateNetworkDetection(): NetworkQualityLevel {
    // 示例：根据时间模拟不同网络质量
    const hour = new Date().getHours();
    if (hour >= 9 && hour <= 18) {
      return NetworkQualityLevel.GOOD; // 工作时间网络较好
    } else if (hour >= 19 && hour <= 22) {
      return NetworkQualityLevel.POOR; // 晚间网络拥堵
    } else {
      return NetworkQualityLevel.EXCELLENT; // 其他时间网络优秀
    }
  }

  /**
   * 获取当前网络质量级别
   */
  public getCurrentLevel(): NetworkQualityLevel {
    return this.currentLevel;
  }

  /**
   * 手动设置网络质量级别（用于测试）
   */
  public setNetworkLevel(level: NetworkQualityLevel): void {
    this.currentLevel = level;
    console.info(`[NetworkQualityMonitor] Network level manually set to: ${level}`);
  }
}

/**
 * 网络质量优化拦截器
 * 根据网络质量动态调整请求策略
 */
export class NetworkOptimizationInterceptor implements rcp.Interceptor {
  private readonly monitor: NetworkQualityMonitor;

  constructor(monitor: NetworkQualityMonitor) {
    this.monitor = monitor;
  }

  async intercept(context: rcp.RequestContext, next: rcp.RequestHandler): Promise<rcp.Response> {
    try {
      const networkLevel = this.monitor.checkNetworkQuality();

      // 根据网络质量执行不同的优化策略
      switch (networkLevel) {
        case NetworkQualityLevel.EXCELLENT:
          console.info('[NetworkOptimizationInterceptor] Network excellent, no optimization needed');
          break;

        case NetworkQualityLevel.GOOD:
          console.info('[NetworkOptimizationInterceptor] Network good, standard request');
          break;

        case NetworkQualityLevel.POOR:
          console.info('[NetworkOptimizationInterceptor] Network poor, applying moderate optimization');
          this.applyModerateOptimization(context);
          break;

        case NetworkQualityLevel.BAD:
          console.info('[NetworkOptimizationInterceptor] Network bad, applying aggressive optimization');
          this.applyAggressiveOptimization(context);
          break;
      }

      return next.handle(context);
    } catch (error) {
      console.error('[NetworkOptimizationInterceptor] Optimization failed:', error);
      throw error;
    }
  }

  /**
   * 中等优化策略
   * 修改URL以请求较小资源
   */
  private applyModerateOptimization(context: rcp.RequestContext): void {
    if (context.request.method === 'GET') {
      const parts = context.request.url.pathname.split('.');
      if (parts.length === 2) {
        const changed = url.URL.parseURL(context.request.url.href);
        changed.pathname = parts[0] + '_small.' + parts[1];
        console.info(`[NetworkOptimizationInterceptor] URL optimized: ${context.request.url.href} -> ${changed}`);
        context.request.url = changed;
      }
    }
  }

  /**
   * 激进优化策略
   * 修改URL请求最小资源，并简化请求头
   */
  private applyAggressiveOptimization(context: rcp.RequestContext): void {
    if (context.request.method === 'GET') {
      const parts = context.request.url.pathname.split('.');
      if (parts.length === 2) {
        const changed = url.URL.parseURL(context.request.url.href);
        changed.pathname = parts[0] + '_mini.' + parts[1];
        console.info(`[NetworkOptimizationInterceptor] URL aggressively optimized: ${context.request.url.href} -> ${changed}`);
        context.request.url = changed;
      }

      // 简化请求头，减少数据传输
      if (context.request.headers) {
        const essentialHeaders = {
          'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
        };
        context.request.headers = essentialHeaders;
        console.info('[NetworkOptimizationInterceptor] Headers simplified');
      }
    }
  }
}

/**
 * 创建网络质量优化Session
 * @param monitor 网络质量监测器
 * @returns 配置好的Session对象
 */
export function createOptimizedSession(monitor: NetworkQualityMonitor): rcp.Session {
  const sessionConfig: rcp.SessionConfiguration = {
    interceptors: [new NetworkOptimizationInterceptor(monitor)],
    requestConfiguration: {
      transfer: {
        timeout: {
          connectMs: 10000,  // 连接超时10秒
          transferMs: 30000  // 传输超时30秒（网络不佳时延长）
        },
        autoRedirect: true,
        maxAutoRedirects: 5
      }
    }
  };

  const session = rcp.createSession(sessionConfig);
  console.info('Optimized session created');
  return session;
}

/**
 * 网络质量优化请求示例
 */
export async function requestWithNetworkOptimization(): Promise<void> {
  const monitor = new NetworkQualityMonitor();
  const session = createOptimizedSession(monitor);

  try {
    // 模拟不同网络质量场景
    console.info('=== Testing Network Optimization ===');

    // 场景1：网络优秀
    monitor.setNetworkLevel(NetworkQualityLevel.EXCELLENT);
    console.info('--- Scenario 1: Excellent Network ---');
    const response1 = await session.get('http://example.com/image.jpg');
    console.info(`Response 1: status=${response1.statusCode}`);

    // 场景2：网络较差
    monitor.setNetworkLevel(NetworkQualityLevel.POOR);
    console.info('--- Scenario 2: Poor Network ---');
    const response2 = await session.get('http://example.com/video.mp4');
    console.info(`Response 2: status=${response2.statusCode}`);

    // 场景3：网络很差
    monitor.setNetworkLevel(NetworkQualityLevel.BAD);
    console.info('--- Scenario 3: Bad Network ---');
    const response3 = await session.get('http://example.com/document.pdf');
    console.info(`Response 3: status=${response3.statusCode}`);

  } catch (error) {
    const businessError = error as BusinessError;
    console.error('Network optimization request failed:', businessError.code, businessError.message);
  } finally {
    session.close();
    console.info('Session closed');
  }
}

/**
 * 动态调整超时时间示例
 */
export async function dynamicTimeoutExample(): Promise<void> {
  const monitor = new NetworkQualityMonitor();
  monitor.setNetworkLevel(NetworkQualityLevel.POOR);

  // 根据网络质量动态配置超时时间
  const timeoutConfig = {
    connectMs: monitor.getCurrentLevel() === NetworkQualityLevel.BAD ? 20000 : 5000,
    transferMs: monitor.getCurrentLevel() === NetworkQualityLevel.BAD ? 60000 : 30000
  };

  console.info(`Timeout configured: connect=${timeoutConfig.connectMs}ms, transfer=${timeoutConfig.transferMs}ms`);

  const session = rcp.createSession({
    interceptors: [new NetworkOptimizationInterceptor(monitor)],
    requestConfiguration: {
      transfer: {
        timeout: timeoutConfig,
        autoRedirect: true
      }
    }
  });

  try {
    const response = await session.get('http://example.com/data');
    console.info('Request with dynamic timeout succeeded:', response.statusCode);
  } catch (error) {
    console.error('Request timed out or failed:', error);
  } finally {
    session.close();
  }
}

/**
 * 网络质量恢复后的请求示例
 */
export async function networkRecoveryExample(): Promise<void> {
  const monitor = new NetworkQualityMonitor();

  // 初始网络质量较差
  monitor.setNetworkLevel(NetworkQualityLevel.POOR);
  const session = createOptimizedSession(monitor);

  console.info('=== Network Recovery Test ===');

  try {
    // 网络质量较差时的请求
    console.info('--- Request with poor network ---');
    const response1 = await session.get('http://example.com/image.jpg');
    console.info('Poor network request completed:', response1.statusCode);

    // 模拟网络质量恢复
    monitor.setNetworkLevel(NetworkQualityLevel.EXCELLENT);
    console.info('--- Network recovered to excellent ---');

    // 网络质量恢复后的请求
    console.info('--- Request with excellent network ---');
    const response2 = await session.get('http://example.com/image.jpg');
    console.info('Excellent network request completed:', response2.statusCode);

  } catch (error) {
    console.error('Network recovery test failed:', error);
  } finally {
    session.close();
    console.info('Session closed');
  }
}