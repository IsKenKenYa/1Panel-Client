# UIAbilityContext

> 文档ID: js-apis-inner-application-uiabilitycontext
> 来源: js-apis-inner-application-uiabilitycontext.md

---

# UIAbilityContext

UIAbility的上下文环境，提供访问UIAbility资源和能力的接口。

## 核心要点

- `UIAbilityContext` 是 `Context` 的子类，提供 UIAbility 专属能力（如 `startAbility`、`openLink`）
- **广告接入要求**：`AdLoader` 构造、`advertising.showAd()` 需要 `UIAbilityContext` 类型
- `this.getUIContext().getHostContext()` 返回 `Context`，需 `as common.UIAbilityContext` 转换
- `openLink(url)` 可用于广告跳转落地页（参见 `ad-redirection.md`）

详细文档请参见：[UIAbilityContext - 华为开发者文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-application-uiabilitycontext)
