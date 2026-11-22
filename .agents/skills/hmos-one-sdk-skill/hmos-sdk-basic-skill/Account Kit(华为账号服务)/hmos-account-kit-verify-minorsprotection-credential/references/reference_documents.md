# 参考文档列表

本技能依赖以下API参考文档和开发指南：

## API开发指南

- [应用内调整未成年人模式设置](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-password-minorsprotection)
  - 场景介绍、业务流程、接口说明、开发步骤完整指南

## API参考文档

- [minorsProtection模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-minorsprotection)
  - 包含supportMinorsMode、getMinorsProtectionInfoSync、getMinorsProtectionInfo、verifyMinorsProtectionCredential等API完整定义

## 错误码文档

- [Account Kit错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-error-code)
  - 包含1009900002、1009900003、1009900007、1009900011等未成年人模式相关错误码说明

- [通用错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal)
  - 包含401、801等通用错误码说明

## Context相关文档

- [Ability公共模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-common)
  - 包含UIAbilityContext、UIExtensionContext等Context类型定义

## 相关场景文档

- [应用内开启未成年人模式](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-app-turn-on-minorsprotection)
  - 如何在应用内引导用户开启未成年人模式

- [应用与系统联动切换未成年人模式](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-system-minorsprotection)
  - 如何实现应用与系统未成年人模式联动切换

## 开发准备文档

- [配置签名和指纹](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-sign-fingerprints)
  - 开发前需要的签名配置（注意：未成年人模式接口无需配置公钥指纹和Client ID）

## 系统事件文档

- [公共事件定义](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/commoneventmanager-definitions)
  - 包含COMMON_EVENT_MINORSMODE_ON和COMMON_EVENT_MINORSMODE_OFF事件定义