# Context

> 文档ID: js-apis-inner-application-context
> 来源: js-apis-inner-application-context.md

---

# Context

Ability或Application的上下文环境，提供访问应用资源和能力的接口。

## 核心要点

- `Context` 是能力上下文基类，提供访问应用资源、Ability、权限校验等能力
- 广告 API 需要的是 `UIAbilityContext`（子类），`getHostContext()` 返回的基类需显式转换
- 通过 `getApplicationContext()` 可获取应用级上下文

详细文档请参见：[Context - 华为开发者文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-application-context)
