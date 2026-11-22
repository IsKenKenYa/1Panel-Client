# CodeLinter 配置参考

## 配置文件

默认配置文件名为 `code-linter.json5`（或 `codelinter.json5`），放置在工程根目录。DevEco Studio CodeLinter 启动时会自动读取该文件；也可通过 CLI `-c/--config` 指定其他路径。

配置使用 JSON5 语法（支持注释和尾逗号）。

## 顶层字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `files` | `string[]` | 检查范围，glob 模式 |
| `ignore` | `string[]` | 排除范围，glob 模式 |
| `ruleSet` | `string[]` | 应用的规则集 |
| `rules` | `object` | 单条规则覆盖 |
| `overrides` | `array` | 针对特定路径的规则覆盖 |
| `plugins` | `string[]` | 自定义插件（保留字段） |
| `extRuleSet` | `array` | 外部规则集扩展 |

## ruleSet 取值

规则集格式为 `plugin:<规则集名>/<粒度>`：

| 粒度 | 说明 |
|------|------|
| `recommended` | 推荐规则子集，告警量适中，适合日常开发 |
| `all` | 全量规则，适合严格审查（告警量较大） |

可用规则集前缀：`@typescript-eslint`、`@hw-stylistic`、`@performance`、`@security`、`@correctness`、`@cross-device-app-dev`、`@compatibility`、`@previewer`。各规则集详细规则见 [规则集索引](rules/index.md)。

> **注意**：
> - `@typescript-eslint`：`recommended` 和 `all` 完全相同（15 条）。另有 98 条预设外规则可通过 `rules` 逐条启用，合计 113 条（含 `eqeqeq`、`prefer-const` 两条无前缀规则）。
> - `@correctness` 和 `@compatibility`：无 `recommended` 粒度，仅 `all`。
> - 部分安全规则不在任何预设中，需通过 `rules` 字段启用（如 `no-unsafe-aes`、`no-unsafe-3des` 等）。

## rules 字段：规则级别覆盖

在 `ruleSet` 基础上，可通过 `rules` 单独调整任意规则的严重级别。

级别值：

| 值 | 数字 | 含义 |
|----|------|------|
| `"off"` | `0` | 关闭规则 |
| `"warn"` | `1` | 警告 |
| `"error"` | `2` | 错误 |
| `"suggestion"` | `3` | 建议 |

带参数的规则使用数组形式 `["级别", 参数对象]`：

```json
{
  "rules": {
    "@hw-stylistic/max-len": ["warn", { "code": 120 }],
    "@typescript-eslint/array-type": ["error", { "default": "array" }]
  }
}
```

## overrides 字段：路径差异化配置

`overrides` 是一个数组，每项通过 `files`（glob）匹配路径，并在该路径下覆盖 `rules`：

```json
{
  "overrides": [
    {
      "files": ["**/test/**/*.ts"],
      "rules": {
        "@typescript-eslint/no-explicit-any": "off",
        "@typescript-eslint/no-magic-numbers": "off"
      }
    }
  ]
}
```

## ignore 常用模式

```json
{
  "ignore": [
    "**/oh_modules/**",     // 第三方依赖（必须排除）
    "**/build/**",          // 构建产物（必须排除）
    "**/.preview/**",       // Previewer 临时文件
    "**/node_modules/**",   // Node 依赖
    "**/*.d.ts",            // 类型声明文件
    "**/generated/**"       // 自动生成代码
  ]
}
```

## 配置示例

### 示例 1：日常开发（推荐配置）

```json
{
  "files": ["**/*.ets", "**/*.ts", "**/*.js"],
  "ignore": [
    "**/oh_modules/**",
    "**/build/**",
    "**/.preview/**",
    "**/node_modules/**"
  ],
  "ruleSet": [
    "plugin:@typescript-eslint/recommended",
    "plugin:@hw-stylistic/recommended",
    "plugin:@performance/recommended"
  ],
  "rules": {}
}
```

### 示例 2：安全审计专项

```json
{
  "files": ["**/*.ets", "**/*.ts"],
  "ignore": ["**/oh_modules/**", "**/build/**"],
  "ruleSet": [
    "plugin:@security/all"
  ],
  "rules": {
    "@security/no-unsafe-aes": "error",
    "@security/no-unsafe-3des": "error",
    "@security/no-unsafe-rsa-encrypt": "error",
    "@security/no-unsafe-hash": "error",
    "@security/no-commented-code": "warn"
  }
}
```

> 注意：`no-unsafe-aes`、`no-unsafe-3des`、`no-unsafe-rsa-encrypt`、`no-unsafe-hash` 等规则不在 `@security/all` 预设中，需在 `rules` 中单独启用。

### 示例 3：性能优化专项

```json
{
  "files": ["**/*.ets"],
  "ignore": ["**/oh_modules/**", "**/build/**"],
  "ruleSet": [
    "plugin:@performance/all"
  ],
  "rules": {
    "@performance/foreach-args-check": "error",
    "@performance/high-frequency-log-check": "warn"
  }
}
```

### 示例 4：跨设备适配检查

```json
{
  "files": ["**/*.ets"],
  "ignore": ["**/oh_modules/**", "**/build/**"],
  "ruleSet": [
    "plugin:@cross-device-app-dev/all",
    "plugin:@compatibility/all"
  ],
  "rules": {}
}
```

### 示例 5：严格全量检查（发布前）

```json
{
  "files": ["**/*.ets", "**/*.ts", "**/*.js"],
  "ignore": ["**/oh_modules/**", "**/build/**"],
  "ruleSet": [
    "plugin:@typescript-eslint/recommended",
    "plugin:@hw-stylistic/recommended",
    "plugin:@performance/all",
    "plugin:@security/all",
    "plugin:@correctness/all",
    "plugin:@compatibility/all",
    "plugin:@cross-device-app-dev/all"
  ],
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@security/no-unsafe-aes": "error",
    "@security/no-unsafe-3des": "error",
    "@security/no-unsafe-rsa-encrypt": "error",
    "@security/no-unsafe-hash": "error",
    "@security/no-unsafe-mac": "error",
    "@security/no-unsafe-dh": "error",
    "@security/no-unsafe-dsa": "error",
    "@security/no-unsafe-ecdsa": "error"
  }
}
```

### 示例 6：overrides 对不同目录差异化配置

```json
{
  "files": ["**/*.ets", "**/*.ts"],
  "ignore": ["**/oh_modules/**", "**/build/**"],
  "ruleSet": [
    "plugin:@typescript-eslint/recommended",
    "plugin:@performance/recommended"
  ],
  "rules": {},
  "overrides": [
    {
      "files": ["**/test/**/*.ts"],
      "rules": {
        "@typescript-eslint/no-explicit-any": "off",
        "@typescript-eslint/no-magic-numbers": "off"
      }
    },
    {
      "files": ["**/pages/**/*.ets"],
      "rules": {
        "@performance/foreach-args-check": "error"
      }
    }
  ]
}
```

### 示例 7：CI/CD 门禁

```json
{
  "files": ["**/*.ets", "**/*.ts"],
  "ignore": ["**/oh_modules/**", "**/build/**", "**/.preview/**"],
  "ruleSet": [
    "plugin:@typescript-eslint/recommended",
    "plugin:@security/recommended"
  ],
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@security/no-unsafe-aes": "error",
    "@security/no-unsafe-hash": "error"
  }
}
```

配合 `--incremental` 仅检查增量文件，`--exit-on error` 在有 error 时返回非零退出码使门禁失败：

```bash
node <CODELINTER> -i -e error,warn -f json -o /tmp/lint-report.json /path/to/project
```
