# @private — 隐私合规

检查应用隐私合规相关规则，适用于上架前的合规检查。

## 规则集

- `plugin:@private/recommended` — 3 条
- `plugin:@private/all` — 3 条（与 recommended 完全相同）

## 全部规则列表（3 条）

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@private/private-layered-image-insight-policy` | rec+all | warn | 应用未使用分层图标 |
| `@private/private-system-bar-insight-policy` | rec+all | warn | 页面状态栏不符合隐私安全规定 |
| `@private/private-go-back-previous-page-issue-check` | rec+all | warn | 滑动手势无法退出应用的问题 |

## 示例

```json
{
  "ruleSet": ["plugin:@private/recommended"]
}
```
