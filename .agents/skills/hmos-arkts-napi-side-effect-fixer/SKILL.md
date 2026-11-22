---
name: hmos-arkts-napi-side-effect-fixer
description: "鸿蒙 ArkTS NAPI 模块 import（dlopen）副作用端到端技能：扫描识别（prescan 初筛/深析 + rulebook 语义判定，输出问题行号、白话判定原因）＋ 整改落地（类别2 加载期重初始化全局单例改惰性访问器；类别1 注册函数违规业务逻辑迁显式 init() 导出）＋ 回归验证（残留清零 + 编译运行验证）。当需要审查 NAPI so import 副作用、排查启动耗时劣化/多页面全局状态不一致、检出的副作用问题需要整改、或整改后回归验证时使用。"
license: MIT
metadata:
  version: "4.0.0"
  keywords:
    - NAPI
    - import副作用
    - dlopen
    - 静态初始化
    - 注册函数
    - 冷启动优化
    - 启动耗时
    - 惰性单例
    - 整改
---

# HarmonyOS ArkTS NAPI Import 副作用：扫描 → 整改 → 回归（端到端）

## 技术概述

NAPI 模块（.so）一旦被 dlopen，其 TopLevel C++ 代码**立即执行**：`__attribute__((constructor))` 修饰函数、`napi_module_register`、注册回调 `nm_register_func`（回调名从注册点字段/宏参数解析，无命名惯例）、以及 C++ 全局静态对象构造函数——不等 ArkTS 调用导出函数才执行。

注册链中的业务动作与加载期初始化直接计入启动路径，转化为启动耗时与全局状态不一致。

本技能提供**端到端闭环**（原扫描端 v2.3.0 与整改端 v3.1.x 合并）：

```
阶段 1：扫描（只读）
  prescan.py <目录|文件>          初筛：路径过滤/注册链要素/形态A信号/回调定位/
  │                               模块归属五档/双不变量基数
  prescan.py <path> --deep        深析底稿：调用链全展开+消歧/CAT1信号/形态B词法路由
  │                               （自动分片；追深触发检查）
  语义判定（rulebook.md）          成本三级 → S-24 归属门控 → 整改映射
  │                               公开通用 API 按 §2 速查表直判
  ▼
  白话报告（R-01/R-02 格式，开发者零上下文可读）
  │  检出两类问题：
  │    · 类别1：注册函数违规业务逻辑（耗时）——Init 回调内业务动作
  │    · 类别2：加载期重初始化——全局单例 so 加载即创建
  ▼
阶段 2：整改（默认 dry-run，确认后 --apply）
  parse_scan_report.py            解析阶段1产出 → 整改工作清单（保留扫描问题编号，
  │                               类别路由：类别2→引擎L / 类别1→引擎E；AUTO/MANUAL 分流）
  apply_lazy_init.py              引擎 L（类别2）：变量名源码重定位 → 闸门 G1–G8 →
  │                               惰性访问器改写（形态A 声明原位替换 / 形态B 初始化块迁 call_once）
  apply_init_extraction.py        引擎 E（类别1）：注册回调定位 → 语句级分类
  │                               （KEEP 导出面 / MOVE 业务动作 / 纠缠保留 / 形态B 分流 /
  │                                 保留信号第三出口降级）
  │                               → 闸门 H1–H7 → 业务语句迁显式 init() 导出（call_once 包装）
  │                               → 三种注册风格自动挂载
  │                               （执行顺序：先 L 后 E——形态B 守卫块先惰性化）
  ▼
阶段 3：回归
  verify_fix.py                   残留候选清零门禁（类别2 形态A/B + 类别1 MOVE 语句）
  ＋ 编译验证 ＋ 运行期验证清单
  ▼
阶段 4：报告
  整改报告（问题编号回溯 #n / 前后对照 / 闸门结果 / 回归结论 / ArkTS 集成状态）
```

两个引擎共用框架路径黑名单（E-14）：ace_engine 高级组件接口 / ets_runtime / napi native_engine / module_manager 命中即硬拒改（框架生命周期设计，非业务初始化违规）；引擎 L 附加生命周期警示（析构含 napi_* / 构造含 throw）。

## 使用场景

- ✅ NAPI so import（dlopen）时副作用审查（基于 dlopen 即执行的默认 import 模型）
- ✅ 排查启动耗时劣化（so 加载即执行的初始化链）/ 多页面组件全局状态不一致
- ✅ NAPI C++ 代码合入评审（import 副作用影响评估）
- ✅ 对检出的「类别2：加载期重初始化」落地整改（全局单例改首次使用时创建）
- ✅ 对检出的「类别1：注册函数违规业务逻辑」落地整改（Init 内业务初始化迁显式 `init()`）
- ✅ 整改后回归验证（残留清零）与编译运行保障

## 整改的问题形态（阶段 2 的输入，与阶段 1 术语一致）

### 场景 1（类别2：全局单例即时初始化）——引擎 L

1. **形态A：文件作用域动态初始化器**——so 加载即构造业务对象：
   ```cpp
   static Database* g_db = new Database("/sandbox/db");            // 裸指针
   std::unique_ptr<Manager> g_mgr = std::make_unique<Manager>();  // 智能指针
   auto g_ctx = new PacketCallbackCtx();                          // auto
   ```
2. **形态B：注册回调内全局赋值**——注册链内创建：
   ```cpp
   static Database* g_db = nullptr;
   static napi_value Init(napi_env env, napi_value exports) {
       g_db = new Database("/sandbox/db");   // 模块加载（import）即触发
       return exports;
   }
   ```
3. **形态C：注册链内创建、不落全局变量**——引擎无法自动改写，分流 MANUAL。

**整改形态**（不改 JS 侧）：声明替换为**惰性初始化**（通过惰性访问器实现：Meyers 单例 / `std::call_once`），
全部使用点改经访问器，初始化从模块加载推迟到首次业务调用。

### 场景 2（类别1：注册函数违规业务逻辑）——引擎 E

**规范**：`nm_register_func` 的 Init 回调尽量只做函数映射（构建导出面），
业务初始化挪到显式导出的 `init()` 接口，由 ArkTS 侧首次使用前调用一次。

```cpp
// 改写前（so 被 dlopen 即执行业务初始化）：
static napi_value Init(napi_env env, napi_value exports)
{
    RegisterCustomBrightness();                 // ← 业务初始化（MOVE）
    napi_property_descriptor desc[] = { … };    //   函数映射（KEEP）
    napi_define_properties(env, exports, …);    //   函数映射（KEEP）
    return exports;
}

// 改写后（Init 只留函数映射；业务初始化进显式 init() 导出）：
// 业务初始化（原位于注册回调 Init L24——类别1：注册函数违规业务逻辑）。
// 由 ArkTS 侧在首次调用本模块其他接口前显式调用一次 init()。
static napi_value ExplicitInit(napi_env env, napi_callback_info info)
{
    static std::once_flag onceFlag;
    std::call_once(onceFlag, [&] {
        RegisterCustomBrightness();             // ← 原样搬迁（verbatim）
    });
    napi_value result = nullptr;
    napi_get_undefined(env, &result);
    return result;
}
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { … },
        DECLARE_NAPI_FUNCTION("init", ExplicitInit),   // ← 自动挂载
    };
    napi_define_properties(env, exports, …);
    return exports;
}
```

**ArkTS 侧集成（必做，人工执行）**：

```ts
import imageEffect from 'libentry.so';
imageEffect.init();          // 首次调用其他接口前执行
imageEffect.PixelMapFilterStart(…);
```

## 工作流程

> 阶段 1 **只读**被检工程；阶段 2 默认 dry-run，写入仅发生在用户确认后（`--apply`）。禁止任何 git 操作（add/commit/push 由用户执行）。

### 阶段 1：扫描（只读）

#### 1.0 输入解析与路径过滤

1. 解析输入：目录或单个 C++ 文件。
2. **S-1**：路径不存在 → `❌ 路径不存在：<path>`，终止。
3. **S-2**：无 C++ 文件 → `未发现 NAPI 相关代码`＋统计，终止。

#### 1.1 批量初筛（必须走 prescan）

**必须执行 `python3 scripts/prescan.py <目录或文件>`**——单次调用完成路径过滤、注册链要素检索、形态A 列首信号（含 ns 收割）、注册点解析与回调定位（含头文件 include-follow/UNRESOLVED）、模块归属清单（M-27 五档），并输出双不变量基数。仅当脚本不可用按 rulebook §4 手工回退。UNRESOLVED 按 rulebook §4.4 待人工确认，禁止静默跳过。`extract_register_chain.py` 为 prescan 的**库层依赖**（非独立回退）。

#### 1.2 语义深析（`--deep` 工作包为底稿）

`prescan.py <path> --deep` 生成深析底稿（调用链全展开＋同名消歧标注、CAT1 信号扫描、形态B 词法路由、干净链压缩）。**命中链 ≥ 10 或底稿 > 40KB 时自动分片**。

**追深触发检查（必做）**：底稿含「⚠️ 深度饱和警告」且最深层命中类含**线程/IPC/dlopen/进程级注册** → 必须以 `--chain-depth <max_level+1>` 复扫（预算 1 次）。

1. **并行复核（分片模式必须并行）**：同一条消息内并行派发全部分片子代理（一片一代理），指令模板：「读取 <分片路径> 与 rulebook.md——§1 判定总览＋§2 S 层＋§4 M 层，按规则册逐链复核并返回结构化结论（链/结论/条目：类别、文件:行、判定依据（引用规则 ID）、整改方向、动作链关系标注——R-11 合并用）；只判定，不改代码，不回读分片外的源文件」。
2. **复核信息边界**：语义判定只依据底稿/分片内联信息——禁止回读源文件；例外仅限：归属存疑核对定义、UNRESOLVED 的 include-follow、外部符号成本定位。
3. **中间结果固化**后再进判定阶段。

#### 1.3 统一成本判定

对每个候选按 rulebook §2 执行（**成本先行、归属惰性**）：成本三级 → 成本=重者执行 S-24 归属门控（M-27 T1/T2＝在 import 路径 → 需整改；待核 → 需确认；范围外 → 附注）→ 整改映射 → 边界兜底。**公开通用 API（C++ 标准/POSIX/语言级）按 §2 速查表直接定级，不转人工**；平台/厂商 API 维持待确认。

**注意：S-02 动作族与 M-19 信号命中只是候选线索，不是重档结论。**每个命中必须显式查 S-07/S-08/S-09 并留下依据；`signal`/`sigaction` 仅函数指针/POD/系统调用时按速查表判**轻量 → 不计问题 → 模块结论 `✅ NAPI OK`**——**禁止用"危险/影响面大"的直觉替代成本判定**（成本轴是加载耗时，不是风险影响面）。**E-15 保留信号第三出口（fix-patterns §8.10）仅属阶段 2 整改**（已判定需整改后的语句分类），**绝不影响阶段 1 扫描判定**——扫描阶段 sigaction 轻量即结案，不出现在问题清单中。

**实现不可见禁止命名推断**：候选动作定义不在检查范围（仅外部声明）时，**禁止凭函数命名**（如 `create_native_global_singleton`/`init_*`/`register_*`）**推断「结构性违规」而直接判 `❌ 需整改`**；必须按 S-09 输出 `⏳ 需确认`，显式出现「人工确认」字样并给出「定位实现函数体后按耗时定级」复核建议。函数名不构成实现可见性证据——命名暗示的业务语义不能替代成本定级。

**汇总期批量例外核查**（按簇 3~6 轮，禁止逐条串行）：① 外部符号成本定位（每簇定位 1 个代表实现，整簇适用）；② 归属实证（sa_profile libpath 核对 → 整簇结案）；③ 归属存疑核对。每簇结论压缩为一行卡点入报告『判定轨迹』段。

#### 1.4 汇总与报告

1. **双不变量核对**：文件级＋回调级＋模块归属五档——不一致必须补扫；
2. **相邻合并＋动作链合并**：rulebook §3 R-05＋R-11；
3. **结论汇总**：R-03/R-04（成本×归属二维、单调汇总）；
4. 按 rulebook §3 输出报告。**报告全文开发者白话**（§3.11 对照表翻译，正文禁止规则 ID）；判定轨迹简版三段式。
5. **档位 token 强制输出**：模块结论与文件结论**必须原样输出规范档位 token**——`❌ 需整改`/`⏳ 需确认`/`✅ NAPI OK`；**禁止用自然语言改写**（如「未发现副作用」「干净模块」「无问题」等）。干净模块结论段必须出现字面 token `✅ NAPI OK`。
6. **导出面构建排除说明**：注册回调内的 `napi_get_undefined`/`napi_wrap`/`napi_set_named_property`/`napi_define_properties`/`napi_create_function` 等属导出面构建（S-03），不计为副作用——报告须显式说明此类调用已排除复核。

#### 1.5 落盘询问

报告输出后主动询问是否保存为 markdown；默认不落盘。**若用户要求继续整改，报告/深析底稿直接作为阶段 2 输入**。

### 阶段 2：整改（dry-run → 确认 → --apply）

#### 2.0 输入解析

1. 输入（按优先级）：
   - 阶段 1 的**最终检查报告**（R-01/R-02 格式，含【类别1】/【类别2】段）；
   - 阶段 1 的 **prescan `--deep` 深析底稿**（**类别1 的信号命中行仅 `--deep` 输出里有**——E-8）；
   - 无报告时的直接目标：`--target <文件>:<行号>[:<变量名>]`（可多次，走引擎 L）。
2. **E-1**：输入文件不存在 → `❌ 输入文件不存在：<path>`，终止。
3. **E-2**：解析后无 AUTO/MANUAL 条目 → 空清单说明，终止。

#### 2.1 解析产出 → 工作清单（按类别路由）

```bash
python3 scripts/parse_scan_report.py <扫描报告.md 或 prescan深析底稿.md> \
    [--target <文件>:<行[:变量]] [--json] [--root <仓库根>]
```

- 自动识别格式：R-02 报告条目（问题 #n + 📍 文件:行 + 代码片段）、
  prescan 形态A 候选段（`- L<行> [P1] <文本>`）、prescan 全局赋值候选行
  （`- [R2表命中(本文件L38)] <文件>:<行> <片段>`）、prescan 类别1 信号命中行
  （`- [进程级回调注册[/exports]] <文件>:<行> <片段>`）；
- **路径解析**：相对路径条目需在仓库根运行解析器，或加 `--root <仓库根>`；
- **类别路由**：类别2 解析出全局变量名 → AUTO（引擎 L，按变量名重定位）；
  解析不出（典型形态C）→ MANUAL。类别1（文件存在）→ AUTO（引擎 E）；不存在 → MANUAL；
- **执行顺序**：批量 `--fix` 时先引擎 L 后引擎 E——形态B 守卫块先惰性化
  （组合规则见 fix-patterns.md §8.6）；
- 保留扫描问题编号供回溯。

#### 2.2 引擎 L——类别2 惰性初始化（惰性访问器改写，先 dry-run）

```bash
python3 scripts/apply_lazy_init.py <文件> --var <变量名> [--root <仓库根>] [--check]
# 或批量：python3 scripts/parse_scan_report.py <报告> --fix [--root <仓库根>] [--check]
```

1. **按变量名源码重定位**（不依赖报告行号）；
2. **判定形态**（A：动态初始化器；B：注册回调内赋值）；
3. **安全闸门 G1–G8**（fix-patterns.md §4）：G1 无其他写入点 / G2 无同名局部遮蔽 / G3 链接性 / G4 形态B 初始化体自包含 / G5 变量形态 / G6 无取地址与 delete / G7 访问器名无冲突 / G8 形态A 单一语句；
4. **策略**：auto → 读模块 BUILD.gn，含 `-fno-threadsafe-statics` → call_once，否则 meyers；形态B 固定 call_once；
5. **改写**＋`#include <mutex>` 自动补齐；
6. **自校验**：旧变量名残留引用 = 0、括号配平、`--check` 语法检查。

**逐条人工审阅 diff**：访问器作用域与原声明一致；形态B 初始化块完整迁入无残留；使用点替换无遗漏。

#### 2.3 引擎 E——类别1 迁显式 init()（先 dry-run）

```bash
python3 scripts/apply_init_extraction.py <文件> \
    [--callback <注册回调名> | --at-line <行号[,行号…]>] \
    [--init-name init] [--func-name ExplicitInit] \
    [--check] [--js-root <ArkTS源码目录>] [--no-once]
```

1. **定位注册回调**：`--callback` ＞ `--at-line`（多行号逐个尝试，E-9）＞ 文件内首个；
2. **语句级分类**（对齐 rulebook S-02/S-03/M-19/M-23）：
   - **KEEP**：napi 导出面 API、实参含 exports 的调用、exports 数据流局部变量、同文件被调函数体只含 napi 面 API、日志、判空守卫、return；
   - **MOVE**：命中 M-19 信号（进程级回调注册/线程/文件IO/连接/信号处理器/事件循环/IPC/`std::call_once`/`ffrt::submit`）或业务动词族且无 KEEP 依赖；**原样搬迁**；
   - **SKIP_FORMB**：回调内全局赋值 → 分流引擎 L；
   - **纠缠**：引用 KEEP 局部变量 / 纠缠簇 → 保留原位＋人工指引；
   - **未命中（?）**：保守保留＋待复核。
3. **安全闸门 H1–H7**：H1 至少一条可迁移语句（幂等）/ H2 不引用 exports 与 KEEP 局部变量 / H3 无 return/break/continue / H4 init 名无冲突（自动重试 initModule/moduleInit/lazyInit）/ H5 注册风格可识别 / H6 回调可定位可提取 / H7 改写自校验；
4. **生成 init() 导出**：`ExplicitInit`（冲突自动加序号）＋ call_once 包装（默认）＋ 三种注册风格自动挂载（描述符数组 / BindNativeFunction / napi_create_function+set_named_property）；
5. **ArkTS 侧集成定位**（`--js-root`）：输出「首次调用前补 `xxx.init()`」指引（**不自动改 JS 代码**）。

**逐条人工审阅 diff**：迁移语句集合与分类表一致；init 挂载位置与注册风格一致；迁移语句原本在 call_once 内会被双层包装（语义不变，可 `--no-once`）。

#### 2.4 写入

确认 diff 后加 `--apply`。闸门未通过时引擎拒绝写入。写入后保持**未暂存、未提交**；提交由用户执行。

**类别1 写入后必须完成 ArkTS 侧集成**（否则业务功能不会初始化）。

### 阶段 3：回归验证

```bash
python3 scripts/verify_fix.py <整改后的文件或目录> [--callback <回调名>]
```

- 类别2 残留候选（形态A/B）＋类别1 残留 MOVE 语句全部清零 → `✅ 回归通过`（exit 0）；
- 跨文件注册回调：加 `--all-tu --callback <回调名>`；
- 已知输入盲区：prescan P1 正则不匹配 `Type *name` 风格——用 verify_fix.py 复扫补充定位后经 `--target` 纳入。

**编译与运行验证**（按工程类型）：

| 工程类型 | 验证命令 |
|---|---|
| OpenHarmony 系统仓（GN/ninja） | `./build.sh --product-name <产品>` 或 `ninja -C out/<产品> <module>` |
| DevEco 应用 | DevEco Studio 构建或 `hvigorw --mode module -p product=default assembleHap` |
| 单文件快速验证 | `clang++ -fsyntax-only -std=c++17 <文件>` |

**运行期验证要点（必须逐项确认）**：

类别2：
- [ ] import 模块后未调用任何接口时，单例未创建；
- [ ] 首次调用业务接口后单例创建且行为正常；
- [ ] 并发首次调用无崩溃、单例唯一；
- [ ] 多页面往返使用同一模块无功能异常。

类别1：
- [ ] import 后未调 `init()` 时业务初始化未执行（零副作用）；
- [ ] 调用 `init()` 一次后各业务注册/初始化各执行一次；
- [ ] 重复调用 `init()` 幂等；
- [ ] 导出面完整（原全部接口 + `init`）；业务接口在 `init()` 后正常。

### 阶段 4：整改报告

对每处整改输出：扫描问题编号（回溯 #n）、改写前后代码、类别与引擎、形态/策略、闸门结果、回归验证结论；MANUAL 条目与闸门拒绝项列出原因与人工整改指引（fix-patterns.md §5/§9）；类别1 条目附 ArkTS 侧集成状态。

## 策略矩阵（类别1 适用性）

| 模块类型 | nm_modname 形态 | 策略 E（显式 init） | 说明 |
|---|---|---|---|
| 应用工程内模块 | `entry` / libentry.so | ✅ 安全推荐 | 调用方在同工程，JS 侧同步修改即可 |
| 系统/公共 kit | `xxx.yyy.zzz`（如 `bundle.bundleManager`） | ⚠️ API 兼容性破坏 | 消费方不会主动调 `init()` → 建议改用策略 L，或版本演进中引入 `init()` 并保留惰性兜底 |

## 边界行为

### 扫描阶段（S-）

| 编号 | 场景 | 行为 |
|---|---|---|
| S-1 | 路径不存在 | `❌ 路径不存在：<path>`，终止 |
| S-2 | 无 C++ 文件 | `未发现 NAPI 相关代码`＋统计 |
| S-3 | 成本不可判定 | 列入待人工确认；模块结论为需确认 |
| S-4 | 单文件输入 | 按文件粒度报告；注明"单文件模式" |

### 整改阶段（E-）

| 编号 | 场景 | 行为 |
|---|---|---|
| E-1 | 输入文件不存在 | `❌ 输入文件不存在：<path>`，终止 |
| E-2 | 解析后无条目 | 输出空清单说明，终止 |
| E-3 | 引擎 L 找不到变量声明 / 形态无法判定 | `❌ G0 …`，退出码 2，不写文件 |
| E-4 | 安全闸门未通过 | 列出全部未过闸门与人工整改指引，拒绝改写 |
| E-5 | --check 无可用编译器 | 打印「跳过语法检查」，其余校验仍执行 |
| E-6 | --apply 时残留引用未清零 | 拒绝写入，退出码 5 |
| E-7 | 回归验证仍有残留候选 | `❌ 回归未通过`＋残留清单，exit 1 |
| E-8 | prescan 不带 --deep | 输出无类别1 信号命中行 → 类别1 清单为空（需 `--deep` 深析底稿） |
| E-9 | 类别1 信号行落在辅助函数体内 | 引擎尝试全部行号定位回调；均失败 → 转 H6 人工 |
| E-10 | 回调无可迁移语句 | `H1 无可迁移语句——回调已是「仅函数映射」`（幂等），不改写 |
| E-11 | 迁移语句与 exports 挂载对象纠缠 | 保留原位＋人工指引（fix-patterns.md §9） |
| E-12 | `init` 导出名冲突 | 自动重试 initModule/moduleInit/lazyInit；全冲突 → H4 拒绝 |
| E-13 | 系统 kit 模块（nm_modname 含 `.`） | API 兼容性警示＋策略 L 建议；可继续（工程内部消费） |
| E-14 | 目标命中框架路径黑名单（ace_engine / ets_runtime / napi native_engine / module_manager） | 硬拒改（引擎 E 退出码 4 / 引擎 L 退出码 6）；转框架演进评审 |
| E-15 | MOVE 语句注册信号（signal/sigaction） | 信号号命中保留段（34..64/60/SIGRTMIN+n/MUSL_SIGNAL_*/同文件常量解析）→ 降级保留＋转设计评审「谁有权注册这个信号」；不可解析 → 保持 MOVE＋显著警示＋同进程信号冲突核对义务 |
| E-16 | 引擎 L 目标类型析构含 napi_* / 构造含 throw | 只警示不阻断（生命周期/行为差异警示）：人工核对 |

## 检查清单

### 扫描阶段
- [ ] prescan 已执行；命中文件/链全部复核（双不变量核对通过）
- [ ] 追深触发已检查（饱和警告含 IPC/线程/dlopen/进程级注册 → 已复扫 1 次或已声明边界效应）
- [ ] 判定均出自 rulebook §2 并引用规则 ID（子代理内部），无自创规则
- [ ] 每个信号命中已逐条查 S-07/S-08/S-09 并留痕（含 `sigaction` 类降档为轻量的判定），未从候选线索直接跳到“需整改”
- [ ] 归属门控：轻量未做无谓归属确认；成本=重者完成三态判定
- [ ] 汇总期批量例外核查已按簇执行并留痕
- [ ] 报告全文开发者白话（无规则 ID，按 §3.11 翻译）；R-11 动作链合并正确
- [ ] 只读约束成立（除用户确认落盘外零写入）

### 整改阶段
- [ ] 阶段 1 产出已解析；问题编号保留（整改报告可回溯 #n）
- [ ] AUTO 条目逐条 dry-run，diff 已人工审阅（作用域/初始化块完整/使用点无遗漏/迁移语句集合与分类表一致）
- [ ] 安全闸门全绿（G1–G8 / H1–H7）
- [ ] 保留信号核对：E-15 第三出口语句已转设计评审裁决（谁有权注册这个信号），未当普通 MOVE 迁移
- [ ] 两族义务判定：init() 动作逐个判定 P1（时机敏感）/¬P1；ArkTS 集成位置与判定一致
- [ ] additive 缺失面盘点（类别1 迁移完成后）：未调 init() 的调用方逐个确认集成
- [ ] 写入后回归验证清零（verify_fix.py exit 0）
- [ ] 类别1：ArkTS 侧 `init()` 集成完成（首次使用前调用；同一线程，勿从 worker）
- [ ] 模块级编译验证通过
- [ ] 运行期验证逐项确认（类别2 4 项 / 类别1 4 项）
- [ ] 框架黑名单命中（E-14）时引擎已拒改，不手工绕过
- [ ] 工作区保持未提交状态，提交由用户执行

## 注意事项

- ⚠️ **阶段 1 只读**：扫描过程对被检工程零写入
- ⚠️ **判定唯一来源**：语义判定引用 rulebook（references/rulebook.md）§2/§3；机械规则语义见其 §4，实现权威＝scripts/prescan.py
- ⚠️ **保守兜底**：不可解析路径必须产出待确认条目，禁止静默判 OK；待确认 ≠ 需整改
- ⚠️ **候选 ≠ 结论**：S-02 动作族表与 M-19 信号表只回答“要复核什么”，不回答“重不重”；写不出引用的规则 ID 就说明没查表
- ⚠️ **防发散**：复核禁回读源文件（例外仅限归属核对定义/UNRESOLVED include-follow/外部符号成本定位）；干净链抽查上限 3；追深最多 1 次；批量核查按簇 3~6 轮
- ⚠️ **阶段 2 默认只读**：dry-run 不写任何文件；写入仅限目标源文件且在用户确认后
- ⚠️ **类别1 不自动改 JS/ArkTS 代码**：`init()` 集成是必做人工步骤——漏做导致业务功能不初始化（编译不受影响，运行期缺失）
- ⚠️ **类别1 仅适用应用工程内模块**：系统/公共 kit 的显式 `init()` 属 API 兼容性破坏——按策略矩阵选策略 L
- ⚠️ **形态B 必须整块搬迁**（类别2）：漏迁导致加载期空指针订阅或判空恒失败
- ⚠️ **纠缠簇不自动拆**（类别1）：只搬一半会编译失败——引擎降级保留＋人工指引
- ⚠️ **线程安全策略不可选错**：BUILD.gn 含 `-fno-threadsafe-statics` 必须 call_once（meyers 该选项下实测 16 线程 14/20 次构造多实例）
- ⚠️ **禁止裸判空**：人工惰性创建必须 `std::call_once` 或双检锁——无锁 `if (p == nullptr)` 并发首调竞态（fix-patterns.md §3.4/§5.1/§9.1）
- ⚠️ **env 纪律**：迁移的 napi_* 语句跟随 init() 调用线程；`init()` 在模块首次 import 的同一线程调用，勿从 worker
- ⚠️ **失败契约如实说明**：verbatim 迁移保留「忽略返回值」；调用方需感知失败按 fix-patterns.md §8.11 模板人工升级（EnsureBusinessInitActions + napi_throw_error）
- ⚠️ **框架路径不整改**（E-14）：框架加载期行为是设计使然，改动属框架演进评审
- ⚠️ **本技能不解决**：页面间可变状态残留；外部链接共享变量、类静态成员、多写入点单例、形态C、类别1 纠缠语句 → 人工整改（fix-patterns.md §5/§9）
- ⚠️ **已知限制**：自定义注册宏无法自动识别——用户已知时显式提示宏名纳入初筛

## 相关资源

- **[references/rulebook.md](references/rulebook.md)——扫描规则唯一权威**：§1 判定总览 / §2 S 层（S-01~S-24，含公开 API 速查表）/ §3 R 层＋§3.10 报告模板＋§3.11 白话对照表 / §4 M 层（M-01~M-27 语义本体＋实现锚点）/ §5 P 层索引
- **[references/fix-patterns.md](references/fix-patterns.md)——整改模式手册**：扫描产出解析格式、术语对齐（类别1/类别2/形态A/B/C）、访问器模板（A/B × meyers/call_once）、语义等价论证、G1–G8 闸门、人工整改指引（§5）、扫描盲区补充定位（§6）、类别1 整改模式（§8：语句分类规则、init() 导出模板×3 注册风格、H1–H7、策略矩阵、组合规则、保留信号第三出口、失败契约与两族）、纠缠语句人工指引（§9）、范围边界与警示（§10）、call_once 竞态实测数据
- **[references/real-cases.md](references/real-cases.md)——整改实测案例**：端到端整改实例（解析→引擎→回归验证）、正例前后对照、类别1 案例含 ArkTS 集成点、25/25 断言矩阵（含 8 线程并发首调）、v3.1.0 增强记录
- [scripts/prescan.py](scripts/prescan.py)——**扫描初筛＋深析底稿首选**：路径过滤/注册链要素/形态A 信号/回调定位/调用链全展开＋消歧/形态B 路由/模块归属五档/自动分片
- [scripts/extract_register_chain.py](scripts/extract_register_chain.py)——**文本处理库层**（`mask_source`/`find_function_def`/`extract_span`/`match_balanced`——prescan 直接 import）＋最小链提取 CLI（备用与 UNRESOLVED `-R` 跟进）
- [scripts/parse_scan_report.py](scripts/parse_scan_report.py)——**整改输入端**：解析阶段 1 产出 → 工作清单（类别路由，AUTO/MANUAL 分流，问题编号回溯）；`--fix` 批量驱动引擎（先 L 后 E）
- [scripts/apply_lazy_init.py](scripts/apply_lazy_init.py)——**引擎 L**：类别2 惰性访问器改写（G 闸门、残留校验、语法检查、框架黑名单拒改、生命周期警示、dry-run/--apply）
- [scripts/apply_init_extraction.py](scripts/apply_init_extraction.py)——**引擎 E**：类别1 迁显式 init() 导出（语句分类、H 闸门、三风格挂载、call_once 包装、保留信号第三出口分流、--js-root ArkTS 调用点定位、dry-run/--apply）
- [scripts/verify_fix.py](scripts/verify_fix.py)——**回归验证**：残留清零门禁（类别2 形态A/B + 类别1 MOVE 语句）；兼作 P1 盲区（`Type *name` 风格）补充定位
- [test-cases/functional.md](test-cases/functional.md)、[test-cases/trigger.md](test-cases/trigger.md)——扫描功能与触发测试用例
