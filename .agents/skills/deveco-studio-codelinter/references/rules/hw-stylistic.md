# @hw-stylistic — ArkTS 代码风格规则

HarmonyOS 华为风格规范，约束代码格式和一致性。

## 规则集

- `plugin:@hw-stylistic/recommended` — 18 条
- `plugin:@hw-stylistic/all` — 18 条（与 recommended 完全相同）

## 全部规则列表（18 条）

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@hw-stylistic/array-bracket-spacing` | rec+all | error | 数组方括号内侧不应有空格 |
| `@hw-stylistic/brace-style` | rec+all | error | 代码块大括号风格 |
| `@hw-stylistic/comma-spacing` | rec+all | error | 逗号前无空格、后需空格 |
| `@hw-stylistic/curly` | rec+all | error | 条件和循环语句必须用大括号 |
| `@hw-stylistic/file-naming-convention` | rec+all | error | 文件命名规范 |
| `@hw-stylistic/indent` | rec+all | error | switch 中 case/default 缩进一层 |
| `@hw-stylistic/keyword-spacing` | rec+all | error | 关键字前后加空格 |
| `@hw-stylistic/max-len` | rec+all | error | 行长度不超过最大允许值 |
| `@hw-stylistic/no-multi-spaces` | rec+all | error | 禁止连续多个空格 |
| `@hw-stylistic/no-tabs` | rec+all | error | 禁止 tab 缩进，推荐空格 |
| `@hw-stylistic/object-property-newline` | rec+all | error | 对象属性必须放在新行 |
| `@hw-stylistic/one-var-declaration-per-line` | rec+all | error | 每行只能有一个变量声明 |
| `@hw-stylistic/operator-linebreak` | rec+all | error | 操作符放在行末 |
| `@hw-stylistic/quotes` | rec+all | error | 字符串必须使用单引号 |
| `@hw-stylistic/semi-spacing` | rec+all | error | 分号前不加空格 |
| `@hw-stylistic/space-before-blocks` | rec+all | error | 大括号前需空格 |
| `@hw-stylistic/space-before-function-paren` | rec+all | error | 函数括号前空格 |
| `@hw-stylistic/space-infix-ops` | rec+all | error | 运算符需空格分隔 |

## 示例

```json
{
  "ruleSet": ["plugin:@hw-stylistic/recommended"],
  "rules": {
    "@hw-stylistic/max-len": ["warn", { "code": 120 }]
  }
}
```
