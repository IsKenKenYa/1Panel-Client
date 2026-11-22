// 连接迁移通知订阅示例
// 完整演示订阅、处理、取消订阅流程

import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { connection } from '@kit.NetworkKit';

// 保存回调函数引用,用于后续取消订阅
let handoverCallback: (info: netHandover.HandoverInfo) => void;

// 订阅连接迁移事件
function subscribeHandoverEvents(): void {
  console.info('[Handover] Start subscribing to handover events');
  
  // 定义回调函数
  handoverCallback = (info: netHandover.HandoverInfo) => {
    handleHandoverInfo(info);
  };
  
  try {
    // 订阅迁移事件
    netHandover.on('handoverChange', handoverCallback);
    console.info('[Handover] Successfully subscribed to handover events');
  } catch (err) {
    const error: BusinessError = err as BusinessError;
    console.error('[Handover] Subscribe failed');
    console.error('[Handover] Error code:', error.code);
    console.error('[Handover] Error message:', error.message);
    
    // 错误处理
    handleSubscribeError(error);
  }
}

// 处理迁移信息
function handleHandoverInfo(info: netHandover.HandoverInfo): void {
  if (info.handoverStart) {
    // 迁移开始
    handleHandoverStart(info.handoverStart);
  } else if (info.handoverComplete) {
    // 迁移完成
    handleHandoverComplete(info.handoverComplete);
  }
}

// 处理迁移开始
function handleHandoverStart(startInfo: netHandover.HandoverStart): void {
  console.info('[Handover] === Migration Start ===');
  
  // 获取超时时间
  const expires: number = startInfo.expires;
  console.info('[Handover] Migration timeout:', expires, 'seconds');
  
  // 获取发包建议
  const dataSpeedAction = startInfo.dataSpeedAction;
  console.info('[Handover] Data speed action:', dataSpeedAction.dataSpeedSimpleAction);
  console.info('[Handover] Link up bandwidth:', dataSpeedAction.linkUpBandwidth);
  console.info('[Handover] Link down bandwidth:', dataSpeedAction.linkDownBandwidth);
  
  // 根据建议调整数据传输策略
  adjustTransmissionStrategy(dataSpeedAction);
}

// 处理迁移完成
function handleHandoverComplete(completeInfo: netHandover.HandoverComplete): void {
  console.info('[Handover] === Migration Complete ===');
  
  // 获取迁移结果
  const result: netHandover.ErrorResult = completeInfo.result;
  console.info('[Handover] Migration result:', result);
  
  if (result === netHandover.ErrorResult.ERROR_NONE) {
    // 迁移成功
    console.info('[Handover] Migration succeeded');
    
    // 获取新链路信息
    const newNetHandle = completeInfo.newNetHandle;
    const reEstAction = completeInfo.reEstAction;
    const oldPathLifetime = completeInfo.oldPathLifetime;
    const pathTypeChanged = completeInfo.pathTypeChanged;
    
    console.info('[Handover] ReEstAction:', reEstAction);
    console.info('[Handover] Old path lifetime:', oldPathLifetime, 'seconds');
    console.info('[Handover] Path type changed:', pathTypeChanged);
    
    // 根据重建建议执行链路重建
    rebuildConnection(reEstAction, newNetHandle, oldPathLifetime);
    
    // 获取新链路发包建议
    const newDataSpeedAction = completeInfo.newDataSpeedAction;
    adjustTransmissionStrategy(newDataSpeedAction);
    
  } else {
    // 迁移失败
    handleMigrationError(result);
  }
  
  // 检查是否还有后续迁移
  const handoverContinue: boolean = completeInfo.handoverContinue;
  console.info('[Handover] Handover continue:', handoverContinue);
}

// 调整数据传输策略
function adjustTransmissionStrategy(action: netHandover.DataSpeedAction): void {
  console.info('[Handover] Adjusting transmission strategy');
  
  // 根据简单建议调整发包速率
  const simpleAction = action.dataSpeedSimpleAction;
  console.info('[Handover] Simple action:', simpleAction);
  
  // 根据带宽信息调整
  const upBandwidth = action.linkUpBandwidth;
  const downBandwidth = action.linkDownBandwidth;
  
  // 实际应用应根据业务逻辑执行调整
  // 例如: 降低视频码率、暂停大文件传输、优化发包频率
  console.info('[Handover] Adjusted strategy based on bandwidth');
  console.info('[Handover] Up bandwidth:', upBandwidth);
  console.info('[Handover] Down bandwidth:', downBandwidth);
}

// 链路重建
function rebuildConnection(
  reEstAction: netHandover.ReEstAction,
  newNetHandle?: connection.NetHandle,
  oldPathLifetime: number
): void {
  console.info('[Handover] Rebuilding connection');
  console.info('[Handover] ReEstAction:', reEstAction);
  
  switch (reEstAction) {
    case netHandover.ReEstAction.DEFAULT:
      console.info('[Handover] Rebuild with same remote IP');
      // 执行同IP重建逻辑
      reconnectWithSameIP();
      break;
      
    case netHandover.ReEstAction.QUERY_DNS:
      console.info('[Handover] Rebuild with DNS query (path type changed)');
      // 执行DNS查询重建
      reconnectWithDNSQuery();
      break;
      
    case netHandover.ReEstAction.CHANGE_REMOTE_IP:
      console.info('[Handover] Rebuild with different remote IP');
      // 执行不同IP重建
      reconnectWithNewIP();
      break;
      
    case netHandover.ReEstAction.CHANGE_IP_VERSION:
      console.info('[Handover] Rebuild with different IP version (IPv4 <-> IPv6)');
      // 执行IP版本切换重建
      reconnectWithDifferentIPVersion();
      break;
      
    case netHandover.ReEstAction.NO_EST:
      console.info('[Handover] Retry on old path immediately (no rebuild needed)');
      // 在老链路重试
      retryOnOldPath();
      break;
      
    default:
      console.warn('[Handover] Unknown ReEstAction:', reEstAction);
  }
  
  // 处理老链路剩余时间
  if (oldPathLifetime > 0) {
    console.info('[Handover] Old path available for', oldPathLifetime, 'seconds');
    // 可选择继续使用老链路进行过渡
  }
}

// 处理迁移错误
function handleMigrationError(result: netHandover.ErrorResult): void {
  console.error('[Handover] Migration failed with result:', result);
  
  switch (result) {
    case netHandover.ErrorResult.ERROR_HANDOVER_TIMEOUT:
      console.error('[Handover] Migration timeout');
      // 执行超时处理
      performManualSwitch();
      break;
      
    case netHandover.ErrorResult.ERROR_NEW_PATH_ACTIVATION_FAILED:
      console.error('[Handover] New path activation failed');
      // 保持老链路或提示用户
      stayOnOldPathOrNotifyUser();
      break;
      
    case netHandover.ErrorResult.ERROR_ABORT:
      console.error('[Handover] Migration aborted');
      // 恢复原状态
      restoreOriginalState();
      break;
      
    default:
      console.error('[Handover] Unknown error result:', result);
  }
}

// 取消订阅连接迁移事件
function unsubscribeHandoverEvents(): void {
  console.info('[Handover] Start unsubscribing from handover events');
  
  try {
    // 取消订阅(不传callback,取消所有订阅)
    netHandover.off('handoverChange');
    console.info('[Handover] Successfully unsubscribed from handover events');
  } catch (err) {
    const error: BusinessError = err as BusinessError;
    console.error('[Handover] Unsubscribe failed');
    console.error('[Handover] Error code:', error.code);
    console.error('[Handover] Error message:', error.message);
  }
}

// 取消特定回调订阅
function unsubscribeSpecificCallback(): void {
  console.info('[Handover] Unsubscribing specific callback');
  
  try {
    // 传入相同的回调引用
    netHandover.off('handoverChange', handoverCallback);
    console.info('[Handover] Successfully unsubscribed specific callback');
  } catch (err) {
    const error: BusinessError = err as BusinessError;
    console.error('[Handover] Unsubscribe failed');
    console.error('[Handover] Error code:', error.code);
    console.error('[Handover] Error message:', error.message);
  }
}

// 订阅错误处理
function handleSubscribeError(error: BusinessError): void {
  switch (error.code) {
    case 201:
      console.error('[Handover] Permission denied: GET_NETWORK_INFO not granted');
      // 提示用户授权或使用降级方案
      requestPermissionOrFallback();
      break;
      
    case 401:
      console.error('[Handover] Parameter check failed');
      // 检查参数格式
      checkParametersAndRetry();
      break;
      
    case 801:
      console.error('[Handover] Device does not support this API');
      // 使用降级方案
      useFallbackNetworkDetection();
      break;
      
    default:
      console.error('[Handover] Unknown error:', error.code);
      useFallbackNetworkDetection();
  }
}

// 降级方案示例
function useFallbackNetworkDetection(): void {
  console.warn('[Handover] Using fallback network detection');
  
  // 使用connection模块监听网络变化
  connection.on('netChange', (data: connection.NetHandle) => {
    console.info('[Handover] Network changed:', data.netId);
    // 执行简化的网络切换处理
    performSimpleNetworkSwitch();
  });
}

// 以下为示意性函数,实际应用需根据业务逻辑实现
function reconnectWithSameIP(): void {
  console.info('[Handover] Reconnecting with same IP...');
}

function reconnectWithDNSQuery(): void {
  console.info('[Handover] Reconnecting with DNS query...');
}

function reconnectWithNewIP(): void {
  console.info('[Handover] Reconnecting with new IP...');
}

function reconnectWithDifferentIPVersion(): void {
  console.info('[Handover] Reconnecting with different IP version...');
}

function retryOnOldPath(): void {
  console.info('[Handover] Retrying on old path...');
}

function performManualSwitch(): void {
  console.info('[Handover] Performing manual switch...');
}

function stayOnOldPathOrNotifyUser(): void {
  console.info('[Handover] Staying on old path or notifying user...');
}

function restoreOriginalState(): void {
  console.info('[Handover] Restoring original state...');
}

function requestPermissionOrFallback(): void {
  console.info('[Handover] Requesting permission or using fallback...');
}

function checkParametersAndRetry(): void {
  console.info('[Handover] Checking parameters and retrying...');
}

function performSimpleNetworkSwitch(): void {
  console.info('[Handover] Performing simple network switch...');
}

// 主函数示例
export function handoverExample(): void {
  console.info('=== Connection Handover Notification Example ===');
  
  // 1. 订阅迁移事件
  subscribeHandoverEvents();
  
  // 2. 应用业务运行...
  console.info('[Handover] Application running...');
  
  // 3. 业务结束时取消订阅
  // unsubscribeHandoverEvents();
  // 或取消特定回调
  // unsubscribeSpecificCallback();
  
  console.info('=== Example End ===');
}