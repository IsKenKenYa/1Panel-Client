import { wifiManager } from '@kit.ConnectivityKit';

/**
 * Wi-Fi状态判断示例
 * 功能：查询WLAN开关状态，注册状态监听事件
 */

// Wi-Fi状态枚举值说明
const WifiState = {
  DISABLED: 0,    // WLAN已关闭
  ENABLED: 1,     // WLAN已开启
  ENABLING: 2,    // WLAN正在开启
  DISABLING: 3,   // WLAN正在关闭
  UNKNOWN: -1     // 未知状态
};

/**
 * 查询Wi-Fi是否已使能
 * @returns {boolean} true-已使能，false-未使能
 */
export function checkWifiActive(): boolean {
  try {
    let isWifiActive = wifiManager.isWifiActive();
    console.info(`Wi-Fi active status: ${isWifiActive}`);
    return isWifiActive;
  } catch (error) {
    console.error(`Failed to check Wi-Fi status: ${error.message}`);
    
    // 错误码处理
    if (error.code === 201) {
      console.error("Permission denied. Need ohos.permission.GET_WIFI_INFO");
    } else if (error.code === 801) {
      console.error("Capability not supported. Device lacks Wi-Fi STA capability");
    } else if (error.code === 2501000) {
      console.error("Operation failed. Try restarting Wi-Fi or device");
    }
    
    return false;
  }
}

/**
 * 注册Wi-Fi状态改变事件监听
 * @param callback 状态改变回调函数
 */
export function registerWifiStateListener(
  callback?: (state: number) => void
): ((state: number) => void) | null {
  // 默认回调函数
  const defaultCallback = (result: number) => {
    let stateName = "";
    switch (result) {
      case WifiState.DISABLED:
        stateName = 'DISABLED';
        break;
      case WifiState.ENABLED:
        stateName = 'ENABLED';
        break;
      case WifiState.ENABLING:
        stateName = 'ENABLING';
        break;
      case WifiState.DISABLING:
        stateName = 'DISABLING';
        break;
      default:
        stateName = 'UNKNOWN';
        break;
    }
    console.info(`Wi-Fi state changed: ${stateName} (${result})`);
  };
  
  const listenerCallback = callback || defaultCallback;
  
  try {
    wifiManager.on("wifiStateChange", listenerCallback);
    console.info("Wi-Fi state listener registered successfully");
    return listenerCallback;
  } catch (error) {
    console.error(`Failed to register Wi-Fi state listener: ${error.message}`);
    return null;
  }
}

/**
 * 取消注册Wi-Fi状态改变事件监听
 * @param callback 要取消的回调函数
 */
export function unregisterWifiStateListener(
  callback: (state: number) => void
): void {
  try {
    wifiManager.off("wifiStateChange", callback);
    console.info("Wi-Fi state listener unregistered successfully");
  } catch (error) {
    console.error(`Failed to unregister Wi-Fi state listener: ${error.message}`);
  }
}

/**
 * 完整的Wi-Fi状态判断流程示例
 */
export function wifiStateCheckExample(): void {
  let stateListener: ((state: number) => void) | null = null;
  
  try {
    // 步骤1：注册状态监听
    stateListener = registerWifiStateListener((state) => {
      console.info(`Current Wi-Fi state: ${state}`);
      
      // 根据状态执行不同逻辑
      if (state === WifiState.ENABLED) {
        console.info("Wi-Fi is enabled, can proceed with connection");
      } else if (state === WifiState.DISABLED) {
        console.warn("Wi-Fi is disabled, need to enable first");
      }
    });
    
    if (!stateListener) {
      console.error("Failed to register listener, abort operation");
      return;
    }
    
    // 步骤2：查询当前Wi-Fi状态
    let isActive = checkWifiActive();
    
    if (!isActive) {
      console.info("Wi-Fi is not enabled. Cannot proceed with connection.");
      // 提示用户开启Wi-Fi
      // 注意：普通应用无权限调用enableWifi()，需系统应用权限
      return;
    }
    
    console.info("Wi-Fi is enabled. Ready to connect.");
    
    // 步骤3：继续执行后续操作（如连接Wi-Fi）
    // ...
    
  } catch (error) {
    console.error(`Wi-Fi state check failed: ${error.message}`);
  } finally {
    // 步骤4：清理监听
    if (stateListener) {
      unregisterWifiStateListener(stateListener);
    }
  }
}

/**
 * 检查设备是否支持Wi-Fi STA特性
 * @returns {boolean} true-支持，false-不支持
 */
export function checkWifiStaCapability(): boolean {
  try {
    // 检查基础结构模式特性（feature ID 0x0001）
    let isSupported = wifiManager.isFeatureSupported(0x0001);
    console.info(`Wi-Fi STA capability supported: ${isSupported}`);
    return isSupported;
  } catch (error) {
    console.error(`Failed to check Wi-Fi capability: ${error.message}`);
    return false;
  }
}

// 使用示例
if (checkWifiStaCapability()) {
  console.info("Device supports Wi-Fi STA mode");
  wifiStateCheckExample();
} else {
  console.warn("Device does not support Wi-Fi STA mode");
}