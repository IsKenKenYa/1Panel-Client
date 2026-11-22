---
name: hmos-performance-analysis-kit-app-killed-event-watcher
description: 订阅应用终止事件，实时接收APP_KILLED系统事件通知，获取事件参数（时间戳、前后台状态、终止原因等），适用于应用生命周期监控、故障分析场景，API version 20+支持
---

# 订阅应用终止事件技能

## 功能描述

本技能实现HarmonyOS应用终止事件（APP_KILLED）的订阅功能，通过HiAppEvent模块的addWatcher接口实时监听系统终止事件，获取事件详细信息包括：

- **事件时间戳**：应用终止发生的时间（time字段）
- **前后台状态**：应用终止时是否在前台运行（foreground字段）
- **终止原因**：应用被终止的具体原因（reason字段，如RssThresholdKiller等管控终止类型）
- **应用唯一标识**：应用运行时的唯一ID（app_running_unique_id字段）
- **应用版本信息**：应用的bundle版本号（bundle_version字段）

该技能适用于应用生命周期监控、性能分析、故障诊断等场景，帮助开发者快速定位应用被系统终止的根本原因。

## 使用场景

### 触发词
- "订阅应用终止事件"
- "监听APP_KILLED事件"
- "应用被杀事件订阅"
- "应用生命周期终止监控"
- "应用崩溃/终止原因分析"

### 能做
- 实时订阅应用终止事件，获取系统管控终止通知
- 自动捕获应用终止时的关键参数（时间、状态、原因、版本）
- 支持自定义事件观察者名称和回调处理逻辑
- 提供完整的事件数据解析示例代码
- 支持移除观察者以取消订阅

### 绝不做
- 不订阅其他系统事件（如APP_CRASH、APP_FREEZE等）
- 不处理应用自定义事件打点
- 不提供故障注入或构造终止事件的测试代码（仅提供订阅功能）
- 不在回调函数中移除观察者（会导致订阅失效）

### 补充
- **API版本要求**：APP_KILLED事件从API version 20开始支持
- **订阅时机**：建议在应用启动时（如EntryAbility.onCreate）立即订阅，确保终止事件不丢失
- **数据时效性**：应用终止事件会在应用下次启动时上报，订阅后立即接收历史事件
- **I/O性能注意**：addWatcher接口涉及I/O操作，对性能敏感场景需考虑线程选择
- **观察者唯一性**：相同的观察者名称会覆盖前一次订阅

## 调用规范和规则

### 输入约束
- **观察者名称**：必须符合命名规范（首字符字母、中间数字/字母/下划线、结尾数字/字母，长度1-32字符）
- **事件领域**：必须使用系统领域 `hiAppEvent.domain.OS`
- **事件名称**：必须使用 `hiAppEvent.event.APP_KILLED`
- **回调函数**：必须实现 `onReceive` 函数处理事件数据
- **参数校验**：必须对回调参数进行类型校验（domain、appEventGroups数组）

### 执行约束
- **订阅操作耗时**：addWatcher接口涉及I/O操作，建议耗时敏感场景在子线程调用（确保子线程生命周期稳定）
- **回调处理限制**：不建议在回调中执行移除观察者操作，避免订阅功能失效
- **事件处理频率**：应用终止事件发生频率低，回调处理通常不会阻塞主线程
- **并发订阅限制**：相同名称的观察者只能存在一个，重复订阅会覆盖前一次

### 内容约束
- **禁止生成**：不生成故障注入代码、不生成构造终止事件的测试代码
- **禁止高危操作**：不使用eval、exec、动态代码执行等高危函数
- **禁止错误回调逻辑**：不在回调函数中移除观察者、不修改观察者配置
- **禁止无效订阅**：不订阅不存在的事件名称、不使用无效的观察者名称

### 降级约束
- **订阅失败降级**：若addWatcher返回null，说明订阅失败，需记录错误日志并提示用户
- **回调数据异常**：若appEventGroups为空或eventInfo.params缺失字段，记录警告日志并跳过处理
- **API版本不兼容**：若API version低于20，提示用户升级系统或使用其他事件订阅方案
- **权限不足降级**：若因权限问题订阅失败，提示用户检查应用权限配置

## 调用流程和步骤

### 步骤1：准备阶段 - 导入模块和参数准备

**前置校验**：
1. 确认API版本 >= 20（APP_KILLED事件最低支持版本）
2. 确认已导入PerformanceAnalysisKit模块
3. 确认应用在启动阶段（如EntryAbility.onCreate）执行订阅

**参数准备**：
```typescript
// 导入必要模块
import { hiAppEvent } from '@kit.PerformanceAnalysisKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 定义日志域和标签
const DOMAIN = 0x0000;
const TAG = 'AppKilledWatcher';
```

### 步骤2：调用API - 添加事件观察者订阅

**示例代码**：
```typescript
// 添加应用终止事件观察者
hiAppEvent.addWatcher({
  // 自定义观察者名称，用于唯一标识订阅者
  name: "app_killed_watcher",
  
  // 订阅过滤条件：系统领域的应用终止事件
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,  // 系统事件领域
      names: [hiAppEvent.event.APP_KILLED]  // 应用终止事件
    }
  ],
  
  // 实时回调函数，事件发生后立即触发
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(DOMAIN, TAG, `HiAppEvent onReceive: domain=${domain}`);
    
    for (const eventGroup of appEventGroups) {
      hilog.info(DOMAIN, TAG, `eventName=${eventGroup.name}`);
      
      for (const eventInfo of eventGroup.appEventInfos) {
        // 提取事件参数
        const params = eventInfo.params;
        
        // 事件基本信息
        hilog.info(DOMAIN, TAG, `eventInfo.domain=${eventInfo.domain}`);
        hilog.info(DOMAIN, TAG, `eventInfo.name=${eventInfo.name}`);
        
        // 应用终止时间戳
        const time = params['time'];
        hilog.info(DOMAIN, TAG, `eventInfo.params.time=${time}`);
        
        // 应用前后台状态
        const foreground = params['foreground'];
        hilog.info(DOMAIN, TAG, `eventInfo.params.foreground=${foreground}`);
        
        // 应用终止原因
        const reason = params['reason'];
        hilog.info(DOMAIN, TAG, `eventInfo.params.reason=${reason}`);
        
        // 应用唯一标识
        const appUniqueId = params['app_running_unique_id'];
        hilog.info(DOMAIN, TAG, `eventInfo.params.app_running_unique_id=${appUniqueId}`);
        
        // 应用版本号
        const bundleVersion = params['bundle_version'];
        hilog.info(DOMAIN, TAG, `eventInfo.params.bundle_version=${bundleVersion}`);
      }
    }
  }
});
```

### 步骤3：错误处理 - 捕获订阅异常

**错误处理代码**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';

// 添加订阅并捕获错误
try {
  const holder = hiAppEvent.addWatcher({
    name: "app_killed_watcher",
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.APP_KILLED]
      }
    ],
    onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
      // 回调处理逻辑
    }
  });
  
  if (holder === null) {
    hilog.error(DOMAIN, TAG, 'Failed to add watcher: holder is null');
  } else {
    hilog.info(DOMAIN, TAG, 'Successfully added app killed watcher');
  }
} catch (error) {
  const err = error as BusinessError;
  hilog.error(DOMAIN, TAG, `Failed to add watcher: code=${err.code}, message=${err.message}`);
  
  // 错误码处理
  switch (err.code) {
    case 401:
      hilog.error(DOMAIN, TAG, 'Parameter error: check watcher name and filters');
      break;
    case 11102001:
      hilog.error(DOMAIN, TAG, 'Invalid watcher name: check naming rules');
      break;
    case 11102002:
      hilog.error(DOMAIN, TAG, 'Invalid event domain: check domain value');
      break;
    default:
      hilog.error(DOMAIN, TAG, `Unknown error: ${err.message}`);
  }
}
```

### 步骤4：降级处理 - 移除观察者取消订阅

**降级处理代码**：
```typescript
// 移除观察者以取消订阅
function removeAppKilledWatcher(): void {
  try {
    // 定义观察者对象（必须与添加时使用的对象一致）
    const watcher: hiAppEvent.Watcher = {
      name: "app_killed_watcher"
    };
    
    hiAppEvent.removeWatcher(watcher);
    hilog.info(DOMAIN, TAG, 'Successfully removed app killed watcher');
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Failed to remove watcher: code=${err.code}, message=${err.message}`);
  }
}

// 使用场景：应用退出前清理订阅
// 注意：不建议在onReceive回调中执行此操作
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，可能原因：必填参数缺失、参数类型错误 | 检查观察者名称、事件过滤条件参数格式 |
| 11102001 | 观察者名称无效，可能原因：包含非法字符、长度不符合规范 | 使用符合规范的观察者名称（首字母、中间数字字母下划线、结尾数字字母、长度1-32） |
| 11102002 | 事件领域无效，可能原因：包含非法字符、长度不符合规范 | 使用系统领域常量 `hiAppEvent.domain.OS` |
| 11102003 | row值无效，row值小于零 | 检查triggerCondition中的row参数（本场景不需要） |
| 11102004 | size值无效，size值小于零 | 检查triggerCondition中的size参数（本场景不需要） |
| 11102005 | timeout值无效，timeout值小于零 | 检查triggerCondition中的timeOut参数（本场景不需要） |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "API version 20+"
  }
}
```

### 环境要求
- **HarmonyOS SDK**：API version 20及以上（APP_KILLED事件最低支持版本）
- **开发工具**：DevEco Studio 3.1及以上版本
- **运行环境**：HarmonyOS设备或模拟器（API version 20+）

### 常见编译问题

**问题1：找不到hiAppEvent模块**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit' or its corresponding type declarations
```
**解决方法**：
- 确认DevEco Studio已安装PerformanceAnalysisKit
- 检查项目API version配置 >= 20
- 在oh-package.json5中添加依赖声明

**问题2：APP_KILLED事件未定义**
```
Error: Property 'APP_KILLED' does not exist on type 'event'
```
**解决方法**：
- 确认API version >= 20（APP_KILLED常量从API version 20开始提供）
- 升级HarmonyOS SDK版本
- 检查导入语句是否正确

**问题3：回调参数类型错误**
```
Error: Type 'AppEventGroup' is not assignable to parameter
```
**解决方法**：
- 检查回调函数参数类型声明是否正确
- 使用正确的类型：`Array<hiAppEvent.AppEventGroup>`
- 确认eventInfo.params字段访问方式（使用索引访问）

**问题4：观察者名称不符合规范**
```
Error: Invalid watcher name (code: 11102001)
```
**解决方法**：
- 观察者名称首字符必须是字母
- 中间字符必须是数字、字母或下划线
- 结尾字符必须是数字或字母
- 长度范围1-32字符

## 常见问题与解决方法

### Q1：订阅后没有收到应用终止事件回调
**原因**：
- API版本低于20，不支持APP_KILLED事件
- 应用未被系统终止或终止原因不符合管控条件
- 观察者名称被覆盖或订阅失败

**解决方法**：
- 检查设备API version >= 20
- 确认订阅成功（addWatcher返回非null）
- 构造触发条件（内存泄漏等）验证订阅功能
- 检查应用是否被系统管控终止（RssThresholdKiller等）

### Q2：回调参数params字段缺失或为undefined
**原因**：
- 事件数据格式异常或系统上报数据不完整
- 参数访问方式错误（使用点访问而非索引访问）

**解决方法**：
- 使用索引访问params字段：`params['time']`而非`params.time`
- 添加字段存在性校验：`if (params && params['time'])`
- 记录完整事件数据用于调试：`JSON.stringify(eventInfo)`

### Q3：订阅后应用启动时立即收到历史终止事件
**原因**：
- 应用终止事件在下次启动时上报
- 系统缓存了上次终止事件数据

**解决方法**：
- 这是正常行为，历史事件会在订阅后立即上报
- 在回调中通过时间戳判断事件是否为历史事件
- 根据业务需求处理历史事件（忽略或记录）

### Q4：如何区分应用在前台还是后台被终止
**原因**：
- foreground字段标识应用终止时的前后台状态
- foreground=true表示前台终止，foreground=false表示后台终止

**解决方法**：
- 提取params['foreground']字段
- 根据foreground值判断应用终止时的运行状态
- 结合reason字段分析终止原因（前台终止通常是管控策略）

### Q5：应用终止事件的常见原因类型有哪些
**原因**：
- 系统管控策略导致应用被终止（如内存泄漏、资源占用过高）

**解决方法**：
- 解析params['reason']字段获取终止原因字符串
- 常见原因类型：
  - **RssThresholdKiller**：内存占用超阈值，系统执行管控终止
  - 其他管控终止类型（系统策略相关）
- 根据reason类型定位具体问题（如内存泄漏需优化内存使用）

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "action": "订阅应用终止事件",
  "watcherName": "app_killed_watcher",
  "eventDomain": "OS",
  "eventName": "APP_KILLED",
  "apiUsed": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.domain.OS",
    "hiAppEvent.event.APP_KILLED"
  ],
  "apiVersion": "20+",
  "description": "已成功订阅应用终止事件，将在应用被系统终止后接收事件回调"
}
```

**事件回调数据示例**：
```json
{
  "domain": "OS",
  "name": "APP_KILLED",
  "params": {
    "time": 1717597063727,
    "foreground": true,
    "reason": "RssThresholdKiller",
    "app_running_unique_id": 207544,
    "bundle_version": "1000000"
  }
}
```

## 参考文档

- [应用终止事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-app-killed-events)
- [API参考说明 - @ohos.hiviewdfx.hiAppEvent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)

## 完整示例代码

- [ArkTS完整示例 - EntryAbility订阅](assets/example_entry_ability.ets)
- [ArkTS完整示例 - 事件处理](assets/example_event_handler.ets)
- [C++故障注入示例（仅测试用）](assets/example_cpp_leak.cpp)

## 测试用例

### 正向测试用例
- [测试订阅成功](tests/test_positive.ets)：验证API version 20+环境下订阅成功
- [测试事件回调](tests/test_positive.ets)：验证终止事件回调数据完整性
- [测试参数解析](tests/test_positive.ets)：验证time、foreground、reason等参数正确提取

### 边界测试用例
- [测试观察者名称边界](tests/test_boundary.ets)：验证名称长度32字符、特殊字符处理
- [测试API版本边界](tests/test_boundary.ets)：验证API version 19/20/21兼容性
- [测试空回调处理](tests/test_boundary.ets)：验证appEventGroups为空时的处理

### 异常测试用例
- [测试无效观察者名称](tests/test_exception.ets)：验证名称不符合规范时的错误码
- [测试参数缺失](tests/test_exception.ets)：验证params字段缺失时的降级处理
- [测试重复订阅](tests/test_exception.ets)：验证相同名称订阅覆盖行为