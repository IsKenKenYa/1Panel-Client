# 权限列表

> 文档ID: permissions-for-all
> 来源: permissions-for-all.md

---

# 权限列表

HarmonyOS所有权限的列表和说明。

## 核心要点

- HarmonyOS 权限分为 `system_grant`（系统自动授予）和 `user_grant`（用户授权）两类
- 广告接入常用权限：
  - `ohos.permission.INTERNET`（system_grant）：网络访问
  - `ohos.permission.APP_TRACKING_CONSENT`（user_grant）：个性化推荐，需 reason 说明
- 权限在 `module.json5` 的 `requestPermissions` 中声明，user_grant 权限需运行时向用户申请

详细文档请参见：[权限列表 - 华为开发者文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/permissions-for-all)
