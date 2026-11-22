import { wifiManager } from '@kit.ConnectivityKit';

/**
 * 完整的STA模式开发示例
 * 包含：状态判断、候选网络管理、连接建立、状态监听、错误处理等完整流程
 */

/**
 * STA模式管理类
 * 提供完整的Wi-Fi STA功能管理
 */
export class WifiStaManager {
  private stateListener: ((state: number) => void) | null = null;
  private connectionListener: ((state: number) => void) | null = null;
  private currentNetworkId: number = -1;
  
  /**
   * 初始化STA管理器
   * 注册必要的监听器
   */
  async initialize(): Promise<boolean> {
    try {
      // 步骤1：检查设备能力
      let isSupported = wifiManager.isFeatureSupported(0x0001);
      if (!isSupported) {
        console.error("Device does not support Wi-Fi STA mode");
        return false;
      }
      
      // 步骤2：检查Wi-Fi状态
      let isActive = wifiManager.isWifiActive();
      if (!isActive) {
        console.warn("Wi-Fi not enabled. Need to enable Wi-Fi first.");
        // 注意：普通应用无法直接调用enableWifi()
        // 需要提示用户手动开启或系统应用调用
        return false;
      }
      
      // 步骤3：注册状态监听器
      this.registerListeners();
      
      console.info("Wi-Fi STA manager initialized successfully");
      return true;
      
    } catch (error) {
      console.error(`Failed to initialize STA manager: ${error.message}`);
      return false;
    }
  }
  
  /**
   * 注册Wi-Fi状态监听器
   */
  private registerListeners(): void {
    try {
      // 注册Wi-Fi开关状态监听
      this.stateListener = (state: number) => {
        const states = ['DISABLED', 'ENABLED', 'ENABLING', 'DISABLING'];
        console.info(`Wi-Fi state changed: ${states[state]}`);
        
        if (state === 0) { // DISABLED
          console.warn("Wi-Fi disabled, cannot continue STA operations");
        } else if (state === 1) { // ENABLED
          console.info("Wi-Fi enabled, ready for STA operations");
        }
      };
      
      wifiManager.on("wifiStateChange", this.stateListener);
      
      // 注册连接状态监听
      this.connectionListener = (state: number) => {
        const states = [
          "SCANNING", "CONNECTING", "AUTHENTICATING",
          "OBTAINING_IPADDR", "CONNECTED", "DISCONNECTING",
          "DISCONNECTED", "UNKNOWN"
        ];
        console.info(`Connection state: ${states[state]}`);
        
        if (state === 4) { // CONNECTED
          console.info("Wi-Fi connection established");
        } else if (state === 6) { // DISCONNECTED
          console.warn("Wi-Fi connection lost");
        }
      };
      
      wifiManager.on("wifiConnectionChange", this.connectionListener);
      
      console.info("All listeners registered successfully");
      
    } catch (error) {
      console.error(`Failed to register listeners: ${error.message}`);
      throw error;
    }
  }
  
  /**
   * 取消注册所有监听器
   */
  private unregisterListeners(): void {
    try {
      if (this.stateListener) {
        wifiManager.off("wifiStateChange", this.stateListener);
        this.stateListener = null;
        console.info("State listener unregistered");
      }
      
      if (this.connectionListener) {
        wifiManager.off("wifiConnectionChange", this.connectionListener);
        this.connectionListener = null;
        console.info("Connection listener unregistered");
      }
      
    } catch (error) {
      console.error(`Failed to unregister listeners: ${error.message}`);
    }
  }
  
  /**
   * 连接到Wi-Fi网络
   * @param ssid 网络SSID
   * @param password 网络密码
   * @param securityType 加密类型
   * @returns {Promise<boolean>} true-连接成功，false-连接失败
   */
  async connectToNetwork(
    ssid: string,
    password: string,
    securityType: wifiManager.WifiSecurityType
  ): Promise<boolean> {
    try {
      // 步骤1：验证Wi-Fi状态
      let isActive = wifiManager.isWifiActive();
      if (!isActive) {
        console.error("Wi-Fi not enabled. Cannot connect.");
        return false;
      }
      
      // 步骤2：验证配置参数
      if (!this.validateConfig(ssid, password, securityType)) {
        return false;
      }
      
      // 步骤3：添加候选网络配置
      let config: wifiManager.WifiDeviceConfig = {
        ssid: ssid,
        preSharedKey: password,
        securityType: securityType
      };
      
      this.currentNetworkId = await wifiManager.addCandidateConfig(config);
      console.info(`Candidate network added: ID ${this.currentNetworkId}`);
      
      // 步骤4：连接到候选网络
      wifiManager.connectToCandidateConfig(this.currentNetworkId);
      console.info("Connection request initiated");
      
      // 步骤5：等待连接完成（最多30秒）
      let connected = await this.waitForConnection(30000);
      
      if (connected) {
        console.info("Successfully connected to Wi-Fi network");
        
        // 步骤6：获取连接信息
        let linkedInfo = await wifiManager.getLinkedInfo();
        console.info(`Connected to: ${linkedInfo.ssid}`);
        console.info(`Signal strength: ${linkedInfo.rssi} dBm`);
        
        let signalLevel = wifiManager.getSignalLevel(linkedInfo.rssi, linkedInfo.band);
        console.info(`Signal level: ${signalLevel}/4`);
        
        return true;
      } else {
        console.error("Connection failed or timeout");
        
        // 步骤7：清理失败的配置
        await this.cleanupFailedConnection();
        return false;
      }
      
    } catch (error) {
      console.error(`Connection failed: ${error.message}`);
      
      // 错误码处理
      this.handleConnectionError(error);
      
      // 清理失败的配置
      await this.cleanupFailedConnection();
      
      return false;
    }
  }
  
  /**
   * 等待连接完成
   * @param maxWaitTime 最大等待时间（毫秒）
   * @returns {Promise<boolean>} true-已连接，false-未连接
   */
  private async waitForConnection(maxWaitTime: number): Promise<boolean> {
    const startTime = Date.now();
    const checkInterval = 1000; // 每秒检查一次
    
    while (Date.now() - startTime < maxWaitTime) {
      try {
        let isConnected = wifiManager.isConnected();
        
        if (isConnected) {
          console.info("Connection established");
          return true;
        }
        
        // 等待1秒后再次检查
        await new Promise(resolve => setTimeout(resolve, checkInterval));
        
      } catch (error) {
        console.error(`Error checking connection status: ${error.message}`);
        await new Promise(resolve => setTimeout(resolve, checkInterval));
      }
    }
    
    console.warn(`Connection timeout after ${maxWaitTime}ms`);
    return false;
  }
  
  /**
   * 验证Wi-Fi配置参数
   */
  private validateConfig(
    ssid: string,
    password: string,
    securityType: wifiManager.WifiSecurityType
  ): boolean {
    // 验证SSID
    if (!ssid || ssid.length === 0 || ssid.length > 32) {
      console.error(`Invalid SSID: length ${ssid.length}`);
      return false;
    }
    
    // 根据加密类型验证密码
    switch (securityType) {
      case wifiManager.WifiSecurityType.WIFI_SEC_TYPE_OPEN:
        if (password && password.length > 0) {
          console.error("OPEN type requires empty password");
          return false;
        }
        break;
        
      case wifiManager.WifiSecurityType.WIFI_SEC_TYPE_PSK:
        if (password.length < 8) {
          console.error("PSK password must be at least 8 bytes");
          return false;
        }
        break;
        
      case wifiManager.WifiSecurityType.WIFI_SEC_TYPE_SAE:
        if (password.length < 1) {
          console.error("SAE password must be at least 1 byte");
          return false;
        }
        break;
        
      case wifiManager.WifiSecurityType.WIFI_SEC_TYPE_WEP:
        const validLengths = [5, 10, 13, 26, 16, 32];
        if (!validLengths.includes(password.length)) {
          console.error(`Invalid WEP password length: ${password.length}`);
          return false;
        }
        break;
    }
    
    return true;
  }
  
  /**
   * 处理连接错误
   */
  private handleConnectionError(error: any): void {
    const errorMessages = {
      201: "Permission denied. Check GET_WIFI_INFO and SET_WIFI_INFO permissions.",
      401: "Invalid parameters. Check SSID and password format.",
      801: "Capability not supported. Device lacks Wi-Fi STA capability.",
      2501000: "Operation failed. Try restarting Wi-Fi or device.",
      2501001: "Wi-Fi STA disabled. Enable Wi-Fi first."
    };
    
    let message = errorMessages[error.code] || `Unknown error: ${error.code}`;
    console.error(`Error ${error.code}: ${message}`);
  }
  
  /**
   * 清理失败的连接配置
   */
  private async cleanupFailedConnection(): Promise<void> {
    if (this.currentNetworkId >= 0) {
      try {
        await wifiManager.removeCandidateConfig(this.currentNetworkId);
        console.info(`Removed failed network config: ${this.currentNetworkId}`);
        this.currentNetworkId = -1;
      } catch (error) {
        console.error(`Failed to cleanup network: ${error.message}`);
      }
    }
  }
  
  /**
   * 断开Wi-Fi连接
   * @returns {Promise<boolean>} true-断开成功，false-断开失败
   */
  async disconnect(): Promise<boolean> {
    try {
      // 检查是否已连接
      let isConnected = wifiManager.isConnected();
      
      if (!isConnected) {
        console.info("Already disconnected");
        return true;
      }
      
      // 获取当前连接信息
      let linkedInfo = await wifiManager.getLinkedInfo();
      console.info(`Disconnecting from: ${linkedInfo.ssid}`);
      
      // 调用断开连接接口（需要系统权限）
      // wifiManager.disconnect(); // API 15+
      
      // 如果没有disconnect接口，可以移除候选网络配置
      if (this.currentNetworkId >= 0) {
        await wifiManager.removeCandidateConfig(this.currentNetworkId);
        console.info("Disconnected by removing candidate network");
        this.currentNetworkId = -1;
      }
      
      return true;
      
    } catch (error) {
      console.error(`Disconnect failed: ${error.message}`);
      return false;
    }
  }
  
  /**
   * 获取当前连接状态
   * @returns {Promise<wifiManager.WifiLinkedInfo | null>} 连接信息或null
   */
  async getCurrentConnectionInfo(): Promise<wifiManager.WifiLinkedInfo | null> {
    try {
      let isConnected = wifiManager.isConnected();
      
      if (!isConnected) {
        console.info("Not connected to any Wi-Fi network");
        return null;
      }
      
      let linkedInfo = await wifiManager.getLinkedInfo();
      return linkedInfo;
      
    } catch (error) {
      console.error(`Failed to get connection info: ${error.message}`);
      return null;
    }
  }
  
  /**
   * 获取所有候选网络配置
   * @returns {Promise<Array<wifiManager.WifiDeviceConfig>>} 候选网络列表
   */
  async getCandidateNetworks(): Promise<Array<wifiManager.WifiDeviceConfig>> {
    try {
      let configs = wifiManager.getCandidateConfigs();
      console.info(`Found ${configs.length} candidate networks`);
      
      for (let config of configs) {
        console.info(`- SSID: ${config.ssid}, Security: ${config.securityType}`);
      }
      
      return configs;
      
    } catch (error) {
      console.error(`Failed to get candidate networks: ${error.message}`);
      return [];
    }
  }
  
  /**
   * 清理所有候选网络配置
   */
  async cleanupAllCandidateNetworks(): Promise<void> {
    try {
      let configs = wifiManager.getCandidateConfigs();
      
      console.info(`Cleaning up ${configs.length} candidate networks`);
      
      for (let config of configs) {
        try {
          await wifiManager.removeCandidateConfig(config.netId);
          console.info(`Removed network: ${config.ssid}`);
        } catch (error) {
          console.error(`Failed to remove ${config.ssid}: ${error.message}`);
        }
      }
      
      this.currentNetworkId = -1;
      console.info("All candidate networks cleaned up");
      
    } catch (error) {
      console.error(`Cleanup failed: ${error.message}`);
    }
  }
  
  /**
   * 销毁STA管理器
   * 清理所有监听器和配置
   */
  async destroy(): Promise<void> {
    try {
      // 清理候选网络配置
      await this.cleanupAllCandidateNetworks();
      
      // 取消注册监听器
      this.unregisterListeners();
      
      console.info("Wi-Fi STA manager destroyed successfully");
      
    } catch (error) {
      console.error(`Failed to destroy STA manager: ${error.message}`);
    }
  }
}

/**
 * STA模式完整使用示例
 */
export async function wifiStaCompleteExample(): Promise<void> {
  // 创建STA管理器
  let staManager = new WifiStaManager();
  
  try {
    // 步骤1：初始化
    let initialized = await staManager.initialize();
    
    if (!initialized) {
      console.error("Failed to initialize Wi-Fi STA manager");
      return;
    }
    
    console.info("STA manager initialized, ready to connect");
    
    // 步骤2：连接到Wi-Fi网络
    let connected = await staManager.connectToNetwork(
      "MyWiFiNetwork",
      "Password123",
      wifiManager.WifiSecurityType.WIFI_SEC_TYPE_PSK
    );
    
    if (connected) {
      console.info("Wi-Fi connected successfully!");
      
      // 步骤3：获取连接信息
      let connectionInfo = await staManager.getCurrentConnectionInfo();
      
      if (connectionInfo) {
        console.info(`Current connection:
          SSID: ${connectionInfo.ssid}
          RSSI: ${connectionInfo.rssi} dBm
          State: ${connectionInfo.connState}`);
      }
      
      // 步骤4：查看候选网络
      let candidateNetworks = await staManager.getCandidateNetworks();
      console.info(`Candidate networks count: ${candidateNetworks.length}`);
      
      // 步骤5：保持连接，执行业务逻辑
      // ...
      
      // 步骤6：断开连接
      await staManager.disconnect();
      console.info("Disconnected from Wi-Fi network");
      
    } else {
      console.error("Failed to connect to Wi-Fi network");
    }
    
  } catch (error) {
    console.error(`STA example failed: ${error.message}`);
  } finally {
    // 步骤7：清理销毁
    await staManager.destroy();
    console.info("STA manager cleaned up");
  }
}

// 执行示例
// wifiStaCompleteExample();