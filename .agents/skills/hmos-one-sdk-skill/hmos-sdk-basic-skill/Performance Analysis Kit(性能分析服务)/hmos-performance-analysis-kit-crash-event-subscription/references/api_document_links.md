# 参考文档链接汇总

本文档汇总了订阅崩溃事件技能相关的所有参考文档链接，所有链接均已转换为华为开发者官网格式。

## API开发指南

### 订阅崩溃事件开发指南
- **原始文件**：hiappevent-watcher-crash-events-arkts.md
- **实际位置**：harmonyos-guides
- **官网链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-crash-events-arkts

### 崩溃事件介绍
- **原始文件**：hiappevent-watcher-crash-events.md
- **实际位置**：harmonyos-guides
- **官网链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-crash-events

### 使用FaultLogExtensionAbility订阅事件
- **原始文件**：fault-log-extension-app-events-arkts.md
- **实际位置**：harmonyos-guides
- **官网链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/fault-log-extension-app-events-arkts

### Cpp Crash检测指南
- **原始文件**：cppcrash-guidelines.md
- **实际位置**：harmonyos-guides
- **官网链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/cppcrash-guidelines

## API参考文档

### HiAppEvent API参考
- **原始文件**：js-apis-hiviewdfx-hiappevent.md
- **实际位置**：harmonyos-references
- **官网链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent

### deviceInfo API参考
- **原始文件**：js-apis-device-info.md
- **实际位置**：harmonyos-references
- **官网链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-device-info

### errorManager API参考
- **原始文件**：js-apis-app-ability-errormanager.md
- **实际位置**：harmonyos-references
- **官网链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-errormanager

### HiAppEvent错误码参考
- **原始文件**：errorcode-hiappevent.md
- **实际位置**：harmonyos-references
- **官网链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-hiappevent

### 已废弃的FaultLogger接口
- **原始文件**：js-apis-faultlogger.md
- **实际位置**：harmonyos-references
- **官网链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-faultlogger

### 通用错误码
- **原始文件**：errorcode-universal.md
- **实际位置**：harmonyos-references
- **官网链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal

## 其他参考文档

### Worker简介
- **原始文件**：worker-introduction.md
- **实际位置**：harmonyos-guides
- **官网链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/worker-introduction

## 链接转换规则说明

根据华为开发者文档规范，本技能中所有MD链接遵循以下转换规则：

1. **只保留MD文件名**：去除完整路径，仅保留文件名
2. **harmonyos-guides文档**：转换为 `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/{filename}`
3. **harmonyos-references文档**：转换为 `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/{filename}`
4. **去除.md后缀**：所有链接去除末尾的`.md`扩展名

## 使用建议

在开发过程中，建议优先参考：
1. **开发指南**：了解功能使用流程和最佳实践
2. **API参考**：查阅接口定义、参数说明、返回值类型
3. **错误码文档**：排查和解决错误问题
4. **废弃接口文档**：了解从FaultLogger迁移到HiAppEvent的方法