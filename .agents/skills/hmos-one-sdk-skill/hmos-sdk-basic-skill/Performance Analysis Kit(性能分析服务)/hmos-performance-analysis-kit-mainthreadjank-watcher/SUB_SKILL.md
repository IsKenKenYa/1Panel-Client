---
name: hmos-performance-analysis-kit-mainthreadjank-watcher
description: 订阅主线程超时事件，通过HiAppEvent添加观察者监听MAIN_THREAD_JANK系统事件，实时获取超时时间、堆栈信息、trace日志，支持自定义采样参数，适用于性能分析、故障排查、应用优化场景
---

# 订阅主线程超时事件技能

## 功能描述

本技能实现HarmonyOS应用主线程超时事件的订阅和监听功能。通过HiAppEvent API添加事件观察者，订阅系统定义的MAIN_THREAD_JANK事件，实时接收主线程超时事件信息，包括超时发生时间、应用版本、包名、进程信息、堆栈数据和trace日志文件路径。支持自定义配置采样栈参数（采样间隔、采样次数、上报次数等），帮助开发者快速定位和解决主线程性能问题。

**核心能力**：
- 实时监听主线程超时事件
- 获取超时事件的详细信息（时间戳、堆栈、trace）
- 自定义采样参数配置
- 事件数据的自定义处理和日志文件管理

## 使用场景

### 触发词
- "订阅主线程超时事件"
- "监听主线程卡顿"
- "主线程性能监控"
- "MAIN_THREAD_JANK事件"
- "主线程超时检测"

### 能做
- 添加事件观察者订阅主线程超时事件
- 实时接收主线程超时事件通知
- 获取超时事件的完整信息（时间、堆栈、trace）
- 自定义采样栈参数（采样间隔、次数等）
- 处理和移动超时事件日志文件
- 移除事件观察者取消订阅

### 绝不做
- 不订阅非系统事件领域的事件
- 不处理应用自定义事件
- 不用于订阅崩溃事件（APP_CRASH）
- 不用于订阅冻屏事件（APP_FREEZE）
- 不修改系统事件定义

### 补充
- 主线程超时事件触发条件：连续两次超时事件后开启采集
- 默认检测启动时间：应用启动10秒后开始检测
- 自定义参数需使用nolog版本并关闭开发者模式才能触发trace采集
- 观察者名称必须唯一，重复添加会覆盖之前的订阅

## 调用规范和规则

### 输入约束
- 观察者名称：首字符必须为字母，中间可包含数字、字母、下划线，结尾必须为数字或字母，长度≤32字符
- 事件领域：固定值 `hiAppEvent.domain.OS`
- 事件名称：固定值 `hiAppEvent.event.MAIN_THREAD_JANK`
- 自定义参数值：字符串长度≤1024字符
- 参数个数：≤64个

### 执行约束
- addWatcher接口涉及I/O操作，执行时间毫秒级
- 主线程超时检测启动时间：默认10秒，自定义可设置ignore_startup_time
- 连续两次超时后才开启采集堆栈
- 单次生命周期内上报次数限制：默认1次，可设置最多3次
- 采样次数限制：需满足公式 sampleCount <= (2500 / sampleInterval - 4)

### 内容约束
- 禁止订阅非系统事件领域
- 禁止修改系统事件参数字段定义
- 禁止在回调函数中移除观察者（会导致回调失效）
- 禁止使用系统事件名称作为自定义事件名称

### 降级约束
- 网络失败：继续监听，不影响事件采集
- 日志文件过大：按从旧到新顺序删除，直到不超出配额
- 参数校验失败：抛出错误码，不执行订阅
- 观察者名称重复：覆盖之前的订阅，之前的订阅失效

## 调用流程和步骤

### 步骤1：准备阶段

**导入必要模块**：
```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { buffer, util } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';
```

**前置校验**：
1. 检查系统事件领域是否为 `hiAppEvent.domain.OS`
2. 检查事件名称是否为 `hiAppEvent.event.MAIN_THREAD_JANK`
3. 检查观察者名称是否符合命名规范（字母开头，字母/数字结尾，≤32字符）

### 步骤2：添加事件观察者

**基本订阅示例**：
```typescript
hiAppEvent.addWatcher({
  name: "watcher",
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.MAIN_THREAD_JANK]
    }
  ],
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'testTag', `HiAppEvent onReceive: domain=${domain}`);
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'testTag', `HiAppEvent eventName=${eventGroup.name}`);
      for (const eventInfo of eventGroup.appEventInfos) {
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.domain=${eventInfo.domain}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.name=${eventInfo.name}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.eventType=${eventInfo.eventType}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.time=${eventInfo.params['time']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.bundle_version=${eventInfo.params['bundle_version']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.bundle_name=${eventInfo.params['bundle_name']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.pid=${eventInfo.params['pid']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.uid=${eventInfo.params['uid']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.begin_time=${eventInfo.params['begin_time']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.end_time=${eventInfo.params['end_time']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.log_over_limit=${eventInfo.params['log_over_limit']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.app_start_jiffies_time=${JSON.stringify(eventInfo.params['app_start_jiffies_time'])}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.heaviest_stack=${eventInfo.params['heaviest_stack']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.external_log=${JSON.stringify(eventInfo.params['external_log'])}`);
        let path: string = String(eventInfo.params['external_log']);
        let targetPath: string = "";
        if (path.endsWith(".txt")) {
          targetPath= "/data/storage/el2/base/mainThreadJank.txt";
        } else if (path.endsWith(".trace")) {
          targetPath= "/data/storage/el2/base/mainThreadJank.trace";
        }
        fileIo.copyFileSync(path.toString(), targetPath.toString());
      }
    }
  }
});
```

### 步骤3：自定义采样参数配置（可选）

**设置采样栈参数**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';

let params: Record<string, hiAppEvent.ParamType> = {
  "log_type": "1",
  "sample_interval": "100",
  "ignore_startup_time": "11",
  "sample_count": "21",
  "report_times_per_app": "3"
};

hiAppEvent.setEventConfig(hiAppEvent.event.MAIN_THREAD_JANK, params).then(() => {
  hilog.info(0x0000, 'testTag', `HiAppEvent success to set event params.`);
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'testTag', `HiAppEvent err.code: ${err.code}, err.message: ${err.message}`);
});
```

**参数说明**：
- `log_type`: "0"（默认采样栈和trace），"1"（仅采样栈），"2"（仅trace）
- `sample_interval`: 超时检测间隔和采样间隔（毫秒），范围[50, 500]
- `ignore_startup_time`: 启动期间忽略检测时间（秒），最小值3
- `sample_count`: 采样次数，需满足公式：sampleCount <= (2500 / sampleInterval - 4)
- `report_times_per_app`: 单次生命周期上报次数，范围[1, 3]

### 步骤4：模拟触发超时事件

**模拟主线程超时**：
```typescript
@Entry
@Component
struct Index {
  build() {
    RelativeContainer() {
      Column() {
        Button("timeOut350", { stateEffect: true, type: ButtonType.Capsule })
          .width('75%')
          .height(50)
          .margin(15)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            let t = Date.now();
            while (Date.now() - t <= 350) {}
          })
      }.width('100%')
    }
    .height('100%')
    .width('100%')
  }
}
```

### 步骤5：错误处理

**订阅失败处理**：
```typescript
try {
  hiAppEvent.addWatcher({
    name: "watcher",
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.MAIN_THREAD_JANK]
      }
    ],
    onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
      hilog.info(0x0000, 'testTag', `Received event: domain=${domain}`);
    }
  });
} catch (error) {
  hilog.error(0x0000, 'testTag', `Failed to add watcher: code=${error.code}, message=${error.message}`);
}
```

### 步骤6：移除观察者

**取消订阅**：
```typescript
let watcher: hiAppEvent.Watcher = {
  name: "watcher",
};

hiAppEvent.addWatcher(watcher);
hiAppEvent.removeWatcher(watcher);
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1. 必填参数未指定；2. 参数类型错误 | 检查参数是否完整且类型正确 |
| 11102001 | 观察者名称无效。可能原因：1. 包含无效字符；2. 镜度无效 | 使用符合规范的名称：字母开头，字母/数字结尾，仅包含数字/字母/下划线，长度≤32 |
| 11102002 | 过滤事件领域无效。可能原因：1. 包含无效字符；2. 镜度无效 | 使用系统事件领域：hiAppEvent.domain.OS |
| 11102003 | 行数值无效。行数值小于0 | 设置正整数值 |
| 11102004 | 大小值无效。大小值小于0 | 设置正整数值 |
| 11102005 | 超时值无效。超时值小于0 | 设置正整数值 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "^1.0.0",
    "@kit.ArkTS": "^1.0.0",
    "@kit.CoreFileKit": "^1.0.0",
    "@kit.BasicServicesKit": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS API Version: ≥12（MAIN_THREAD_JANK事件从API 12开始支持）
- DevEco Studio: ≥3.1
- ArkTS: 支持ES2015+语法

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit'
```
**解决方法**：检查项目依赖配置，确保已安装@kit.PerformanceAnalysisKit模块

**问题2：事件名称未定义**
```
Error: 'MAIN_THREAD_JANK' is not defined
```
**解决方法**：确认API Version ≥12，MAIN_THREAD_JANK常量从API 12开始支持

**问题3：文件路径权限不足**
```
Error: Permission denied for /data/storage/el2/base/
```
**解决方法**：检查应用权限配置，确保具有文件读写权限

## 常见问题与解决方法

### Q1：订阅后未收到事件回调
**原因**：
1. 主线程未发生超时事件
2. 应用启动未超过检测时间（默认10秒）
3. 未连续触发两次超时事件
4. 观察者名称被覆盖

**解决方法**：
- 快速点击2~3次触发超时按钮，确保连续两次超时
- 等待应用启动10秒后再测试
- 检查观察者名称是否唯一

### Q2：未生成堆栈或trace日志
**原因**：
1. 使用了非nolog版本
2. 开启了开发者模式（trace采集需关闭）
3. log_type参数设置不正确

**解决方法**：
- 使用nolog版本进行测试
- 关闭开发者模式后触发trace采集
- 检查log_type参数：0（默认）、1（仅采样栈）、2（仅trace）

### Q3：采样参数设置失败
**原因**：
1. sampleCount超出计算公式限制
2. sampleInterval不在有效范围[50, 500]
3. ignore_startup_time小于最小值3

**解决方法**：
- 计算最大sampleCount：sampleCount <= (2500 / sampleInterval - 4)
- 设置sampleInterval在有效范围内
- 设置ignore_startup_time ≥ 3

### Q4：事件日志文件无法访问
**原因**：
1. 日志文件路径格式错误
2. 文件权限不足
3. external_log字段为空

**解决方法**：
- 检查external_log字段值是否为有效路径
- 验证文件读写权限配置
- 使用fileIo.copyFileSync移动文件到可访问目录

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcher_name": "watcher",
  "event_domain": "OS",
  "event_name": "MAIN_THREAD_JANK",
  "subscription_time": "2024-06-13T21:17:39Z",
  "event_params": {
    "time": 1717593620518,
    "bundle_version": "1.0.0",
    "bundle_name": "com.example.main_thread_jank",
    "pid": 40986,
    "uid": 20020150,
    "begin_time": 1717593620016,
    "end_time": 1717593620518,
    "log_over_limit": false,
    "external_log": "/data/storage/el2/log/watchdog/MAIN_THREAD_JANK_20240613211739_40986.txt"
  },
  "apiUsed": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.event.MAIN_THREAD_JANK",
    "hiAppEvent.domain.OS"
  ]
}
```

## 参考文档

- [API开发指南](references/hiappevent-watcher-mainthreadjank-events-arkts.md)
- [API参考说明](references/js-apis-hiviewdfx-hiappevent.md)

## 完整示例代码

- [ArkTS示例](assets/example_mainthreadjank_watcher.ets)
- [配置示例](assets/config.json)

## 测试用例

### 正向测试用例
- [基本订阅测试](tests/test_positive.py)：验证基本订阅功能和事件接收
- [自定义参数测试](tests/test_positive.py)：验证自定义采样参数配置

### 边界测试用例
- [观察者名称边界测试](tests/test_boundary.py)：测试名称长度和字符限制
- [采样参数边界测试](tests/test_boundary.py)：测试采样间隔和次数的边界值

### 异常测试用例
- [参数错误测试](tests/test_exception.py)：测试无效参数的错误处理
- [重复订阅测试](tests/test_exception.py)：测试观察者名称重复的场景