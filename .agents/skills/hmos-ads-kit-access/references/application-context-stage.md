# 各类Context的获取方式

> 文档ID: application-context-stage
> 来源: application-context-stage.md

---

# 各类Context的获取方式

说明UIAbilityContext、ApplicationContext等各类Context的获取和使用方式。

## 核心要点

- **UIAbilityContext**：UIAbility 实例的上下文，通过 `getContext(this)` 或 Ability 的 `context` 属性获取；广告 API（`AdLoader`、`showAd`）要求传入此类型
- **ApplicationContext**：应用级上下文，通过 `context.getApplicationContext()` 获取，生命周期与应用一致
- **StageContext / ExtensionContext**：Stage 模型下 AbilityStage 和 ExtensionAbility 各自的上下文
- **广告接入注意**：`this.getUIContext().getHostContext()` 返回 `Context`，传给广告 API 时必须 `as common.UIAbilityContext` 显式转换

详细文档请参见：[各类Context的获取方式 - 华为开发者文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-context-stage)
