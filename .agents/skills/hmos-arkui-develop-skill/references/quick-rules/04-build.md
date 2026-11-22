# 4. build() 函数约束

## 规则

| 规则 | 说明 | 错误码 |
|------|------|--------|
| `@Entry` 根节点必须为容器组件 | 根节点唯一且必需，**必须为容器组件**（`Column`/`Row`/`Stack`/`Navigation` 等） | — |
| `@Component` 根节点可为非容器 | 根节点唯一且必需，但可为非容器组件 | — |
| `ForEach` 禁止作为根节点 | 任何组件根节点都不能是 `ForEach`/`LazyForEach` | — |
| 禁止声明本地变量 | `let n = 1` 不允许 | — |
| 禁止 `console.info` | build() 中不允许直接 console.info（但方法/函数里可以） | — |
| 禁止本地作用域 | `{ ... }` 不允许 | — |
| 禁止调用非 `@Builder` 方法产出 UI | 只能调用 `@Builder` 装饰的方法来生成 UI 片段 | — |
| 禁止 `switch` | 用 `if` 替代 | — |
| 禁止三元表达式 | `? :` 不允许，用 `if` 渲染 | — |
| **禁止直接改变状态变量** | `this.counter += 1` 会导致循环渲染 | — |
| **sort/filter 陷阱** | `this.arr.sort().filter(...)` 中 `sort()` 改变原数组触发状态变更 → 循环 | — |
| **Button('label') 与 children 互斥** | `Button('x') { ... }` 同时传 label 和 children 报 **10905202**。要么 `Button('x')` 要么 `Button() { Text('x') }` | **10905202** |
| **嵌套 ForEach 参数名必须不同** | 嵌套 ForEach 每层用不同的 item 参数名（`row`/`cell`，不用 `item`/`item`） | — |
| **@Builder 返回 void，调用处不可链式** | @Builder 不返回值，不能在调用处链 `.onClick(...)` | — |

## 常见错误对比

| ❌ 错误写法 | ✅ 正确写法 | 说明 |
|------------|-----------|------|
| `@Entry struct P { build() { ForEach(this.list, ...) } }` | `@Entry struct P { build() { Column() { ForEach(this.list, ...) } } }` | ForEach 不能做根节点 |
| `let n = this.compute()` 在 build() 中 | 把计算逻辑提到方法中，在 build() 中调用 | 禁止本地变量 |
| `console.info('x')` 在 build() 中 | 移到方法/事件回调中 | 禁止 console |
| `switch (this.type) { case 1: Text('a'); }` | `if (this.type === 1) { Text('a') }` | 用 if 替代 switch |
| `Text(this.flag ? 'yes' : 'no')` | `if (this.flag) { Text('yes') } else { Text('no') }` | 用 if 替代三元 |
| `this.counter += 1` 在 build() 中 | 放在事件回调 `.onClick(() => { this.counter += 1 })` | 不直接改状态变量 |
| `this.arr.sort().filter(x => x > 0)` | `this.arr.filter(x => x > 0).sort()` | sort() 改变原数组 |
| `Button('x') { Text('x') }`（同时传 label 和 children） | `Button('x')` 或 `Button() { Text('x') }` | 10905202 |
| 嵌套 ForEach 都叫 `item` | 外层 `row` 内层 `cell` 等不同名 | 参数名冲突 |

**根因**：AI 把 build() 当成普通函数来写，不理解声明式 UI 的渲染约束。

## 参考

- 渲染控制（ForEach/LazyForEach/Repeat）见 [08-rendering](06-rendering.md)
- 容器直接子组件约束见 [16-layout](12-layout.md)