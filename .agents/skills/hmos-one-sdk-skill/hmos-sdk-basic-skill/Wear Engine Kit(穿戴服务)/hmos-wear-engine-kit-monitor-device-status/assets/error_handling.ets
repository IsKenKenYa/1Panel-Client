import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 穿戴设备状态监控错误处理示例
 * 本示例演示各种错误场景的处理方法
 */

let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(this.getUIContext().getHostContext());
let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());

/**
 * 错误处理器
 */
function handleMonitorError(error: BusinessError, context?: string): void {
  console.error(`[${context || 'Unknown'}] Error ${error.code}: ${error.message}`);
  
  const errorHandlers: Record<number, () => void> = {
    // 参数错误
    401: () => {
      console.error('参数错误: 必填参数缺失或参数类型错误');
      console.warn('解决方案: 检查deviceRandomId是否为有效字符串,检查MonitorItem/MonitorEvent枚举值');
    },
    
    // 设备能力不支持
    801: () => {
      console.error('设备能力不支持: 当前设备类型不支持此能力');
      console.warn('解决方案: 仅支持Phone和Tablet设备,其他设备类型返回801错误码');
    },
    
    // 网络错误
    1008500001: () => {
      console.error('网络错误: 网络不可用');
      console.warn('解决方案: 检查网络连接,等待网络恢复后重试');
      console.warn('建议: 使用重试机制,最多重试3次,间隔2秒');
    },
    
    // 无设备绑定
    1008500002: () => {
      console.error('无设备绑定: 没有绑定的穿戴设备');
      console.warn('解决方案: 提示用户在运动健康App中绑定设备');
    },
    
    // 设备断开连接
    1008500003: () => {
      console.error('设备断开连接: 穿戴设备已断开连接');
      console.warn('解决方案: 提示用户重新连接设备,检查蓝牙连接状态');
      console.warn('建议: 调用getConnectedDevices检查已连接设备列表');
    },
    
    // 应用未申请服务
    1008500004: () => {
      console.error('应用未申请Wear Engine服务');
      console.warn('解决方案: 引导开发者到开发者联盟申请Wear Engine服务');
    },
    
    // 账号未授权
    1008500005: () => {
      console.error('华为账号ID未授权');
      console.warn('解决方案: 提示用户授权华为账号访问');
    },
    
    // 隐私协议未同意
    1008500006: () => {
      console.error('用户隐私协议未同意');
      console.warn('解决方案: 提示用户同意隐私协议');
    },
    
    // 设备能力不支持
    1008500007: () => {
      console.error('设备能力不支持: 设备不支持此能力');
      console.warn('解决方案: 调用isWearEngineCapabilitySupported检查设备能力支持情况');
    },
    
    // 未登录华为账号
    1008500008: () => {
      console.error('账号错误: 用户未登录华为账号');
      console.warn('解决方案: 提示用户登录华为账号');
    },
    
    // 获取账号信息失败
    1008500009: () => {
      console.error('账号错误: 无法获取华为账号信息');
      console.warn('解决方案: 检查账号状态,重新登录华为账号');
    },
    
    // 设备ID无效
    1008500010: () => {
      console.error('设备ID无效');
      console.warn('解决方案: 检查Device.randomId是否有效,重新获取设备列表');
    },
    
    // 订阅回调过多
    1008500012: () => {
      console.error('同类型回调过多');
      console.warn('解决方案: 减少重复订阅,取消无用订阅');
      console.warn('建议: 每种MonitorEvent只订阅一次,避免重复注册回调');
    },
    
    // 内部错误
    1008509999: () => {
      console.error('内部错误');
      console.warn('解决方案: 等待后重试,如持续失败联系技术支持');
    }
  };
  
  const handler = errorHandlers[error.code];
  if (handler) {
    handler();
  } else {
    console.error(`未知错误码: ${error.code}`);
  }
}

/**
 * 网络失败重试机制
 */
async function queryWithRetry(
  deviceRandomId: string,
  item: wearEngine.MonitorItem,
  maxRetry = 3,
  retryInterval = 2000
): Promise<wearEngine.MonitorData | null> {
  let retryCount = 0;
  
  while (retryCount < maxRetry) {
    try {
      const result = await monitorClient.queryStatus(deviceRandomId, item);
      console.info(`查询成功(尝试次数: ${retryCount + 1})`);
      return result;
    } catch (error) {
      const businessError = error as BusinessError;
      retryCount++;
      
      if (businessError.code === 1008500001) {
        // 网络错误,等待后重试
        console.warn(`网络错误,第${retryCount}次重试...`);
        if (retryCount < maxRetry) {
          await new Promise(resolve => setTimeout(resolve, retryInterval));
        }
      } else {
        // 其他错误直接抛出
        handleMonitorError(businessError, 'queryWithRetry');
        return null;
      }
    }
  }
  
  console.error(`重试${maxRetry}次后仍然失败`);
  return null;
}

/**
 * 设备连接状态检查
 */
async function checkDeviceConnection(): Promise<boolean> {
  try {
    const devices = await deviceClient.getConnectedDevices();
    
    if (devices.length === 0) {
      console.warn('未找到已连接设备');
      return false;
    }
    
    console.info(`找到${devices.length}个已连接设备`);
    return true;
  } catch (error) {
    handleMonitorError(error as BusinessError, 'checkDeviceConnection');
    return false;
  }
}

/**
 * 设备能力支持检查
 */
async function checkDeviceCapability(
  device: wearEngine.Device,
  capability: wearEngine.WearEngineCapability
): Promise<boolean> {
  try {
    const isSupported = await device.isWearEngineCapabilitySupported(capability);
    
    if (isSupported) {
      console.info(`设备支持${capability}能力`);
    } else {
      console.warn(`设备不支持${capability}能力`);
    }
    
    return isSupported;
  } catch (error) {
    handleMonitorError(error as BusinessError, 'checkDeviceCapability');
    return false;
  }
}

/**
 * 演示: 参数错误处理
 */
async function demoInvalidParams(): Promise<void> {
  try {
    // 错误示例: 使用无效的设备ID
    await monitorClient.queryStatus('', wearEngine.MonitorItem.POWER_STATUS);
  } catch (error) {
    handleMonitorError(error as BusinessError, 'demoInvalidParams');
  }
}

/**
 * 演示: 设备未连接错误处理
 */
async function demoDeviceDisconnected(): Promise<void> {
  try {
    // 模拟设备断开连接场景
    const devices = await deviceClient.getConnectedDevices();
    if (devices.length === 0) {
      throw new BusinessError('Device disconnected', 1008500003);
    }
    
    const fakeDeviceId = 'invalid_device_id_12345';
    await monitorClient.queryStatus(fakeDeviceId, wearEngine.MonitorItem.POWER_STATUS);
  } catch (error) {
    handleMonitorError(error as BusinessError, 'demoDeviceDisconnected');
    
    // 降级处理: 检查设备连接状态
    const isConnected = await checkDeviceConnection();
    if (!isConnected) {
      console.warn('降级方案: 提示用户连接设备');
    }
  }
}

/**
 * 演示: 网络错误重试
 */
async function demoNetworkError(): Promise<void> {
  try {
    // 模拟网络错误场景
    const devices = await deviceClient.getConnectedDevices();
    if (devices.length === 0) {
      return;
    }
    
    const device = devices[0];
    
    // 使用重试机制查询
    const result = await queryWithRetry(device.randomId, wearEngine.MonitorItem.POWER_STATUS, 3, 2000);
    
    if (result) {
      console.info(`电量: ${result.code}%`);
    } else {
      console.warn('降级方案: 使用缓存数据或提示用户稍后重试');
    }
  } catch (error) {
    handleMonitorError(error as BusinessError, 'demoNetworkError');
  }
}

/**
 * 演示: 订阅回调重复错误
 */
async function demoDuplicateSubscribe(): Promise<void> {
  const devices = await deviceClient.getConnectedDevices();
  if (devices.length === 0) {
    return;
  }
  
  const device = devices[0];
  const callback = (data: wearEngine.MonitorEventData) => {
    console.info(`Battery: ${data.data.code}%`);
  };
  
  try {
    // 第一次订阅
    await monitorClient.subscribeEvent(
      device.randomId,
      wearEngine.MonitorEvent.EVENT_BATTERY_LEVEL_DROPPED,
      callback
    );
    console.info('第一次订阅成功');
    
    // 第二次订阅(使用相同回调,可能触发1008500012错误)
    await monitorClient.subscribeEvent(
      device.randomId,
      wearEngine.MonitorEvent.EVENT_BATTERY_LEVEL_DROPPED,
      callback
    );
    console.info('第二次订阅成功');
    
  } catch (error) {
    handleMonitorError(error as BusinessError, 'demoDuplicateSubscribe');
    
    if ((error as BusinessError).code === 1008500012) {
      console.warn('解决方案: 每种事件只订阅一次,避免重复注册');
    }
  }
}

/**
 * 演示: 权限错误处理(USER_STATUS权限)
 */
async function demoPermissionDenied(): Promise<void> {
  try {
    const devices = await deviceClient.getConnectedDevices();
    if (devices.length === 0) {
      return;
    }
    
    const device = devices[0];
    
    // 尝试查询佩戴状态(需要USER_STATUS权限)
    await monitorClient.queryStatus(device.randomId, wearEngine.MonitorItem.WEAR_STATUS);
    
  } catch (error) {
    const businessError = error as BusinessError;
    
    if (businessError.code === 1008500005 || businessError.code === 1008500006) {
      console.error('权限错误: USER_STATUS权限未授权');
      console.warn('解决方案: 引导用户授权权限,或提示功能不可用');
      console.warn('注意: USER_STATUS权限仅限企业开发者申请');
    } else {
      handleMonitorError(businessError, 'demoPermissionDenied');
    }
  }
}

/**
 * 演示: 设备能力不支持
 */
async function demoCapabilityNotSupported(): Promise<void> {
  try {
    const devices = await deviceClient.getConnectedDevices();
    if (devices.length === 0) {
      return;
    }
    
    const device = devices[0];
    
    // 检查设备是否支持MONITOR能力
    const isSupported = await checkDeviceCapability(device, wearEngine.WearEngineCapability.MONITOR);
    
    if (!isSupported) {
      console.warn('设备不支持MONITOR能力,无法查询状态');
      return;
    }
    
    // 设备支持,继续查询
    const result = await monitorClient.queryStatus(device.randomId, wearEngine.MonitorItem.POWER_STATUS);
    console.info(`电量: ${result.code}%`);
    
  } catch (error) {
    handleMonitorError(error as BusinessError, 'demoCapabilityNotSupported');
  }
}

/**
 * 主函数: 执行所有错误处理演示
 */
async function main(): Promise<void> {
  console.info('=== 开始错误处理演示 ===');
  
  console.info('\n1. 参数错误处理演示');
  await demoInvalidParams();
  
  console.info('\n2. 设备未连接错误处理演示');
  await demoDeviceDisconnected();
  
  console.info('\n3. 网络错误重试演示');
  await demoNetworkError();
  
  console.info('\n4. 重复订阅错误演示');
  await demoDuplicateSubscribe();
  
  console.info('\n5. 权限错误处理演示');
  await demoPermissionDenied();
  
  console.info('\n6. 设备能力不支持演示');
  await demoCapabilityNotSupported();
  
  console.info('\n=== 错误处理演示完成 ===');
}

// 执行主函数
main();