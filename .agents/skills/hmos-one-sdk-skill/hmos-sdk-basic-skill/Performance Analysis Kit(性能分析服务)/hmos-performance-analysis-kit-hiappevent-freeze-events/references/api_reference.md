# 订阅应用冻屏事件（ArkTS）- 参考文档

## 原始文档来源

本文档基于以下官方文档整理：

- 开发指南：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-freeze-events-arkts
- API参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent

## 核心API列表

### hiAppEvent.addWatcher
添加应用事件观察者，以添加对应用事件的订阅。

**接口定义**：
```typescript
addWatcher(watcher: Watcher): AppEventPackageHolder
```

**参数说明**：
| 参数名 | 类型 | 必填 | 说明 |
|-------|------|------|------|
| watcher | Watcher | 是 | 事件观察者对象 |

**返回值**：
- 成功：返回AppEventPackageHolder订阅数据持有者
- 失败：返回null

**错误码**：
- 401：参数错误
- 11102001：观察者名称无效
- 11102002：事件领域无效

### hiAppEvent.removeWatcher
移除应用事件观察者，以移除对应用事件的订阅。

**接口定义**：
```typescript
removeWatcher(watcher: Watcher): void
```

### hiAppEvent.setEventParam (API 12+)
事件自定义参数设置方法，使用Promise方式作为异步回调。

**接口定义**：
```typescript
setEventParam(params: Record<string, ParamType>, domain: string, name?: string): Promise<void>
```

**参数规格**：
- 参数名：string类型，首字符字母或$，中间数字/字母/下划线，结尾数字/字母，长度≤32
- 参数值：ParamType类型，长度≤1024字符
- 参数个数：≤64个

### hiAppEvent.configEventPolicy (API 22+)
系统事件相关的配置策略设置方法。

**接口定义**：
```typescript
configEventPolicy(policy: EventPolicy): Promise<void>
```

## 系统事件常量

### hiAppEvent.domain.OS
系统事件领域常量，用于订阅系统事件。

### hiAppEvent.event.APP_FREEZE
应用冻屏事件名称常量，表示应用无响应事件。

## Watcher对象结构

```typescript
interface Watcher {
  name: string;                               // 观察者名称（必填）
  triggerCondition?: TriggerCondition;        // 回调触发条件（可选）
  appEventFilters?: AppEventFilter[];         // 事件过滤条件（可选）
  onTrigger?: Function;                       // 触发回调函数（可选）
  onReceive?: Function;                       // 实时回调函数（可选，API 11+）
}
```

## AppEventInfo对象结构

冻屏事件params包含以下字段：

| 字段名 | 说明 |
|-------|------|
| time | 事件发生时间戳 |
| foreground | 应用前后台状态 |
| app_running_unique_id | 应用唯一关联id |
| bundle_version | 应用版本 |
| bundle_name | 应用包名 |
| process_name | 进程名 |
| pid | 进程id |
| uid | 用户id |
| uuid | 唯一标识符 |
| exception | 异常信息（包含name和message） |
| hilog | 日志信息数组 |
| event_handler | 主线程未处理消息数组 |
| event_handler_size_3s | 3秒内事件处理数 |
| event_handler_size_6s | 6秒内事件处理数 |
| peer_binder | binder调用信息数组 |
| threads | 全量线程调用栈数组 |
| memory | 内存信息对象 |
| external_log | 故障日志文件路径数组 |
| log_over_limit | 日志是否超限 |
| process_life_time | 进程存活时间 |
| external_callback_log | 回调日志信息 |
| page_switch_log | 页面切换日志（API 24+） |

## 异常类型说明

冻屏事件exception.name字段包含以下类型：

- **THREAD_BLOCK_6S**：主线程阻塞6秒
- **THREAD_BLOCK_3S**：主线程阻塞3秒

## FaultLogger迁移映射

从FaultLogger API迁移到HiAppEvent的字段对应关系：

| FaultLogger.FaultLogInfo | HiAppEvent.AppEventInfo.params |
|-------------------------|-------------------------------|
| pid | pid |
| uid | uid |
| type | exception.name |
| timestamp | time |
| module | bundle_name |
| fullLog | external_log（文件路径） |
| reason | external_log文件内容中的Reason字段 |
| summary | external_log文件特定段落 |

## 使用注意事项

1. **性能影响**：addWatcher接口涉及I/O操作，建议在子线程调用
2. **回调限制**：不建议在回调中执行移除观察者操作
3. **订阅覆盖**：相同名称的订阅会覆盖之前的订阅
4. **维测耗时**：系统捕获维测日志典型耗时30s，极端情况2min
5. **版本要求**：页面切换日志需要API Version 24+
6. **数据获取**：建议使用takeNext方法延时重试获取事件

## 相关文档链接

- [应用冻屏事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-freeze-events)
- [使用FaultLogExtensionAbility订阅事件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/fault-log-extension-app-events-arkts)
- [HiAppEvent介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-intro)
- [崩溃事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-crash-events)