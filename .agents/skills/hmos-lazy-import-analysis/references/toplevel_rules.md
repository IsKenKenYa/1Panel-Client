# Top-Level 代码判定规则

> 本规则是 `scripts/check_toplevel.py`（含 `analyze_report.py` 批量调用）的判定依据，也是 agent 解读报表 `has_toplevel`/`why` 列、复核存疑文件时的参考。脚本启发式有边界偏差，agent 复核时以本规则为准。

## 0. 目标与三态语义

判定"导入某 ets 模块时，其自身及 import 闭包是否存在 **import 时执行的代码**（top-level 代码）"。

> 官方定义（[模块加载副作用及优化](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/arkts-module-side-effects)）：副作用指模块导入时除导出功能或对象之外的额外行为或状态变化，可致非预期顶层代码执行、全局状态变化、原型链修改、导入内容未定义。本规则的检测目标是其**必要条件**——顶层代码的存在性；是否构成副作用（全局状态变化/时序依赖）由 `references/lazy_safety_rules.md` 判定。

脚本内部 verdict（stdout 显示）：

- **`TRUE`** —— 自身及全部可解析 import 闭包均**无** top-level 代码
- **`FALSE`** —— 存在 top-level 代码
- **`MAYBE`** —— 存在不确定项且无 FALSE

**报表 `has_toplevel` 列与 verdict 相反**（脚本写入 xlsx 时做了转换）：

| verdict（stdout） | has_toplevel（xlsx 列） | 含义 | 后续动作 |
|------------------|------------------------|------|---------|
| TRUE | `false` | 无顶层代码 | 天然可 lazy，直接进 safe 候选 |
| FALSE | `true` | 有顶层代码 | 需副作用预判（`references/lazy_safety_rules.md`） |
| MAYBE | `maybe` | 存疑 | 按预判规则读码细化，无法确认 → unknown |

## 1. per-file 自身判定 (own)

逐文件给出 `own ∈ {false, maybe, true}`，仅看该文件自身代码（不含 import）。

### 1.1 CLEAR YES → own = false（明确 import 时执行）

| # | 类别 | 判定 | 示例 |
|---|------|------|------|
| Y1 | 顶层控制流 | 顶层（不嵌在任何函数/类/方法体内）出现 `if/for/while/do/switch/try/return/throw/break/continue/else/catch/finally` 语句 | `if (AppStorage.get('X') === true) { ... }` |
| Y2 | 顶层表达式语句 | 顶层语句以 **调用 / `new` / 赋值 / 自增自减 / `await`调用** 形式出现（非声明） | `console.info('Module loaded!');`（官方示例，导入时立即执行）<br>`AppStorage.setOrCreate('k', false);`<br>`FooResourceConverter.initMaps();` |
| Y3 | 顶层变量初始化含函数调用 | 顶层 `const/let/var` 初始化器：含**非-new 的函数调用** → YES；或 `new X()` 且该变量被 `export` → YES。**例外**：`new` 容器且变量**未导出、仅模块内使用** → 无副作用分配，不计（benign）。**多行初始化器**（`const A = [\n { x: f(1) }\n];`）自声明行累积到括号/花括号配平后**整体分类**，嵌套在数组/对象字面量内的调用同样命中 | `const x = compute();`→YES<br>`export const m = new Map();`→YES<br>`const m = new Map();`(未导出)→不计<br>`export const T = [{ label: fmt(60) }];`→YES |
| Y4 | 类 static 字段初始化含 new/调用 | 类体内 `static` 字段初始化器含 `new` 或函数调用 | `static delegate = new FooTransition();` |

> 模板字面量内含调用并入 Y2/Y3：`const x = \`a${f()}\`` → `f()` 为调用 → Y3。

### 1.2 MAYBE → own = maybe（存疑：装饰器）

| # | 类别 | 判定 | 示例 |
|---|------|------|------|
| M1 | 装饰器（非白名单） | 出现**非白名单** `@装饰器`（类级 `@Component/@Entry/@Reusable/@Builder` 或成员级 `@State/@Prop/@Expose/@Transform/@Watch/@StorageProp` 等）。装饰器在类定义（import）时求值，是否计入 top-level 存疑，判 maybe | `@Component export struct X {}` |

> **装饰器副作用白名单**（`@concurrent` 等）：类定义时求值但**无副作用**的装饰器不计 maybe。默认含 `@concurrent`；脚本可经 `--no-side-effect-decorators @A,@B` 扩充。

### 1.3 CLEAR NO → 不计入（仅这些且无 Y/M 命中时 own = true）

- `import` / `export`（含 re-export / `export default 声明`）
- `function` / `class` / `struct` / `interface` / `type` / `enum` / `namespace` 声明
- 顶层 `const/let/var` **无初始化器** 或 **字面量**初始化器（`const TAG='x'`、数组/对象字面量且无调用）
- 类 `static` 字段**字面量**初始化器
- 类**实例**字段初始化器（含 `= new X()`）—— 实例化时才执行，非 import 时，不计
- 箭头函数值（`const f = () => {...}`）—— 仅定义，不执行

### 1.4 own 汇总

```
own = false   若命中任意 Y1–Y4
    = maybe   若未命中 Y 但命中 M1
    = true    否则
```

## 2. 递归 import 闭包判定

### 2.1 import 跟随规则

| import 形式 | 处理 |
|-------------|------|
| `import lazy {...} from 'SPEC'` | **不跟**（lazy 模块在 import 时不加载） |
| `export ... from` / 普通 `import ... from` / `import 'SPEC'` | 按 SPEC 类型处理（见下） |

### 2.2 SPEC 解析与分类（resolver.py）

| SPEC 类型 | 处理 | 对结果的贡献 |
|-----------|------|-------------|
| 相对路径（`./` `../` `/`）解析到本地 `.ets` | 跟入递归 | 子节点 verdict |
| 本地源码模块 bare 名（oh-package.json5 `name` 映射） | 跟入其入口 ets | 子节点 verdict |
| 根 `oh-package.json5` `overrides` 中 `file:` 值 | 重定向到本地路径入口，跟入 | 子节点 verdict |
| ohpm 包（`@group/*` 等）且 `oh_modules/<spec>/` 有 `.ets` 入口 | 跟入 | 子节点 verdict |
| 系统模块（`@kit.` / `@ohos:` / `@hms:` / `@native:` 前缀） | **跳过**（无源码） | 无贡献 |
| 其余无法解析 / 无 `.ets` 源码（预编译 HAR） | 无法判定 | **maybe** |

### 2.3 综合

设 F 的 `own` 与所有跟入子节点 verdict 集合为 `C`（环：访问中再次遇到 → 视作 TRUE）：

```
verdict = FALSE  若 own == false 或 C 含 FALSE
        = MAYBE  否则若 own == maybe 或 C 含 MAYBE
        = TRUE   否则
```

> 取"最差者"：有 FALSE→FALSE；无 FALSE 但有 MAYBE→MAYBE；全 TRUE→TRUE。

## 3. 边界与已知限制

- 解析器为启发式：多行 `const/let/var` 初始化器已按括号配平累积整体分类；其余**多行语句/嵌套表达式**仍可能有偏差；遇到不确定行**保守不计 YES**（宁漏报不误报），agent 复核时按本规则人工判断。
- 磁盘缓存（`analyze_report.py --cache`）带 `_version`（= `check_toplevel.DETECTION_VERSION`）；检测规则变更会 bump 版本，旧缓存自动失效并重查。
- 装饰器（M1）是唯一 maybe 来源（自身层面）；预编译 HAR 无源码 → 闭包层面 maybe。
