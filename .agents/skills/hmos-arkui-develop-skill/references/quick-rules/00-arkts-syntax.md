# 0. ArkTS 语法约束（arkts-* 规则）

> ArkTS 是 TypeScript 的静态子集，不少 TS 习惯写法在 ArkTS 会编译报错。本节按官方 `arkts-*` 规则标签组织，标签与编译器/linter 报错一一对应。**写任何 .ets 前先扫本文件，尤其 top traps（实测高频）。**
>
> 定位：与 01-import 至 20-particle 的 **ArkUI 组件/状态/导航约束** 正交，本节专注 **ArkTS 语言级语法规则**。

## ⚠Top traps（实测高频，生成前必扫）

| # | 陷阱 | ❌ 错误 | ✅ 正确 |
|---|------|---------|--------|
| 1 | 解构 | `const { a, b } = obj` | `const a = obj.a; const b = obj.b;` |
| 2 | 无类型对象字面量 | `const cfg = { timeout: 30 }` | `const cfg: Config = { timeout: 30 }`（先声明 `interface Config`） |
| 3 | 原型/结构类型 | `X.prototype.fn = ...` 或传结构匹配对象 | 在 class 内声明方法；用 `extends`/`implements` 做类型兼容 |
| 4 | 遗漏 export/import | 一个文件定义 `class CartItem`，另一文件直接用未导出 | 声明处加 `export`；使用处加 `import { CartItem } from '...'` |
| 5 | kit 命名空间错 | `import { audio } from '@kit.MediaKit'` | `audio` → `@kit.AudioKit`；`media` → `@kit.MediaKit` |
| 6 | enum 反射方法 | `HeavenlyStem.values()` / `Color.keys()` / `MyEnum.entries()` | ArkTS 枚举无 `.values()/.keys()/.entries()`，声明显式数组迭代 |

### 三个最高频错误的完整正例

**① 遗漏 export/import → `Cannot find name 'X'`**（单类最常犯）

```ets
// ❌ model 文件忘了 export；页面文件忘了 import
class CartItem { id: string = '' }          // CartItem.ets — no export
struct CartPage { item: CartItem = new CartItem() }  // Cannot find name 'CartItem'

// ✅ 声明处 export，使用处文件顶部 import
export class CartItem { id: string = '' }   // CartItem.ets
import { CartItem } from '../model/CartItem' // CartPage.ets — FIRST line
// 路由表 / @Builder 命名页面 struct 时必须逐个 import——NavPathStack 不会使其全局可见：
import { HomePage } from './HomePage'
import { DetailPage } from './DetailPage'
```

**② 无类型上下文的对象字面量 → `arkts-no-untyped-obj-literals`**（类型不会渗入嵌套字面量或调用实参）

```ets
// ❌ 无类型上下文，在调用实参/数组元素等任何位置都失败
const cfg = { timeout: 30 }
foo({ id: 1, name: 'a' })
const rows = [{ x: 1 }, { x: 2 }]

// ✅ 先声明 interface，在字面量处标注
interface Config { timeout: number }
const cfg: Config = { timeout: 30 }
foo({ id: 1, name: 'a' } as ItemArg)         // 标注实参
const rows: Point[] = [{ x: 1 }, { x: 2 }]   // 标注数组而非变量
// Record 字面量需带引号 key：
const m: Record<string, number> = { 'a': 1 }
```

**③ `enum.values()` 或臆造枚举成员 → `Property 'X' does not exist on type 'typeof Enum'`**

```ets
// ❌ ArkTS 枚举无反射；臆造的框架枚举成员也不存在
for (const s of HeavenlyStem.values()) {}  // .values() 不存在
animation({ curve: Curve.Spring })         // Curve 无 'Spring'

// ✅ 声明显式成员数组迭代；只从 quick-apis/16-enums.md 取真实成员
const ALL_STEMS: HeavenlyStem[] = [HeavenlyStem.JIA, HeavenlyStem.YI]
for (const s of ALL_STEMS) {}
animation({ curve: Curve.Smooth })         // 真实成员
```

---

## TypeScript → ArkTS 改写表（tag 与报错一一对应）

| TS 写法 | ArkTS 改写 | 规则标签 |
|---------|-----------|---------|
| `var x = 1` | `let x = 1` / `const x = 1` | `arkts-no-var` |
| `let x: any` / `unknown` | 明确类型；未定时用 `Object` 或联合类型 | `arkts-no-any-unknown` |
| `const { a, b } = obj` | `const a = obj.a; const b = obj.b` | `arkts-no-destruct-decls` |
| `function f({ a }: P)` | `function f(p: P)` 后用 `p.a` | `arkts-no-destruct-params` |
| `[x, y] = [y, x]` | 用临时变量逐一赋值 | `arkts-no-destruct-assignment` |
| `const fn = function() {}` | `const fn = () => {}` | `arkts-no-func-expressions` |
| `const id = <T>(v: T): T => v` | `function id<T>(v: T): T { return v }` | `arkts-no-generic-lambdas` |
| 函数体内 `function inner() {}` | `const inner = (): void => {}` 或提升为类方法 | `arkts-no-nested-funcs` |
| `<string>value` | `value as string` | `arkts-as-casts` |
| `obj as const` | 显式声明常量类型 | `arkts-no-as-const` |
| `type T = { x: number }` | `interface T { x: number }` | `arkts-no-obj-literals-as-types` |
| `f(p: { x: number })` | 定义具名 interface 作参数类型 | `arkts-no-obj-literals-as-types` |
| `interface I { [key: string]: T }` | `Record<string, T>` | `arkts-no-indexed-signatures` |
| `type C = A & B` | `interface C extends A, B {}` | `arkts-no-intersection-types` |
| `type N = T['prop']` | 直接使用目标类型 | `arkts-no-aliases-by-index` |
| `obj['key']`（非 Record） | `obj.key`；动态 key 用 Record | `arkts-no-props-by-index` |
| `const o = { a: 1 }`（无类型） | `const o: MyIface = { a: 1 }` 或 Record | `arkts-no-untyped-obj-literals` |
| `Pick`/`Omit`/`ReturnType` 等 | 手写具名 interface | `arkts-no-utility-types` |
| `delete obj.x` | 字段加 `\| undefined`，`obj.x = undefined` | `arkts-no-delete` |
| `'key' in obj` | `obj.key !== undefined` 或 `instanceof` | `arkts-no-in` |
| `for (const k in obj)` | `for...of` / `Map` / 已知 key 列表 | `arkts-no-for-in` |
| `v is Cat`（类型守卫） | `instanceof` 检查 + `as` 收窄 | `arkts-no-is` |
| `{ ...obj1, ...obj2 }` | 构造新对象，显式赋值字段 | `arkts-no-spread` |
| `throw 'msg'` | `throw new Error('msg')` | `arkts-limited-throw` |
| `catch (e: Error)` | `catch (e)` 后 `const err = e as Error` | `arkts-no-types-in-catch` |
| `constructor(public x: number) {}` | 在 class 体内声明字段，构造中赋值 | `arkts-no-ctor-prop-decls` |
| `#privateField` | `private privateField` | `arkts-no-private-identifiers` |
| `class D implements Base`（Base 是类） | `extends Base`，或抽 interface | `arkts-implements-only-iface` |
| `function* gen() { yield }` | 返回数组/迭代器类，或改普通函数 | `arkts-no-generators` |
| `fn.bind(this)` | 捕获 this 的箭头函数 | `arkts-no-func-bind` |
| `/pattern/g` | `new RegExp("pattern", "g")` | `arkts-no-regexp-literals` |
| `Object.assign(t, s)` | 显式赋值字段或用构造器 | `arkts-limited-stdlib` |
| `obj.hasOwnProperty('k')` | `obj.k !== undefined` | `arkts-limited-stdlib` |
| `globalThis.x` | 显式导出单例 / 模块级全局变量。AppStorage **不是**等价替代——它是状态管理设施，只存放需要被 UI 观察的状态变量，不存放普通全局数据，更不存 NavPathStack 等 UI 控制器 | `arkts-no-globalthis` |
| `// @ts-ignore` | 修复底层类型错误；抑制被禁 | `arkts-strict-typing-required` |
| `import type { T }` | `import { T }` | `arkts-no-special-imports` |
| `import './polyfill'` | 删除；显式 import 所需符号 | `arkts-no-side-effects-imports` |
| `import x = require('m')` | `import x from 'm'` | `arkts-no-require` |
| `export = X` | `export default X` | `arkts-no-export-assignment` |
| `router.getParams() as MyIface` | interface 不能实例化，用 `as` 转换；构造用 class | TS2693 |

---

## 核心硬约束（未标 WARNING 均为 ERROR 级）

### Types
| 规则 | 说明 |
|------|------|
| 禁止 `any`/`unknown` | 含 `as unknown as T` 双重断言；用具体类型、`Object`、联合类型 |
| 类型名作用域内唯一 | 不复用 imported 类型名作本地 struct/class 名（`arkts-unique-names`） |
| 无结构类型 | 需 `extends`/`implements`（`arkts-no-structural-typing`） |
| 对象字面量需类型上下文 | 含调用实参、回调返回；外层类型不渗入嵌套 |
| Record 字面量需带引号 key | `{ 'k': v }` 非 `{ k: v }` |
| 类类型对象字面量列全部字段 | class 默认值不使字段可选；用 `static of()` 工厂 |
| 无内联对象类型 | 用具名 interface（`arkts-no-obj-literals-as-types`） |
| 无交叉类型 `A & B` | 用接口继承（`arkts-no-intersection-types`） |
| 无索引签名 | 用 `Record<K,V>`（`arkts-no-indexed-signatures`） |
| 工具类型仅 Partial/Required/Readonly/Record | 其余手写（`arkts-no-utility-types`） |
| 显式标注泛型调用和返回类型 | `arkts-no-inferred-generic-params` / `arkts-no-implicit-return-types` |
| **enum 无反射方法** | `.values()/.keys()/.entries()` 不存在；用显式成员数组 |
| **禁止声明合并** | 类/接口分开定义，同类型名不能在多个文件顶层声明（`arkts-no-decl-merging`） |
| **对象字面量必须补齐全部必填字段** | 字段类型对齐；可选字段才允许缺省，声明时标 `?` |

### Null safety（检查错误最大来源）
| 规则 | 说明 |
|------|------|
| 可能 undefined 的值必须收窄 | `?.`、`?? fallback`、`if (x !== undefined)` |
| `T \| undefined` 不能赋给 `T` | **含函数实参**：`foo(x)` 中 x 为 `T \| undefined` 不能传给 `param: T`，传参前 `?? defaultValue` 或 if 收窄 |
| 空状态组件用 `T \| undefined` 或真实初始值 | 不用非空断言 `!` |
| 优先 `undefined` 而非 `null` | 外部 null 用 `?? undefined` 转换 |

### @Link 绑定约束
| 规则 | 说明 |
|------|------|
| **@Link 源必须是 @State** | 传给子组件 `@Link` 的父属性必须是 `@State`/`@Prop` 等装饰变量，不能是 `private`/普通属性 |
| **@Link 传值用 `this.`** | `Child({ aLink: this.aState })`（推荐）；`$aState` 是 API9 前旧写法，不推荐 |
| **@Prop 传值** | 见 [05-state](05-state.md) @Prop 节：本地有初始化则可选（同 @State），无则必选；支持父组件常规变量但只做数值初始化、不触发刷新 |

```ets
// ❌ WRONG — 普通属性传 @Link
struct Parent {
  private count: number = 0
  build() {
    Child({ count: this.count })  // Error: regular property cannot be assigned to @Link
  }
}

// ✅ RIGHT — @State 才能传 @Link
struct Parent {
  @State count: number = 0
  build() {
    Child({ count: this.count })
  }
}
```

### Functions and classes
| 规则 | 说明 |
|------|------|
| 不用 `function(){}` 作值 | 用箭头函数（`arkts-no-func-expressions`） |
| 无嵌套函数声明 | `arkts-no-nested-funcs` |
| async 方法必须显式标注 `Promise<T>` | 省略报 error；无返回值写 `Promise<void>` |
| 独立/static 方法无 `this` | static 成员用类名访问（`arkts-no-standalone-this`） |
| 无构造参数属性 | `arkts-no-ctor-prop-decls` |
| 同作用域不允许同名函数声明 | 无函数重载，每函数名只有一个实现 |
| 无 `#` 私有字段 | 用 `private`（`arkts-no-private-identifiers`） |
| `implements` 仅接口 | 接口不能 extends 类 |
| 无 generator/`yield`、类表达式、`Function.bind` | |

### Exports and imports（"Cannot find name" / "not exported" 高频来源）
| 规则 | 说明 |
|------|------|
| 跨文件使用的类型必须 `export` | 忘记 export 报 `Module '...' declares 'X' locally, but it is not exported` |
| 自定义类型必须显式 `import` | `Cannot find name 'X'` 几乎总是缺 import |
| "No overload matches this call" = 实参类型/数量错 | 常见：传错枚举（如 `EdgeEffect.Spring` 处传 `ScrollAlign.Start`）、给类型化枚举传 string、回调签名错 |

> kit 归属和速查表见 [01-import](01-import.md)。

### Statements and expressions
| 规则 | 说明 |
|------|------|
| 无任何解构 | 声明/赋值/参数（`arkts-no-destruct-*`） |
| import 必须在文件顶部 | 其他语句之前（`arkts-no-misplaced-imports`） |
| 无 `delete`、`in`、`for...in`、`with` | |
| 非 Record 无索引访问 `obj['k']` | 用点访问（`arkts-no-props-by-index`） |
| `throw` 只抛 Error+子类 | `catch (e)` 无类型注解；系统 API 错误用 `BusinessError` |
| 无 `is` 类型守卫 | 用 `instanceof` + `as` |
| 对象展开受限 | 数组展开 OK（`arkts-no-spread`） |
| 无正则字面量 | 用 `new RegExp()`（`arkts-no-regexp-literals`） |
| 无 `@ts-ignore` | `arkts-strict-typing-required` |
| **JSON.parse 收窄模式** | 先 `as` 转换到原始类型，再逐字段校验赋值到严格类型，不直接使用 `as` 后的对象 |

```ts
// JSON.parse 收窄 — 不要直接信任 parsed 结果
interface TaskRaw { id?: number; title?: string }
const raw = JSON.parse(text) as TaskRaw
const task: Task = { id: raw.id ?? 0, title: raw.title ?? '' }
```

### Standard library
- 禁用：`eval`、`Object.assign/create/freeze/defineProperty`、`Reflect`/`Proxy`、`Symbol()`（除 `.iterator`）、`globalThis`
- 无 `import type`、副作用导入、`require`、`export =`

### 模板字符串注意
> **注意**：`restrictions.md` 声称模板字符串不支持，但 `arkts-rules.md` "Explicitly allowed constructs" 明确 **模板字符串合法**（`Text(\`${this.msg}\`)` 是惯用写法）。以 `arkts-rules.md` 为准——模板字符串、`value as T`、`Record<K,V>`、箭头函数均合法，不要防御性改写。

---

## 显式允许的构造（不要过度限制）

模板字面量、`as T` 断言、`Record<K,V>` + 索引访问、`Partial<T>`/`Required<T>`/`Readonly<T>`、箭头函数、`async/await`、泛型类/接口/函数、数组展开 `[...a]`、表达式上下文 `typeof x`、`new RegExp()`、联合类型/类型别名、`for...of`/`Map`/`Set`——**全部合法，正常使用**。**例外：`@Component`（V1）struct 内的 getter accessor 会被编译转换丢弃，禁用，改用普通成员方法**（`@ComponentV2` 不受此限）。

## 参考

- 错误码速查见 [18-error-code](../quick-apis/18-error-code.md)
- 空安全回调场景高发错误见 [09-attribute-params](07-attribute-params.md) 空安全节
- kit 归属和速查表见 [01-import](01-import.md)
- 对象字面量类型约束见 [10-type-annotation](00-arkts-syntax.md)
- 命名冲突（struct 名 ≠ imported 类型名、跨文件重名）见 [03-component](03-component.md)