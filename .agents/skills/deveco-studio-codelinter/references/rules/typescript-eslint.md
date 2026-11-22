# @typescript-eslint — 通用规则

面向 TypeScript/ArkTS 的语法、类型安全和代码风格规则。

## 规则集

- `plugin:@typescript-eslint/recommended` — 15 条
- `plugin:@typescript-eslint/all` — 15 条（与 recommended 完全相同）

> 其余 98 条规则不在任何预设中，可通过 `rules` 字段逐条启用。

## 全部规则列表（113 条）

### 类型安全

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@typescript-eslint/await-thenable` | rec+all | error | 禁止对非 Promise 值使用 await |
| `@typescript-eslint/consistent-type-imports` | rec+all | error | 强制统一使用类型导入 |
| `@typescript-eslint/no-dynamic-delete` | rec+all | error | 禁止动态删除属性 |
| `@typescript-eslint/no-explicit-any` | rec+all | error | 禁止使用 any 类型 |
| `@typescript-eslint/no-for-in-array` | rec+all | error | 禁止 for-in 遍历数组 |
| `@typescript-eslint/no-this-alias` | rec+all | error | 禁止给 this 起别名 |
| `@typescript-eslint/no-unnecessary-type-constraint` | rec+all | error | 禁止不必要的类型约束 |
| `@typescript-eslint/no-unsafe-argument` | rec+all | error | 禁止将 any 类型的值作为参数传递 |
| `@typescript-eslint/no-unsafe-assignment` | rec+all | error | 禁止 any 类型赋值 |
| `@typescript-eslint/no-unsafe-call` | rec+all | error | 禁止调用 any 类型 |
| `@typescript-eslint/no-unsafe-member-access` | rec+all | error | 禁止对 any 类型成员访问 |
| `@typescript-eslint/no-unsafe-return` | rec+all | error | 禁止返回 any 类型 |
| `@typescript-eslint/no-non-null-assertion` | — | error | 禁止非空断言 `!` |
| `@typescript-eslint/no-non-null-asserted-optional-chain` | — | error | 禁止在可选链后使用非空断言 |
| `@typescript-eslint/no-confusing-non-null-assertion` | — | error | 禁止混淆非空断言 |
| `@typescript-eslint/no-extra-non-null-assertion` | — | error | 禁止多余非空断言 |
| `@typescript-eslint/strict-boolean-expressions` | — | error | 强制严格布尔表达式 |
| `@typescript-eslint/no-confusing-void-expression` | — | error | 禁止混淆 void 表达式 |
| `@typescript-eslint/no-invalid-void-type` | — | error | 禁止无效 void 类型 |
| `@typescript-eslint/consistent-type-assertions` | — | error | 强制一致类型断言 |
| `@typescript-eslint/consistent-type-definitions` | — | error | 强制一致类型定义（interface vs type） |
| `@typescript-eslint/consistent-indexed-object-style` | — | error | 强制一致索引对象风格（Record vs index signature） |

### Promise/异步

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@typescript-eslint/no-floating-promises` | — | error | Promise 必须被处理 |
| `@typescript-eslint/no-misused-promises` | — | error | 禁止在非 Promise 场景使用 Promise |
| `@typescript-eslint/promise-function-async` | — | error | 含 await 的函数应标记 async |
| `@typescript-eslint/return-await` | — | error | async 函数中应使用 return await |
| `@typescript-eslint/no-implicit-any-catch` | — | error | 禁止隐式 any 的 catch |

### 函数/类声明

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@typescript-eslint/explicit-function-return-type` | rec+all | error | 要求函数和类方法显式声明返回类型 |
| `@typescript-eslint/explicit-module-boundary-types` | rec+all | error | 要求模块边界显式声明类型 |
| `@typescript-eslint/prefer-literal-enum-member` | rec+all | error | 枚举成员应使用字面量 |
| `@typescript-eslint/adjacent-overload-signatures` | — | error | 重载签名应相邻 |
| `@typescript-eslint/unified-signatures` | — | error | 合并相同签名 |
| `@typescript-eslint/class-literal-property-style` | — | error | 类字面量属性风格 |
| `@typescript-eslint/explicit-member-accessibility` | — | error | 显式成员可见性 |
| `@typescript-eslint/method-signature-style` | — | error | 方法签名风格 |
| `@typescript-eslint/default-param-last` | — | error | 默认参数在最后 |
| `@typescript-eslint/no-empty-function` | — | error | 禁止空函数 |
| `@typescript-eslint/no-empty-interface` | — | error | 禁止空接口 |
| `@typescript-eslint/no-parameter-properties` | — | error | 禁止构造函数参数属性 |
| `@typescript-eslint/no-type-alias` | — | error | 禁止类型别名 |
| `@typescript-eslint/typedef` | — | error | 要求类型定义 |
| `@typescript-eslint/ban-types` | — | error | 禁止特定类型 |
| `@typescript-eslint/ban-ts-comment` | — | error | 禁止 @ts- 注释 |
| `@typescript-eslint/ban-tslint-comment` | — | error | 禁止 tslint 注释 |

### 语法规范

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@typescript-eslint/no-unused-vars` | — | error | 禁止未使用的变量 |
| `@typescript-eslint/no-unused-expressions` | — | error | 禁止无副作用的表达式 |
| `@typescript-eslint/no-use-before-define` | — | error | 禁止使用前定义 |
| `@typescript-eslint/no-useless-constructor` | — | error | 禁止无用构造函数 |
| `@typescript-eslint/no-duplicate-imports` | — | error | 禁止重复导入 |
| `@typescript-eslint/no-redeclare` | — | error | 禁止重复声明 |
| `@typescript-eslint/no-shadow` | — | error | 禁止变量遮蔽 |
| `@typescript-eslint/no-throw-literal` | — | error | 禁止 throw 字面量 |
| `@typescript-eslint/no-implied-eval` | — | error | 禁止隐式 eval |
| `@typescript-eslint/no-loop-func` | — | error | 禁止循环内函数闭包 |
| `@typescript-eslint/no-loss-of-precision` | — | error | 禁止精度丢失 |
| `@typescript-eslint/no-inferrable-types` | — | error | 禁止可推断的显式类型 |
| `@typescript-eslint/no-namespace` | — | error | 禁止 namespace |
| `@typescript-eslint/no-require-imports` | — | error | 禁止 require |
| `@typescript-eslint/no-restricted-syntax` | — | error | 禁止受限语法 |
| `@typescript-eslint/no-array-constructor` | — | error | 禁止 new Array() |
| `@typescript-eslint/no-base-to-string` | — | error | 禁止对无 toString 的对象调用 toString |
| `@typescript-eslint/no-dupe-class-members` | — | error | 禁止重复类成员 |
| `@typescript-eslint/no-extraneous-class` | — | error | 禁止无用类 |
| `@typescript-eslint/no-misused-new` | — | error | 禁止误用 new |
| `@typescript-eslint/no-invalid-this` | — | error | 禁止无效 this |
| `@typescript-eslint/no-magic-numbers` | — | warn | 禁止魔法数字 |
| `@typescript-eslint/no-extra-parens` | — | error | 禁止多余括号 |
| `@typescript-eslint/no-extra-semi` | — | error | 禁止多余分号 |

### 优先使用

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@typescript-eslint/prefer-optional-chain` | — | error | 优先使用可选链 `?.` |
| `@typescript-eslint/prefer-nullish-coalescing` | — | error | 优先使用空值合并 `??` |
| `@typescript-eslint/prefer-readonly` | — | error | 未修改的私有成员应标记 readonly |
| `@typescript-eslint/prefer-readonly-parameter-types` | — | warn | 参数应标记 readonly |
| `@typescript-eslint/prefer-as-const` | — | error | 优先使用 as const |
| `@typescript-eslint/prefer-for-of` | — | error | 优先使用 for-of |
| `@typescript-eslint/prefer-includes` | — | error | 优先使用 includes |
| `@typescript-eslint/prefer-function-type` | — | error | 优先使用函数类型 |
| `@typescript-eslint/prefer-namespace-keyword` | — | error | 优先使用 namespace 关键字 |
| `@typescript-eslint/prefer-enum-initializers` | — | error | 枚举应显式初始化 |
| `@typescript-eslint/prefer-reduce-type-parameter` | — | error | reduce 应使用类型参数 |
| `@typescript-eslint/prefer-regexp-exec` | — | error | 优先使用 RegExp.exec |
| `@typescript-eslint/prefer-string-starts-ends-with` | — | error | 优先使用 startsWith/endsWith |
| `@typescript-eslint/prefer-ts-expect-error` | — | error | 优先使用 @ts-expect-error |

### 代码风格

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@typescript-eslint/quotes` | — | error | 引号风格 |
| `@typescript-eslint/semi` | — | error | 分号风格 |
| `@typescript-eslint/comma-dangle` | — | error | 尾逗号 |
| `@typescript-eslint/comma-spacing` | — | error | 逗号间距 |
| `@typescript-eslint/brace-style` | — | error | 大括号风格 |
| `@typescript-eslint/keyword-spacing` | — | error | 关键字间距 |
| `@typescript-eslint/space-before-function-paren` | — | error | 函数括号前空格 |
| `@typescript-eslint/space-infix-ops` | — | error | 中缀运算符间距 |
| `@typescript-eslint/type-annotation-spacing` | — | error | 类型注解间距 |
| `@typescript-eslint/func-call-spacing` | — | error | 函数调用间距 |
| `@typescript-eslint/member-delimiter-style` | — | error | 成员分隔符风格 |
| `@typescript-eslint/lines-between-class-members` | — | error | 类成员间空行 |
| `@typescript-eslint/init-declarations` | — | error | 要求声明时初始化 |

### 命名/结构

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@typescript-eslint/naming-convention` | — | error | 强制命名约定 |
| `@typescript-eslint/member-ordering` | — | error | 类成员排序 |
| `@typescript-eslint/dot-notation` | — | error | 要求点号访问 |
| `@typescript-eslint/array-type` | — | error | 数组类型一致性 |

### 逻辑/比较

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@typescript-eslint/no-unnecessary-condition` | — | error | 禁止不必要条件 |
| `@typescript-eslint/no-unnecessary-boolean-literal-compare` | — | error | 禁止不必要布尔比较 |
| `@typescript-eslint/no-unnecessary-qualifier` | — | error | 禁止不必要限定符 |
| `@typescript-eslint/no-unnecessary-type-arguments` | — | error | 禁止不必要类型参数 |
| `@typescript-eslint/no-unnecessary-type-assertion` | — | error | 禁止不必要类型断言 |
| `@typescript-eslint/switch-exhaustiveness-check` | — | error | switch 需穷尽 |
| `@typescript-eslint/restrict-plus-operands` | — | error | 限制加法操作数类型 |
| `@typescript-eslint/restrict-template-expressions` | — | error | 限制模板表达式类型 |
| `@typescript-eslint/require-array-sort-compare` | — | error | sort 需比较函数 |
| `@typescript-eslint/require-await` | — | error | async 函数需含 await |
| `@typescript-eslint/unbound-method` | — | error | 禁止解绑方法调用 |
| `@typescript-eslint/triple-slash-reference` | — | error | 禁止三斜杠引用 |

### 通用规则（无插件前缀）

> 以下规则无 `@typescript-eslint/` 前缀，但也归属于`@typescript-eslint`。

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `eqeqeq` | — | error | 要求使用 `===` 和 `!==` |
| `prefer-const` | — | error | 要求用 `const` 声明不会再赋值的变量 |

## 示例

```json
{
  "ruleSet": ["plugin:@typescript-eslint/recommended"],
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-unused-vars": "warn",
    "@typescript-eslint/no-floating-promises": "error"
  }
}
```
