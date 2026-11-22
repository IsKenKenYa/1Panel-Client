# 应用声明接入系统关怀模式 - API开发指南

## 文档来源

本文档来源于HarmonyOS官方开发指南，详细说明了如何在应用中声明接入系统关怀模式。

原文链接：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-appconfig

## 核心内容摘要

### 功能概述

从API版本26.0.0开始，已实现独立关怀模式功能（或称长辈模式、长辈版、关爱版、关怀版、大字版、敬老版等）的应用，可以通过在应用工程module.json5对应module声明metadata，让用户可以在设备"设置>关怀和无障碍>关怀模式>应用管理"里查看本应用，并自由切换关怀模式开关状态。

### 关键要点

1. **声明位置**：建议声明在有关怀模式功能的module下
2. **metadata配置**：
   - name: "senior_mode"
   - value: "independent_control"
3. **联动机制**：
   - 用户在设置里关闭了系统关怀模式开关，应用内关怀模式也会随之关闭
   - 重新开启系统关怀模式，原先被关闭的应用会同步开启

### 配置示例

```typescript
{
  "module": {
    // 其他声明此处省略
    "metadata": [{
      "name": "senior_mode",
      "value": "independent_control"
    }]
  }
}
```

### 相关功能

如果应用内没有独立关怀模式开关，可参照获取系统关怀模式状态以实现跟随系统关怀模式变化。

为实现应用内关怀模式状态与系统设置页面的开关状态保持实时同步，建议参照应用内关怀模式与系统设置同步完成配置。

## API版本要求

- **最低API版本**：26.0.0
- **适用Kit**：Accessibility Kit

## 参考文档

- [应用内关怀模式与系统设置同步](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-senior-mode-description)
- [获取关怀模式状态](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/eldercare-description)