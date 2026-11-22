---
name: hmos-performance-analysis-kit-battery-usage-watcher
description: 订阅应用24h功耗器件分解统计事件，支持CPU/GPU/DDR/Display/Audio等器件的能耗数据采集，最大订阅时长24小时，适用于应用功耗分析、性能优化、电量监控场景
---

# 订阅24h功耗器件分解统计事件技能

## 功能描述

本技能提供HarmonyOS应用24h功耗器件分解统计事件的订阅能力。通过HiAppEvent API订阅系统级别的功耗统计事件（BATTERY_USAGE），实时获取应用在前台和后台运行时的各器件能耗数据，包括CPU、GPU、DDR、Display、Audio、WiFi、Modem、GPS、Sensor、ROM等器件的前台和后台能耗数据。该技能支持：

- 实时订阅系统功耗统计事件
- 获取完整的器件能耗分解数据
- 区分前台和后台能耗统计
- 支持多器件能耗监控（CPU、GPU、DDR、Display等12类器件）
- 自动采集24小时内的能耗数据

## 使用场景

### 触发词
- "订阅功耗事件"
- "监控电池使用"
- "获取功耗器件数据"
- "统计应用能耗"
- "监控耗电情况"
- "BATTERY_USAGE"

### 能做
- 订阅系统级别的24h功耗器件分解统计事件
- 获取应用的前台和后台能耗数据
- 监控CPU、GPU、DDR、Display等12类器件的能耗情况
- 实时接收功耗统计事件回调
- 分析应用的耗电热点和优化点
- 支持在主线程和子线程中订阅事件

### 绝不做
- 不订阅非功耗相关的系统事件（如崩溃事件、冻屏事件）
- 不修改或伪造功耗统计数据
- 不替代系统级的功耗管理功能
- 不处理超过24小时的历史功耗数据
- 不支持订阅其他应用的功耗数据

### 补充
- 订阅的功耗数据为系统自动采集，需等待系统上报（通常在每日0点后）
- 测试时可使用hdc命令快速触发上报：`hdc shell hidumper -s 1213 -a '--test 1'`
- 设备需断开充电并使用应用5分钟以上才会有数据上报
- 需在应用启动时（如EntryAbility.onCreate）添加订阅，确保不错过事件

## 调用规范和规则

### 输入约束
- 观察者名称：首字符必须为字母，中间字符必须为数字、字母或下划线，结尾字符必须为数字或字母，长度不超过32字符
- 域名：必须使用系统事件域 `hiAppEvent.domain.OS`
- 事件名称：必须使用 `hiAppEvent.event.BATTERY_USAGE`
- 订阅时机：建议在应用启动时（EntryAbility.onCreate）添加订阅

### 执行约束
- 最大订阅时长：24小时（系统自动采集周期）
- 回调函数执行时间：建议不超过100ms，避免阻塞事件处理
- 事件上报延迟：0点后系统统一上报，测试模式可快速触发
- 数据完整性：需确保应用运行满24小时才能获得完整统计数据

### 内容约束
- 禁止在回调函数中执行耗时操作（如网络请求、大量计算）
- 禁止在回调函数中调用removeWatcher移除当前观察者
- 禁止修改或丢弃事件数据
- 必须正确处理回调中的domain和appEventGroups参数

### 降级约束
- 网络失败：不影响功耗数据采集，数据存储在本地
- 权限不足：无需特殊权限，系统事件默认可订阅
- 数据未上报：提示用户断开充电并使用应用5分钟以上
- 系统不支持：检查API版本（需API 9+），提示用户升级系统

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备API版本是否 >= 9
2. 确认应用已正确导入@kit.PerformanceAnalysisKit
3. 确认在EntryAbility.onCreate中添加订阅逻辑

**参数准备**：
```typescript
// 导入必要的模块
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

// 定义观察者名称（需符合命名规范）
const watcherName = "batteryUsageWatcher";

// 定义事件过滤条件
const eventFilters: hiAppEvent.AppEventFilter[] = [
  {
    domain: hiAppEvent.domain.OS,
    names: [hiAppEvent.event.BATTERY_USAGE]
  }
];
```

### 步骤2：订阅功耗事件

**示例代码**：
```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

export class BatteryUsageWatcher {
  private watcher: hiAppEvent.Watcher;

  constructor() {
    // 初始化观察者配置
    this.watcher = {
      name: "batteryUsageWatcher",
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.BATTERY_USAGE]
        }
      ],
      onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
        this.handleBatteryUsageEvent(domain, appEventGroups);
      }
    };
  }

  // 订阅功耗事件
  subscribe(): void {
    try {
      const holder = hiAppEvent.addWatcher(this.watcher);
      if (holder) {
        hilog.info(0x0000, 'BatteryUsage', 'Successfully subscribed to battery usage events');
      } else {
        hilog.error(0x0000, 'BatteryUsage', 'Failed to subscribe: holder is null');
      }
    } catch (error) {
      hilog.error(0x0000, 'BatteryUsage', `Subscribe failed: ${JSON.stringify(error)}`);
    }
  }

  // 处理功耗事件回调
  private handleBatteryUsageEvent(
    domain: string, 
    appEventGroups: Array<hiAppEvent.AppEventGroup>
  ): void {
    hilog.info(0x0000, 'BatteryUsage', `Received event from domain: ${domain}`);
    
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'BatteryUsage', `Event name: ${eventGroup.name}`);
      
      for (const eventInfo of eventGroup.appEventInfos) {
        // 解析功耗数据
        this.parseBatteryUsageData(eventInfo);
      }
    }
  }

  // 解析功耗数据
  private parseBatteryUsageData(eventInfo: hiAppEvent.AppEventInfo): void {
    hilog.info(0x0000, 'BatteryUsage', `Event info: ${JSON.stringify(eventInfo)}`);
    
    // 提取关键功耗指标
    const params = eventInfo.params as Record<string, any>;
    if (params) {
      const bundleName = params.bundle_name;
      const beginTime = params.begin_time;
      const endTime = params.end_time;
      const foregroundUsage = params.foreground_usage;
      const backgroundUsage = params.background_usage;
      
      // 各器件能耗数据（前台/后台各24个小时段）
      const cpuForeground = params.cpu_foreground_energy;
      const cpuBackground = params.cpu_background_energy;
      const gpuForeground = params.gpu_foreground_energy;
      const gpuBackground = params.gpu_background_energy;
      const displayForeground = params.display_foreground_energy;
      const audioForeground = params.audio_foreground_energy;
      
      hilog.info(0x0000, 'BatteryUsage', 
        `App: ${bundleName}, Time: ${beginTime}-${endTime}, ` +
        `Foreground: ${foregroundUsage}, Background: ${backgroundUsage}`
      );
    }
  }
}
```

### 步骤3：在EntryAbility中集成

**集成代码**：
```typescript
// entry/src/main/ets/entryability/EntryAbility.ets
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BatteryUsageWatcher } from '../watcher/BatteryUsageWatcher';

export default class EntryAbility extends UIAbility {
  private batteryUsageWatcher: BatteryUsageWatcher;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'EntryAbility', 'Ability onCreate');

    // 初始化并订阅功耗事件
    this.batteryUsageWatcher = new BatteryUsageWatcher();
    this.batteryUsageWatcher.subscribe();
  }

  onDestroy(): void {
    hilog.info(0x0000, 'EntryAbility', 'Ability onDestroy');
    
    // 取消订阅
    if (this.batteryUsageWatcher) {
      this.batteryUsageWatcher.unsubscribe();
    }
  }
}
```

### 步骤4：错误处理

```typescript
import { BusinessError } from '@kit.BasicServicesKit';

// 增强的订阅方法，包含完整错误处理
subscribeWithRetry(): void {
  try {
    const holder = hiAppEvent.addWatcher(this.watcher);
    
    if (!holder) {
      const error: BusinessError = {
        code: 11102001,
        name: 'InvalidWatcherName',
        message: 'Failed to create event holder, watcher name may be invalid'
      };
      throw error;
    }
    
    hilog.info(0x0000, 'BatteryUsage', 'Successfully subscribed to battery usage events');
    
  } catch (error) {
    const err = error as BusinessError;
    
    switch (err.code) {
      case 401:
        hilog.error(0x0000, 'BatteryUsage', 
          'Parameter error: Mandatory parameters are missing or incorrect parameter types');
        break;
      case 11102001:
        hilog.error(0x0000, 'BatteryUsage', 
          'Invalid watcher name: Contains invalid characters or length is invalid');
        break;
      case 11102002:
        hilog.error(0x0000, 'BatteryUsage', 
          'Invalid filtering event domain: Contains invalid characters or length is invalid');
        break;
      default:
        hilog.error(0x0000, 'BatteryUsage', 
          `Unknown error occurred: code=${err.code}, message=${err.message}`);
    }
    
    // 降级方案：延迟重试
    setTimeout(() => {
      hilog.info(0x0000, 'BatteryUsage', 'Retrying to subscribe...');
      this.subscribeWithRetry();
    }, 1000);
  }
}
```

### 步骤5：取消订阅

```typescript
// 取消订阅功耗事件
unsubscribe(): void {
  try {
    hiAppEvent.removeWatcher(this.watcher);
    hilog.info(0x0000, 'BatteryUsage', 'Successfully unsubscribed from battery usage events');
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(0x0000, 'BatteryUsage', 
      `Failed to unsubscribe: code=${err.code}, message=${err.message}`);
  }
}
```

### 步骤6：测试验证（可选）

**构造高耗电测试场景**：
```typescript
// 测试时需要构造CPU高负载场景来触发功耗数据上报
// 1. 创建Worker线程执行死循环
// entry/src/main/ets/workers/worker.ets
import { worker } from '@kit.ArkTS';

const workerPort = worker.workerPort;

workerPort.onmessage = (message) => {
  eatCpu();
}

function eatCpu(): void {
  let val: number = 0;
  while (true) {
    val++;
  }
}

// 2. 创建CPU测试类
// entry/src/main/ets/tester/CpuTester.ets
import { worker } from '@kit.ArkTS';

export default class CpuTester {
  start(threadNum: number) {
    for (let index = 0; index < threadNum; index++) {
      const workerInstance = new worker.ThreadWorker('entry/ets/workers/worker.ets');
      workerInstance.postMessage('msg');
    }
  }
}
```

**触发测试数据上报**：
```bash
# 方式1：等待系统自动上报（每日0点后）
# 方式2：快速触发上报（测试模式）
hdc shell hidumper -s 1213 -a '--test 1'

# 修改设备时间为23:58，加速触发
hdc shell "date 0158"
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误：必填参数缺失或参数类型不正确 | 检查watcher对象是否包含必需的name字段，参数类型是否正确 |
| 11102001 | 观察者名称无效：包含非法字符或长度无效 | 确保名称首字符为字母，中间为数字/字母/下划线，结尾为数字/字母，长度≤32 |
| 11102002 | 事件域无效：包含非法字符或长度无效 | 使用系统事件域 `hiAppEvent.domain.OS`，不要自定义域 |
| 11102003 | 行数值无效：row值小于0 | 检查triggerCondition.row参数是否为非负整数 |
| 11102004 | 大小值无效：size值小于0 | 检查triggerCondition.size参数是否为非负整数 |
| 11102005 | 超时值无效：timeout值小于0 | 检查triggerCondition.timeOut参数是否为非负整数 |

## 编译和修复问题

### 依赖声明

**oh-package.json5**：
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "^1.0.0"
  }
}
```

**导入声明**：
```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 环境要求
- HarmonyOS API版本：≥ 9
- DevEco Studio版本：≥ 3.1
- 设备类型：支持所有HarmonyOS设备
- 权限要求：无需特殊权限（系统事件默认可订阅）

### 常见编译问题

**问题1：找不到@kit.PerformanceAnalysisKit模块**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit'
```
**解决方法**：
1. 检查HarmonyOS SDK版本是否≥ API 9
2. 在DevEco Studio中，File > Settings > SDK > HarmonyOS，更新SDK
3. 清理项目并重新编译：Build > Clean Project，然后 Build > Rebuild Project

**问题2：hiAppEvent.event.BATTERY_USAGE未定义**
```
Error: Property 'BATTERY_USAGE' does not exist on type 'typeof event'
```
**解决方法**：
1. 检查API版本，BATTERY_USAGE事件需API 9+
2. 使用完整的常量字符串替代：`"BATTERY_USAGE"`

**问题3：回调函数参数类型错误**
```
Error: Type 'AppEventGroup' is not assignable to type 'Array<AppEventGroup>'
```
**解决方法**：
```typescript
// 确保回调函数签名正确
onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => void
```

**问题4：Worker线程无法创建**
```
Error: Cannot find module 'entry/ets/workers/worker.ets'
```
**解决方法**：
1. 检查worker文件路径是否正确
2. 确保worker.ets文件已创建在正确的目录下
3. 清理并重新编译项目

## 常见问题与解决方法

### Q1：订阅后没有收到功耗事件回调
**原因**：
1. 设备未断开充电（充电状态下不会上报功耗数据）
2. 应用使用时间不足5分钟
3. 系统还未到上报时间（默认每日0点后上报）
4. 观察者名称重复，后一次覆盖了前一次

**解决方法**：
1. 断开USB充电线和充电器
2. 使用应用至少5分钟以上
3. 使用hdc命令快速触发上报：
   ```bash
   hdc shell hidumper -s 1213 -a '--test 1'
   ```
4. 确保观察者名称唯一，避免重复订阅

### Q2：回调中的功耗数据为空或异常
**原因**：
1. 系统采集数据未完成
2. 应用在采集周期内未运行或运行时间过短
3. 设备处于休眠状态

**解决方法**：
1. 等待完整24小时采集周期
2. 增加应用使用时间和频率
3. 构造高耗电场景（如CPU加压、屏幕常亮）
4. 检查params字段是否存在且格式正确

### Q3：如何区分前台和后台能耗数据
**原因**：功耗数据包含foreground和background两个字段数组，每个数组24个元素对应24小时

**解决方法**：
```typescript
const params = eventInfo.params as Record<string, any>;
const foregroundUsage = params.foreground_usage; // 前台使用时长数组
const backgroundUsage = params.background_usage; // 后台使用时长数组
const cpuForegroundEnergy = params.cpu_foreground_energy; // CPU前台能耗
const cpuBackgroundEnergy = params.cpu_background_energy; // CPU后台能耗

// 计算总前台使用时长（分钟）
let totalForeground = 0;
for (const hour of foregroundUsage) {
  totalForeground += hour;
}
```

### Q4：订阅后应用崩溃或无响应
**原因**：
1. 回调函数中执行了耗时操作
2. 回调函数中调用了removeWatcher移除当前观察者
3. 内存泄漏或资源未释放

**解决方法**：
1. 回调函数中避免执行耗时操作，使用异步处理：
   ```typescript
   onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
     // 使用setTimeout延迟处理
     setTimeout(() => {
       this.handleBatteryUsageEvent(domain, appEventGroups);
     }, 0);
   }
   ```
2. 不要在回调函数中移除当前观察者
3. 在Ability的onDestroy中正确释放资源

### Q5：如何在多线程环境中订阅
**原因**：addWatcher接口涉及I/O操作，可能影响主线程性能

**解决方法**：
1. 在子线程中订阅时，确保子线程在整个生命周期内不会被销毁
2. 使用Worker实现子线程订阅：
   ```typescript
   // 主线程
   const worker = new worker.ThreadWorker('entry/ets/workers/watcher-worker.ets');
   worker.postMessage({ action: 'subscribe' });
   
   // worker.ets
   workerPort.onmessage = (message) => {
     if (message.data.action === 'subscribe') {
       hiAppEvent.addWatcher({...});
     }
   }
   ```

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcher_name": "batteryUsageWatcher",
  "subscribed_event": "BATTERY_USAGE",
  "event_domain": "OS",
  "subscription_time": "2026-07-03T10:30:00.000Z",
  "api_used": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.removeWatcher",
    "hiAppEvent.domain.OS",
    "hiAppEvent.event.BATTERY_USAGE"
  ],
  "message": "Successfully subscribed to 24h battery usage statistics event"
}
```

## 参考文档

- [API开发指南：订阅24h功耗器件分解统计事件](references/hiappevent-watcher-battery-usage-arkts.md)
- [API参考说明：@ohos.hiviewdfx.hiAppEvent](references/js-apis-hiviewdfx-hiappevent.md)

## 完整示例代码

- [ArkTS完整示例：订阅功耗事件](assets/battery_usage_watcher_example.ets)
- [ArkTS完整示例：CPU加压测试](assets/cpu_stress_test_example.ets)
- [配置文件示例：EntryAbility集成](assets/entry_ability_example.ets)

## 测试用例

### 正向测试用例
- [正常订阅功耗事件](tests/test_positive.ets)：验证在正常情况下能够成功订阅BATTERY_USAGE事件
- [接收功耗数据](tests/test_positive.ets)：验证能够正确接收并解析功耗统计数据
- [取消订阅](tests/test_positive.ets)：验证能够成功取消订阅并释放资源

### 边界测试用例
- [观察者名称边界](tests/test_boundary.ets)：测试观察者名称长度为32字符的情况
- [多器件功耗监控](tests/test_boundary.ets)：验证能同时监控多个器件的能耗数据
- [长时间运行](tests/test_boundary.ets)：测试应用运行24小时完整周期的功耗采集

### 异常测试用例
- [无效观察者名称](tests/test_exception.ets)：测试观察者名称包含非法字符的情况
- [重复订阅](tests/test_exception.ets)：测试使用相同名称重复订阅的情况
- [空回调函数](tests/test_exception.ets)：测试回调函数为null或undefined的情况
- [权限不足](tests/test_exception.ets)：测试在受限环境下订阅系统事件的情况