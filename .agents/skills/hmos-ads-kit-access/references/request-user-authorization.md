# 向用户申请授权

> 文档ID: request-user-authorization
> 来源: request-user-authorization.md

---

# 向用户申请授权

向用户申请应用权限和授权的指导说明。

## 核心要点

- 使用 `abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, permissions)` 向用户动态申请权限
- 广告接入需在获取 OAID 前申请 `ohos.permission.APP_TRACKING_CONSENT`，并在 `module.json5` 中配置 `reason` 和 `usedScene`
- 申请结果通过 `PermissionRequestResult.authResults` 判断是否授予
- 拒绝授权不影响应用基本功能，广告相关个性化能力降级

详细文档请参见：[向用户申请授权 - 华为开发者文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request-user-authorization)
