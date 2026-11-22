import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * Wear Engine连接销毁管理示例
 * 演示如何主动断开Wear Engine服务连接
 */
class ConnectionDestroyer {
  private isConnected: boolean = true;

  /**
   * 主动销毁Wear Engine服务连接
   * @returns Promise<boolean> 是否销毁成功
   */
  public async destroyConnection(): Promise<boolean> {
    if (!this.isConnected) {
      console.warn('Connection already destroyed');
      return true;
    }

    try {
      await wearEngine.destroy();
      this.isConnected = false;
      console.info('Succeeded in destroying wear engine channel');
      
      // 断开连接后的清理逻辑
      this.cleanupAfterDestroy();
      
      return true;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to destroy wear engine channel. Code: ${err.code}, Message: ${err.message}`);
      
      // 错误处理分支
      switch (err.code) {
        case 1008509999:
          console.error('Internal error, retrying after delay');
          // 延时重试
          await this.delay(2000);
          try {
            await wearEngine.destroy();
            this.isConnected = false;
            this.cleanupAfterDestroy();
            return true;
          } catch (retryError) {
            const retryErr: BusinessError = retryError as BusinessError;
            console.error(`Retry failed. Code: ${retryErr.code}, Message: ${retryErr.message}`);
            return false;
          }
        default:
          console.error(`Unknown error: ${err.message}`);
          return false;
      }
    }
  }

  /**
   * 断开连接后的清理逻辑
   */
  private cleanupAfterDestroy(): void {
    console.info('Performing cleanup after connection destroyed');
    
    // 清理本地缓存
    // 重置状态变量
    // 清理回调函数引用
    
    // 注意：
    // 1. 监测设备状态、收消息、收文件等功能不再可用
    // 2. serviceDie回调函数不会执行
    // 3. 之前注册的回调函数已被清理
    // 4. 如需重新连接，调用任意Wear Engine接口即可
  }

  /**
   * 延时函数
   * @param ms 延时毫秒数
   */
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * 检查连接状态
   */
  public async checkConnectionStatus(): Promise<boolean> {
    try {
      // 调用任意Wear Engine接口检查连接状态
      // 如果连接已断开，此调用会重新建立连接
      const context = getContext(this);
      const deviceClient = wearEngine.getDeviceClient(context);
      await deviceClient.getConnectedDevices();
      
      // 如果成功调用，说明连接已恢复或正常
      this.isConnected = true;
      return true;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Connection check failed. Code: ${err.code}, Message: ${err.message}`);
      return false;
    }
  }

  /**
   * 获取当前连接状态
   */
  public getConnectionStatus(): boolean {
    return this.isConnected;
  }
}

// 使用示例
@Entry
@Component
struct ConnectionDestroyPage {
  private destroyer: ConnectionDestroyer = new ConnectionDestroyer();
  @State connectionStatus: string = '已连接';

  build() {
    Column({ space: 20 }) {
      Text(`连接状态: ${this.connectionStatus}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Button('断开Wear Engine连接')
        .onClick(async () => {
          const success = await this.destroyer.destroyConnection();
          if (success) {
            this.connectionStatus = '已断开';
            console.info('连接断开成功');
          } else {
            console.error('连接断开失败');
          }
        })

      Button('检查连接状态')
        .onClick(async () => {
          const isConnected = await this.destroyer.checkConnectionStatus();
          this.connectionStatus = isConnected ? '已连接' : '已断开';
        })
    }
    .width('100%')
    .padding(20)
  }
}