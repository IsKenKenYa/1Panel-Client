---
name: hmos-jscrash-analysis
description: >
  DFX Skills，分析 HarmonyOS/OpenHarmony 应用的 JS Crash（ArkTS/JS 层闪退）faultlogger 日志，
  按 Reason、Error name、Error message、Error code 和 Stacktrace 定位根因，支持使用 SourceMap
  反解 release/混淆堆栈并给出修复建议。
  当用户提供包含 JS Crash、Reason:Error/TypeError/SyntaxError/ReferenceError/RangeError/
  BusinessError/OutOfMemoryError/URIError/TerminationError/AggregateError、Error message、
  Stacktrace、HybridStack、faultlogger、Cannot get SourceMap info 等字段的日志，
  或询问 HarmonyOS 应用启动/点击后闪退、ArkTS 崩溃、JS Crash 怎么定位、OOM 闪退原因时，
  必须使用此技能。确认崩溃原因为 OOM 且用户同时提供 rawheap 或 heapsnapshot 快照时，
  必须继续调用 jsleak-analysis Skill 分析快照。即使用户只说“帮分析这个 JS Crash 日志”
  “应用闪退了是什么原因”“ArkTS 报错导致崩溃怎么修”，也应立即触发此技能；如果日志是 cppcrash、
  freeze，或者用户询问的是原生/C++ 层崩溃，且没有 JS/ArkTS 错误字段，则不该调用此技能。
metadata:
   author: Huawei Reliability Technology Lab
   version: 1.4.0
---

# JS Crash Analysis

## 目标

系统化分析 HarmonyOS / OpenHarmony 应用 JS Crash 日志，输出基于证据的根因、责任代码位置和应用侧修复建议。分析必须以日志真实字段为依据，不得编造未出现的堆栈、错误码或业务路径。

## 工作流

0. SourceMap 反解环境检查
   - 仅在调用 SourceMap 反解时执行本检查，普通 JS Crash 分析不依赖 `hstack`。
   - 先执行 `node --version`，确认 Node.js 可用；仓库已内置完整 `hstack` 工具，无需另行安装 npm 依赖。
   - Windows 执行 `"<skill-root>\scripts\hstack\bin\hstack.bat" --help`；Linux/macOS 执行 `"<skill-root>/scripts/hstack/bin/hstack" --help`。
   - 若 Node.js 缺失、启动脚本不存在、`lib/index.js` 或 `lib/mappings.wasm` 缺失，停止反解并明确报告缺失项，不得将 raw stack 标记为已反解。

1. 提取关键信息
   - 如果用户给了文件路径，读取文件内容并提取 `Reason`、`Error name`、`Error message`、`Error code`、`page`、`Stacktrace`、`Uid/Pid`、故障时间。
   - 如果用户直接粘贴日志，手动提取上述关键字段。
   - 保留原始 `Error message` 和最靠前的应用栈帧作为证据。

2. SourceMap 反解门禁
   - **源码可达性检测（反解前必须执行）**：在当前工作目录（及父目录）中查找以下标志文件：`build-profile.json5`、`oh-package.json5`、`AppScope/app.json5`。若找到，读取 `AppScope/app.json5` 中的 `bundleName` 字段，与 faultlog 中的故障进程名（`Module name` 或 `processName`）对比，若一致即源码可达；若不一致或未找到标志文件，视为源码不可达，跳过 SourceMap 反解，在报告中标注"源码不可达，SourceMap 反解未执行"。
   - 分析调用栈前先判断其是否已还原到源码。出现 `Cannot get SourceMap info, dump raw stack`、构建缓存路径、混淆函数名，或行列号无法对应源码时，视为未完成 SourceMap 反解。
   - 用户提供与故障版本匹配的 `sourceMaps.json`、SourceMap 归档目录或工程构建产物时，读取 `references/sourcemap-symbolication.md`，优先使用仓库内置 `scripts/hstack/` 生成反解后的堆栈，再继续根因分析。
   - 反解前必须先做 UUID / 构建指纹校验：比对故障日志中的 `Fingerprint`（构建指纹/UUID 字段）与 SourceMap 产物携带的构建指纹（如 `build-info.json` 或 sourcemap 元数据 `fingerprint`）。一致才允许反解；不一致时不得使用该产物，按“未提供匹配 SourceMap”处理，并要求补充与故障构建指纹一致的映射产物。
   - 启用了名称混淆时，同时使用同一构建产物中的 `nameCache.json` 还原方法名。SourceMap、nameCache、应用版本、VersionCode、product、模块、构建模式和构建指纹必须匹配，不得混用不匹配版本的映射文件。
   - 后续应用帧、源码位置和责任代码判断以反解后的堆栈为主，同时保留原始栈帧作为证据。若反解结果未产生有效应用源码帧，不得标记为反解成功。
   - 用户未提供 SourceMap 时仍可使用 raw stack 初步分析，但必须标记“未反解”、降低源码定位可信度，并将补充匹配版本 SourceMap 后重新分析作为第一项建议。

3. 分类故障类型
   - 以 `Reason` 为第一分类键；缺失时用 `Error name`；两者都缺失时用 `Error message` 关键词推断，并标注可信度降低。
   - 常见类型：`ReferenceError`、`TypeError`、`Error`、`BusinessError`、`SyntaxError`、`RangeError`、`OutOfMemoryError`、`URIError`、`TerminationError`、`AggregateError`。

4. 匹配错误模式
   - 优先读取 `references/fault-mode-library.md`，按 `Reason` / `Error name` / `Error message` 匹配 JSError 三级根因。
   - 再读取 `references/jscrash-patterns.md`，补充未覆盖错误的根因解释与修复建议。
   - 若堆栈中出现`librnoh.so`、TurboModule、NAPI Promise 相关帧，优先读取`references/react_native.md` 匹配RN/RNOH专利案例库。
   - 多个模式命中时，优先选择与完整 `Error message`、`Error code` 和栈顶应用帧同时吻合的模式。
   - 不要只凭 Reason 下结论；同一个 Reason 下有多种完全不同根因。
   - 最终报告必须输出“故障模式库匹配”表，字段与 `references/fault-mode-library.md` 对齐：一级根因、二级根因、三级根因、Error message 模式、匹配依据。

5. 分析堆栈
   - 优先定位第一个应用栈帧，例如 `entry|entry|...|src/main/ets/...:line:column` 或 `entry/src/main/ets/...:line:column`。
   - 框架栈（如 `stateMgmt.js`、`json_js.js`、`js_url.js`、`js_uri.js`）只用于判断触发框架，不作为应用根因。
   - 如果 SourceMap 不可用，才降级使用 raw stack 中的应用路径、行号和调用链；不得把构建缓存路径或未验证的行列号表述为已确认源码位置。

6. 形成根因
   - 说明触发路径：哪个接口/组件/变量/参数/资源/文件/URL/递归/内存分配触发了异常。
   - 区分"应用未捕获异常导致进程崩溃"和"框架主动抛出明确错误"。大多数 JS Crash 的修复都在应用侧。
   - 对 `OutOfMemoryError`，判断堆栈是否稳定：稳定堆栈偏向高频调用或泄漏路径；不稳定堆栈需通过 Snapshot 对比泄漏对象。已上架应用市场的应用通常不能使用 Snapshot 分析模板。
   - **源码级修复建议要求**：当 SourceMap 已反解并定位到源码位置（文件:行:列）时，【修复建议】必须给出源码级修复建议——具体到文件:行:列、函数名和修改方案，不得仅停留在模块级或泛化描述。

7. OOM 快照联动分析
   - 仅当日志已由 `Reason`、`Error name` 或 `Error message` 明确定性为 `OutOfMemoryError` / OOM，且用户同时提供 `.rawheap` 或 `.heapsnapshot` 文件时，必须调用 `jsleak-analysis` Skill 继续分析，不要只建议用户自行分析快照。
   - 先完成 JS Crash 日志定性，再按 `jsleak-analysis/SKILL.md` 的流程处理快照。输入为 `.rawheap` 时先执行 rawheap 转换；输入为单快照、多快照或不同版本快照时，分别选择 JS Leak Skill 对应的分析模式。
   - JS Crash 日志与快照应属于同一进程、同一问题场景或用户明确指定的对照场景。若 PID、时间或应用信息无法对应，仍可分析快照，但必须说明关联关系未经确认，不能直接把快照中的疑似泄漏对象认定为本次 OOM 的根因。
   - 联动结果必须同时保留 Crash 证据与快照证据：Crash 部分说明 OOM 的直接触发信息，JS Leak 部分给出最严重的疑似泄漏对象、Retained Size、强引用链和一级/二级/三级根因。
   - 只有快照证据能解释 OOM 的内存增长时，才能将对应对象定为根因；证据不足时写明“疑似泄漏对象”，不要把相关性表述成因果关系。
   - OOM 但未提供快照时，只完成 JS Crash 分析并说明需要补充的快照类型；提供快照但 Crash 并非 OOM 时，不自动调用 JS Leak Skill，除非用户明确要求分析快照。

## 输出格式要求

分析完成后，参考 `cppcrash-analysis` 的结构输出结论，并强制呈现故障模式库的三级根因匹配结果：

- **可信度判定指引**：当 `Reason`、完整 `Error message`、`Error code` 和栈顶应用帧均支持同一模式时，可信度判定为 HIGH；缺少错误码或栈帧但 `Reason` 和 `Error message` 明确命中模式时为 MEDIUM；只有片段化日志或需结合业务代码/SourceMap 才能确认时为 LOW。
- **多假设保留**：当根因无法完全确定（如缺少 SourceMap、缺少业务代码或错误信息模糊）时，【根本原因】必须列举多种可能并标注各自依据，不得仅给出单一结论。
- **Error code 系统含义**：当日志中存在 `Error code` 时，必须在故障模式库匹配的匹配说明中解释该错误码的系统含义（如"HarmonyOS 系统通用参数错误码"），并说明其与 `Error message` 的一致性，作为佐证。
- **调用栈全帧展示**：当 Stacktrace 帧数 ≤15 时，证据链§3 必须展示全部帧并逐帧添加行内注释（如 `← 参数解析与校验`、`← NAPI 桥接入口`），不得仅展示关键帧而省略其余帧。帧数 >15 时可仅展示关键帧，但需说明省略范围。
- **调用方向明确展示**：证据链§3 或§4 中必须以明确格式展示完整调用方向链（如 `应用 JS → #09 NAPI入口 → #08 系统实现 → #07 参数校验 → #06 抛出Error → #00-#05 JS运行时传播`）。
- **修复建议 diff 展示**：涉及代码修改的建议必须使用以 `diff` 为语言标记的围栏代码块（```` ```diff ````），代码块内只展示增删的行：行首 `-` 为删除行、`+` 为新增行；不展示 `---`/`+++` 文件头、`@@` 行号标注与上下文行。不得改用 `typescript`/`text` 等语言标记。未反解或源码不可达、无法落到具体代码行时，用普通文字描述修改方向，不得编造无法确认的源码 diff。
- **末尾补充说明**：报告末尾必须包含补充说明段，列出日志字段缺失情况、分析局限性、证据链完整度评估和可信度评级依据。

```text
## JS Crash 分析报告

### 分析结论摘要
- 根因模块：<责任领域归属：三方应用 / 系统框架 / 三方 SDK / 不确定>
<责任模块名称，例如：entry / appentry / @xxx/network / @xxx/push / ArkUI / Web / RDB / Camera / Window / ResourceManager>
注意：
（1）必须基于故障根本原因输出定界结果。若根因明确是应用入参、状态、生命周期、资源、URL、SQL、递归或异常未捕获问题，责任模块应划分给应用或三方 SDK。
（2）框架栈如 stateMgmt.js、json_js.js、js_url.js、js_uri.js 只表示抛错框架，不等同于系统根因；需要结合第一个应用栈帧判断责任代码。
（3）如果缺少 SourceMap 或业务代码，只能初步定界时，要明确写出“不确定”及缺失证据。
- 根因总结：...

### 故障基本信息
- 故障时间：<Timestamp / Fault time，若有>
- 故障进程：<Module name / processName>
- PID / UID：<pid / uid>
- 应用版本：<Version / VersionCode，若有>
- 故障类型：<Reason / Error name>
- 错误信息：<Error message 原文>
- 错误码：<Error code，若有>
- 页面/Ability：<page 或日志中的页面信息，若有>
- 日志 Fingerprint（构建指纹/UUID）：<Fingerprint 原文；日志缺失时写“缺失”>
- UUID 校验：<一致 / 不一致 / 无法校验；一致时注明产物指纹与日志一致，不一致时给出两侧指纹值，无法校验时说明缺失字段>
- SourceMap 反解状态：<日志已还原 / hstack 反解成功 / UUID 不匹配未反解 / 未提供映射文件 / 反解失败>
- SourceMap 输入：<sourceMaps.json / nameCache.json 所属版本、构建指纹和路径；未提供时写“未提供”>
- 栈顶应用帧：<第一个应用栈帧>
- 源码位置：<反解后的文件:行:列；未反解时标记为 raw stack 位置>

### 故障模式库匹配
| 层级 | 根因 | 匹配依据 |
| --- | --- | --- |
| 一级根因 | `JSError` | appevent / errorManager / faultlogger 上报 ArkTS 异常崩溃 |
| 二级根因 | <fault-mode-library.md 中的二级根因，如 Error / TypeError / ReferenceError / URIError / OutOfMemoryError / TerminationError / AggregateError> | <Reason / Error name 原文> |
| 三级根因 | <fault-mode-library.md 中命中的三级根因；若仅命中二级，写“未收录子类”> | <Error message 模式，例如 `DecodeURI: invalid character: <string>`；若未命中，写实际 Error message 与兜底原因> |

匹配说明：
- 若 `fault-mode-library.md` 精确命中三级根因，必须输出命中的 `Error message 模式` 和 `三级根因`。
- 若只命中二级根因，三级根因写“未收录子类”，并在“根因判断”中结合 `references/jscrash-patterns.md` 与堆栈继续定性。
- 若 `fault-mode-library.md` 与 `jscrash-patterns.md` 结论不同，优先以日志中 `Error message + Error code + 栈顶应用帧` 同时支持的结论为准，并说明取舍依据。

### 根因判断
- **类别**：<二级根因类型>
- **可信度**：HIGH / MEDIUM / LOW
- **触发点**：<文件:行:列 处的具体调用 / 变量 / 参数 / 组件 / 资源 / URL / SQL / 递归 / 内存分配>
- **直接原因**：<导致 JS Crash 的直接错误，例如空对象属性访问、非法参数、未捕获业务异常、JSON 非法、递归栈溢出、OOM 等>
- **根本原因**：<状态管理、生命周期、接口契约、输入校验、异常处理、资源管理或内存管理层面的深层原因。当根因无法完全确定时，必须列举多种可能并标注各自依据>

### 关键证据链
1. 日志字段：<Reason / Error name / Error message / Error code 原文>
2. 故障模式库证据：<一级根因 -> 二级根因 -> 三级根因，必须与上方"故障模式库匹配"一致>
3. 调用栈证据（分层展示）：
   - **栈顶应用帧**：<反解后的第一个应用栈帧；未反解时标记为 raw stack 位置>
   - **关键上游帧**：<反解后的关键上游应用帧；系统/框架帧只作为传播路径，不作为应用根因>
   - **框架帧区分**：<stateMgmt.js、json_js.js 等框架栈只表示抛错框架，需结合第一个应用栈帧判断责任代码>
4. HybridStack / Native 桥接证据（如有）：<NAPI、libfs、libark_jsruntime 等关键帧及其意义>
5. SourceMap 映射证据：<日志 Fingerprint 与产物指纹比对结果；原始栈帧 -> 反解后源码帧；未反解时说明缺少的匹配构建产物（版本/构建指纹）>

### OOM 快照分析（仅在触发 jsleak-analysis Skill 时输出）
- 快照输入：<rawheap / heapsnapshot 文件及其与 Crash 的时间、PID、进程关联>
- 最严重疑似泄漏对象：<对象名称、Retained Size、数量>
- 强引用链：<对象到 GC Root 的最短强引用链>
- JS Leak 三级根因：<一级根因 -> 二级根因 -> 三级根因>
- 与本次 OOM 的关系：<已确认根因 / 高度疑似 / 关联证据不足，并说明依据>

### 修复建议（源码可达时需给出源码级修复建议）
1. <关键业务栈未反解时，优先要求提供故障版本匹配的 sourceMaps.json；启用名称混淆时同时提供 nameCache.json，并使用 hstack 反解后重新分析。已反解并定位到源码位置时，必须给出源码级修复建议（文件:行:列、具体修改方案）>
2. <补充输入校验、try-catch、生命周期/状态检查、资源路径检查、URL/JSON/SQL 校验、内存释放等>
3. <如果只能初步定界，说明需要补充什么源码或映射才能闭环>
4. <涉及代码修改的建议，每条修改使用一个 diff 代码块展示（只展示增删行），块前一行说明修改目的与位置，格式必须符合"修复建议 diff 格式示例">

---

### 补充说明
- <日志字段缺失情况：如缺少 PID/UID、故障时间、页面信息等字段时列出>
- <分析局限性：如缺少 SourceMap 无法定位应用源码、缺少应用 JS 栈帧无法闭环等>
- <证据链完整度评估：如 NAPI 桥接证据链是否完整、调用方向是否清晰>
- 可信度：<HIGH / MEDIUM / LOW>（<说明评级依据，如"Error name + Error message + Error code + NAPI 桥接证据一致指向参数校验失败，但缺少应用栈帧无法闭环定位具体代码位置">）
```

### 修复建议 diff 格式示例

报告"修复建议"中涉及代码修改的条目按以下形式呈现（内容仅为格式示意，必须替换为基于真实证据的修改，不得照抄）：

**修改 1** — `entry/src/main/ets/pages/Index.ets:12`（为异步加载补充 catch，防止未捕获异常导致崩溃）

```diff
-    this.data.load()
+    this.data.load().catch((e: Error) => {
+      hilog.error(0x0000, "Index", "load failed: %{public}s", e.message)
+    })
```

## 资源

- `references/jscrash-patterns.md`: JS Crash 错误模式、分析结论和修复建议矩阵。
- `references/fault-mode-library.md`: JSError 一级/二级/三级根因库，用于在报告中输出故障模式匹配结果。
- `references/sourcemap-symbolication.md`: release/混淆堆栈的 SourceMap 反解条件、`hstack` 命令和结果校验规则。
- `references/react_native.md`：react_native案例库。
- `scripts/hstack/`: 跨平台 SourceMap 反解工具；Windows 使用 `bin/hstack.bat`，Linux/macOS 使用 `bin/hstack`。
- `../jsleak-analysis/SKILL.md`: OOM 且提供 rawheap / heapsnapshot 时继续执行的 JS 内存泄漏分析流程。
