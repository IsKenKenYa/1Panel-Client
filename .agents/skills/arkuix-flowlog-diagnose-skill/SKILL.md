---
name: arkuix-flowlog-diagnose-skill
description: Use when diagnosing ArkUI-X (Android/iOS) white screen, jank, startup slowness, or crash from developer logcat/os_log/hilog. Analyzes 4 dimensions — lifecycle anchor coverage (22 anchors across Java/JNI/native/shared) / FAQ pattern grep (12 log signatures + 4 config fallbacks) / first-frame presence (F1 request + vsync) / timestamp gaps-duplicates — and outputs symptom classification → stall stage → evidence → FAQ root cause → remediation. Triggers on "白屏", "卡顿", "闪退", "启动慢", "ArkUI-X 日志排查", "flowlog diagnose", or when a developer pastes ArkUI-X log fragments for triage.
license: MIT
metadata:
  version: "1.0.0"
---

# ArkUI-X 流程日志诊断 Skill

> 输入：开发者提供的 ArkUI-X（Android/iOS/OHOS）logcat / `log stream` / hilog 片段。
> 输出：症状分类 → 卡点阶段 → 证据 → FAQ 根因 → 处置建议 → 需补充信息。
> 真相源：`references/` 下 4 个自包含知识库（不依赖运行时读仓外 `arkuix-x/docs`）。

## 日志配置要求（诊断前提·必须遵守）

> **本 skill 的诊断准确性完全依赖日志完整性。** 日志限流（chatty）或日志级别过滤不当会导致关键锚点/异常签名丢失，造成误判。

### Android 最优日志配置

```bash
adb shell setprop log.tag.Ace V            # 全级别保留（22锚点中18个为LOGI）
adb shell setprop log.tag.ArkCompiler W     # W+E+F保留（Throw error为E级，必须保留）
adb shell setprop log.tag.NAPI S            # 全静默
adb logcat -c                               # 每次测试前清buffer
adb logcat -G 16M                           # 加大buffer防chatty
```

### 配置错误的后果

| 错误配置 | 问题 | 误判表现 |
|---------|------|---------|
| `log.tag.Ace E` | 过滤18/22个LOGI级锚点 | 无法判定全链覆盖和首帧，误判白屏 |
| `log.tag.ArkCompiler S` | 静默所有级别含E级Throw error | JS异常签名丢失 |
| 未清buffer | chatty配额占满关键日志被丢弃 | Succeeded in loading content被丢弃 |

## 触发条件

- 开发者报告 ArkUI-X 应用**白屏 / 卡顿 / 闪退 / 启动慢**，并提供日志片段。
- 开发者粘贴 logcat / os_log / hilog 要求"排查""定位""看看卡在哪"。
- 明确点名本 skill 或提到 flowlog / 流程日志诊断。

不适用：纯 OHOS（非跨平台）日志、卡顿帧率精确定位（每帧耗时不在 logcat 通道，需 trace 工具）。

## 诊断流程（4 维度决策树）

按顺序执行 4 个维度，逐个 grep / 分析，最后汇总输出。

### 准备

1. 识别日志平台：`logcat` → Android；`os_log`/`log stream` → iOS；`hilog` → OHOS。
2. 确认日志 tag：ArkUI-X 关键日志多在 `Ace` tag（native）或 `ArkUI`/`StageActivity` tag（Java/JNI）。
3. 获取日志时间范围：冷启动（进程拉起→首帧）、warm 重启（后台→前台）、或销毁段。

### 维度 ① 流程走完（lifecycle anchor coverage）

**目的：** 判断启动流程走到哪步、链断点在哪。

**方法：** 按 `references/expected_anchors.md` 的 22 锚点清单，逐个 grep 日志。每个锚点有期望日志文案 + `文件:行号`。

**判定规则：**
- 锚点日志**存在** → 流程走到该阶段。
- 锚点日志**缺失** → 链断点：**上一个存在的锚点**是卡点阶段。
- 特殊：
  - `#10 S2 AttachView` 锚点 `AceContainerSG::AttachView begin, instance=`（**本期已补 LOGI**，release 可见）——确认容器装配是否开始。
  - `#16 Q-24 回放` 锚点 `Window DelayNotify replay: created=.. changed=..`（**本期已补 LOGI**，release 可见）——确认延迟通知是否被回放，排除白屏竞态。
  - 若有 `delay notify` 暂存行但无 `DelayNotify replay` → 延迟通知未回放，疑 UIContent 创建失败/时序错乱（RC-1.1）。

**输出：** 卡点阶段（如"停在 S4 InitPiplineContext，#13 S5 SetupRootElement 无"）。

### 维度 ② 异常 grep（FAQ pattern）

**目的：** 命中已知根因的日志签名，直接给出根因 + 处置。

**方法：** 按 `references/faq_patterns.md` 的 A 类 12 条可 grep 模式逐个 grep（A-5 模块加载段缺 .so / A-6 aboutToAppear 段）；若全未命中且症状是配置类白屏，提示 B 类 4 条 fallback。

**判定规则：**
- A 类命中 → 输出根因 + 处置 + 源 FAQ 文件名（Dev-faq-11/7/26）。
- A 类全未命中 + 无日志签名白屏 → 提示 B 类 4 条配置 fallback（useNormalizedOHMUrl / iOS addChildViewController / 主线程 API / 输入法异常）。

**输出：** FAQ 根因（若命中）或配置 fallback 提示。

### 维度 ③ 首帧来临（first frame）

**目的：** 判断首帧是"未请求""请求未上屏"还是"已上屏"。

**方法：** grep 两个关键锚点：
- `F1 首帧请求`：`pipeline_context.cpp(751)` `Root node request first frame`（共享仓，已有）
- `首帧 vsync`：`rosen_window.cpp(281)` `ArkUI requests first Vsync`（arkuix，已有）

**判定规则：**
- F1 有 + vsync 有 → 首帧已上屏（白屏则查 JS 异常 / Vulkan `RenderContext::Create() return nullptr`）。
- F1 有 + vsync 无 → 首帧请求了未上屏（查 aboutToAppear 异常 / abc 执行慢 / Vulkan RenderContext null）。
- F1 无 → 首帧未请求（查上游 S5/S6 RunPage 是否走完）。

**输出：** 首帧判定（未请求 / 请求未上屏 / 已上屏）。

### 维度 ④ 时间戳间隔 / 重复（timestamp gaps & duplicates）

**目的：** 粗粒度发现卡顿嫌疑（大间隔=stall）和循环嫌疑（重复行）。

**方法：** 取相邻 Ace 日志时间戳差值，对照 `references/baseline_timings.md` 基线 + 阈值。

**判定规则：**
- 相邻日志 ts 差 > 阈值（如 S5 SetupRootElement :967→:973 超 25ms 基线，实测 480ms）→ stall 卡顿嫌疑，标注嫌疑段。
- 同 ts 重复行（如 `ProcessPointerEvent` 同 ms 重复 30+）→ 循环嫌疑。**注意**：adb 模拟受触摸采样率限制（60~120Hz），同 ms 30+ 物理上不可达；建议判定弹性化：**同一签名日志在短窗口（如 100ms）重复 >=N 次或总量异常**即标循环嫌疑（B-S7 实测 277 次/数秒）。
- `pipeline_context.cpp(7795) Time decreases` → 时钟回退，负 dur/异常 gap 标"时钟异常"，不计 stall。

**边界（ER-1.1）：** 每帧耗时信号不在 logcat 通道，本维度仅做粗粒度嫌疑，**不做帧率定位**。卡顿帧率需 trace 工具（如 SmartPerf / Profiler）。

**输出：** 嫌疑段（大间隔 stall / 重复循环）或无异常。

## 输出模板

```
## ArkUI-X 应用诊断报告

**问题类型**：<白屏 / 卡顿 / 闪退 / 启动慢 / 正常>
**平台**：<Android / iOS / OHOS>
**问题概述**：<一句话描述应用出了什么问题，如“应用冷启动时主线程被阻塞约20秒，用户看到白屏后界面才显示”>

**日志证据**：
1. <简明描述关键日志行及其含义，如“应用启动后内容加载成功，但随后出现20秒日志空白期”>
2. <第二条关键证据，如“系统报告跳过1203帧，确认主线程被阻塞”>
3. <可选：第三条证据>

**根因分析**：
<用开发者能看懂的语言解释问题原因，如“应用的 ArkTS 模块顶层代码中包含同步阻塞操作，阻塞了 JS 主线程，导致渲染管线无法运行”>

**修复建议**：
1. <最高优先级操作，如“排查 entry 模块顶层代码，移除或异步化20秒的同步阻塞”>
2. <次优先级操作，如“将耗时初始化改用 setTimeout / Promise / TaskPool 移出主线程”>
3. <可选：第三条建议>

**补充信息**：<见下方“源码辅助诊断”规则；无则填“无”>
```

### 输出要求

- **问题类型**：白屏 / 卡顿 / 闪退 / 启动慢 / 正常（5选1）
- **问题概述**：一句话让开发者明白发生了什么，不用内部术语（如“维度④”“链断点#7”）
- **日志证据**：逐条列出关键日志，每条用“日志含义 + 时间”格式，不贴原始技术编号（如 pipeline_context.cpp:751）
- **根因分析**：用开发者能理解的语言，解释“为什么会出现这个问题”
- **修复建议**：按优先级给出可执行的代码级操作，不是概念性建议
- **补充信息**：根据下方“源码辅助诊断”规则判断是否需要开发者提供源码或其他信息；无则填“无”

## 源码辅助诊断

> 日志是诊断的主要依据。当日志定位不够精确时，可请求开发者提供相关 .ets 源码以精确定位根因。

### 何时请求源码

| 场景 | 日志能定位到 | 请求哪个文件 | 理由 |
|------|-------------|---------|------|
| 启动阻塞（top-level block） | 知道“顶层代码卡了N秒”，不知道具体哪行 | 问题页面的 `pages/Index.ets` 和 `EntryAbility.ets` | 查看顶层代码中的 while/同步IO/重计算 |
| JS 异常（栈丢失） | 只有 `NoClassDefFoundError: no stack trace` ，无文件名行号 | 问题页面的 `.ets` 文件 | release 包无 sourcemap，需看源码确认异常位置 |
| 触摸循环 | 知道“onTouch Move 高频重复”，不知道 Move 回调里做了什么 | 含 `onTouch` 的页面 `.ets` 文件 | 查看回调中的状态更新/重计算/同步操作 |
| 销毁路径慢 | 知道“aboutToDisappear 卡了N秒”，不知道里面做了什么 | 含 `aboutToDisappear` 的页面 `.ets` 文件 | 查看回调中的同步慢任务 |
| onAppear 阻塞 | 知道“onAppear 卡了N秒”，不知道里面做了什么 | 含 `onAppear` 的页面 `.ets` 文件 | 查看回调中的同步阻塞操作 |

### 何时不需请求源码

- **JS 异常栈完整**：日志已含 `BadPage.ts:58:1` 精确行号 → 直接给出结论，不需源码
- **FAQ 命中**：如 `UnsatisfiedLinkError` + `dlopen failed` → 根因明确（缺 so），不需源码
- **正常启动**：全链锚点齐 + 首帧已上屏 → 无问题，不需源码
- **配置类问题**：如 `bundleInfo_ is nullptr` + `RunScriptBuffer failed` → 根因明确（assets 缺失），不需源码

### 输出示例

当日志定位不足时，“补充信息”字段输出：
```
**补充信息**：建议提供 `pages/Index.ets` 源码，以精确定位顶层代码中导致20秒阻塞的具体语句。另需 trace 工具（SmartPerf / Profiler）抓取阻塞期间的 CPU 调用栈。
```

当日志定位充分时，“补充信息”字段输出：
```
**补充信息**：无。日志已含完整 JS 异常栈（BadPage.ts:58:1），定位粒完。
```

## 样例走查

详见 `test-cases/functional.md` B-S1~S10。要点：

| 样例 | 症状 | 关键判定 |
|------|------|---------|
| B-S1 | 白屏·启动卡 S4 | 维度①链断点 S4（#13 S5 无）；维度③ F1 未请求 |
| B-S2 | 白屏·首帧未上屏 | 维度③ F1 有、vsync 无 → 请求未上屏 |
| B-S3 | 闪退·FAQ命中 | 维度② `UnsatisfiedLinkError nativeAttachStageActivity` → Dev-faq-11 闪退1 |
| B-S4 | 白屏·FAQ命中 | 维度② `bundleInfo_ is nullptr` → Dev-faq-11 白屏4 assets 漏拷贝 |
| B-S5 | 白屏·FAQ命中 | 维度② A-6 `Throw error: Cannot read property toString of undefined` at aboutToAppear → Dev-faq-11 白屏1（**注意：ArkUI-X 框架 catch 该异常，不直接白屏，需确认后续流程是否中断**） |
| B-S6 | 卡顿·大间隔 | 维度④ S5 :967→:973 gap 480ms 超基线 25ms → stall |
| B-S7 | 卡顿·重复行 | 维度④ ProcessPointerEvent 同 ts 重复 30+ → 循环嫌疑 |
| B-S8 | 闪退·销毁屏障 | 维度① D2 :171 start 无 :176 end → 屏障未完成 |
| B-S9 | 正常·冷启动 | 维度①全链齐；④各段 gap 在基线；②③无异常 |
| B-S10 | 正常·warm | 维度① fgbg 四态齐；②③无异常 |

## 常见陷阱

1. **release 包 LOGD 不可见**：`log_wrapper.h` 的 `STRIP_RELEASE_LOG` 在 release 下仅 strip LOGD，LOGI/LOGW/LOGE/LOGF 均保留（ace_engine 主仓 commit 60747816208 / PR #89442 已改，全链 22 锚点 LOGI 在 release 包可见）。本期已把 S2/Q-24 提升为 LOGI（release 可见）。若日志来自 debug 包可看 LOGD，release 包无 LOGD 但有 LOGI/LOGW/LOGE/LOGF。诊断时确认包类型。
2. **行号偏移**：`expected_anchors.md` 行号为实测（2026-09 基准），master 演进会偏移。grep 用**文案 + 文件名**而非精确行号；行号仅辅助。
3. **pre-S1 段无 LOGI 缺口**：lib 加载 / JNI / App launch / Activity 段已有 Java/JNI 日志（非缺口），维度① 把 #1-#7 纳入算 gap（102/39/54ms），不是代码缺口。
4. **共享仓零改动约束**：本 skill 锚点表引用了共享仓行号（F1 :751 / F3 :1273 / ON_SHOW :3073 等），这些是**已有日志**，skill 直接用，不补。
5. **卡顿帧率不在 logcat**：维度④仅做时间戳粗粒度嫌疑，不做帧率。开发者要帧率需 trace 工具，明确告知。
6. **OHOS 不在本期范围**：本期仅 arkuix（android+ios）补点，OHOS 共享仓零改动。若日志来自 OHOS，维度①的 S2/Q-24 锚点可能不可见（OHOS 无 AttachView/DelayNotify）。
7. **Android logcat chatty 限流（关键）**：Android logd 对同一 tag + priority 在短时间内连续输出超过阈值（约 5-10 条/秒）时，会触发 chatty 限流丢弃后续日志。**每次验证前必须执行日志配置（见上方"日志配置要求"章节）**。
8. **`Delegator is null` 是非致命警告（关键·易误判）**：`UIContent::AddUIContent Delegator is null`（ui_content.cpp:35）出现在**所有** ArkUI-X release 应用中，app 会继续正常加载。诊断时**不能**将其当作白屏根因——必须检查其**后续**是否出现 `Succeeded in loading content` + `AttachView` + `RunPage` + `first frame` + `vsync`。**判定优先级：`Succeeded in loading content` + 首帧 > `Delegator is null`**。
9. **`log.tag.ArkCompiler S` 会丢失JS异常签名**：`S`静默**所有**级别含E级`Throw error`。正确配置是`W`（保留W+E+F，只静默D+I+V噪音）。
10. **`log.tag.Ace E` 会丢失18/22生命周期锚点**：22锚点中18个是LOGI级别，设`E`会全部过滤掉。必须设`V`。

### 日志限流预防与重置（Android）

> **核心原则：确保应用日志尽可能完整输出，不能因限流导致日志丢失影响诊断。**

**每次验证前必须执行**：

```bash
# 1. 日志级别配置（最关键）
adb shell setprop log.tag.Ace V            # 全级别（22锚点中18个为LOGI）
adb shell setprop log.tag.ArkCompiler W     # W+E+F（保留Throw error / Pending exception）
adb shell setprop log.tag.NAPI S            # 全静默

# 2. 清buffer + 加大buffer
adb logcat -c
adb logcat -G 16M

# 3. 若有root：重置logd的chatty计数器
adb shell stop logd && adb shell start logd
```

**无root时用客户端过滤**：
```bash
adb logcat -s Ace:V ArkCompiler:W StageActivity:V StageApplicationDelegate:V JSApp:V
```

**诊断时如何识别限流**：
- 日志中某 tag 突然中断（如 ArkCompiler 有初始化日志但无 Throw error）
- 重启手机后同一应用日志恢复正常
- 日志密度极高（同一秒内单 tag 超过 100 条）
- 提示开发者执行上述重置命令后重新抓日志再诊断

## 验证 Checklist

诊断完成后，按以下清单确认每个维度已执行：

- [ ] 维度①：22 个生命周期锚点已逐个 grep（含 S2 AttachView / Q-24 DelayNotify / F1 首帧 / vsync）
- [ ] 维度②：FAQ A 类 12 条模式已逐个 grep（含 A-13 Delegator is null 非致命）
- [ ] 维度③：首帧三态已判定（未请求 / 请求未上屏 / 已上屏）
- [ ] 维度④：时间戳 gap 已对照基线（含重复行检查）
- [ ] `Delegator is null` 后续是否有 `Succeeded in loading content` + 首帧锚点（确认非致命）
- [ ] 输出已按模板格式给出（症状 → 卡点 → 证据 → FAQ根因 → 处置建议）

## references 索引

| 文件 | 内容 |
|------|------|
| `references/expected_anchors.md` | 全链 22 锚点（Java/JNI/native/共享四层）+ 链断点判定规则 |
| `references/faq_patterns.md` | FAQ A 类 12 可 grep 模式（A-1~A-12）+ B 类 4 配置 fallback（自包含，标源） |
| `references/baseline_timings.md` | 冷启动各段 gap 基线（102/39/54/16/2ms）+ 阈值建议 |
| `references/corroborating_signals.md` | DFX 旁证信号（Vulkan null / unmarshal fail / Throw error / nativeWindow null / Time decreases） |
