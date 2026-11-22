# @previewer — 预览规则

检查 Previewer 组件装饰器使用规范，适用于 UI 预览调试场景。

## 规则集

- `plugin:@previewer/recommended` — 3 条
- `plugin:@previewer/all` — 3 条（与 recommended 完全相同）

## 全部规则列表（3 条）

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@previewer/mandatory-default-value-for-local-initialization` | rec+all | warn | 可本地初始化的组件属性需提供默认值 |
| `@previewer/no-page-method-on-preview-component` | rec+all | error | @Preview 组件不能调用页面方法（onPageShow 等） |
| `@previewer/no-unallowed-decorator-on-root-component` | rec+all | error | @Entry/@Preview 根组件不能含 @Consume/@Link/@ObjectLink/@Prop |

## 示例

```json
{
  "ruleSet": ["plugin:@previewer/recommended"]
}
```
