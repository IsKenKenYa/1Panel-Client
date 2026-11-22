# 参考文档

本技能相关的API开发指南和API参考说明文档。

## API开发指南

- [订阅资源泄漏事件(C/C++)](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-resourceleak-events-ndk)
  - 来源: harmonyos-guides
  - 路径: 系统/调测调优/Performance Analysis Kit(性能分析服务)/事件订阅/使用HiAppEvent订阅事件/系统事件/资源泄漏事件/订阅资源泄漏事件(C_C++)/hiappevent-watcher-resourceleak-events-ndk.md
  - 内容: 使用HiAppEvent C/C++接口订阅资源泄漏事件的完整开发指南

## API参考说明

### C API参考

- [hiappevent.h](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h)
  - 来源: harmonyos-references
  - 路径: 系统/调测调优/Performance Analysis Kit(性能分析服务)/C API/头文件/capi-hiappevent-h.md
  - 内容: HiAppEvent模块C API接口定义,包含所有事件订阅和打点函数

### ArkTS API参考

- [@ohos.hidebug](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hidebug)
  - 来源: harmonyos-references
  - 路径: 系统/调测调优/Performance Analysis Kit(性能分析服务)/ArkTS API/js-apis-hidebug.md
  - 内容: hidebug模块接口定义,包含setAppResourceLimit等资源限制设置接口

## 相关概念文档

- [HiAppEvent介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-overview)
  - HiAppEvent模块功能概述和基本概念

- [系统事件订阅](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-system-events)
  - 系统事件订阅的通用流程和方法

## 第三方库参考

- [jsoncpp库](https://github.com/open-source-parsers/jsoncpp)
  - JSON解析库,用于解析事件参数中的JSON字符串
  - 使用方法: 下载源码后按照README的Amalgamated source步骤生成json.h和json-forwards.h文件

## 注意事项

1. 所有文档链接均指向华为开发者官网,确保访问最新版本的文档
2. 本地文档路径仅供参考,实际使用时请访问官网链接
3. API版本信息请参考各API参考说明文档中的"起始版本"字段
4. 开发前请确认设备API版本是否符合要求(本技能需要API version 12+)