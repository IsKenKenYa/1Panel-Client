# 规则集索引

## 规则集总览

| 规则集 | recommended | all | 全部规则 | 详细文档 |
|--------|:-----------:|:---:|:-----------:|---------|
| `@typescript-eslint` | 15 | 15 | 113 | [typescript-eslint.md](typescript-eslint.md) |
| `@hw-stylistic` | 18 | 18 | 18 | [hw-stylistic.md](hw-stylistic.md) |
| `@performance` | 15 | 35 | 74 | [performance.md](performance.md) |
| `@security` | 1 | 8 | 21 | [security.md](security.md) |
| `@correctness` | — | 14 | 19 | [correctness.md](correctness.md) |
| `@cross-device-app-dev` | 8 | 10 | 12 | [cross-device.md](cross-device.md) |
| `@compatibility` | — | 1 | 2 | [compatibility.md](compatibility.md) |
| `@previewer` | 3 | 3 | 3 | [previewer.md](previewer.md) |

"—" 表示该粒度不存在。"全部规则" 列包含不在任何预设中但可通过 `rules` 字段启用的规则。

## 粒度说明

- **`recommended`**：推荐规则子集，告警量适中，适合日常开发
- **`all`**：全量规则，适合严格审查
- **预设外规则**：标注 "—" 的规则不在任何预设中，通过 `rules` 字段逐条启用

在 `ruleSet` 中使用 `plugin:<规则集名>/<粒度>` 格式引用：

```json
{
  "ruleSet": [
    "plugin:@typescript-eslint/recommended",
    "plugin:@performance/all"
  ]
}
```

## 重要说明

- **`@typescript-eslint`**：`recommended` 与 `all` 完全相同（15 条），另有 98 条规则可通过 `rules` 字段逐条启用（含 `eqeqeq`、`prefer-const` 两条无前缀规则）。
- **`@performance`**：`all`（35 条）含 20 条 recommended 之外的规则；另有 39 条规则（含 `hp-arkui-*`、`hp-arkts-*`、`hp-performance-*`、`hp-ffrt-*` 前缀）不在任何预设中。
- **`@security`**：`recommended` 仅 1 条；`all` 8 条；另有 13 条规则（含 `no-unsafe-aes`、`no-unsafe-3des`、`no-cycle` 等）不在任何预设中。
- **`@correctness`** 和 **`@compatibility`**：无 `recommended` 粒度，仅 `all`。`@correctness` 另有 2 条规则不在 `all` 预设中；`@compatibility` 的 `api-compatibility-check` 不在 `all` 预设中。
- **`@cross-device-app-dev`**：`all`（10 条）是 `recommended`（8 条）的超集；另有 `color-contrast` 和 `color-value` 不在任何预设中。
- **`@private`**：无官网文档页面，规则基于 shipped ruleSet.json。详见 [private.md](private.md)（内部参考，不进入用户可选规则集）。

## 严重级别

| 值 | 数字 | 含义 |
|----|------|------|
| `"off"` | `0` | 关闭规则 |
| `"warn"` | `1` | 警告 |
| `"error"` | `2` | 错误 |
| `"suggestion"` | `3` | 建议 |

## 规则集速查

| 规则集前缀 | 检查内容 | 典型使用场景 |
|-----------|---------|------------|
| `@typescript-eslint` | ArkTS/TS 语法与类型安全 | 所有项目必选 |
| `@hw-stylistic` | 代码风格（缩进、命名、行长等） | 代码规范审查 |
| `@performance` | 性能优化（懒加载、状态变量、渲染优化等） | 性能调优 |
| `@security` | 加密算法安全（AES/RSA/Hash/SM 等） | 安全审计 |
| `@correctness` | 行为正确性（音频、无障碍、网络等） | 功能正确性验证 |
| `@cross-device-app-dev` | 跨设备适配（布局、字体、断点等） | 多设备支持 |
| `@compatibility` | API 兼容性（版本兼容、废弃 API 检查） | SDK 版本升级 |
| `@previewer` | Previewer 组件装饰器规则 | UI 预览调试 |
| (无前缀) | 通用 ESLint 规则（`eqeqeq`、`prefer-const`） | 基础代码质量 |

## 规则级别覆盖

在 `rules` 字段中可单独调整任意规则的严重级别，详见 [配置参考](../config-reference.md)。
