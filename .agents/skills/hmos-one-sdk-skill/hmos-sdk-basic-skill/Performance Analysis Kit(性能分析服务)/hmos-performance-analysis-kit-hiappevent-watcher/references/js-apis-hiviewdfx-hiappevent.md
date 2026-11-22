# @ohos.hiviewdfx.hiAppEvent API 参考

本模块提供应用打点和事件订阅能力，包括事件存储、事件订阅、事件清理、打点配置等功能。

## 导入模块

```typescript
import { hiAppEvent } from '@kit.PerformanceAnalysisKit';
```

## 核心 API

### hiAppEvent.addWatcher

添加事件观察者。可通过事件观察者的回调函数监听事件。

```typescript
addWatcher(watcher: Watcher): AppEventPackageHolder
```

**参数**：
- `watcher`: Watcher - 事件观察者对象

**返回值**：
- `AppEventPackageHolder`: 订阅数据持有者。订阅失败时返回 null。

**错误码**：
- 401: 参数错误
- 11102001: 观察者名称无效
- 11102002: 事件领域无效
- 11102003: row 值无效
- 11102004: size 值无效
- 11102005: timeout 值无效

**示例**：
```typescript
// OnReceive 模式
hiAppEvent.addWatcher({
  name: "watcher1",
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_CRASH]
    }
  ],
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'hiAppEvent', `domain=${domain}`);
  }
});
```

### hiAppEvent.removeWatcher

移除事件观察者。

```typescript
removeWatcher(watcher: Watcher): void
```

**参数**：
- `watcher`: Watcher - 事件观察者对象

**错误码**：
- 401: 参数错误
- 11102001: 观察者名称无效

### hiAppEvent.write

应用事件打点方法，将 AppEventInfo 类型的事件进行存储。

**Promise 模式**：
```typescript
write(info: AppEventInfo): Promise<void>
```

**Callback 模式**：
```typescript
write(info: AppEventInfo, callback: AsyncCallback<void>): void
```

**参数**：
- `info`: AppEventInfo - 应用事件对象

**错误码**：
- 401: 参数错误
- 11100001: 打点功能禁用
- 11101001: 事件领域无效
- 11101002: 事件名称无效
- 11101003: 事件参数个数超限
- 11101004: 事件参数字符串长度超限
- 11101005: 事件参数名无效
- 11101006: 事件参数数组长度超限

**示例**：
```typescript
let eventParams: Record<string, number | string> = {
  "int_data": 100,
  "str_data": "strValue",
};
hiAppEvent.write({
  domain: "test_domain",
  name: "test_event",
  eventType: hiAppEvent.EventType.FAULT,
  params: eventParams,
}).then(() => {
  hilog.info(0x0000, 'hiAppEvent', `success to write event`);
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'hiAppEvent', `code: ${err.code}, message: ${err.message}`);
});
```

### hiAppEvent.configure

应用事件打点配置方法，支持配置打点开关和目录存储配额大小。

```typescript
configure(config: ConfigOption): void
```

**参数**：
- `config`: ConfigOption - 应用事件打点配置项对象

**示例**：
```typescript
let config: hiAppEvent.ConfigOption = {
  disable: true,
  maxStorage: '100M',
};
hiAppEvent.configure(config);
```

### hiAppEvent.clearData

应用事件打点数据清理方法，将当前应用存储在本地的打点数据进行清除。

```typescript
clearData(): void
```

## 数据类型

### Watcher

事件观察者的参数选项。

| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| name | string | 是 | 观察者名称，用于唯一标识观察者。长度不超过32字符。 |
| triggerCondition | TriggerCondition | 否 | 订阅回调触发条件 |
| appEventFilters | AppEventFilter[] | 否 | 订阅过滤条件 |
| onTrigger | function | 否 | 订阅回调函数（批量触发） |
| onReceive | function | 否 | 订阅实时回调函数 |

### AppEventInfo

事件信息的参数选项。

| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| domain | string | 是 | 事件领域。长度不超过32字符。 |
| name | string | 是 | 事件名称。长度不超过48字符。 |
| eventType | EventType | 是 | 事件类型。 |
| params | object | 是 | 事件参数对象。参数个数不超过32个。 |

### EventType

事件类型枚举。

| 名称 | 值 | 说明 |
| --- | --- | --- |
| FAULT | 1 | 故障类型事件 |
| STATISTIC | 2 | 统计类型事件 |
| SECURITY | 3 | 安全类型事件 |
| BEHAVIOR | 4 | 行为类型事件 |

### TriggerCondition

订阅回调触发条件的参数选项。

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| row | number | 满足触发回调的事件总数量，正整数 |
| size | number | 满足触发回调的事件总大小，正整数，单位为 byte |
| timeOut | number | 满足触发回调的超时时长，正整数，单位为 30s |

### AppEventFilter

订阅过滤条件的参数选项。

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| domain | string | 需要订阅的事件领域 |
| eventTypes | EventType[] | 需要订阅的事件类型集合 |
| names | string[] | 需要订阅的事件名称集合 |

### AppEventPackageHolder

订阅数据持有者类，用于对事件信息进行处理。

**方法**：
- `setSize(size: number)`: 设置每次取出的事件包的数据大小阈值
- `setRow(row: number)`: 设置每次取出的事件包的数据条数
- `takeNext()`: 获取订阅事件

### AppEventPackage

订阅返回的事件包的参数定义。

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| packageId | number | 事件包ID，从0开始自动递增 |
| row | number | 事件包的事件数量 |
| size | number | 事件包的事件大小，单位为 byte |
| data | string[] | 事件包的事件信息 |
| appEventInfos | AppEventInfo[] | 事件对象集合 |

### ConfigOption

应用事件打点功能的配置选项。

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| disable | boolean | 打点功能开关，默认值为 false |
| maxStorage | string | 打点数据存放目录的配额大小，默认值为 "10M" |

## 常量

### hiAppEvent.domain

提供领域名称常量。

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| OS | string | 系统领域 |

### hiAppEvent.event

提供事件名称常量。

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| USER_LOGIN | string | 用户登录事件（应用事件） |
| USER_LOGOUT | string | 用户登出事件（应用事件） |
| DISTRIBUTED_SERVICE_START | string | 分布式服务启动事件（应用事件） |
| APP_CRASH | string | 应用崩溃事件（系统事件） |
| APP_FREEZE | string | 应用冻屏事件（系统事件） |
| APP_LAUNCH | string | 应用启动耗时事件（系统事件） |
| SCROLL_JANK | string | 应用滑动丢帧事件（系统事件） |
| CPU_USAGE_HIGH | string | 应用CPU高负载事件（系统事件） |
| BATTERY_USAGE | string | 应用24h功耗器件分解统计事件（系统事件） |
| RESOURCE_OVERLIMIT | string | 应用资源泄漏事件（系统事件） |
| ADDRESS_SANITIZER | string | 应用地址越界事件（系统事件） |
| MAIN_THREAD_JANK | string | 应用主线程超时事件（系统事件） |
| APP_KILLED | string | 应用终止事件（系统事件） |
| APP_HICOLLIE | string | 应用任务执行超时事件（系统事件） |
| AUDIO_JANK_FRAME | string | 应用音频卡顿事件（系统事件） |

### hiAppEvent.param

提供参数名称常量。

| 名称 | 类型 | 说明 |
| --- | --- | --- |
| USER_ID | string | 用户自定义ID |
| DISTRIBUTED_SERVICE_NAME | string | 分布式服务名称 |
| DISTRIBUTED_SERVICE_INSTANCE_ID | string | 分布式服务实例ID |

## 参数规格

### 观察者名称规格
- 首字符必须为字母字符
- 中间字符必须为数字字符、字母字符或下划线字符
- 结尾字符必须为数字字符或字母字符
- 长度非空且不超过32个字符

### 事件领域规格
- 事件领域名称支持数字、字母、下划线字符
- 需要以字母开头且不能以下划线结尾
- 长度非空且不超过32个字符

### 事件名称规格
- 首字符必须为字母字符或$字符
- 中间字符必须为数字字符、字母字符或下划线字符
- 结尾字符必须为数字字符或字母字符
- 长度非空且不超过48个字符

### 事件参数规格
- 参数名长度不超过32字符
- 参数值长度不超过8KB（字符串类型）
- 参数个数不超过32个
- 数组类型参数元素个数不超过100个

## 相关文档

- [崩溃事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-crash-events)
- [应用冻屏事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-freeze-events)
- [主线程超时事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-mainthreadjank-events)
- [资源泄漏事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-resourceleak-events)
- [Worker简介](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/worker-introduction)
- [通用错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal)
- [应用事件打点错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-hiappevent)