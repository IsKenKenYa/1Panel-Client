# @compatibility — 兼容性规则

检查 API 版本兼容性和已废弃 API，适用于 SDK 版本升级场景。

## 规则集

- `plugin:@compatibility/all` — 1 条
- **无 `recommended` 粒度**

> `api-compatibility-check` 不在 `all` 预设中，可通过 `rules` 字段启用。

## 全部规则列表（2 条）

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@compatibility/api-compatibility-check` | — | suggestion | 检查 API 版本兼容性（API 支持版本 vs 当前兼容 SDK 版本） |
| `@compatibility/deprecate-api-check` | all | suggestion | 检测已废弃 API，建议使用替代 API |

## 示例

```json
{
  "ruleSet": ["plugin:@compatibility/all"]
}
```
