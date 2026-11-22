---
name: hmos-network-boost-kit-network-quality-qos-callback
description: 订阅网络质量QoS信息状态变化，获取链路类型、上下行带宽速率、RTT时延等网络质量评估数据，支持实时监听网络质量变化，适用于视频播放、实时通讯、游戏等需要根据网络质量动态调整策略的场景
---

# 网络质量评估技能

## 功能描述

本技能提供网络质量QoS(Quality of Service)信息订阅和监听能力。应用订阅后，系统按照一定周期或QoS变化后回调给应用，回调信息包括数据传输的链路类型、上下行空口实时带宽、上下行空口实时速率、RTT时延等关键网络质量指标，帮助应用实现网络自适应策略调整。

**核心能力**：
- 订阅/取消订阅网络质量变化事件
- 获取多链路网络质量信息(蜂窝主副卡、WiFi主辅)
- 实时监控上下行带宽、速率、RTT时延
- 支持网络质量评估数据回调处理

**适用场景**：
- 视频播放：根据带宽动态调整码率、分辨率
- 实时通讯：根据网络质量调整帧率、清晰度
- 游戏应用：根据延迟优化游戏体验
- 文件传输：根据速率调整并发策略

## 使用场景

### 触发词
- "网络质量评估"
- "QoS监听"
- "网络质量订阅"
- "获取网络带宽"
- "监听网络延迟"
- "网络自适应"

### 能做
- 订阅网络质量QoS信息变化事件
- 获取实时的上下行带宽、速率信息
- 获取RTT时延和缓冲时延数据
- 获取多链路网络质量信息(蜂窝、WiFi)
- 在业务结束时取消订阅

### 绝不做
- 不提供网络切换功能
- 不修改网络配置参数
- 不创建网络连接
- 不处理非网络质量相关的功能

### 补充
- 需要申请`ohos.permission.GET_NETWORK_INFO`权限
- 支持API 12及以上版本
- 回调数据单位为bps(比特每秒)，需除以8转换为B/s
- 支持多链路并发场景的质量评估

## 调用规范和规则

### 输入约束
- 回调函数必须符合`Callback<Array<NetworkQos>>`类型签名
- 订阅类型必须为`'netQosChange'`字符串
- 取消订阅时callback参数可选，不传则取消所有回调

### 执行约束
- 订阅后系统周期性回调或在QoS变化时回调
- 单次回调可能包含多条链路的质量信息
- 回调数据为实时数据，不做历史缓存
- 最大回调频率由系统控制

### 内容约束
- 禁止在回调函数中执行耗时操作
- 禁止阻塞回调线程
- 禁止在回调中再次订阅同一事件
- 回调函数应快速处理并返回

### 降级约束
- 权限不足时：提示用户授权并使用默认策略
- 设备不支持API：跳过订阅，使用兜底方案
- 回调数据异常：验证数据有效性，忽略无效数据
- 订阅失败：记录日志，业务继续执行

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备API版本是否≥12
2. 确认已申请`ohos.permission.GET_NETWORK_INFO`权限
3. 准备好网络质量变化的业务处理逻辑

**权限配置**：
在`module.json5`中添加权限声明：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_NETWORK_INFO"
      }
    ]
  }
}
```

**参数准备**：
```typescript
import { netQuality } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义回调处理函数
const qosCallback = (list: Array<netQuality.NetworkQos>) => {
  // 网络质量变化处理逻辑
};
```

### 步骤2：订阅网络质量变化

**示例代码**：
```typescript
import { netQuality } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

let qosCallback: (list: Array<netQuality.NetworkQos>) => void | undefined;

/**
 * 订阅网络质量QoS信息变化
 * @returns void
 */
function subscribeNetworkQuality(): void {
  try {
    // 定义回调函数
    qosCallback = (list: Array<netQuality.NetworkQos>) => {
      if (list.length > 0) {
        list.forEach((qos) => {
          console.info(`数据链路类型: ${JSON.stringify(qos.pathType)}`);
          console.info(`上行带宽: ${qos.linkUpBandwidth} bps`);
          console.info(`下行带宽: ${qos.linkDownBandwidth} bps`);
          console.info(`上行速率: ${qos.linkUpRate} bps`);
          console.info(`下行速率: ${qos.linkDownRate} bps`);
          console.info(`实时速率: ${(qos.linkUpRate + qos.linkDownRate) / 8} B/s`);
          console.info(`RTT时延: ${qos.rttMs} ms`);
          console.info(`上行缓冲时延: ${qos.linkUpBufferDelayMs} ms`);
          
          // 根据网络质量调整业务策略
          adjustBusinessStrategy(qos);
        });
      }
    };

    // 订阅网络质量变化事件
    netQuality.on('netQosChange', qosCallback);
    console.info('网络质量订阅成功');
  } catch (err) {
    const error = err as BusinessError;
    console.error(`订阅失败，错误码: ${error.code}, 错误信息: ${error.message}`);
  }
}

/**
 * 根据网络质量调整业务策略
 * @param qos 网络质量信息
 */
function adjustBusinessStrategy(qos: netQuality.NetworkQos): void {
  // 计算实时速率(B/s)
  const totalRate = (qos.linkUpRate + qos.linkDownRate) / 8;
  
  // 根据带宽调整策略
  if (qos.linkDownBandwidth < 1000000) { // < 1Mbps
    console.warn('网络带宽较低，建议降低画质');
  }
  
  // 根据RTT调整策略
  if (qos.rttMs > 200) {
    console.warn('网络延迟较高，建议优化交互体验');
  }
}
```

### 步骤3：处理网络质量数据

**数据类型说明**：
```typescript
// NetworkQos - 网络质量回调信息
interface NetworkQos {
  pathType: PathType;              // 数据路径类型(蜂窝主卡/副卡、WiFi主/辅)
  linkUpBandwidth: RateBps;         // 上行带宽(bps)
  linkDownBandwidth: RateBps;       // 下行带宽(bps)
  linkUpRate: RateBps;              // 上行速率(bps)
  linkDownRate: RateBps;            // 下行速率(bps)
  rttMs: number;                    // RTT时延(ms)
  linkUpBufferDelayMs: number;      // 上行发送空口缓冲时延(ms)
  linkUpBufferCongestionPercent?: number; // 上行缓冲时延占比(可选)
}

// PathType - 数据路径类型
enum PathType {
  CELLULAR_PRIMARY = 0,   // 蜂窝主卡
  CELLULAR_SECONDARY = 1, // 蜂窝副卡
  WIFI_PRIMARY = 2,       // 主WiFi
  WIFI_SECONDARY = 3      // 辅WiFi
}

// RateBps - 带宽或速率(bps)
type RateBps = number;
```

**数据转换示例**：
```typescript
/**
 * 处理网络质量数据
 * @param qos 网络质量信息
 */
function processQosData(qos: netQuality.NetworkQos): void {
  // 带宽单位转换: bps -> Mbps
  const upBandwidthMbps = qos.linkUpBandwidth / 1000000;
  const downBandwidthMbps = qos.linkDownBandwidth / 1000000;
  
  // 速率单位转换: bps -> KB/s
  const upRateKBps = qos.linkUpRate / 8000;
  const downRateKBps = qos.linkDownRate / 8000;
  
  // 总速率(B/s)
  const totalRate = (qos.linkUpRate + qos.linkDownRate) / 8;
  
  // 链路类型判断
  const linkType = getLinkTypeName(qos.pathType);
  
  console.info(`[${linkType}] 下行带宽: ${downBandwidthMbps.toFixed(2)} Mbps, ` +
               `速率: ${downRateKBps.toFixed(2)} KB/s, RTT: ${qos.rttMs} ms`);
}

/**
 * 获取链路类型名称
 * @param pathType 路径类型枚举值
 * @returns 链路类型名称
 */
function getLinkTypeName(pathType: netQuality.PathType): string {
  const typeMap = {
    [netQuality.PathType.CELLULAR_PRIMARY]: '蜂窝主卡',
    [netQuality.PathType.CELLULAR_SECONDARY]: '蜂窝副卡',
    [netQuality.PathType.WIFI_PRIMARY]: '主WiFi',
    [netQuality.PathType.WIFI_SECONDARY]: '辅WiFi'
  };
  return typeMap[pathType] || '未知链路';
}
```

### 步骤4：取消订阅

**示例代码**：
```typescript
import { netQuality } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 取消订阅网络质量变化
 * @param callback 可选，指定要取消的回调函数
 */
function unsubscribeNetworkQuality(callback?: (list: Array<netQuality.NetworkQos>) => void): void {
  try {
    if (callback) {
      // 取消指定的回调函数
      netQuality.off('netQosChange', callback);
      console.info('已取消指定回调的网络质量订阅');
    } else {
      // 取消所有回调
      netQuality.off('netQosChange');
      console.info('已取消所有网络质量订阅');
    }
  } catch (err) {
    const error = err as BusinessError;
    console.error(`取消订阅失败，错误码: ${error.code}, 错误信息: ${error.message}`);
  }
}

// 使用示例：业务结束时取消订阅
function onBusinessEnd(): void {
  // 取消特定回调
  if (qosCallback) {
    unsubscribeNetworkQuality(qosCallback);
  }
  
  // 或取消所有订阅
  // unsubscribeNetworkQuality();
}
```

### 步骤5：错误处理

**完整错误处理代码**：
```typescript
import { netQuality } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 安全订阅网络质量变化，包含完整错误处理
 */
function safeSubscribeNetworkQuality(): void {
  try {
    netQuality.on('netQosChange', (list: Array<netQuality.NetworkQos>) => {
      try {
        // 数据有效性检查
        if (!list || list.length === 0) {
          console.warn('网络质量数据为空');
          return;
        }
        
        list.forEach((qos) => {
          // 验证数据有效性
          if (!validateQosData(qos)) {
            console.warn('网络质量数据无效，跳过处理');
            return;
          }
          
          // 处理有效的网络质量数据
          processQosData(qos);
        });
      } catch (processErr) {
        console.error('处理网络质量数据异常:', processErr);
      }
    });
    
    console.info('网络质量订阅成功');
  } catch (err) {
    const error = err as BusinessError;
    handleSubscribeError(error);
  }
}

/**
 * 验证网络质量数据有效性
 * @param qos 网络质量数据
 * @returns 是否有效
 */
function validateQosData(qos: netQuality.NetworkQos): boolean {
  // 检查必要字段
  if (qos.pathType === undefined || qos.pathType === null) {
    return false;
  }
  
  // 检查数值合法性
  if (qos.linkUpBandwidth < 0 || qos.linkDownBandwidth < 0) {
    return false;
  }
  
  if (qos.rttMs < 0) {
    return false;
  }
  
  return true;
}

/**
 * 处理订阅错误
 * @param error 错误对象
 */
function handleSubscribeError(error: BusinessError): void {
  switch (error.code) {
    case 201:
      console.error('权限校验失败，请检查是否申请了ohos.permission.GET_NETWORK_INFO权限');
      // 提示用户授权或使用默认策略
      useFallbackStrategy();
      break;
    case 401:
      console.error('参数检查失败，请检查参数类型和格式');
      break;
    case 801:
      console.error('设备不支持该API，当前设备可能不支持网络质量评估功能');
      // 使用降级方案
      useFallbackStrategy();
      break;
    default:
      console.error(`未知错误，错误码: ${error.code}, 错误信息: ${error.message}`);
      break;
  }
}

/**
 * 降级处理方案
 */
function useFallbackStrategy(): void {
  console.warn('使用降级策略：跳过网络质量评估，使用默认配置');
  // 使用预设的网络策略，不依赖实时网络质量数据
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限校验失败 | 在module.json5中声明ohos.permission.GET_NETWORK_INFO权限，并在运行时申请权限 |
| 401 | 参数检查失败 | 检查订阅类型是否为'netQosChange'字符串，检查回调函数签名是否正确 |
| 801 | 设备不支持该API | 检查设备API版本是否≥12，使用降级方案跳过网络质量评估功能 |

## 编译和修复问题

### 依赖声明
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "deviceTypes": ["default", "tablet"],
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_NETWORK_INFO"
      }
    ]
  }
}
```

### 环境要求
- HarmonyOS SDK: API 12 (5.0.0) 及以上
- 开发工具: DevEco Studio 4.0及以上
- 设备要求: 支持SystemCapability.Communication.NetworkBoost.Core

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.NetworkBoostKit' or its corresponding type declarations.
```
**解决方法**：
- 确认HarmonyOS SDK版本≥12
- 在DevEco Studio中检查SDK Manager，确保安装了API 12及以上版本的SDK
- 清理项目缓存并重新编译：Build -> Clean Project

**问题2：权限编译错误**
```
Error: Permission denied. Need to request ohos.permission.GET_NETWORK_INFO.
```
**解决方法**：
- 在module.json5中添加权限声明
- 确保权限名称拼写正确：ohos.permission.GET_NETWORK_INFO

**问题3：类型定义错误**
```
Error: Property 'NetworkQos' does not exist on type 'typeof netQuality'.
```
**解决方法**：
- 检查API版本是否≥12
- 确保导入语句正确：`import { netQuality } from '@kit.NetworkBoostKit';`
- 使用正确的类型引用：`netQuality.NetworkQos`

## 常见问题与解决方法

### Q1：回调函数未被触发
**原因**：
- 权限未授予
- 订阅失败但未捕获异常
- 回调函数被意外取消

**解决方法**：
- 确认已申请并获得权限
- 使用try-catch捕获订阅异常
- 在订阅成功后打印日志确认
- 避免在业务逻辑中意外调用off方法

### Q2：回调数据为空或异常
**原因**：
- 设备网络状态不稳定
- 多链路场景下部分链路无数据
- 数据单位理解错误(bps vs B/s)

**解决方法**：
- 添加数据有效性验证
- 处理空数组情况：`if (list.length > 0)`
- 正确转换单位：速率/8得到B/s
- 过滤无效或异常数据

### Q3：取消订阅失败
**原因**：
- 传入的回调函数与订阅时不一致
- 未订阅却尝试取消
- 多次取消订阅

**解决方法**：
- 取消指定回调时，确保传入同一个回调函数引用
- 不传callback参数，取消所有订阅：`netQuality.off('netQosChange')`
- 避免重复调用off方法

### Q4：权限申请被拒绝
**原因**：
- 用户拒绝授权
- 未在module.json5中声明权限

**解决方法**：
- 确保在module.json5中声明权限
- 运行时使用@ohos.abilityAccessCtrl申请权限
- 用户拒绝后提示用户手动授权
- 使用降级方案，不依赖网络质量数据

### Q5：内存泄漏风险
**原因**：
- 忘记取消订阅
- 回调函数中引用了大量对象

**解决方法**：
- 在页面aboutToDisappear或业务结束时调用off取消订阅
- 回调函数中使用弱引用或及时释放对象
- 避免在回调中创建大量临时对象

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "action": "网络质量QoS信息订阅/取消订阅",
  "apisUsed": [
    "netQuality.on('netQosChange', callback)",
    "netQuality.off('netQosChange', callback?)"
  ],
  "dataReturned": {
    "pathType": "PathType枚举值(蜂窝主卡/副卡、WiFi主/辅)",
    "linkUpBandwidth": "上行带宽(bps)",
    "linkDownBandwidth": "下行带宽(bps)",
    "linkUpRate": "上行速率(bps)",
    "linkDownRate": "下行速率(bps)",
    "rttMs": "RTT时延(ms)",
    "linkUpBufferDelayMs": "上行缓冲时延(ms)"
  },
  "callback": "回调函数接收Array<NetworkQos>参数"
}
```

## 参考文档

- [API开发指南 - 网络质量评估](references/networkboost-qoscallback.md)
- [API参考说明 - netQuality](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/networkboost-netquality)

## 完整示例代码

- [ArkTS示例 - 网络质量订阅](assets/network-quality-subscribe.ets)
- [ArkTS示例 - 业务策略调整](assets/business-strategy-adjustment.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [正常订阅网络质量变化](tests/test_positive.py)：测试正常订阅流程和回调触发
- [多链路质量监听](tests/test_positive.py)：测试多链路场景下的质量数据回调
- [取消订阅](tests/test_positive.py)：测试取消订阅功能

### 边界测试用例
- [空回调数据](tests/test_boundary.py)：测试回调数据为空数组的处理
- [极值数据](tests/test_boundary.py)：测试带宽、时延极值的处理
- [单位转换](tests/test_boundary.py)：测试bps到B/s的单位转换精度

### 异常测试用例
- [权限缺失](tests/test_exception.py)：测试未授权时的错误处理
- [参数错误](tests/test_exception.py)：测试参数类型错误的处理
- [重复订阅](tests/test_exception.py)：测试重复订阅的处理
- [设备不支持](tests/test_exception.py)：测试API 801错误的降级处理