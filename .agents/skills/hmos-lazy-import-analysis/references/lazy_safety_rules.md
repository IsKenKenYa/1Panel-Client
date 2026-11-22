# Lazy-Import 副作用预判与安全规则

> 用于 Phase 3：对报表 `has_toplevel=true`（存在顶层代码）或 `maybe`（存疑）的模块，由 agent **读源码**预判改为 `import lazy` 是否安全。输出 safe / critical / unknown 三态，作为 Phase 4 与用户批量确认的依据。

## 官方定义

> **副作用**是指在模块导入时除了导出功能或对象之外，额外的行为或状态变化，这些行为可能影响程序的其他部分，并导致**非预期的顶层代码执行、全局状态变化、原型链修改、导入内容未定义**等问题。
> —— [模块加载副作用及优化（华为官方文档）](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/arkts-module-side-effects)

官方归纳的副作用场景：① 模块执行顶层代码 ② 修改全局对象（`globalThis`）③ 修改应用级 ArkUI 状态变量（`AppStorage` 等）④ 修改内置全局变量或原型链 ⑤ 循环依赖（导入内容未定义）⑥ **lazy import 改变模块执行顺序**。

## lazy-import 的副作用机制

`import lazy { X } from '...'` 把模块加载推迟到**首次使用**。官方示例：模块顶层 `globalThis.someGlobalVar = 100`，lazy 后在首次使用该模块变量之前，`someGlobalVar` 为 `undefined`——模块内的全局修改行为被推迟，运行结果可能不符合预期。

因此判定标准为：**顶层代码是否产生全局状态变化、或其执行时机被他人依赖**。

- 有 → lazy 推迟执行 → 空指针/功能缺失/读到 undefined → **critical**
- 无（纯分配/纯读取，不改变任何外部可见状态）→ lazy 仅推迟执行，结果不变 → **safe**

脚本只判"有无 top-level"（对应官方场景①），**不区分**其上两类——本维度由 agent 读码补齐。

## 判定规则

读每个候选模块的 top-level 源头（报表 `why` 列给出的源文件+行）及**被调函数实现**，归入：

### safe（可安全 lazy）

top-level 代码**全部**满足：

- 不产生任何全局状态变化（未写 `globalThis` / `AppStorage` / 全局单例 / 原型链）
- 无 import 顺序依赖
- 属"良性"：纯分配（`new X()` 且构造函数为空/无副作用）、缓存/设备信息读取（`getXxx()` 返回值）、字面量赋值、纯调用（如 `Math.random()`）、仅影响本模块内部的局部计算

典型：
- `static ME = new FooUser()`（空构造）
- `static MANUFACTURER = FooEnv.getManufacturer()`（读设备信息）
- `export const MAP = new Map([..., new FooAssigner()])`（FooAssigner 仅方法无构造）
- `const flag = Math.random() <= 0.001`

> `console.info()` 等仅产生日志输出的顶层调用：不影响程序状态，lazy 化安全（仅日志时序推迟），但建议在报告中注明。

### critical（时序敏感，不可 lazy）

命中以下**任一**官方副作用场景：

| # | 场景 | 判定 | 典型 |
|---|------|------|------|
| C1 | 修改全局对象 | 顶层写 `globalThis.*` 或其他全局变量 | `globalThis.someGlobalVar = 100` |
| C2 | 修改应用级 ArkUI 状态 | 调用 `AppStorage.setOrCreate` / `PersistentStorage` 等应用级状态管理接口 | `AppStorage.setOrCreate('k', 200)`（@StorageLink 消费方预期值被改变） |
| C3 | 全局注册/订阅/单例写值 | 向 Manager/Proxy/Registry/单例写值或注册；EventBus、路由、插件容器、组件构建器注册 | `FooPluginManager.initContainer(c)`；`FooComponentProxy.setComponentBuilders([...])` |
| C4 | 修改内置对象或原型链 | 重写/扩展内置全局对象或原型（ArkTS 禁止，但第三方库可能） | `Array.prototype.includes = function...` |
| C5 | 执行时机被他人依赖 | 其他模块依赖其 load 时完成初始化（典型：barrel Index 顶层 `serviceManager.init()`） | 见官方"import 路径展开"示例——跳过/推迟中间模块执行导致 `ServiceManager is not inited` |

### unknown（未验证）

- 被调函数实现在字节码包（仅 `.d.ets` 类型声明）或源码不可达，**无法确认**是否产生全局状态变化。典型：`BarImpl.getInstance()`（实现在预编译 HAR 包，仅声明可见）
- 模块或其 import 闭包中存在**循环依赖**：加载时序本就不可控（官方场景⑤，报 `xxx is not initialized`），lazy 进一步扰动时序，且 agent 难以静态推演 → 保守 unknown，建议先治理循环依赖（可用 `@security/no-cycle` 检查）后再评估

## 判定输出格式

每模块一条记录，Phase 4 汇总呈现给用户；Phase 5 报告的「为什么可以/不可以 lazy」与「证据」块**直接取自该记录**：

```
模块: {module}（row {行号}, cost {耗时}ms, has_toplevel={true|maybe}）
预判: safe | critical | unknown
源头: {源文件:行号}
顶层代码片段: {read 核对后的原文}
被调实现: {被调函数/构造函数的 文件:行号 + 关键实现片段；unknown 项写明不可达点（仅 .d.ets 声明 / 循环依赖边）}
命中规则: {safe 条款 | C1–C5 编号 | unknown 条目}
依据: {safe: 为何良性/无全局写入; critical: 全局写入点在哪; unknown: 哪个实现不可达}
```

取证约束：片段必须当场 read 原文，不得凭记忆转述；`has_toplevel=false` 的模块无需读码，证据记为"脚本闭包检测无顶层代码"。

## has_toplevel=maybe 的处理

- 优先按 `references/toplevel_rules.md` 读码自查：若 maybe 仅由**白名单外装饰器**引起且装饰器无副作用（如纯 UI 声明），可预判 safe 并在依据中注明"装饰器存疑，已人工复核"
- 若由**不可解析 import**（预编译 HAR）引起 → 保守预判 unknown，交用户裁定

## 官方治理模式（写入建议报告）

对判为 critical 的模块，lazy 化不可行时，按官方推荐给出**替代治理建议**：把顶层副作用代码移入导出的初始化函数，按需调用：

```ts
// 改前（模块顶层）：globalThis.someGlobalVar = 100;
// 改后（官方优化方式）：
export function initialize() {
  globalThis.someGlobalVar = 100;  // 延迟到函数调用时执行
}
// 使用方：import lazy { data, initialize } from '...'; initialize(); // 先显式初始化再使用
```

同理适用于：`AppStorage.setOrCreate` 移入 `initialize()`；`serviceManager.init()` 移到使用方显式调用或模块导出语句之后执行。

## 执行约束

- **纯查看**：预判阶段不修改任何源码/脚本/规则文件
- 不调用 `check_toplevel.py` 等脚本（它们已在此前 Phase 完成）；agent 用 grep/read 直接定位与读码
- **token 警告**：候选模块数 > 20 时，先警告用户 token 消耗，确认后再进行

## 「可lazy?」列规则（解读 safe 引用报告 xlsx）

`gen_safe_importers_report.py` 产出的报告中，每个引用点一行，`可lazy?` 列取值：

- **引用行是 `export ... from`（re-export）→ `暂不可(re-export)`**：lazy-import 对 re-export 的语义未明，不处理。注意判据是**引用行本身**是否为 re-export，而非 parentModule 的文件名——`pages/Index.ets` 这类 `@Entry` 页面文件内的普通 `import ... from` 引用是可 lazy 的
- **否则 `可`**：该处是普通 `import ... from`，可建议改为 `import lazy {...} from`
- 未找到引用行 → `待确认`（请人工在 parentModule 文件中搜索）
- 若引用行已是 `import lazy {...}` → 已懒加载，无需再改

最终建议报告中，仅对 `可lazy? = 可` 的行给出改写建议；以下形式**跳过并在报告中说明原因**：

- `export ... from` re-export（`暂不可(re-export)`）
- 默认导入 `import Foo from 'mod'`、命名空间导入 `import * as ns from 'mod'`（lazy 语法对这些形式的支持需按目标 SDK 版本核实）
- 已是 `import lazy` / `import type`（纯类型导入编译期擦除，无需 lazy）

引用定位行由 `scripts/xlsx_to_md.py --match "报表row={row}"` 原样嵌入各模块小节（含 `暂不可(re-export)`/`待确认` 行，不删列不改写）；跳过形式集中在报告「跳过项及原因」章节逐项说明。

Phase 6（可选）仅对 `可lazy? = 可` 行做 `import lazy` 机械插入；顺序强制为：预览生成 diff 与计划文件 → 用户选择 → `--apply --plan` 按计划应用。治理重构与所有跳过形式一律人工实施。
