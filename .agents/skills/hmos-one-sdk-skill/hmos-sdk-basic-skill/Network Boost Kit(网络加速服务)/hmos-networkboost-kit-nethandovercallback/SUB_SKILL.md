---
name: hmos-networkboost-kit-nethandovercallback
description: 订阅和处理网络连接迁移通知，支持WiFi与蜂窝网络切换、主卡副卡切换场景，需申请ohos.permission.GET_NETWORK_INFO权限，适用于弱网环境下应用快速恢复业务
---

# 连接迁移通知技能

## 功能描述

本技能提供网络连接迁移通知的订阅和处理能力，在弱网环境下系统发起多网迁移（WiFi<->蜂窝、主卡<->副卡等）时，应用可接收连接迁移开始和完成通知，根据通知建议调整数传策略、重建链路，快速恢复业务，提供平滑、高速、低时延的用户体验。

**核心能力**：
- 订阅/取消订阅连接迁移事件
- 接收连接迁移开始通知（HandoverStart）
- 接收连接迁移完成通知（HandoverComplete）
- 根据迁移建议调整应用网络策略

**适用范围**：
- 需要处理网络切换的应用
- 弱网环境下需要快速恢复业务的应用
- 对网络连续性要求较高的实时应用

**版本要求**：
- API版本：5.0.0(12)及以上
- 系统能力：SystemCapability.Communication.NetworkBoost.Core

## 使用场景

### 触发词
- "连接迁移通知"
- "网络切换监听"
- "WiFi蜂窝切换"
- "多网迁移处理"
- "handover"
- "网络迁移回调"

### 能做
- 订阅连接迁移开始和完成事件
- 获取迁移超时时间、发包建议、链路类型变更等信息
- 根据迁移建议调整应用数传策略
- 根据迁移建议重建链路或重试网络请求
- 在业务结束时取消订阅释放资源

### 绝不做
- 不主动触发网络切换
- 不修改系统网络配置
- 不拦截或阻止系统网络迁移决策
- 不在主线程执行耗时网络操作
- 不在迁移回调中执行阻塞性操作

### 补充
- 必须申请ohos.permission.GET_NETWORK_INFO权限
- 建议在应用启动时订阅，在应用退出时取消订阅
- 迁移回调可能在短时间内多次触发
- 需要处理迁移超时、失败等异常场景

## 调用规范和规则

### 输入约束
- 订阅事件类型：固定为'handoverChange'
- 回调函数参数：必须是HandoverInfo类型
- 取消订阅参数：事件类型必须与订阅时一致
- 权限声明：必须在module.json5中声明ohos.permission.GET_NETWORK_INFO权限

### 执行约束
- 最大回调执行时间：不超过100ms
- 回调函数应快速返回，避免阻塞
- 网络重建建议在迁移完成回调后100ms内发起
- 取消订阅操作应在应用生命周期结束前完成

### 内容约束
- 禁止在回调中执行文件I/O操作
- 禁止在回调中执行耗时计算
- 禁止在回调中弹出模态对话框
- 禁止在回调中调用同步网络请求
- 必须处理所有迁移结果状态

### 降级约束
- 权限未授予：提示用户授权或使用基础网络能力
- API不支持：使用传统网络监听方式降级
- 回调执行异常：记录日志并继续监听后续事件
- 迁移超时：使用重试机制或提示用户检查网络

## 调用流程和步骤

### 步骤1：权限配置

**前置校验**：
1. 确认module.json5中已声明权限
2. 确认应用签名已包含权限
3. 确认设备API版本≥5.0.0(12)

**权限声明**：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_NETWORK_INFO",
        "reason": "$string:network_permission_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "always"
        }
      }
    ]
  }
}
```

### 步骤2：导入模块和订阅迁移事件

**示例代码**：
```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

class NetworkHandoverManager {
  private handoverCallback: (info: netHandover.HandoverInfo) => void;

  constructor() {
    this.handoverCallback = this.handleHandoverInfo.bind(this);
  }

  subscribeHandover(): void {
    try {
      netHandover.on('handoverChange', this.handoverCallback);
      console.info('[NetworkHandover] Subscribed successfully');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[NetworkHandover] Subscribe failed: ${error.code}, ${error.message}`);
      this.handleSubscribeError(error);
    }
  }

  private handleHandoverInfo(info: netHandover.HandoverInfo): void {
    if (info.handoverStart) {
      this.onHandoverStart(info.handoverStart);
    } else if (info.handoverComplete) {
      this.onHandoverComplete(info.handoverComplete);
    }
  }

  private onHandoverStart(startInfo: netHandover.HandoverStart): void {
    console.info('[NetworkHandover] Handover started');
    console.info(`[NetworkHandover] Timeout: ${startInfo.expires}s`);
    console.info(`[NetworkHandover] Data speed action: ${startInfo.dataSpeedAction.dataSpeedSimpleAction}`);
    
    // 根据发包建议调整数传策略
    this.adjustDataTransmission(startInfo.dataSpeedAction);
  }

  private onHandoverComplete(completeInfo: netHandover.HandoverComplete): void {
    console.info('[NetworkHandover] Handover completed');
    console.info(`[NetworkHandover] Result: ${completeInfo.result}`);
    console.info(`[NetworkHandover] Old path lifetime: ${completeInfo.oldPathLifetime}s`);
    console.info(`[NetworkHandover] Path type changed: ${completeInfo.pathTypeChanged}`);
    
    // 处理迁移结果
    if (completeInfo.result === netHandover.ErrorResult.ERROR_NONE) {
      // 迁移成功，根据重建建议恢复业务
      this.rebuildConnection(completeInfo.reEstAction, completeInfo.newNetHandle);
    } else {
      // 迁移失败，处理错误
      this.handleHandoverError(completeInfo.result);
    }
    
    // 根据新链路发包建议调整策略
    if (completeInfo.newDataSpeedAction) {
      this.adjustDataTransmission(completeInfo.newDataSpeedAction);
    }
  }

  private adjustDataTransmission(action: netHandover.DataSpeedAction): void {
    // 根据系统建议调整数据发送速率
    console.info(`[NetworkHandover] Adjusting transmission: ${action.dataSpeedSimpleAction}`);
    console.info(`[NetworkHandover] Bandwidth: ↑${action.linkUpBandwidth} ↓${action.linkDownBandwidth}`);
  }

  private rebuildConnection(
    reEstAction: netHandover.ReEstAction,
    newNetHandle?: connection.NetHandle
  ): void {
    switch (reEstAction) {
      case netHandover.ReEstAction.DEFAULT:
        console.info('[NetworkHandover] Rebuild with same remote IP');
        this.rebuildWithSameIP();
        break;
        
      case netHandover.ReEstAction.QUERY_DNS:
        console.info('[NetworkHandover] Rebuild with DNS query');
        this.rebuildWithDNSQuery();
        break;
        
      case netHandover.ReEstAction.CHANGE_REMOTE_IP:
        console.info('[NetworkHandover] Rebuild with different remote IP');
        this.rebuildWithNewIP();
        break;
        
      case netHandover.ReEstAction.CHANGE_IP_VERSION:
        console.info('[NetworkHandover] Rebuild with IP version change');
        this.rebuildWithIPVersionChange();
        break;
        
      case netHandover.ReEstAction.NO_EST:
        console.info('[NetworkHandover] Retry on old path');
        this.retryOnOldPath();
        break;
    }
  }

  private handleHandoverError(result: netHandover.ErrorResult): void {
    switch (result) {
      case netHandover.ErrorResult.ERROR_HANDOVER_TIMEOUT:
        console.error('[NetworkHandover] Handover timeout');
        this.retryAfterDelay(2000);
        break;
        
      case netHandover.ErrorResult.ERROR_NEW_PATH_ACTIVATION_FAILED:
        console.error('[NetworkHandover] New path activation failed');
        this.fallbackToOldPath();
        break;
        
      case netHandover.ErrorResult.ERROR_ABORT:
        console.error('[NetworkHandover] Handover aborted');
        this.notifyUserNetworkChanged();
        break;
    }
  }

  private handleSubscribeError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        console.error('[NetworkHandover] Permission denied');
        break;
      case 401:
        console.error('[NetworkHandover] Invalid parameters');
        break;
      case 801:
        console.error('[NetworkHandover] API not supported');
        break;
    }
  }

  unsubscribeHandover(): void {
    try {
      netHandover.off('handoverChange', this.handoverCallback);
      console.info('[NetworkHandover] Unsubscribed successfully');
    } catch (err) {
      const error = err as BusinessError;
      console.error(`[NetworkHandover] Unsubscribe failed: ${error.code}, ${error.message}`);
    }
  }

  // 以下为示例重建方法，实际实现需根据应用业务逻辑调整
  private rebuildWithSameIP(): void {
    // 使用相同的远端IP重建链路
  }

  private rebuildWithDNSQuery(): void {
    // 链路类型变化，需要重新查询DNS
  }

  private rebuildWithNewIP(): void {
    // 使用不同的远端IP重建链路
  }

  private rebuildWithIPVersionChange(): void {
    // 修改IP类型（IPv4/IPv6）重建链路
  }

  private retryOnOldPath(): void {
    // 在老链路上立即重试
  }

  private retryAfterDelay(delay: number): void {
    // 延迟后重试
  }

  private fallbackToOldPath(): void {
    // 回退到老链路
  }

  private notifyUserNetworkChanged(): void {
    // 通知用户网络已变更
  }
}
```

### 步骤3：错误处理

```typescript
class NetworkHandoverErrorHandler {
  handleError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        console.error('[HandoverError] Permission verification failed');
        console.error('[HandoverError] Solution: Add ohos.permission.GET_NETWORK_INFO to module.json5');
        this.requestPermission();
        break;
        
      case 401:
        console.error('[HandoverError] Parameter check failed');
        console.error('[HandoverError] Solution: Check callback function type and parameter validity');
        this.validateParameters();
        break;
        
      case 801:
        console.error('[HandoverError] API not supported on this device');
        console.error('[HandoverError] Solution: Use feature detection or fallback to basic network monitoring');
        this.useFallback();
        break;
        
      default:
        console.error(`[HandoverError] Unknown error: ${error.code}, ${error.message}`);
        this.logError(error);
    }
  }

  private requestPermission(): void {
    // 引导用户授权
  }

  private validateParameters(): void {
    // 校验参数
  }

  private useFallback(): void {
    // 使用降级方案
  }

  private logError(error: BusinessError): void {
    // 记录错误日志
  }
}
```

### 步骤4：降级处理

```typescript
class NetworkHandoverFallback {
  private useBasicNetworkMonitor: boolean = false;

  initialize(): void {
    try {
      // 尝试使用Network Boost Kit
      if (this.checkApiSupport()) {
        netHandover.on('handoverChange', this.handoverCallback);
        console.info('[Fallback] Using Network Boost Kit');
      } else {
        throw new Error('API not supported');
      }
    } catch (err) {
      console.warn('[Fallback] Network Boost Kit not available, using fallback');
      this.useBasicNetworkMonitor = true;
      this.startBasicNetworkMonitor();
    }
  }

  private checkApiSupport(): boolean {
    try {
      // 检查API是否支持
      return typeof netHandover.on === 'function';
    } catch {
      return false;
    }
  }

  private handoverCallback = (info: netHandover.HandoverInfo): void => {
    // 处理迁移信息
  }

  private startBasicNetworkMonitor(): void {
    // 使用基础网络监听作为降级方案
    console.info('[Fallback] Started basic network monitoring');
    // 使用connection模块监听网络变化
  }

  cleanup(): void {
    if (this.useBasicNetworkMonitor) {
      // 清理基础监听
    } else {
      try {
        netHandover.off('handoverChange');
      } catch (err) {
        console.error('[Fallback] Cleanup failed:', err);
      }
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限校验失败 | 在module.json5中声明ohos.permission.GET_NETWORK_INFO权限，并在应用签名中包含该权限 |
| 401 | 参数检查失败 | 确认回调函数类型正确，参数类型为HandoverInfo |
| 801 | 设备不支持该API | 使用特性检测，如不支持则降级到基础网络监听方式 |

**迁移结果错误码**：

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| ERROR_NONE (0) | 迁移成功 | 按建议重建链路或调整策略 |
| ERROR_HANDOVER_TIMEOUT (1) | 迁移超时 | 延迟后重试或提示用户检查网络 |
| ERROR_NEW_PATH_ACTIVATION_FAILED (2) | 新链路激活失败 | 回退到老链路或使用其他网络 |
| ERROR_ABORT (3) | 迁移被取消 | 通知用户网络已变更 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.NetworkBoostKit": "^5.0.0",
    "@kit.BasicServicesKit": "^5.0.0"
  }
}
```

### 环境要求
- DevEco Studio：4.0.3.700及以上
- HarmonyOS SDK：API 12及以上
- 运行设备：HarmonyOS 5.0.0(12)及以上

### 常见编译问题

**问题1：找不到@kit.NetworkBoostKit模块**
```
Error: Cannot find module '@kit.NetworkBoostKit'
```
**解决方法**：
1. 确认DevEco Studio版本≥4.0.3.700
2. 确认HarmonyOS SDK版本≥API 12
3. 在项目根目录执行`ohpm install`

**问题2：权限未生效**
```
Error: Permission verification failed
```
**解决方法**：
1. 在module.json5中正确声明权限
2. 确认应用签名包含该权限
3. 重新安装应用并授权

**问题3：API不存在**
```
Error: Property 'on' does not exist on type 'typeof netHandover'
```
**解决方法**：
1. 检查设备API版本≥5.0.0(12)
2. 使用特性检测：`if (typeof netHandover.on === 'function')`
3. 提供降级方案

## 常见问题与解决方法

### Q1：订阅成功但未收到迁移回调
**原因**：
- 设备未发生网络切换
- 应用在后台被限制
- 回调函数执行异常被吞掉

**解决方法**：
- 确认测试环境支持网络切换（WiFi/蜂窝）
- 检查应用后台运行权限配置
- 在回调函数中增加try-catch捕获异常

### Q2：迁移完成后重建链路失败
**原因**：
- 未正确处理ReEstAction建议
- 新链路NetHandle信息无效
- 业务重建逻辑存在问题

**解决方法**：
- 根据reEstAction类型执行对应重建策略
- 验证newNetHandle有效性后再使用
- 参考示例代码实现完整的重建流程

### Q3：取消订阅后仍收到回调
**原因**：
- 取消订阅传入的回调函数与订阅时不一致
- 存在多个订阅实例

**解决方法**：
- 确保off传入的回调函数与on时是同一个引用
- 使用单例模式管理订阅实例
- 取消订阅时传入回调函数：`netHandover.off('handoverChange', callback)`

### Q4：应用切换到后台时迁移回调被限制
**原因**：
- 系统对后台应用的网络能力有限制
- 后台执行权限未配置

**解决方法**：
- 在module.json5中配置后台任务类型
- 使用backgroundTaskManager申请长时任务
- 在后台时暂停非关键网络操作

### Q5：如何判断当前是否处于迁移中
**原因**：
- 需要区分迁移开始和完成状态
- 需要跟踪迁移流程进度

**解决方法**：
- 维护迁移状态机（IDLE -> STARTED -> COMPLETED）
- 在HandoverStart时设置状态为STARTED
- 在HandoverComplete时设置状态为COMPLETED
- 根据expires设置超时保护

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "eventType": "handoverChange",
  "action": "subscribed",
  "timestamp": "2026-07-03T10:30:00.000Z",
  "apiUsed": [
    "netHandover.on('handoverChange')",
    "netHandover.off('handoverChange')"
  ],
  "permissions": [
    "ohos.permission.GET_NETWORK_INFO"
  ],
  "capabilities": [
    "SystemCapability.Communication.NetworkBoost.Core"
  ]
}
```

## 参考文档

- [API开发指南：连接迁移通知](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-nethandovercallback)
- [API参考说明：netHandover](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/networkboost-nethandover)
- [通用错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal)

## 完整示例代码

- [ArkTS完整示例](./assets/network_handover_example.ets)
- [权限配置示例](./assets/module.json5)
- [降级处理示例](./assets/fallback_example.ets)

## 测试用例

### 正向测试用例
- [正常订阅和取消订阅](./tests/test_positive.py)：测试正常流程下的订阅和取消订阅
- [处理迁移开始通知](./tests/test_positive.py)：测试HandoverStart回调处理
- [处理迁移完成通知](./tests/test_positive.py)：测试HandoverComplete回调处理

### 边界测试用例
- [多次订阅同一回调](./tests/test_boundary.py)：测试重复订阅场景
- [快速连续订阅取消](./tests/test_boundary.py)：测试高频操作场景
- [迁移超时处理](./tests/test_boundary.py)：测试expires超时场景

### 异常测试用例
- [权限未授予](./tests/test_exception.py)：测试缺少权限时的错误处理
- [设备不支持API](./tests/test_exception.py)：测试API不支持时的降级处理
- [回调函数异常](./tests/test_exception.py)：测试回调函数抛出异常时的处理