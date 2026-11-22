/**
 * 订阅多网建议示例代码
 * 演示如何订阅系统多网建议变化事件
 */
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 多网建议回调函数
 * @param data 多网建议信息
 */
function onMultiPathRecommendation(data: netHandover.MultiPathRecommendationInfo): void {
  console.info('[MultiPathRecommendation] Received recommendation: ' + JSON.stringify(data));
  
  // 根据建议动作执行相应操作
  if (data.action === netHandover.MultiPathAction.MULTIPATH_ACTION_REQUEST) {
    console.info('[MultiPathRecommendation] System recommends to REQUEST multi-path connection');
    // 在此处可以调用 netHandover.requestMultiPath() 发起多网请求
  } else if (data.action === netHandover.MultiPathAction.MULTIPATH_ACTION_RELEASE) {
    console.info('[MultiPathRecommendation] System recommends to RELEASE multi-path connection');
    // 在此处可以调用 netHandover.releaseMultiPath() 释放多网请求
  }
}

/**
 * 订阅多网建议
 */
export function subscribeMultiPathRecommendation(): void {
  try {
    // 订阅多网建议信息变化
    netHandover.on('multiPathRecommendation', onMultiPathRecommendation);
    console.info('[MultiPathRecommendation] Successfully subscribed to multiPathRecommendation');
  } catch (err) {
    const error = err as BusinessError;
    console.error('[MultiPathRecommendation] Failed to subscribe: errCode: ' + error.code + 
                  ', errMessage: ' + error.message);
    handleError(error);
  }
}

/**
 * 取消订阅多网建议
 */
export function unsubscribeMultiPathRecommendation(): void {
  try {
    // 取消所有订阅
    netHandover.off('multiPathRecommendation');
    console.info('[MultiPathRecommendation] Successfully unsubscribed from multiPathRecommendation');
  } catch (err) {
    const error = err as BusinessError;
    console.error('[MultiPathRecommendation] Failed to unsubscribe: errCode: ' + error.code + 
                  ', errMessage: ' + error.message);
    handleError(error);
  }
}

/**
 * 取消特定回调函数的订阅
 * @param callback 要取消的回调函数
 */
export function unsubscribeSpecificCallback(callback: (data: netHandover.MultiPathRecommendationInfo) => void): void {
  try {
    netHandover.off('multiPathRecommendation', callback);
    console.info('[MultiPathRecommendation] Successfully unsubscribed specific callback');
  } catch (err) {
    const error = err as BusinessError;
    console.error('[MultiPathRecommendation] Failed to unsubscribe: errCode: ' + error.code + 
                  ', errMessage: ' + error.message);
    handleError(error);
  }
}

/**
 * 错误处理
 * @param error 业务错误
 */
function handleError(error: BusinessError): void {
  switch (error.code) {
    case 201:
      console.error('[MultiPathRecommendation] Permission denied: LINKTURBO permission is required');
      // 提示用户申请权限
      requestPermission();
      break;
    case 401:
      console.error('[MultiPathRecommendation] Parameter check failed: Invalid parameters');
      // 检查参数类型和格式
      break;
    case 801:
      console.error('[MultiPathRecommendation] API not supported: Device or system version does not support this API');
      // 提示用户升级系统或使用降级方案
      useFallback();
      break;
    case 1013600001:
      console.error('[MultiPathRecommendation] Internal error: Internal processing exception');
      // 记录错误日志，稍后重试
      retryLater();
      break;
    case 1013600002:
      console.error('[MultiPathRecommendation] System error: IPC call failed or network service not started');
      // 检查网络服务状态
      checkNetworkService();
      break;
    default:
      console.error('[MultiPathRecommendation] Unknown error: ' + error.message);
      // 处理未知错误
      break;
  }
}

/**
 * 申请权限（示意）
 */
function requestPermission(): void {
  console.info('[MultiPathRecommendation] Please apply for ohos.permission.LINKTURBO permission');
}

/**
 * 使用降级方案（示意）
 */
function useFallback(): void {
  console.info('[MultiPathRecommendation] Using fallback network monitoring solution');
  // 使用 connection API 实现网络监听
}

/**
 * 稍后重试（示意）
 */
function retryLater(): void {
  console.info('[MultiPathRecommendation] Will retry later');
}

/**
 * 检查网络服务（示意）
 */
function checkNetworkService(): void {
  console.info('[MultiPathRecommendation] Checking network service status');
}

/**
 * 使用示例
 */
export function example(): void {
  // 订阅多网建议
  subscribeMultiPathRecommendation();
  
  // 业务逻辑...
  
  // 取消订阅
  unsubscribeMultiPathRecommendation();
}

// 主入口
if (require.main === module) {
  example();
}