# API参考文档链接

本文档提供了订阅启动耗时事件相关的API参考文档链接。

## 核心API文档

### HiAppEvent C API头文件
- **文档名称**: capi-hiappevent-h.md
- **在线链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h
- **说明**: 包含所有HiAppEvent C/C++接口定义，包括观察者创建、事件过滤、回调设置等核心API

### 主要API列表

| API名称 | 功能说明 | 文档链接 |
|---------|---------|---------|
| OH_HiAppEvent_CreateWatcher | 创建观察者 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h |
| OH_HiAppEvent_SetAppEventFilter | 设置事件过滤器 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h |
| OH_HiAppEvent_SetWatcherOnReceive | 设置实时接收回调 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h |
| OH_HiAppEvent_SetWatcherOnTrigger | 设置触发回调 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h |
| OH_HiAppEvent_SetTriggerCondition | 设置触发条件 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h |
| OH_HiAppEvent_AddWatcher | 添加观察者 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h |
| OH_HiAppEvent_RemoveWatcher | 移除观察者 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h |
| OH_HiAppEvent_DestroyWatcher | 销毁观察者 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h |
| OH_HiAppEvent_TakeWatcherData | 获取观察者数据 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h |

## 相关结构体文档

| 结构体名称 | 功能说明 | 文档链接 |
|-----------|---------|---------|
| HiAppEvent_Watcher | 观察者结构体 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-hiappevent-watcher |
| HiAppEvent_AppEventGroup | 事件组结构体 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-hiappevent-appeventgroup |
| HiAppEvent_AppEventInfo | 事件信息结构体 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-hiappevent-appeventinfo |

## 系统常量说明

| 常量名称 | 常量值 | 说明 |
|---------|-------|------|
| DOMAIN_OS | "OS" | 系统事件领域 |
| EVENT_APP_LAUNCH | "APP_LAUNCH" | 应用启动耗时事件名称 |

## 注意事项

1. 所有API文档链接均指向HarmonyOS官方开发者文档
2. 文档链接去除了.md后缀，符合在线文档URL规范
3. 参考文档目录：D:\code\APIDevice\output\md_output\harmonyos-references