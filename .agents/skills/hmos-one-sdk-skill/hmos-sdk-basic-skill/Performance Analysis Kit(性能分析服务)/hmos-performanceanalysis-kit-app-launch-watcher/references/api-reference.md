# @ohos.hiviewdfx.hiAppEvent API参考说明

## 模块概述

本模块提供应用打点和事件订阅能力，包括事件存储、事件订阅、事件清理、打点配置等功能。HiAppEvent将应用运行过程中触发的事件信息统一归纳到AppEventInfo中，并将事件分为系统事件和应用事件两类。

本模块首批接口从API version 9开始支持。

## 导入模块

```typescript
import { hiAppEvent } from '@kit.PerformanceAnalysisKit';
```

## 主要API接口

### hiAppEvent.addWatcher

**接口定义**：
```typescript
addWatcher(watcher: Watcher): AppEventPackageHolder
```

**功能说明**：添加事件观察者。可通过事件观察者的回调函数监听事件。

**参数说明**：

| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| watcher | Watcher | 是 | 事件观察者对象 |

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
| 11102003 | Invalid row value. Possible caused by the row value is less than zero. |
| 11102004 | Invalid size value. Possible caused by the size value is less than zero. |
| 11102005 | Invalid timeout value. Possible caused by the timeout value is less than zero. |

### hiAppEvent.removeWatcher

**接口定义**：
```typescript
removeWatcher(watcher: Watcher): void
```

**功能说明**：移除事件观察者。

**参数说明**：

| 参数名 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| watcher | Watcher | 是 | 事件观察者对象 |

**错误码**：

| 错误码ID | 错误信息 |
| --- | --- |
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types. |
| 11102001 | Invalid watcher name. Possible causes: 1. Contain invalid characters; 2. Length is invalid. |

## 数据类型定义

### Watcher

提供事件观察者的参数选项。用于配置和管理事件的观察者，实现对特定事件的监听和处理。

| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| name | string | 否 | 否 | 观察者名称，用于唯一标识观察者。首字符必须为字母字符，中间字符必须为数字字符、字母字符或下划线字符，结尾字符必须为数字字符或字母字符，长度非空且不超过32个字符。如testName1、crash_Watcher等。 |
| triggerCondition | TriggerCondition | 否 | 是 | 订阅回调触发条件，需要与回调函数onTrigger一同传入才会生效。默认不触发。 |
| appEventFilters | AppEventFilter[] | 否 | 是 | 订阅过滤条件，在需要对订阅事件进行过滤时传入。默认不过滤事件。 |
| onTrigger | (curRow: number, curSize: number, holder:AppEventPackageHolder) => void | 否 | 是 | 订阅回调函数，需要与回调触发条件triggerCondition一同传入才会生效。 |
| onReceive | (domain: string, appEventGroups: Array<AppEventGroup>) => void | 否 | 是 | 订阅实时回调函数，与回调函数onTrigger同时存在时，只触发此回调。 |

### AppEventFilter

提供设置Watcher的订阅过滤条件的参数选项。

| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| domain | string | 否 | 否 | 需要订阅的事件领域。可以是系统事件领域（hiAppEvent.domain.OS）或开发者自定义的事件领域。 |
| eventTypes | EventType[] | 否 | 是 | 需要订阅的事件类型集合。默认不进行过滤。 |
| names | string[] | 否 | 是 | 需要订阅的事件名称集合。默认不进行过滤。 |

### AppEventInfo

提供事件信息的参数选项。

| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| domain | string | 否 | 否 | 事件领域。事件领域名称支持数字、字母、下划线字符，需要以字母开头且不能以下划线结尾，长度非空且不超过32个字符。 |
| name | string | 否 | 否 | 事件名称。首字符必须为字母字符或$字符，中间字符必须为数字字符、字母字符或下划线字符，结尾字符必须为数字字符或字母字符，长度非空且不超过48个字符。 |
| eventType | EventType | 否 | 否 | 事件类型。 |
| params | object | 否 | 否 | 事件参数对象，包含每个事件参数的参数名和参数值。 |

### AppEventGroup

提供订阅返回的事件组的参数定义。

| 名称 | 类型 | 只读 | 可选 | 说明 |
| --- | --- | --- | --- | --- |
| name | string | 否 | 否 | 事件名称。 |
| appEventInfos | Array<AppEventInfo> | 否 | 否 | 事件对象集合。 |

## 系统事件常量

### hiAppEvent.domain.OS

系统事件领域常量，值为"OS"。

### hiAppEvent.event.APP_LAUNCH

启动耗时事件名称常量，值为"APP_LAUNCH"。

该事件在应用启动完成时由系统自动生成，包含以下参数：

| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| start_type | number | 启动类型。0表示冷启动，1表示热启动。 |
| time | number | 启动耗时，单位毫秒。 |
| animation_finish_time | number | 动画完成时间，单位毫秒。 |
| bundle_name | string | 应用包名。 |
| bundle_version | string | 应用版本。 |
| process_name | string | 进程名。 |
| extend_time | number | 扩展时间，单位毫秒。 |
| icon_input_time | number | 图标输入时间戳。 |

## 使用示例

### 示例1：使用onReceive实时回调

```typescript
import { hilog } from '@kit.PerformanceAnalysisKit';

hiAppEvent.addWatcher({
  name: "watcher3",
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_LAUNCH]
    }
  ],
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'hiAppEvent', `domain=${domain}`);
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'hiAppEvent', `eventName=${eventGroup.name}`);
      for (const eventInfo of eventGroup.appEventInfos) {
        hilog.info(0x0000, 'hiAppEvent', `event=${JSON.stringify(eventInfo)}`);
      }
    }
  }
});
```

### 示例2：使用triggerCondition和onTrigger回调

```typescript
import { hilog } from '@kit.PerformanceAnalysisKit';

hiAppEvent.addWatcher({
  name: "watcher1",
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_LAUNCH]
    }
  ],
  triggerCondition: {
    row: 10,
    size: 1000,
    timeOut: 1
  },
  onTrigger: (curRow: number, curSize: number, holder: hiAppEvent.AppEventPackageHolder) => {
    if (holder == null) {
      hilog.error(0x0000, 'hiAppEvent', "holder is null");
      return;
    }
    hilog.info(0x0000, 'hiAppEvent', `curRow=${curRow}, curSize=${curSize}`);
    let eventPkg: hiAppEvent.AppEventPackage | null = null;
    while ((eventPkg = holder.takeNext()) != null) {
      hilog.info(0x0000, 'hiAppEvent', `eventPkg.packageId=${eventPkg.packageId}`);
      for (const eventInfo of eventPkg.data) {
        hilog.info(0x0000, 'hiAppEvent', `eventPkg.data=${eventInfo}`);
      }
    }
  }
});
```

### 示例3：手动获取事件

```typescript
import { hilog } from '@kit.PerformanceAnalysisKit';

let holder: hiAppEvent.AppEventPackageHolder = hiAppEvent.addWatcher({
  name: "watcher2",
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_LAUNCH]
    }
  ]
});

if (holder != null) {
  let eventPkg: hiAppEvent.AppEventPackage | null = null;
  while ((eventPkg = holder.takeNext()) != null) {
    hilog.info(0x0000, 'hiAppEvent', `eventPkg.packageId=${eventPkg.packageId}`);
    for (const eventInfo of eventPkg.data) {
      hilog.info(0x0000, 'hiAppEvent', `eventPkg.data=${eventInfo}`);
    }
  }
}
```

## 系统能力要求

- **系统能力**：SystemCapability.HiviewDFX.HiAppEvent
- **最低API版本**：API version 9
- **元服务支持**：从API version 11开始支持在元服务中使用

## 注意事项

1. addWatcher接口涉及I/O操作。在对性能敏感的业务场景中，开发者应根据实际需要确定该接口是在主线程还是在子线程中调用。

2. 如果选择在子线程中调用addWatcher，需要确保该子线程在整个接口使用周期内不会被销毁，以免影响接口的正常工作。

3. 订阅接口addWatcher传入的名称name是唯一的，相同的name，后一次调用会覆盖前一次的订阅。

4. 不建议在回调函数中执行移除观察者的操作，watcher一旦被移除，则其原有的订阅回调功能也会随之失效。

## 相关参考

- [完整API文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)