---
name: hmos-performance-analysis-kit-audio-jank-event-watcher
description: 订阅应用音频卡顿事件，监控音频播放丢帧场景，支持实时回调处理卡顿事件数据，适用于音频性能监控和故障排查场景，需要API version 21及以上
---

# 订阅音频卡顿事件（ArkTS）技能

## 功能描述

本技能提供应用音频卡顿事件的订阅能力，通过HiAppEvent模块实现对音频播放过程中丢帧生成的卡顿事件的监听和处理。音频卡顿事件（AUDIO_JANK_FRAME）是系统预定义的系统事件，当应用在音频渲染过程中触发丢帧时自动生成。

**核心能力**：
- 添加事件观察者订阅音频卡顿事件
- 实时回调接收卡顿事件数据
- 处理和分析卡顿事件信息
- 移除事件观察者取消订阅

**事件参数**：
音频卡顿事件包含以下关键参数：
- `bundle_name`: 应用包名
- `bundle_version`: 应用版本号
- `fault_type`: 故障类型
- `happen_time`: 发生时间
- `max_frame_time`: 最大帧耗时（毫秒）
- `time`: 事件时间戳

## 使用场景

### 触发词
- "订阅音频卡顿事件"
- "监控音频播放性能"
- "检测音频丢帧"
- "音频卡顿故障排查"
- "HiAppEvent音频事件"

### 能做
- 实时订阅和接收音频卡顿事件
- 解析卡顿事件的详细参数信息
- 记录和分析音频播放性能问题
- 自定义处理卡顿事件数据（如日志记录、上报服务器等）
- 动态添加和移除事件观察者

### 绝不做
- 不用于订阅其他类型的系统事件（如崩溃事件、冻屏事件等）
- 不用于应用事件打点（Write接口）
- 不用于配置事件策略（configEventPolicy接口）
- 不用于音频播放功能实现（仅监控）
- 不在回调函数中移除观察者（会造成订阅失效）

### 补充
- 音频卡顿事件从API version 21开始支持
- 需要音频渲染器（AudioRenderer）触发卡顿才会生成事件
- 卡顿事件由系统自动生成，开发者无需手动打点
- 订阅失败时返回null，需要检查参数合法性
- 相同观察者名称的后一次订阅会覆盖前一次

## 调用规范和规则

### 输入约束
- 观察者名称：首字符必须为字母，中间字符必须为数字、字母或下划线，结尾字符必须为数字或字母，长度不超过32个字符
- 事件领域：必须使用hiAppEvent.domain.OS（系统领域）
- 事件名称：必须使用hiAppEvent.event.AUDIO_JANK_FRAME
- API版本：最低要求API version 21

### 执行约束
- addWatcher接口涉及I/O操作，性能敏感场景建议在子线程调用
- 如在子线程调用，需确保线程不会被销毁
- 最大观察者数量受系统限制
- 回调函数执行时间不宜过长，避免阻塞事件处理

### 内容约束
- 禁止在回调函数中调用removeWatcher移除观察者
- 禁止订阅与音频卡顿无关的系统事件
- 禁止使用包含非法字符的观察者名称
- 禁止在禁用打点功能（disable=true）时订阅事件

### 降级约束
- 订阅失败（返回null）：检查参数合法性并重试
- 未接收到事件：确认音频渲染是否触发卡顿，检查订阅配置
- API版本不支持：提示用户升级系统版本或使用其他监控方式
- 网络上报失败：本地缓存事件数据，待网络恢复后上报

## 调用流程和步骤

### 步骤1：导入必要模块

```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { audio } from '@kit.AudioKit';
```

### 步骤2：添加事件观察者

在应用启动时（如EntryAbility.ets）添加观察者订阅音频卡顿事件：

```typescript
hiAppEvent.addWatcher({
  name: "audioJankWatcher",
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.AUDIO_JANK_FRAME]
    }
  ],
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'AudioJank', `onReceive: domain=${domain}`);
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'AudioJank', `eventName=${eventGroup.name}`);
      for (const eventInfo of eventGroup.appEventInfos) {
        hilog.info(0x0000, 'AudioJank', `eventInfo=${JSON.stringify(eventInfo)}`);
      }
    }
  }
});
```

### 步骤3：触发音频卡顿事件

创建AudioRenderer实例，在音频数据写入回调中模拟卡顿：

```typescript
let g_invalidCount = 0;

function normalCallback(buffer: ArrayBuffer) {
  if (g_invalidCount > 0) {
    g_invalidCount--;
    return audio.AudioDataCallbackResult.INVALID;
  }
  return audio.AudioDataCallbackResult.VALID;
}

audio.createAudioRenderer(audioRendererOptions, (err, renderer) => {
  if (!err && renderer) {
    renderer.on('writeData', normalCallback);
  }
});
```

### 步骤4：手动触发卡顿

通过按钮或其他方式改变INVALID返回次数，触发卡顿：

```typescript
Button("触发卡顿").onClick(() => {
  g_invalidCount = 30;
});
```

### 步骤5：处理接收的事件

在onReceive回调中自定义处理逻辑：

```typescript
onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
  for (const eventGroup of appEventGroups) {
    for (const eventInfo of eventGroup.appEventInfos) {
      const params = eventInfo.params;
      hilog.info(0x0000, 'AudioJank', 
        `卡顿详情：bundle_name=${params.bundle_name}, max_frame_time=${params.max_frame_time}ms`);
    }
  }
}
```

### 步骤6：移除观察者（可选）

在不需要继续订阅时移除观察者：

```typescript
let watcher: hiAppEvent.Watcher = {
  name: "audioJankWatcher",
};
hiAppEvent.removeWatcher(watcher);
```

### 步骤7：错误处理

```typescript
try {
  hiAppEvent.addWatcher({
    name: "audioJankWatcher",
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.AUDIO_JANK_FRAME]
      }
    ],
    onReceive: (domain, appEventGroups) => {
      hilog.info(0x0000, 'AudioJank', `Received event in domain=${domain}`);
    }
  });
} catch (error) {
  hilog.error(0x0000, 'AudioJank', `订阅失败: code=${error.code}, message=${error.message}`);
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：必填参数未指定、参数类型错误 | 检查watcher对象的name、appEventFilters参数是否正确 |
| 11102001 | 无效的观察者名称。可能原因：包含非法字符、长度无效 | 使用合法字符（字母、数字、下划线），长度不超过32字符 |
| 11102002 | 无效的过滤事件领域。可能原因：包含非法字符、长度无效 | 使用系统领域hiAppEvent.domain.OS |
| 11100001 | 功能被禁用。原因：ConfigOption中disable参数为true | 调用configure接口设置disable=false |
| 11101001 | 无效的事件领域。可能原因：包含非法字符、长度无效 | 检查domain参数格式 |
| 11101002 | 无效的事件名称。可能原因：包含非法字符、长度无效 | 使用hiAppEvent.event.AUDIO_JANK_FRAME常量 |

## 编译和修复问题

### 依赖声明

```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "latest",
    "@kit.AudioKit": "latest"
  }
}
```

### 环境要求
- HarmonyOS SDK：最低API version 21
- DevEco Studio：推荐3.1及以上版本
- 设备类型：支持音频渲染的所有设备

### 常见编译问题

**问题1：找不到hiAppEvent模块**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit'
```
**解决方法**：确保DevEco Studio已安装PerformanceAnalysisKit，检查ohpm配置

**问题2：AUDIO_JANK_FRAME未定义**
```
Error: Property 'AUDIO_JANK_FRAME' does not exist on type 'event'
```
**解决方法**：升级HarmonyOS SDK至API version 21及以上

**问题3：audio模块导入失败**
```
Error: Cannot find module '@kit.AudioKit'
```
**解决方法**：确保已安装AudioKit，在oh-package.json5中添加依赖

## 常见问题与解决方法

### Q1：订阅成功但未接收到卡顿事件
**原因**：音频渲染器未触发卡顿或卡顿未达到系统阈值
**解决方法**：
- 确认AudioRenderer正常工作
- 模拟触发卡顿（返回INVALID）
- 检查音频数据写入逻辑
- 确认系统检测阈值配置

### Q2：订阅返回null
**原因**：参数不合法或打点功能被禁用
**解决方法**：
- 检查观察者名称格式和长度
- 确认事件领域和名称正确
- 检查disable配置是否为false
- 查看hilog日志中的错误信息

### Q3：如何获取卡顿事件的详细参数
**原因**：事件数据在params字段中
**解决方法**：
```typescript
for (const eventInfo of eventGroup.appEventInfos) {
  const params = eventInfo.params;
  console.log(`bundle_name: ${params.bundle_name}`);
  console.log(`max_frame_time: ${params.max_frame_time}`);
  console.log(`happen_time: ${params.happen_time}`);
}
```

### Q4：能否同时订阅多个卡顿事件
**原因**：names字段支持数组
**解决方法**：
```typescript
appEventFilters: [
  {
    domain: hiAppEvent.domain.OS,
    names: [hiAppEvent.event.AUDIO_JANK_FRAME, hiAppEvent.event.MAIN_THREAD_JANK]
  }
]
```

### Q5：如何在子线程调用addWatcher
**原因**：addWatcher涉及I/O操作，影响性能
**解决方法**：
- 使用Worker创建子线程
- 确保子线程在整个订阅周期内不被销毁
- 参考Worker简介文档实现多线程

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcher_name": "audioJankWatcher",
  "subscribed_events": ["AUDIO_JANK_FRAME"],
  "event_domain": "OS",
  "api_version": "21+",
  "capabilities": [
    "实时接收音频卡顿事件",
    "解析事件参数信息",
    "自定义事件处理逻辑"
  ]
}
```

## 参考文档

- [API开发指南：订阅音频卡顿事件](references/hiappevent-watcher-audio-jank-event-arkts.md)
- [API参考说明：@ohos.hiviewdfx.hiAppEvent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)

## 完整示例代码

- [ArkTS示例：音频卡顿事件订阅完整实现](assets/audio_jank_event_watcher_example.ets)
- [配置示例：AudioRenderer配置](assets/audio_renderer_config.json)

## 测试用例

### 正向测试用例
- [测试订阅音频卡顿事件](tests/test_subscribe_audio_jank_event.py)：验证正常订阅和事件接收
- [测试事件参数解析](tests/test_parse_event_params.py)：验证事件数据解析正确性

### 边界测试用例
- [测试观察者名称长度限制](tests/test_watcher_name_length.py)：验证32字符长度限制
- [测试API版本兼容性](tests/test_api_version_compatibility.py)：验证API version 21支持

### 异常测试用例
- [测试无效观察者名称](tests/test_invalid_watcher_name.py)：验证非法字符和长度错误处理
- [测试功能禁用场景](tests/test_disabled_function.py)：验证disable=true时的错误处理