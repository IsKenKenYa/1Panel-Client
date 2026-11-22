# @ohos.hiviewdfx.hiAppEvent API参考文档

完整API参考文档请查看：
- https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent

## 核心API说明

### addWatcher(watcher: Watcher): AppEventPackageHolder
添加事件观察者。可通过事件观察者的回调函数监听事件。

**参数**：
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| watcher | Watcher | 是 | 事件观察者。 |

**返回值**：
| 类型 | 说明 |
| --- | --- |
| AppEventPackageHolder | 订阅数据持有者。订阅失败时返回null。 |

**错误码**：
| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types. |
| 11102001 | Invalid watcher name. Possible causes: 1. Contain invalid characters; 2. Length is invalid. |
| 11102002 | Invalid filtering event domain. Possible causes: 1. Contain invalid characters; 2. Length is invalid. |

### removeWatcher(watcher: Watcher): void
移除事件观察者。

**参数**：
| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| watcher | Watcher | 是 | 事件观察者。 |

### Watcher
提供事件观察者的参数选项。

| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| name | string | 否 | 否 | 观察者名称，用于唯一标识观察者。首字符必须为字母字符，中间字符必须为数字字符、字母字符或下划线字符，结尾字符必须为数字字符或字母字符，长度非空且不超过32个字符。 |
| triggerCondition | TriggerCondition | 否 | 是 | 订阅回调触发条件。 |
| appEventFilters | AppEventFilter[] | 否 | 是 | 订阅过滤条件。 |
| onTrigger | (curRow: number, curSize: number, holder:AppEventPackageHolder) => void | 否 | 是 | 订阅回调函数。 |
| onReceive | (domain: string, appEventGroups: Array<AppEventGroup>) => void | 否 | 是 | 订阅实时回调函数。 |

### AppEventFilter
提供设置Watcher的订阅过滤条件的参数选项。

| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| domain | string | 否 | 否 | 需要订阅的事件领域。可以是系统事件领域（hiAppEvent.domain.OS）或自定义事件领域。 |
| names | string[] | 否 | 是 | 需要订阅的事件名称集合。 |

## 常量说明

### hiAppEvent.domain.OS
系统事件领域常量，用于订阅系统事件。

### hiAppEvent.event.APP_HICOLLIE
任务执行超时事件名称常量，用于订阅APP_HICOLLIE事件。