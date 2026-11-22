# 参考文档索引

本文档列出了与"判断应用是否被系统分享拉起"技能相关的所有API参考文档。

## 核心API文档

### 1. UIAbility组件API
- **文档路径**: `应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiability.md`
- **在线链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-uiability
- **主要接口**: 
  - `onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void`
  - `onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void`
  - `onWindowStageCreate(windowStage: window.WindowStage): void`

### 2. AbilityConstant常量API
- **文档路径**: `应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-abilityconstant.md`
- **在线链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-abilityconstant
- **主要接口**:
  - `LaunchParam`接口定义
  - `launchReasonMessage`字段（API version 18+）
  - `LaunchReason`枚举
  - `LastExitReason`枚举

### 3. ShareExtensionAbility组件API
- **文档路径**: `应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-shareextensionability.md`
- **在线链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-shareextensionability
- **主要接口**:
  - `onCreate(launchParam: AbilityConstant.LaunchParam): void`
  - `onSessionCreate(want: Want, session: UIExtensionContentSession): void`

### 4. UIExtensionAbility组件API
- **文档路径**: `应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiextensionability.md`
- **在线链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-uiextensionability
- **主要接口**:
  - `onCreate(launchParam: AbilityConstant.LaunchParam): void`
  - 继承自`ShareExtensionAbility`

### 5. Want数据结构API
- **文档路径**: `应用框架/Ability Kit（程序框架服务）/ArkTS API/通用能力的接口(推荐)/js-apis-app-ability-want.md`
- **在线链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-want
- **主要接口**:
  - `Want`接口定义
  - `parameters`字段（用于传递分享数据）

### 6. UIExtensionContentSession API
- **文档路径**: `应用框架/Ability Kit（程序框架服务）/ArkTS API/Stage模型能力的接口/js-apis-app-ability-uiextensioncontentsession.md`
- **在线链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-uiextensioncontentsession
- **主要接口**:
  - `loadContent(path: string, callback?: (err, data) => void): void`

## 开发指南文档

### 1. 判断应用是否被系统分享拉起
- **文档路径**: `应用服务/Share Kit（分享服务）/系统分享/目标应用处理分享内容/判断应用是否被系统分享拉起/share-launch-param.md`
- **本地链接**: [查看本地文档](share-launch-param.md)
- **主要内容**:
  - 功能描述和版本要求
  - UIAbility和UIExtensionAbility两种实现方式
  - 示例代码

### 2. Share Kit系统分享指南
- **文档路径**: `应用服务/Share Kit（分享服务）/系统分享/`
- **在线链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/
- **主要内容**:
  - 系统分享概述
  - 目标应用接入流程
  - 分享内容处理

### 3. Ability Kit应用框架指南
- **文档路径**: `应用框架/Ability Kit（程序框架服务）/`
- **在线链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/
- **主要内容**:
  - Stage模型应用组件
  - UIAbility生命周期
  - ExtensionAbility组件

## 相关文档

### 窗口管理API
- **文档路径**: `应用框架/ArkUI（方舟UI框架）/ArkTS API/窗口管理/@ohos.window (窗口)/arkts-apis-window-windowstage.md`
- **在线链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-window-windowstage
- **主要接口**: `WindowStage.loadContent()`

### 日志工具API
- **文档路径**: `调测调优/Performance Analysis Kit（性能分析服务）/ArkTS API/@ohos.hilog (日志)/js-apis-hilog.md`
- **在线链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hilog
- **主要接口**: `hilog.info()`, `hilog.error()`, `hilog.warn()`

## 文档使用说明

1. **API版本兼容性**: 
   - `launchReasonMessage`字段从API version 18 (5.1.0)开始支持
   - API version < 18时使用`LaunchReason.SHARE`枚举判断

2. **文档路径转换规则**:
   - 本地路径格式: `D:\z00810349\APIDevice\output\md_output\harmonyos-references\{分类}\{Kit}\{子路径}\{文件名}.md`
   - 在线链接格式: `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/{文件名}`（去掉.md后缀）
   - 开发指南在线链接: `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/`

3. **文档查询方法**:
   - 使用`scripts/search_api.py`脚本查询API文档路径
   - 命令示例: `python search_api.py UIAbility -d harmonyos-references --verify`

## 文档更新记录

- **API version 18**: 新增`launchReasonMessage`字段
- **API version 12**: 新增`lastExitMessage`字段
- **API version 10**: 新增`ShareExtensionAbility`组件
- **API version 9**: 基础`UIAbility`和`LaunchReason`枚举