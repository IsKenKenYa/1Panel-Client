# 参考文档索引

本技能相关的API开发指南和参考文档汇总。

## API开发指南

- **主动通知页面变化的场景**：[https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/proactively-notify-page-changes](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/proactively-notify-page-changes)
  - 功能场景详细说明
  - 完整的开发实例代码
  - EventInfo参数说明
  - Stack组件使用示例

## API参考文档

### 核心API

- **@ohos.accessibility (辅助功能)**：[https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-accessibility](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-accessibility)
  - sendAccessibilityEvent方法详细说明
  - EventInfo接口定义
  - EventType枚举值说明
  - Action枚举值说明
  - 错误码定义
  - API版本要求

### 相关组件

- **Stack组件**：[https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-stack](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-stack)
  - Stack容器组件说明
  - zIndex属性使用方法
  - 堆叠布局实现

### 通用属性

- **无障碍通用属性**：[https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-accessibility](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-accessibility)
  - accessibilityLevel属性说明
  - id属性设置方法
  - 无障碍可见性控制

## 错误码参考

- **无障碍子系统错误码**：[https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-accessibility](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-accessibility)
  - 9300003：不具备执行该操作的无障碍权限
  - 9300004：属性不存在
  - 9300005：不支持该操作
  - 9300006：目标应用和无障碍服务建立连接失败

- **通用错误码**：[https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal)
  - 401：参数错误（必填参数未指定、参数类型错误、参数校验失败）

## 相关技能

- **屏幕朗读服务集成**：了解如何与系统屏幕朗读服务配合使用
- **无障碍最佳实践**：应用无障碍功能开发的整体最佳实践指南
- **组件无障碍属性配置**：详细的无障碍属性配置和使用方法

## 文档路径映射规则

**本地文档路径 → 华为开发者网站URL转换规则**：

1. **harmonyos-guides文档**：
   - 本地路径：`D:\code\APIDevice\output\md_output\harmonyos-guides\{path}\{filename}.md`
   - 网站URL：`https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/{filename}`
   
2. **harmonyos-references文档**：
   - 本地路径：`D:\code\APIDevice\output\md_output\harmonyos-references\{path}\{filename}.md`
   - 网站URL：`https://developer.huawei.com/consumer/cn/doc/harmonyos-references/{filename}`

**注意**：URL中去掉了`.md`后缀，保持文件名部分。

## 更新记录

- 2026-07-02：创建技能参考文档索引
- API版本：HarmonyOS API version 9及以上
- 文档来源：HarmonyOS官方开发者文档（2026年4月1日版本）