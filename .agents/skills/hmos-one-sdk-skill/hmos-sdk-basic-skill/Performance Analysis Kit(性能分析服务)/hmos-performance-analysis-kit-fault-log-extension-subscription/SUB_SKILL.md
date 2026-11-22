---
name: hmos-performance-analysis-kit-fault-log-extension-subscription
description: 实现应用崩溃和冻屏事件的延迟通知订阅，支持应用无法启动或长时间未启动场景的故障处理，仅支持API version 21+和Stage模型，适用于故障延迟上报和维测场景
---

# 使用FaultLogExtensionAbility订阅故障事件技能

## 功能描述

本技能提供应用崩溃事件和应用冻屏事件的延迟通知订阅能力，通过继承FaultLogExtensionAbility实现应用故障发生后30分钟的延迟处理机制。适用于应用因崩溃或冻屏退出后无法启动或长时间未启动的场景，补充HiAppEvent正常订阅机制的局限性。

**核心能力**：
- 订阅系统崩溃事件（APP_CRASH）和应用冻屏事件（APP_FREEZE）
- 实现故障事件的延迟通知回调处理
- 在FaultLogExtensionAbility进程中处理故障事件信息
- 获取故障事件的详细参数（时间戳、前后台状态、进程信息、异常信息等）

**原理机制**：
应用发生崩溃或冻屏事件后，系统服务采集故障信息并保存到应用沙箱。若应用未及时重启处理，30分钟后系统拉起FaultLogExtensionAbility进程，通过事件观察者回调处理未处理的故障事件。FaultLogExtensionAbility进程在处理完成后10秒内退出。

**约束限制**：
- 仅支持API version 21及以上版本
- 仅可在Stage模型下使用
- FaultLogExtensionAbility被拉起后只有10秒处理时间
- 从故障发生开始计时30分钟后拉起（设备非休眠状态累积时间）
- FaultLogExtensionAbility自身崩溃不会再次被拉起
- 仅订阅崩溃和冻屏事件，不订阅其他系统事件
- 主进程观察者名称不能与延迟处理观察者重复
- 调用受限API名单中的API会导致功能异常

## 使用场景

### 触发词
- "订阅崩溃事件延迟通知" - 实现崩溃事件的延迟处理
- "订阅冻屏事件延迟处理" - 实现冻屏事件的延迟回调
- "FaultLogExtensionAbility" - 使用故障延迟通知能力
- "故障延迟上报" - 应用无法启动场景的故障处理
- "应用崩溃延迟处理" - 30分钟后处理崩溃事件
- "应用冻屏延迟通知" - 30分钟后处理冻屏事件

### 能做
- 实现应用崩溃事件（APP_CRASH）的延迟通知订阅
- 实现应用冻屏事件（APP_FREEZE）的延迟通知订阅
- 在应用无法启动或长时间未启动场景下处理故障事件
- 获取故障事件的详细信息（时间戳、前后台状态、进程信息、异常类型、故障日志等）
- 在FaultLogExtensionAbility进程中进行自定义的故障处理逻辑
- 补充主进程正常启动时的故障处理机制

### 绝不做
- 替代主进程正常启动时的故障事件处理（仅作为补充机制）
- 订阅除崩溃和冻屏外的其他系统事件（会导致事件重复上报）
- 在FaultLogExtensionAbility进程中调用受限API名单中的API
- 在主进程和FaultLogExtensionAbility进程使用同名的事件观察者（会导致事件丢失）
- 在FaultLogExtensionAbility自身崩溃时期望再次被拉起
- 在设备重启后期望拉起FaultLogExtensionAbility进程

### 补充
- **API版本要求**：仅API version 21及以上版本支持
- **模型限制**：仅可在Stage模型下使用，不支持FA模型
- **时间延迟**：故障发生后30分钟拉起（设备非休眠状态累积时间），测试时需保持设备屏幕常亮
- **处理时限**：FaultLogExtensionAbility被拉起后只有10秒处理时间，超时可在onDisconnect保存状态
- **观察者要求**：主进程需预先订阅相同事件并使用同名观察者B（空实现），FaultLogExtensionAbility进程观察者B需实现完整回调逻辑
- **事件限制**：仅订阅崩溃（APP_CRASH）和冻屏（APP_FREEZE）事件，订阅其他系统事件会导致重复上报问题
- **受限API**：调用受限API名单中的API会导致功能异常，详见API参考文档附录

## 调用规范和规则

### 输入约束
- **API版本**：必须为API version 21及以上版本
- **模型类型**：必须为Stage模型，不支持FA模型
- **观察者名称**：主进程和FaultLogExtensionAbility进程的事件观察者B必须同名，且不能与观察者A重复
- **事件类型**：仅订阅崩溃事件（APP_CRASH）和应用冻屏事件（APP_FREEZE），不支持其他系统事件
- **事件领域**：必须为系统事件领域（hiAppEvent.domain.OS）
- **Extension配置**：module.json5必须正确配置extensionAbilities，type为"faultLog"

### 执行约束
- **处理时限**：FaultLogExtensionAbility被拉起后最多10秒处理时间，超时在onDisconnect保存状态
- **延迟时间**：故障发生后30分钟拉起FaultLogExtensionAbility（设备非休眠状态累积时间）
- **计时规则**：从开机或上次拉起FaultLogExtensionAbility后应用首次触发故障开始计时，反复触发故障不重新计时
- **进程退出**：FaultLogExtensionAbility进程处理完成后10秒内自动退出
- **回调实现**：onFaultReportReady中必须实现完整的事件订阅和回调处理逻辑

### 内容约束
- **禁止订阅其他系统事件**：除崩溃和冻屏外的其他系统事件会导致重复上报问题
- **禁止调用受限API**：调用受限API名单中的API会导致功能异常，包括AVSessionKit、AbilityKit、ArkUI、AudioKit等Kit中的特定模块
- **禁止高危操作**：不建议在回调函数中执行移除观察者操作，会导致订阅回调功能失效
- **禁止重复观察者**：主进程观察者A和B不能同名，会导致部分事件丢失
- **禁止替代主处理**：FaultLogExtensionAbility仅用于补充处理，不能替代主进程的正常故障处理

### 降级约束
- **处理超时**：超时未处理完成时在onDisconnect中保存状态，下次启动时继续处理
- **主进程已处理**：若主进程正常启动并处理了故障事件，FaultLogExtensionAbility进程观察者B通过空处理消耗事件，不重复处理
- **首次订阅失败**：应用安装后首次在FaultLogExtensionAbility进程订阅，HiAppEvent不感知订阅前发生的事件，需主进程预先订阅
- **设备重启**：设备重启后不会拉起FaultLogExtensionAbility进程，故障事件需应用下次启动时处理
- **自身崩溃**：FaultLogExtensionAbility自身崩溃不会再次被系统服务拉起，需记录状态信息

## 调用流程和步骤

### 步骤1：准备阶段 - 新建应用工程并构造故障代码

**前置校验**：
1. 确认开发环境支持API version 21及以上版本
2. 确认使用Stage模型（不支持FA模型）
3. 确认已安装@kit.PerformanceAnalysisKit依赖

**创建应用工程**：
```bash
# 使用DevEco Studio创建ArkTS应用工程
# 选择Stage模型
# 配置API version >= 21
```

**构造故障代码（可选，用于测试）**：
```typescript
// entry/src/main/ets/pages/Index.ets
@Entry
@Component
struct Index {
  build() {
    Button("AppInput")
    .onClick(() => {
      // 构造冻屏场景：主线程阻塞15秒
      let t = Date.now();
      while (Date.now() - t <= 15000) {}
    })
  }
}
```

### 步骤2：主进程订阅配置 - 编辑EntryAbility.ets

**导入模块**：
```typescript
// entry/src/main/ets/entryability/EntryAbility.ets
import { hiAppEvent } from '@kit.PerformanceAnalysisKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```

**添加观察者A（正常处理）**：
```typescript
// 在onCreate函数中添加系统事件的订阅，观察者A
hiAppEvent.addWatcher({
  // 开发者自定义观察者名称，系统使用名称标识不同观察者
  name: "EntryAbilityWatcherNormal",
  // 订阅感兴趣的系统事件，此处订阅应用冻屏事件
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_FREEZE]
    }
  ],
  // 故障发生后，正常重启执行观察者A处理事件回调
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'testTag', `HiAppEvent onReceive: domain=${domain}`);
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'testTag', `HiAppEvent eventName=${eventGroup.name}`);
      for (const eventInfo of eventGroup.appEventInfos) {
        // 开发者可自定义处理逻辑，如上报服务器、记录日志等
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo=${JSON.stringify(eventInfo)}`);
      }
    }
  }
});
```

**添加观察者B（延迟处理预备）**：
```typescript
// 在onCreate函数中添加系统事件的订阅，观察者B
hiAppEvent.addWatcher({
  // 观察者名称，保持与FaultLogExtensionAbility进程观察者B一致
  name: "EntryAbilityWatcherExtension",
  // 订阅应用冻屏事件
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_FREEZE]
    }
  ],
  // 空实现，仅用于生成过滤规则，使故障事件在被处理前保留在应用沙箱内
  // 若应用正常重启，观察者A已处理相同事件，观察者B通过空处理消耗事件，不重复处理
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    // 空实现，不做任何处理
  }
});
```

**注意事项**：
- 观察者A和B的名称不能重复
- 观察者B仅用于生成过滤规则，实际处理在FaultLogExtensionAbility进程
- 订阅的事件必须与FaultLogExtensionAbility进程订阅的事件一致

### 步骤3：创建FaultLogExtensionAbility类

**创建文件**：
```bash
# 在entry/src/main/ets路径下新建文件
# faultlogextension/MyFaultLogExtensionAbility.ets
```

**实现FaultLogExtensionAbility类**：
```typescript
// entry/src/main/ets/faultlogextension/MyFaultLogExtensionAbility.ets
import { FaultLogExtensionAbility, hilog, hiAppEvent } from '@kit.PerformanceAnalysisKit';

export default class MyFaultLogExtensionAbility extends FaultLogExtensionAbility {
  // 重写onConnect函数，执行初始化操作
  onConnect() {
    hilog.info(0x0000, 'testTag', `FaultLogExtensionAbility onConnect`);
    // 可在此处进行初始化操作
  }

  // 重写onDisconnect函数，释放资源清理状态
  onDisconnect() {
    hilog.info(0x0000, 'testTag', `FaultLogExtensionAbility onDisconnect`);
    // 超时未处理完成时，可在此处保存状态
  }

  // 重写onFaultReportReady函数，订阅并处理故障事件
  onFaultReportReady() {
    hilog.info(0x0000, 'testTag', `FaultLogExtensionAbility onFaultReportReady`);
    
    // 添加事件观察者B，与主进程观察者B同名
    hiAppEvent.addWatcher({
      // 观察者名称，保持与主进程事件观察者B一致
      name: "EntryAbilityWatcherExtension",
      // 订阅应用冻屏事件（仅订阅崩溃和冻屏事件）
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.APP_FREEZE]
        }
      ],
      // 实现订阅回调函数，对事件数据进行自定义处理
      onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
        hilog.info(0x0000, 'testTag', `HiAppEvent onReceive: domain=${domain}`);
        for (const eventGroup of appEventGroups) {
          hilog.info(0x0000, 'testTag', `HiAppEvent eventName=${eventGroup.name}`);
          for (const eventInfo of eventGroup.appEventInfos) {
            // 获取冻屏事件详细信息
            this.processFreezeEvent(eventInfo);
          }
        }
      }
    });
  }

  // 处理冻屏事件信息
  private processFreezeEvent(eventInfo: hiAppEvent.AppEventInfo) {
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.domain=${eventInfo.domain}`);
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.name=${eventInfo.name}`);
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.eventType=${eventInfo.eventType}`);
    
    // 获取冻屏事件发生的时间戳
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.time=${eventInfo.params['time']}`);
    
    // 获取冻屏事件发生时应用的前后台状态
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.foreground=${eventInfo.params['foreground']}`);
    
    // 获取冻屏事件发生时应用的版本信息
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.bundle_version=${eventInfo.params['bundle_version']}`);
    
    // 获取冻屏事件发生时应用的唯一关联id
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.app_running_unique_id=${eventInfo.params['app_running_unique_id']}`);
    
    // 获取冻屏事件发生时应用的包名
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.bundle_name=${eventInfo.params['bundle_name']}`);
    
    // 获取冻屏事件发生时应用的进程名称
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.process_name=${eventInfo.params['process_name']}`);
    
    // 获取冻屏事件发生时应用的进程id
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.pid=${eventInfo.params['pid']}`);
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.uid=${eventInfo.params['uid']}`);
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.uuid=${eventInfo.params['uuid']}`);
    
    // 获取冻屏事件发生的异常类型、异常原因
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.exception=${JSON.stringify(eventInfo.params['exception'])}`);
    
    // 获取冻屏事件发生时日志信息
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.hilog.size=${eventInfo.params['hilog'].length}`);
    
    // 获取冻屏事件发生时主线程未处理消息
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.event_handler=${eventInfo.params['event_handler']}`);
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.event_handler_size_3s=${eventInfo.params['event_handler_size_3s']}`);
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.event_handler_size_6s=${eventInfo.params['event_handler_size_6s']}`);
    
    // 获取冻屏事件发生时同步binder调用信息
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.peer_binder=${eventInfo.params['peer_binder']}`);
    
    // 获取冻屏事件发生时全量线程调用栈
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.threads.size=${eventInfo.params['threads'].length}`);
    
    // 获取冻屏事件发生时内存信息
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.memory=${JSON.stringify(eventInfo.params['memory'])}`);
    
    // 获取冻屏事件发生时的故障日志文件
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.external_log=${JSON.stringify(eventInfo.params['external_log'])}`);
    hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.log_over_limit=${eventInfo.params['log_over_limit']}`);
    
    // 开发者可在此处实现自定义处理逻辑，如：
    // 1. 上报故障信息到服务器
    // 2. 记录故障日志到本地文件
    // 3. 发送通知提醒用户
    // 4. 分析故障原因并尝试修复
  }
}
```

### 步骤4：配置module.json5

**编辑配置文件**：
```json5
// entry/src/main/module.json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "default",
      "tablet"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:icon",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:startIcon",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": [
              "entity.system.home"
            ],
            "actions": [
              "action.system.home"
            ]
          }
        ]
      }
    ],
    // 新增extensionAbilities配置
    "extensionAbilities": [
      {
        "name": "MyFaultLogExtensionAbility",
        "srcEntry": "./ets/faultlogextension/MyFaultLogExtensionAbility.ets",
        "type": "faultLog",
        "description": "$string:ExtensionAbility_desc",
        "label": "$string:ExtensionAbility_label"
      }
    ]
  }
}
```

**配置说明**：
- `name`：ExtensionAbility名称，需与代码中的类名一致
- `srcEntry`：源文件路径，指向FaultLogExtensionAbility实现文件
- `type`：必须为"faultLog"，表示故障延迟通知类型
- `description`和`label`：在string.json中定义对应的字符串资源

### 步骤5：调测验证

**触发故障事件**：
```bash
# 1. 点击DevEco Studio运行按钮，启动应用工程
# 2. 在应用界面点击"AppInput"按钮，触发冻屏事件（主线程阻塞15秒）
# 3. 应用退出后，保持应用和设备不重启
# 4. 等待30分钟左右（设备屏幕常亮，防止休眠）
```

**查看日志输出**：
```bash
# 在HiLog窗口搜索"testTag"关键字，查看回调执行结果
# 预期输出：
# FaultLogExtensionAbility onConnect
# FaultLogExtensionAbility onFaultReportReady
# HiAppEvent onReceive: domain=OS
# HiAppEvent eventName=APP_FREEZE
# HiAppEvent eventInfo.domain=OS
# HiAppEvent eventInfo.name=APP_FREEZE
# HiAppEvent eventInfo.eventType=1
# ... (其他事件参数信息)
# FaultLogExtensionAbility onDisconnect
```

**验证成功标志**：
- FaultLogExtensionAbility依次执行连接、处理、断开
- 成功接收到冻屏事件回调
- 成功获取事件详细信息（domain、name、eventType、params等）
- onDisconnect在处理完成后执行

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1. 必选参数未指定；2. 参数类型错误 | 检查参数类型和必填参数是否正确传入 |
| 11102001 | 无效的观察者名称。可能原因：1. 包含无效字符；2. 镀度无效 | 检查观察者名称是否符合规范：首字符必须为字母，中间字符为数字字母下划线，结尾字符为数字字母，长度不超过32字符 |
| 11102002 | 无效的事件领域过滤条件。可能原因：1. 包含无效字符；2. 镀度无效 | 检查domain参数是否为系统事件领域（hiAppEvent.domain.OS）或符合规范的自定义领域 |
| 11102003 | 无效的row值。可能原因：row值小于零 | 检查triggerCondition中的row参数是否为正整数 |
| 11102004 | 无效的size值。可能原因：size值小于零 | 检查triggerCondition中的size参数是否为正整数 |
| 11102005 | 无效的timeout值。可能原因：timeout值小于零 | 检查triggerCondition中的timeOut参数是否为正整数 |

**常见错误场景**：
- **观察者名称重复**：主进程观察者A和B同名，导致部分事件丢失
- **订阅其他系统事件**：订阅除崩溃冻屏外的其他系统事件，导致事件重复上报
- **调用受限API**：在FaultLogExtensionAbility进程调用受限API名单中的API，导致功能异常
- **首次订阅无回调**：应用安装后首次在FaultLogExtensionAbility进程订阅，HiAppEvent不感知订阅前事件，需主进程预先订阅

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "API version 21+"
  }
}
```

### 环境要求
- **HarmonyOS SDK**：API version 21及以上版本
- **DevEco Studio**：支持Stage模型的最新版本
- **设备要求**：支持HarmonyOS API version 21+的真机或模拟器
- **测试环境**：设备屏幕常亮，防止休眠影响30分钟计时

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit'
```
**解决方法**：
1. 确认项目配置的API version >= 21
2. 在DevEco Studio中重新同步项目（File -> Sync Project with Gradle Files）
3. 检查build-profile.json5中的compatibleSdkVersion配置

**问题2：FaultLogExtensionAbility类未找到**
```
Error: Cannot find name 'FaultLogExtensionAbility'
```
**解决方法**：
1. 确认导入语句正确：`import { FaultLogExtensionAbility } from '@kit.PerformanceAnalysisKit';`
2. 确认API version >= 21（FaultLogExtensionAbility从API version 21开始支持）
3. 检查模块路径和名称是否正确

**问题3：module.json5配置错误**
```
Error: Invalid extensionAbilities configuration
```
**解决方法**：
1. 检查extensionAbilities配置中type字段是否为"faultLog"
2. 检查srcEntry路径是否正确指向FaultLogExtensionAbility实现文件
3. 确认name字段与代码中的类名一致

**问题4：观察者订阅失败**
```
Error: 11102001 Invalid watcher name
```
**解决方法**：
1. 检查观察者名称是否符合规范（首字符字母、中间字符数字字母下划线、结尾字符数字字母、长度不超过32）
2. 确认主进程和FaultLogExtensionAbility进程的观察者B名称一致
3. 避免观察者名称与观察者A重复

## 常见问题与解决方法

### Q1：FaultLogExtensionAbility进程没有接收到回调事件
**原因**：
- 在FaultLogExtensionAbility进程启动前，主进程已经订阅并处理了事件
- 在FaultLogExtensionAbility进程中的订阅是应用安装后的首次订阅，HiAppEvent不感知订阅前发生的事件
- 主进程未预先订阅相关事件

**解决方法**：
- 确认主进程中已订阅崩溃或冻屏事件（观察者A和观察者B）
- 确认主进程观察者B与FaultLogExtensionAbility进程观察者B同名
- 确认故障事件在主进程订阅后发生，HiAppEvent才会记录事件
- 检查事件是否已被主进程观察者A处理（应用正常重启场景）

### Q2：系统事件重复上报
**原因**：
- FaultLogExtensionAbility进程订阅了除崩溃冻屏外的其他系统事件
- 主进程和FaultLogExtensionAbility进程订阅了相同的事件，但观察者名称不同

**解决方法**：
- 仅订阅崩溃事件（APP_CRASH）和应用冻屏事件（APP_FREEZE），不订阅其他系统事件
- 主进程观察者B与FaultLogExtensionAbility进程观察者B必须同名
- 若需订阅其他系统事件，仅在主进程订阅，不在FaultLogExtensionAbility进程订阅

### Q3：部分事件丢失
**原因**：
- 主进程观察者A和B同名，导致订阅过滤条件被覆盖
- 在应用启动后事件观察者注册前发生的事件

**解决方法**：
- 确保主进程观察者A（正常处理）和观察者B（延迟处理预备）名称不重复
- 在应用启动后立即注册事件观察者，避免事件丢失
- HiAppEvent在应用启动后会扫描上次退出前未移除的事件观察者的订阅过滤条件，据此对事件进行订阅保存

### Q4：处理超时未完成
**原因**：
- FaultLogExtensionAbility被拉起后处理逻辑耗时超过10秒
- 回调函数中执行了复杂的数据处理或网络请求

**解决方法**：
- 在onDisconnect中保存处理状态，下次启动时继续处理
- 简化onFaultReportReady中的处理逻辑，避免耗时操作
- 将复杂处理逻辑异步执行或延迟到下次应用启动时处理

### Q5：测试时未触发FaultLogExtensionAbility
**原因**：
- 设备进入休眠状态，导致30分钟计时延长
- 故障发生后应用或设备重启，清除了计时任务
- FaultLogExtensionAbility自身崩溃

**解决方法**：
- 测试时保持设备屏幕常亮，防止休眠
- 故障发生后保持应用和设备不重启，等待30分钟
- 检查FaultLogExtensionAbility实现是否会导致自身崩溃
- 确认module.json5配置正确，FaultLogExtensionAbility能够正常拉起

### Q6：调用受限API导致功能异常
**原因**：
- 在FaultLogExtensionAbility进程中调用了受限API名单中的API
- 受限API包括AVSessionKit、AbilityKit、ArkUI、AudioKit等多个Kit中的特定模块

**解决方法**：
- 查阅API参考文档附录中的受限API名单
- 避免在FaultLogExtensionAbility进程中调用受限API
- 仅使用PerformanceAnalysisKit中的hiAppEvent和hilog API
- 若需其他功能，在主进程实现，不在FaultLogExtensionAbility进程调用

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "eventType": "APP_FREEZE",
  "eventDomain": "OS",
  "eventTimestamp": "1234567890",
  "processInfo": {
    "bundleName": "com.example.myapp",
    "processName": "com.example.myapp",
    "pid": 12345,
    "uid": 10001
  },
  "exceptionInfo": {
    "type": "APP_FREEZE",
    "reason": "MainThreadBlocked"
  },
  "handledBy": "FaultLogExtensionAbility",
  "observerName": "EntryAbilityWatcherExtension",
  "apiUsed": [
    "FaultLogExtensionAbility",
    "hiAppEvent.addWatcher",
    "hiAppEvent.domain.OS",
    "hiAppEvent.event.APP_FREEZE"
  ],
  "processTime": "2024-01-01T12:00:00Z",
  "logFiles": [
    "/data/local/tmp/myapp_freeze_12345.log"
  ]
}
```

**输出字段说明**：
- `status`：处理状态，success表示成功处理
- `eventType`：事件类型，APP_FREEZE或APP_CRASH
- `eventDomain`：事件领域，OS表示系统事件
- `eventTimestamp`：事件发生时间戳
- `processInfo`：进程信息，包括包名、进程名、PID、UID
- `exceptionInfo`：异常信息，包括类型和原因
- `handledBy`：处理进程标识，FaultLogExtensionAbility表示由延迟通知进程处理
- `observerName`：观察者名称
- `apiUsed`：使用的API列表
- `processTime`：处理时间
- `logFiles`：故障日志文件路径列表

## 参考文档

- [使用FaultLogExtensionAbility订阅事件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/fault-log-extension-app-events-arkts)
- [@ohos.hiviewdfx.FaultLogExtensionAbility (故障延迟通知)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-faultlogextensionability)
- [@ohos.hiviewdfx.hiAppEvent (应用事件打点)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)
- [崩溃事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-crash-events)
- [应用冻屏事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-freeze-events)

## 完整示例代码

- [ArkTS完整示例](assets/MyFaultLogExtensionAbility.ets)
- [EntryAbility示例](assets/EntryAbility.ets)
- [module.json5配置示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [订阅冻屏事件延迟处理](tests/test_positive_freeze.ets)：测试应用冻屏事件的延迟通知订阅和处理
- [订阅崩溃事件延迟处理](tests/test_positive_crash.ets)：测试应用崩溃事件的延迟通知订阅和处理
- [获取事件详细信息](tests/test_positive_event_info.ets)：测试获取故障事件的详细参数信息

### 边界测试用例
- [处理时限测试](tests/test_boundary_timeout.ets)：测试FaultLogExtensionAbility10秒处理时限
- [观察者名称唯一性](tests/test_boundary_observer_name.ets)：测试观察者名称唯一性约束
- [API版本兼容性](tests/test_boundary_api_version.ets)：测试API version 21版本要求

### 异常测试用例
- [调用受限API](tests/test_exception_restricted_api.ets)：测试调用受限API导致的异常
- [订阅其他系统事件](tests/test_exception_other_events.ets)：测试订阅其他系统事件导致的重复上报
- [观察者名称重复](tests/test_exception_duplicate_name.ets)：测试观察者名称重复导致的事件丢失
- [FaultLogExtensionAbility自身崩溃](tests/test_exception_self_crash.ets)：测试FaultLogExtensionAbility自身崩溃场景