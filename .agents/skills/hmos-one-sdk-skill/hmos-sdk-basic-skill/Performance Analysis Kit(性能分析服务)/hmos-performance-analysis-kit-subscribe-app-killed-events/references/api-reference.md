# HiAppEvent API参考

## 概述

HiAppEvent模块为应用开发者提供的事件订阅和事件打点函数定义。在执行应用事件打点之前，开发者必须先构造一个参数列表对象来存储输入的事件参数，并指定事件领域、事件名称和事件类型。

- **事件领域**：用于标识事件打点的领域的字符串。
- **事件名称**：用于标识事件打点的名称的字符串。
- **事件类型**：故障、统计、安全、行为。
- **参数列表**：用于存储事件参数的链表，每个参数由参数名和参数值组成。

**引用文件**：<hiappevent/hiappevent.h>
**库**：libhiappevent_ndk.z.so
**系统能力**：SystemCapability.HiviewDFX.HiAppEvent
**起始版本**：8

## 核心结构体

### HiAppEvent_Watcher

用于接收app事件的监听器。

### HiAppEvent_AppEventGroup

一组事件信息，包含事件组的名称，按名称分组的单个事件信息数组，事件数组的长度。

### HiAppEvent_AppEventInfo

单个事件信息，包含事件领域、事件名称、事件类型和事件携带的用json格式字符串表示的自定义参数列表。

## 核心API

### OH_HiAppEvent_CreateWatcher

```c
HiAppEvent_Watcher* OH_HiAppEvent_CreateWatcher(const char* name)
```

**描述**：创建一个用于监听app事件的监听器。

**注意**：创建的监听器不再使用后，必须通过OH_HiAppEvent_DestroyWatcher接口进行销毁。

**起始版本**：12

**参数**：
- name: 监听器名称

**返回**：
- 成功时返回指向新建监听器的指针
- name参数异常时返回nullptr

### OH_HiAppEvent_SetAppEventFilter

```c
int OH_HiAppEvent_SetAppEventFilter(HiAppEvent_Watcher* watcher, const char* domain, uint8_t eventTypes, const char* const *names, int namesLen)
```

**描述**：用于设置监听器需要监听的事件的类型。该函数可以重复调用，可添加多个过滤规则，而非替换，监听器将收到满足任一过滤规则的事件的通知。

**起始版本**：12

**参数**：
- watcher: 指向监听器的指针
- domain: 需要监听事件的领域
- eventTypes: 需要监听事件的事件类型
- names: 需要监听的事件名称数组
- namesLen: 监听的事件名称的数组长度

**返回**：
- 0：接口调用成功
- -1：names参数异常
- -4：domain参数异常
- -5：watcher入参空指针

### OH_HiAppEvent_SetWatcherOnReceive

```c
int OH_HiAppEvent_SetWatcherOnReceive(HiAppEvent_Watcher* watcher, OH_HiAppEvent_OnReceive onReceive)
```

**描述**：用于设置监听器onReceive回调函数的接口。当监听器监听到相应事件后，onReceive回调函数将被调用。

**起始版本**：12

**参数**：
- watcher: 指向监听器的指针
- onReceive: 回调函数的函数指针

**返回**：
- 0：接口调用成功
- -5：watcher入参空指针

### OH_HiAppEvent_AddWatcher

```c
int OH_HiAppEvent_AddWatcher(HiAppEvent_Watcher* watcher)
```

**描述**：添加监听器的接口，监听器开始监听系统消息。

**注意**：
- OH_HiAppEvent_AddWatcher接口涉及I/O操作。在对性能敏感的业务场景中，开发者应根据实际需要确定该接口是在主线程还是在子线程中调用。
- 订阅接口OH_HiAppEvent_AddWatcher传入的名称name是唯一的，相同的name，后一次调用会覆盖前一次的订阅。

**起始版本**：12

**参数**：
- watcher: 指向监听器的指针

**返回**：
- 0：接口调用成功
- -5：watcher入参空指针

### OH_HiAppEvent_RemoveWatcher

```c
int OH_HiAppEvent_RemoveWatcher(HiAppEvent_Watcher* watcher)
```

**描述**：移除监听器的接口，监听器停止监听系统消息。

**注意**：该接口仅仅使监听器停止监听系统消息，并未销毁该监听器，该监听器依然常驻内存，直至调用OH_HiAppEvent_DestroyWatcher接口，内存才会释放。

**起始版本**：12

**参数**：
- watcher: 指向监听器的指针

**返回**：
- 0：接口调用成功
- -5：watcher入参空指针

### OH_HiAppEvent_DestroyWatcher

```c
void OH_HiAppEvent_DestroyWatcher(HiAppEvent_Watcher* watcher)
```

**描述**：销毁已创建的监听器。

**注意**：已创建的监听器不再使用后，需要将其销毁，释放内存，防止内存泄漏，销毁后需将对应指针置空。

**起始版本**：12

**参数**：
- watcher: 指向监听器的指针

## 回调函数类型

### OH_HiAppEvent_OnReceive

```c
typedef void (*OH_HiAppEvent_OnReceive)(const char* domain, const struct HiAppEvent_AppEventGroup* appEventGroups, uint32_t groupLen)
```

**描述**：监听器接收到事件后，将触发该回调，将事件内容传递给调用方。

**注意**：回调中的指针所指对象的生命周期仅限于该回调函数内，请勿在该回调函数外直接使用该指针，若需缓存该信息，请对指针指向的内容进行深拷贝。

**起始版本**：12

**参数**：
- domain: 接收到的app事件的领域
- appEventGroups: 按照不同事件名称分组的事件组数组
- groupLen: 事件组数组的长度

## 错误码定义

| 错误码 | 说明 |
|--------|------|
| 0 | 操作成功 |
| -1 | 非法的事件名称 |
| -4 | 非法的事件领域名称 |
| -5 | watcher入参空指针 |
| -6 | 还未调用OH_HiAppEvent_AddWatcher，操作顺序有误 |
| -9 | 参数值无效 |
| -100 | 操作失败 |

## 事件类型枚举

| 枚举值 | 说明 |
|--------|------|
| FAULT = 1 | 故障事件类型 |
| STATISTIC = 2 | 统计事件类型 |
| SECURITY = 3 | 安全事件类型 |
| BEHAVIOR = 4 | 行为事件类型 |

## 系统事件常量

### DOMAIN_OS

系统事件领域，用于标识系统级别的事件。

### EVENT_APP_KILLED

应用终止事件名称，用于标识应用被系统强制终止的事件。

完整API参考请查看 [HiAppEvent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h)。