# 参考文档链接汇总

本文档汇总订阅任务执行超时事件相关的API参考文档和开发指南链接。

## API开发指南

### 主要指南文档
- [订阅任务执行超时事件（ArkTS）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-apphicollie-events-arkts)
  - 详细开发步骤和完整示例代码
  - 包含Native C++工程创建、配置、订阅、触发和验证流程

### 相关系统事件指南
- [HiAppEvent介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-intro)
  - HiAppEvent功能概述和约束限制
- [崩溃事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-crash-events)
  - APP_CRASH系统事件订阅指南
- [应用冻屏事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-freeze-events)
  - APP_FREEZE系统事件订阅指南
- [资源泄漏事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-resourceleak-events)
  - RESOURCE_OVERLIMIT系统事件订阅指南（API version 20+）

## API参考文档

### ArkTS API
- [应用事件打点API - @ohos.hiviewdfx.hiAppEvent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)
  - addWatcher(watcher: Watcher): AppEventPackageHolder
  - removeWatcher(watcher: Watcher): void
  - Watcher、AppEventFilter、AppEventGroup等类型定义
  - domain.OS和event.APP_HICOLLIE常量定义

### C API
- [HiCollie模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hicollie)
  - OH_HiCollie_SetTimer(HiCollie_SetTimerParam param, int *id)
  - OH_HiCollie_CancelTimer(int id)
  - HiCollie_ErrorCode错误码定义
  - HiCollie_Flag超时动作标志
- [HiCollie头文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hicollie-h)
  - 详细函数签名和参数说明
  - 回调函数类型定义

### 结构体定义
- [HiCollie_SetTimerParam结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hicollie-hicollie-settimerparam)
  - 定时器名称、超时阈值、回调函数、超时动作等参数

### 错误码
- [应用事件打点错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-hiappevent)
  - 11102001: Invalid watcher name
  - 11102002: Invalid filtering event domain
  - 其他HiAppEvent相关错误码

## Kit概述

- [Performance Analysis Kit（性能分析服务）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/performance-analysis-kit-overview)
  - Kit功能概述和主要模块介绍
  - 包含HiAppEvent、HiChecker、HiDebug等模块

## 相关技术文档

### NAPI开发指南
- [NAPI开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/napi-guidelines)
  - Native C++与ArkTS交互开发指南
  - NAPI接口注册和调用方法

### 多线程并发
- [Worker简介](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/worker-introduction)
  - 子线程调用接口的最佳实践
- [多线程并发概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/multi-thread-concurrency-overview)
  - 线程安全和并发编程指导

## 快速查找表

| 功能需求 | 推荐文档 |
|---------|---------|
| 订阅事件（ArkTS） | [js-apis-hiviewdfx-hiappevent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent) |
| 触发超时（C++） | [capi-hicollie-h](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hicollie-h) |
| 完整示例 | [hiappevent-watcher-apphicollie-events-arkts](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-apphicollie-events-arkts) |
| 错误处理 | [errorcode-hiappevent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-hiappevent) |
| NAPI开发 | [napi-guidelines](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/napi-guidelines) |

## 说明

以上链接均为华为开发者官网文档，可通过浏览器直接访问。
- harmonyos-guides路径：开发指南文档，提供开发步骤和示例
- harmonyos-references路径：API参考文档，提供接口详细说明

**注意**：所有链接均已去除.md后缀，符合华为开发者网站URL格式规范。