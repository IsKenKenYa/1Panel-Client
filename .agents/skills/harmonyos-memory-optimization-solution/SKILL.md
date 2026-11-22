---
name: harmonyos-memory-optimization-solution
description: 优化 HarmonyOS 应用内存以降低内存峰值与冗余占用，覆盖四大类场景：① 离线 Web 组件（预渲染停止、离开页面复用、退后台释放、低端机预创建控制）；② ArkUI 组件（Image 降采样、长列表懒加载、LazyForEach/Repeat/@Reusable 内存优化策略、Navigation 路由栈、Tabs 预加载、cachedCount、容器嵌套、XComponent Surface 释放）；③ SO/HAP 包体积（编译选项裁剪、abc 字节码去冗余）；④ 并发（Worker 收敛复用、taskpool 共享传输）。当涉及 Web 组件预渲染或内存释放、图片/长列表内存峰值高、缓存池或复用池内存过高、so Pss 增长、hap/abc 体积增长、worker 实例过多、taskpool 大数据拷贝翻倍等场景时调用。
license: MIT
metadata:
  author: harmonyos-dev-skills
  version: 1.0.0
---
## 内存优化工作流

为优化 HarmonyOS 应用的内存使用，按以下步骤执行。步骤之间通过文末的**场景注册表**衔接：

```text
场景注册表（文末）
  applies_when ────────► 步骤 1 按场景决策树比对，定位命中的场景
  resource_refs ───────► 步骤 2 读取参考文档，给出优化方案
  verification_point ──► 步骤 5 逐场景验证优化效果
```

- 步骤 0：前置检查（源码路径必需，故障根因可选）
- 步骤 1：基于场景决策树完成进入方式与场景命中判定，产出「命中场景清单」
- 步骤 2：按命中场景的 resource_refs 读取参考文档，给出优化方案（仅限注册场景，未注册方案不得输出，见步骤 2「硬性边界」）
- 步骤 3：逐一询问用户确认优化点
- 步骤 4：根据用户确认执行优化
- 步骤 5：构建并按 verification_point 验证

### 步骤 0. 前置检查

- **0.1 源码路径（必需，硬性门禁）**：源码路径是必需项，报告数据仅用于缩小扫描范围、不能替代源码访问。未获取前不得读取任何报告文件、不得分析任何数据、不得进入 0.2 及后续步骤；未提供时立即向用户询问（询问完成前不做任何其他操作），路径无效时报错并要求重新提供。
- **0.2 故障根因（可选）**：已提供根因（内存分析报告、对比报告、案例匹配结论、heapsnapshot 分析等）时记录之；未提供时向用户确认一次并记录结果。进入方式的判定规则见**场景决策树**（场景注册表之前）。

### 步骤 1. 基于场景决策树完成判定

按**场景决策树**（场景注册表之前）完成判定，规则以决策树为准：

1. **进入方式判断**（决策树 Step 1）：依据 0.2 记录的故障根因与用户描述的异常表现，判定方式 A（全量扫描）或方式 B（定向扫描）。
2. **场景字段化决策**（决策树 Step 2）：按判定的范围扫描源码与构建配置，逐场景比对 `applies_when` 判定命中，核查命中位置的既有优化措施。
3. 产出「命中场景清单」（场景 + 位置 + 现状），供步骤 2 使用。

### 步骤 2. 根据参考文档给出优化方案

对「命中场景清单」中的每个场景：按其 `resource_refs` 读取参考文档（位于 `references/` 目录），结合文档中的方案、示例代码与文末「核心约束」给出优化方案。

**硬性边界（方案注册制）**：优化方案只能来自命中场景的 `resource_refs` 参考文档。凡未注册、或所属场景未命中 `applies_when` 的修复动作（资源侧整改、外部报告的根因改法、参考文档中所属场景未命中的通用建议等），一律不得作为优化项输出——不得编号、不进入步骤 3 确认清单、不在步骤 4 执行；如与传入问题相关，仅在方案末尾一句话披露「超出本 SKILL 场景注册范围，建议人工处理」。不得因与劣化根因直接相关而放宽命中判定。

**实现忠实性**：代码写法可灵活，核心思路必须与参考文档一致，不得用语义效果不同的操作替代（如「销毁-释放」不得改为「暂停-恢复」）；每个优化点执行后按步骤 4.4 的五维校验逐项比对。

### 步骤 3. 逐一询问用户确认优化点

对步骤 1 定位到的每个使用场景，逐一与用户确认，不要批量确认或跳过。确认清单仅包含场景注册表中注册场景的优化项（见步骤 2「硬性边界」），未注册方案不进入确认。

#### 3.1 呈现定位结果与优化方案

对每个定位到的使用位置，向用户说明：

1. **当前位置**：文件路径、代码行号、场景/组件类型。
2. **当前问题**：可能存在的内存风险（如未停止预渲染、未释放组件、未启用降采样等）。
3. **命中的优化项**：列出该位置适用的所有优化项（场景注册表中的 scene），说明各优化项解决的问题角度。
4. **优化建议**：针对每个命中的优化项，依据参考文档给出具体优化建议和关键代码。

#### 3.2 逐一询问用户确认

对命中的每个优化项，分别询问以下问题：

- 是否要应用此优化项？
- 是按给出的方案优化，还是需要修改什么？

记录用户的确认结果，区分以下情况：

- **确认按方案优化**：按步骤 2 方案执行。
- **确认但需修改**：记录用户的修改要求，按修改后的方案执行。
- **不优化**：跳过此优化项，不进行改动。

IMPORTANT: 每个优化项都要一一询问，即使同一位置命中多个优化项也要分别确认。用户可能对某些优化项有特殊考虑（如清晰度优先于内存、特定页面不释放组件等）。同一类场景出现多次时，也要分别询问。

### 步骤 4. 根据用户确认执行优化

仅对用户确认的优化点执行优化。

1. 按用户确认的方案（原方案或修改后的方案）逐一执行优化。
2. 每个优化点执行后，检查代码是否符合对应参考文档文末的「核心约束」。
3. 如执行中发现与方案不符的情况（如组件已绑定无法释放），及时反馈用户。
4. **实现忠实性校验（每个优化点执行后必须逐项比对）**：将实现代码与步骤 2 读取的参考文档（含示例代码）比对核心思路是否匹配，代码写法可以灵活，但以下各维度必须一致：
   - **存储对象能力**：实现中存储的对象具备文档方案所需调用的全部方法/能力。
   - **操作语义效果**：实现中每个操作的语义效果与文档一致，未用语义效果不同的操作替代。
   - **架构思路**：实现的核心处理思路与文档匹配，未替换为语义效果不同的架构。
   - **技术/组件模式**：实现使用的组件/技术模式能支撑文档方案的全部操作。
   - **关键机制**：文档方案中的关键机制环节在实现中存在，未省略。
   - 如有任一维度不匹配，**立即修正使思路与文档一致**，不得跳过。
5. 执行完成后核对所有确认的优化点是否都已执行、有无遗漏，再进入步骤 5。

### 步骤 5. 构建并验证

构建应用并运行本地测试：

1. 确保优化后应用功能不受影响。
2. 对每个已执行的优化场景，按场景注册表中该场景的 `verification_point` 逐条验证。

重要提示：当验证涉及内存占用测量、退后台释放恢复验证时，**不得在本 SKILL 内自行执行验证操作**（如直接调用 hdc 查看内存、模拟退后台等），必须按以下步骤路由：

1. 按标准流程执行内存占用和释放恢复验证。
2. 收集编译日志、内存占用截图和释放恢复截图作为验证证据。

工作流收口前，按下方「检查清单」逐项核对。

## 检查清单

整个工作流结束前，按级别逐项核对。Critical 项任一不满足，不得结束流程；Warning 项不满足时须在最终输出中说明原因。

### Critical（不满足不得结束流程）

- [ ] 源码路径已获取并验证有效后，才开始读取报告与分析数据（步骤 0.1 硬性门禁）
- [ ] 输出的每个优化项均来自命中场景 `resource_refs` 指向的参考文档，无未注册方案混入（步骤 2 硬性边界）
- [ ] 每个优化项均已单独向用户确认，并按「确认按方案优化 / 确认但需修改 / 不优化」记录结果，无批量确认或跳过
- [ ] 仅执行了用户确认的优化点，核对无遗漏、无未经确认的改动
- [ ] 每个优化点执行后已通过实现忠实性校验：存储对象能力、操作语义效果、架构思路、技术/组件模式、关键机制环节五个维度均与参考文档一致
- [ ] 构建通过，优化后应用功能不受影响
- [ ] 每个已执行场景已按其 `verification_point` 逐条验证通过，并留存编译日志、内存占用截图、释放恢复截图

### Warning（不满足须说明原因）

- [ ] 未注册但与传入问题相关的内容，仅在方案末尾以一句话披露「超出本 SKILL 场景注册范围，建议人工处理」，未编号、未进入确认清单
- [ ] 内存占用测量、退后台释放恢复验证未在本 SKILL 内自行执行（未直接调用 hdc 查内存、未模拟退后台）
- [ ] 执行中发现与方案不符的情况（如组件已绑定无法释放）已及时反馈用户
- [ ] 同一位置命中多个优化项时，已说明各优化项解决问题的不同角度

### Info（建议核对）

- [ ] 进入方式已按场景决策树完成判定：已有根因或明确定位问题时按方式 B 定向扫描，否则按方式 A 全量扫描
- [ ] 每个命中位置已记录文件路径与代码行号，并核查过该位置是否已存在优化措施
- [ ] 多场景优化项可同时应用的说明已向用户传达（并非只能选其一）

## 目录结构

```text
harmonyos-memory-optimization-solution/
├── SKILL.md           # 工作流入口：优化步骤 + 检查清单 + 场景决策树 + 场景注册表
├── references/        # 各注册场景的优化方案参考文档（由场景注册表 resource_refs 指向，各文档文末含「核心约束」）
├── assets/            # 参考文档配套的可运行示例代码（由 references/ 内各文档以 ../assets/ 链接引用）
└── test-cases/        # 本 SKILL 的测试用例：trigger.md 触发验证、functional.md 功能验证；供检视流水线（hmos-skill-test-runner）执行与人工回归验收使用，不属于内存优化工作流的执行资源，执行优化任务时不读取
```

## 场景决策树
用户提出内存 / 体积优化相关问题时，按本决策树完成进入方式判定与场景命中决策。决策树只负责路由：**不在决策树中维护场景描述，所有具体场景描述以下方「场景注册表」为准**；命中判定以 `applies_when` 逐条比对为准。
```text
用户报告内存 / 体积问题
│
├── Step 1: 进入方式判断（对应步骤 1）
│   │
│   │  判断原则: 用户是否已定位到具体问题，决定步骤 1 按方式 A 还是方式 B 进入
│   │
│   ├── 方式 B（定向）: 满足以下任一条件
│   │   ├── 用户提供了故障根因（内存分析报告 / 对比报告 / 案例匹配结论 / heapsnapshot 分析）
│   │   │   强信号: "内存报告"、"topdown 对比"、"smaps 对比"、"heapsnapshot"、"Pss 增长"
│   │   ├── 用户描述了明确的异常表现
│   │   │   强信号: "预渲染一直渲染"、"退后台内存不降"、"滑动内存持续涨"、"worker 越建越多"
│   │   │   中信号: "发热"、"卡顿"、"首帧慢"、"包变大"
│   │   └── 处理: 将问题对应到注册表中的场景，仅对涉及场景定向比对 applies_when
│   │
│   └── 方式 A（全量）: 未提供具体问题
│       关键词: "帮我做内存优化"、"全面排查内存"、"内存治理"
│       注意: "内存高"（泛化诉求）≠ 已定位问题；须全量读取注册表全部场景的 applies_when 逐场景比对
│
└── Step 2: 场景字段化决策（multi-label，对应步骤 1）
    │   不在决策树中维护场景描述；所有具体场景描述以下方「场景注册表」为准。
    │   按进入方式确定的范围（全量或定向）对场景做并行匹配，可同时命中多个场景。
    │
    ├── 2.1 适用边界校准
    │   ├── 对范围内场景逐条检查 applies_when，确认该场景覆盖用户真实诉求
    │   ├── 同时判断命中位置是否已存在优化措施（已配置 memoryOptimizationStrategy、
    │   │   已调用 terminate() 等），已优化的位置不重复进入确认清单
    │   └── applies_when 逐条比对未通过的场景，不得进入命中场景清单
    │
    ├── 2.2 命中清单产出（multi-label）
    │   ├── 场景之间不互斥；多个 applies_when 同时成立时全部保留
    │   │   （如图片流长列表可同时命中 ARKUI_MEM_01/07/08）
    │   ├── 每个命中场景记录 场景 + 文件路径 + 代码行号 + 现状，
    │   │   产出「命中场景清单」供步骤 2 使用
    │   └── 同一位置命中多个场景时，各场景优化项分别进入步骤 3 逐一确认，不合并
    │
    └── 2.3 资源读取决策（对应步骤 2）
        ├── 将每个命中场景 resource_refs 指向的参考文档全部纳入读取清单，不得遗漏
        ├── 优化方案只能来自命中场景的参考文档（方案注册制，未注册方案不得输出）
        └── 全部场景均未命中时如实告知用户，不得凭经验输出注册表之外的方案
```

## 场景注册表

本注册表是工作流的数据枢纽：`applies_when` 供步骤 1 定位比对（含定位特征与适用条件）；`resource_refs` 为相对本 SKILL 的参考文档路径，供步骤 2 读取方案（各文档文末含「核心约束」）；`verification_point` 供步骤 5 验证。`phase_tags` 标记该场景适用的阶段（REQ 需求 / DEV 开发 / FIX 修复）。场景注册表同时是优化方案的**唯一合法来源**——未注册的修复动作不得作为优化项输出（方案注册制硬边界，见步骤 2）。

### ARKWEB_MEM_01 离线组件预渲染完成后停止渲染
```yaml
scene_id: ARKWEB_MEM_01
scene_name: 离线组件预渲染完成后停止渲染
phase_tags: [REQ, DEV, FIX]
applies_when:
  - 代码中使用 Web/NodeController/NodeContainer/BuilderNode 搭建离线 Web 组件（常见于 EntryAbility 的 onWindowStageCreate 预创建）
  - 使用 onFirstMeaningfulPaint 检测预渲染完成，但渲染完成后未调用 onInactive 停止渲染
  - 需要预渲染 Web 页面实现快速显示，且渲染完成后需停止渲染以节省功耗
  - 问题表现为预渲染的网页在后台不断渲染，导致发热和功耗
verification_point:
  - 预渲染完成后正确停止渲染，发热和功耗问题消除
resource_refs:
  - references/prerender_stop.md
```
### ARKWEB_MEM_02 减少离线Web组件使用
```yaml
scene_id: ARKWEB_MEM_02
scene_name: 减少离线Web组件使用
phase_tags: [REQ, DEV, FIX]
applies_when:
  - 离线 Web 组件在离开 Web 页面后未复用（无 loadUrl('about:blank') 逻辑），退后台后未释放（无 dispose/rebuild 逻辑），组件仍占用内存
  - onBackground/onForeground 中无组件释放/恢复逻辑（recycleNWebs/restoreNWebs）
  - 应用退至后台时需释放离线 Web 组件降低内存占用，回到前台时需恢复
  - 多个 UI 页面需要复用同一离线 Web 组件
verification_point:
  - 离开 Web 页面后组件加载空页面，可被其他页面复用（无新增组件）
  - 应用退后台后内存占用降低，回到前台后 Web 组件正确恢复显示
  - 释放后无 NodeContainer 白屏
  - nodeMap 用唯一 key（genWebKey）而非 url，同 url 多页面实例同时存活不冲突
  - restoreNWebs 用 about:blank 重建空闲件回池，回前台后 getFreeWebNode 取用并 loadUrl(targetUrl) 正确恢复
  - getFreeWebNode 空闲件判定只用 isBlanked()（未绑定 && 内容已置空）
resource_refs:
  - references/component_reuse_recycle.md
```
### ARKWEB_MEM_03 低端机不预先创建离线组件
```yaml
scene_id: ARKWEB_MEM_03
scene_name: 低端机不预先创建离线组件
phase_tags: [REQ, DEV, FIX]
applies_when:
  - 预创建离线 Web 组件未按设备能力分级控制（无 deviceInfo.performanceClass/PerformanceClassLevel 判断），各档位设备使用相同预渲染策略
  - 低端机上预先创建离线 Web 组件导致内存占用过高、卡顿或被系统终止
  - 需根据设备能力分级决定是否预先创建，低端机进入页面时按需创建 Web 组件加载
verification_point:
  - 低端机不预先创建离线组件，启动时内存占用降低
  - 进入页面时 Web 组件正确创建加载
  - onBind 时从 nodeMap 删除（组件正在使用不占预创建名额），onUnbind 时检查 nodeMap.size < maxPreloadCount 决定重新注册回池或 dispose 释放
resource_refs:
  - references/component_preload_count.md
```
### ARKWEB_MEM_04 离线组件预加载个数优化
```yaml
scene_id: ARKWEB_MEM_04
scene_name: 离线组件预加载个数优化
phase_tags: [REQ, DEV, FIX]
applies_when:
  - 代码中一次性/循环创建多个离线 Web 组件，未限制预创建个数
  - 应用预创建多个离线 Web 组件导致内存占用成倍增长
  - 需根据设备能力分级限制预创建个数（低端机不创建，中端机最多 1 个，高端机最多 1-2 个）
verification_point:
  - 高端机预创建离线组件个数符合分级限制，内存占用符合预期
  - onBind 时从 nodeMap 删除，onUnbind 时检查 nodeMap.size 决定重新注册或 dispose；nodeMap 只持有空闲预创建组件
resource_refs:
  - references/component_preload_count.md
```
### ARKUI_MEM_01 Image组件降采样
```yaml
scene_id: ARKUI_MEM_01
scene_name: Image组件降采样
phase_tags: [REQ, DEV, FIX]
applies_when:
  - Image 组件加载原图尺寸远大于显示区域的图片（大图小显示），未设置 autoResize
  - 图片资源为本地资源/网络图片/PixelMap，问题表现为 Image 组件加载大图导致内存占用过高
  - 图片需根据父容器尺寸动态适配，或需响应不同屏幕尺寸/折叠屏形态差异
verification_point:
  - Image 组件启用 autoResize 后内存占用降低，图片显示无异常
resource_refs:
  - references/image_autoresize.md
```
### ARKUI_MEM_02 LazyForEach内存优化策略
```yaml
scene_id: ARKUI_MEM_02
scene_name: LazyForEach内存优化策略
phase_tags: [REQ, DEV, FIX]
applies_when:
  - LazyForEach 承载的列表项数量较多（数百项以上），或单项子组件结构复杂（多层嵌套/数十个子节点）
  - 未使用 LazyForEachOptions（第四个参数）或未配置 memoryOptimizationStrategy（默认 DEFAULT，无内存优化）；releaseStrategy/customComponentFreezeMode 未配置
  - 应用退后台后预加载区域节点仍占用内存，需要自动释放
  - 整机低内存时需要主动释放预加载区域节点
  - 列表项结构复杂导致节点释放耗时长，出现超大帧卡顿
verification_point:
  - 启用 ENABLE_AUTO_CACHE_OPTIMIZATION 后，应用退后台内存占用降低，回到前台后列表正确恢复显示
  - 使用 LazyForEachOptions 时已正确设置 keyGenerator，编译无报错
  - 节点释放和恢复时自定义组件生命周期回调正常执行，列表无空白项
resource_refs:
  - references/lazyforeach_memory_optimization.md
```
### ARKUI_MEM_03 Repeat内存优化策略
```yaml
scene_id: ARKUI_MEM_03
scene_name: Repeat内存优化策略
phase_tags: [REQ, DEV, FIX]
applies_when:
  - Repeat 使用 virtualScroll 且数据项数量较多（长列表），滑动后缓存池持有大量旧节点占用内存
  - 使用 template 多模板，各 template 缓存池持有大量未被复用的节点；TemplateOptions.cachedCount 设置过大导致内存持续增长
  - 未配置 VirtualScrollOptions 的 memoryOptimizationStrategy（默认 DEFAULT，无内存优化）
  - reusable 配置与 @ReusableV2 存在复用冲突（reusable: false 会使 Repeat 内存优化策略失效）
  - 应用退后台后 Repeat 缓存池节点仍占用内存，或整机低内存时需要主动释放
verification_point:
  - 启用 ENABLE_AUTO_CACHE_OPTIMIZATION 后，应用退后台内存占用降低，回到前台后列表正确恢复显示
  - 配置内存优化策略时 reusable 保持为 true（默认值），未与 @ReusableV2 接管复用（reusable: false）的配置组合导致策略失效
  - .each() 属性已设置，运行无报错
  - template cachedCount 设置合理，滑动后内存不持续增长
resource_refs:
  - references/repeat_memory_optimization.md
```
### ARKUI_MEM_04 可复用自定义组件内存优化策略
```yaml
scene_id: ARKUI_MEM_04
scene_name: 可复用自定义组件内存优化策略
phase_tags: [REQ, DEV, FIX]
applies_when:
  - @Reusable/@ReusableV2 装饰的可复用自定义组件，复用池持有大量实例占用内存
  - 未传入 ReusableOptions 或未配置 memoryOptimizationStrategy（默认 DEFAULT，无内存优化）；aboutToRecycle/aboutToReuse 未正确实现
  - 复用组件被频繁回收进入复用池，复用池持续增长
  - 应用退后台后复用池实例仍占用内存，或整机低内存时需要主动释放
  - 复用池中相同 ReuseId 的组件数量超过容量限额，需要按限额裁剪
verification_point:
  - 启用 ENABLE_AUTO_CACHE_OPTIMIZATION 后，应用退后台内存占用降低，回前台后组件复用正常
  - 复用池容量限额裁剪机制生效，超过限额且 5 秒不增加时正确裁剪
  - aboutToRecycle/aboutToReuse 回调正常执行，复用后组件状态正确初始化
resource_refs:
  - references/reusable_memory_optimization.md
```
### ARKUI_MEM_05 Navigation路由栈内存优化策略
```yaml
scene_id: ARKUI_MEM_05
scene_name: Navigation路由栈内存优化策略
phase_tags: [REQ, DEV, FIX]
applies_when:
  - Navigation 作为页面根容器，NavPathStack 路由栈深度大（pushPath/pushDestination 持续入栈不清理）
  - 未调用 .configuration() 配置 NavigationConfiguration（stackSizeLimit/recyclePagesOnLowMemory/clearContentStackOnPrimaryNavigation 均未配置）
  - 不可见 NavDestination 页面实例结构复杂、占用大量内存
  - 整机低内存时需要自动回收不可见页面；Split 模式下需要在主页侧导航时自动清理旧页面栈
verification_point:
  - 配置 stackSizeLimit 后，路由栈超过限制时正确销毁最早入栈的页面实例，回退时页面正确重新创建
  - 配置 recyclePagesOnLowMemory: true 后，低内存时不可见页面被自动回收，回退时页面正确恢复
  - Split 模式下配置 clearContentStackOnPrimaryNavigation: true 后，主页侧导航时旧页面栈正确清理
resource_refs:
  - references/navigation_memory_optimization.md
```
### NATIVE_SO_01 SO包体积与内存劣化优化
```yaml
scene_id: NATIVE_SO_01
scene_name: SO包体积与内存劣化优化
phase_tags: [REQ, DEV, FIX]
applies_when:
  - 自研 so（libs/arm64-v8a、libs/armeabi-v7a）体积相比上一版本明显增长
  - smaps 对比显示 .so 映射 Pss 增大，且 Size 与 Pss 同步增长（二进制膨胀型劣化）
  - CMakeLists.txt/build-profile.json5（nativeOption）/*.cmake 缺失体积优化选项（--gc-sections、-fvisibility=hidden、RELR、gnu hash、icf 等）或选项被回退
  - 存在 -WI,（大写 i）拼写错误、误用 gcc 专属 -moutline（OHOS clang 静默忽略）等选项失效问题
  - 需要在体积与性能之间权衡（-Oz、--icf=all、低 inline 阈值均有性能代价）
verification_point:
  - 体积优化选项配置后，llvm-readelf -S 确认目标段回落（.text/.dynsym/.rela.dyn）
  - --gc-sections 裁剪后注册/反射类代码（函数指针表、静态自注册）未被误删，相关功能正常
  - -fno-rtti/-fno-exceptions 启用后编译通过（无 dynamic_cast/typeid/try-catch/throw 残留）
  - 性能敏感模块启用 -Oz/--icf=all/低 inline 阈值后，性能测试无不可接受的劣化
resource_refs:
  - references/so_size_optimization.md
```
### NATIVE_HAP_01 HAP包体积优化（abc去冗余）
```yaml
scene_id: NATIVE_HAP_01
scene_name: HAP包体积优化（abc去冗余）
phase_tags: [REQ, DEV, FIX]
applies_when:
  - hap 产物 ets/modules.abc 体积相比基线明显增长（unzip -l *.hap | grep abc）
  - 出包所用 Command Line Tools/DevEco Studio 版本低于 6.1.1 Release，未享受 ArkTS 编译器对 string section/code section 的去冗余优化
  - 需要在不修改应用代码的前提下减小 abc size
verification_point:
  - 升级/替换 es2abc 出包后，unzip -l 对比 ets/modules.abc 体积回落，应用功能回归正常
  - 仅替换 es2abc 的环境未用于开发场景（预览器正常），且工程为 Stage 模型出包
resource_refs:
  - references/hap_size_optimization.md
```
### CONCURRENT_MEM_01 Worker数量优化
```yaml
scene_id: CONCURRENT_MEM_01
scene_name: Worker数量优化
phase_tags: [REQ, DEV, FIX]
applies_when:
  - 同一任务（同一 script）的 new worker.ThreadWorker/new worker.Worker（已废弃旧写法）实例化调用点总数超过 8 个，libworker.z.so/ARKTS_HEAP 占用随实例数线性增长
  - 按调用次数/页面进入次数新建 worker 而非复用，用完后不 terminate
  - 同职责任务拆散到多个 worker 实例，需要合并收敛
  - postMessage 大数据传输依赖默认结构化克隆（双份拷贝），未用第二个参数（transfer list）转移所有权
  - worker 文件顶层（全局作用域）长期持有大对象或只增不减的缓存容器
verification_point:
  - Worker 收敛后，同一任务（同 script）同时存活的 worker 实例不超过 8 个（按任务独立计数，不设全应用统一上限），libworker.z.so/ARKTS_HEAP 占用较收敛前下降
  - WorkerManager 按任务独立计数的上限检查生效，全局检索确认无绕过管理器的裸 new worker.ThreadWorker()/new worker.Worker() 创建
  - worker terminate() 后内存回落，无回调引用滞留；合并的常驻 worker 消息分发正常，任务无串行化卡顿
  - 大数据消息改用 transfer 后，传输无双份内存增长，worker 侧数据读写正常（发送侧转移后不可再访问该缓冲区）
resource_refs:
  - references/worker_count_optimization.md
```
### CONCURRENT_MEM_02 taskpool任务优化
```yaml
scene_id: CONCURRENT_MEM_02
scene_name: taskpool任务优化
phase_tags: [REQ, DEV, FIX]
applies_when:
  - taskpool 任务传参/返回值为图片、视频、大文件等大量数据，以普通对象直接传输（默认序列化/反序列化双份拷贝）
  - "@Concurrent 函数体内发起网络请求（http.createHttp、@ohos.net.http、axios 等 I/O 密集任务）"
  - "@Concurrent 函数多点散落在页面/业务文件，unused import 膨胀（文件全部 import 远多于实际使用）"
verification_point:
  - 大量数据改用 @Sendable 后，跨线程传输无序列化双份内存峰值，任务处理结果正确
  - http 请求移出 taskpool 后，线程池无 I/O 等待占用，CPU 密集任务调度正常，网络功能回归正常
  - "@Concurrent 提取为独立 *Task.ets 后编译通过，原文件外部调用方 import 路径不变（re-export 生效），任务文件仅保留实际依赖的 import，test_extract_concurrent.js 回归通过"
resource_refs:
  - references/taskpool_optimization.md
```
### ARKUI_MEM_06 Tabs页签内存优化
```yaml
scene_id: ARKUI_MEM_06
scene_name: Tabs页签内存优化
phase_tags: [REQ, DEV, FIX]
applies_when:
  - 调用 TabsController.preloadItems 预加载不可见 TabContent：低端机仍调用、无参/大数组一次性加载、无设备能力分级（deviceInfo.performanceClass）控制
  - animationMode 为默认 CONTENT_FIRST 或未设置；animationDuration 未设置（默认 300ms）或大于 0
  - 点击 TabBar 或 TabsController.changeIndex 跨页签跳转时，默认切换动画滑过并连带构建中间页面
  - 页签内容为长列表/大图/WebView 等重页面，未访问页签提前驻留内存
verification_point:
  - 低端机去掉 preloadItems 后，未访问页签不再提前构建，启动/进入 Tabs 页内存占用降低；高端机分批预加载正常，切换首帧无退化
  - 设置 NO_ANIMATION/animationDuration(0) 后，跨页签跳转（点击 TabBar/changeIndex）不再连带构建中间页面，目标页正常显示，功能回归无异常
resource_refs:
  - references/tabs_memory_optimization.md
```
### ARKUI_MEM_07 长列表懒加载改造
```yaml
scene_id: ARKUI_MEM_07
scene_name: 长列表懒加载改造
phase_tags: [REQ, DEV, FIX]
applies_when:
  - List/Grid/Swiper/WaterFlow 滚动容器内使用 ForEach 渲染列表项，数据源为全量数组（数百项以上）一次性灌入
  - 未使用 LazyForEach（含 IDataSource 实现）或 Repeat().virtualScroll()
  - LazyForEach 误放在非滚动容器（Scroll/Column/Row）内，懒加载不生效（等同全量）
  - 页面首帧慢、内存峰值高，根因为 ForEach 全量挂载列表节点
verification_point:
  - 长列表由 ForEach 改为 LazyForEach/Repeat virtualScroll 后，仅按需构建可视区域节点，首帧耗时与内存峰值明显下降
  - 滚动功能与数据刷新正常（增删改后 UI 正确更新）
resource_refs:
  - references/longlist_lazy_loading.md
```
### ARKUI_MEM_08 滚动容器cachedCount预加载优化
```yaml
scene_id: ARKUI_MEM_08
scene_name: 滚动容器cachedCount预加载优化
phase_tags: [REQ, DEV, FIX]
applies_when:
  - List/Grid/Swiper/WaterFlow 滚动容器（配合 LazyForEach/Repeat virtualScroll）配置 .cachedCount(N) 或 Repeat virtualScroll({ cachedCount: N })，N 大于 2（如 5、10）
  - 列表项为图片密集型内容（图片流/瀑布流/表情壁纸/头像列表），预加载区域节点连带加载图片，缓存图片数量过多，滚动时内存峰值高或随滑动持续增长
  - 列表项总数较少（几十项）但 cachedCount 设置过大，导致懒加载失效退化为一次性全量加载
verification_point:
  - cachedCount 收敛为不超过 2 后，滚动场景内存峰值下降，内存不再随滑动持续增长
  - 快速滑动无明显白块劣化（如出现白块，通过 autoResize 降采样/组件复用解决，而非改回大 cachedCount）
  - 数据量较少的列表懒加载恢复生效（列表项按需构建，不再一次性全量加载）
resource_refs:
  - references/scroll_cachedcount_optimization.md
```
### ARKUI_MEM_09 XComponent Surface 隐藏释放
```yaml
scene_id: ARKUI_MEM_09
scene_name: XComponent Surface 隐藏释放
phase_tags: [REQ, DEV, FIX]
applies_when:
  - 代码中使用 XComponent(type=SURFACE) 进行 native 渲染（EGL/OpenGL ES、媒体数据输入），surface 不可见时（页面跳转/Tab 切换/退后台）其 OHNativeWindow、dmabuf 等图形资源仍驻留内存
  - 使用传统 OH_NativeXComponent（libraryname 注入）方式，仅有 OnSurfaceCreated/Changed/Destroyed 回调，无 hide/show 事件，无法在 surface 不可见时主动释放
  - 页面跳转或退后台后 surface 引用仍驻留，native 侧持有 OHNativeWindow 引用计数不归零，dmabuf 不释放
  - 多页面 XComponent surface 累积导致图形内存峰值过高
verification_point:
  - 方案一（API 20+）：hilog 中能看到 OnSurfaceHide→Finalize→OnSurfaceDestroyed 释放序列，返回时 OnSurfaceShow→Initialize→OnSurfaceCreated 重建序列
  - 方案二（API 8+）：手动调用 NativeObjectUnreference 后 window/buffer 引用计数归零，dmabuf 释放，PSS 回落
  - 两种方案均可使 surface 隐藏后 dmabuf/图形缓冲释放，重新可见后 surface 正确恢复
resource_refs:
  - references/xcomponent_surface_release.md
```
### ARKUI_MEM_10 容器组件嵌套层级优化
```yaml
scene_id: ARKUI_MEM_10
scene_name: 容器组件嵌套层级优化
phase_tags: [REQ, DEV, FIX]
applies_when:
  - 容器组件（Column/Row/Stack/Flex/List/Grid/Swiper/WaterFlow/Scroll/RelativeContainer 及自定义组件根容器等）嵌套层级达到或超过 10 层（以组件树实际层级计，经 ArkUI Inspector/CodeLinter 布局层级检查/人工审阅确认）
  - 布局中存在仅包裹单个子节点、不承担布局语义的透传容器，或多个中间层仅为承载 padding/背景/圆角等装饰属性
  - 多层 Row/Column/Stack 交叉嵌套实现纵横定位，或 Stack 内再包 Row/Column 手工定位悬浮角标/徽标
  - 长列表列表项结构嵌套层级深，组件树节点数随加载列表项数成倍放大，内存占用高、布局测量耗时长
  - 前提约束：减层后必须保持原本布局逻辑与视觉效果不变
verification_point:
  - 治理后容器嵌套层级降到 10 层以下（ArkUI Inspector 组件树复查），页面显示效果与治理前一致（截图/真机比对，位置/尺寸/背景/圆角/间距无变化）
  - 删除的均为不承担布局语义的透传/装饰层；承担排布/对齐/尺寸语义的容器与结构必需容器（ListItem/GridItem/FlowItem/TabContent、Scroll 直接滚动子容器等）未被误删
  - 长列表场景列表项子树节点数下降，进入页面与滚动场景内存占用/峰值下降
  - 未以 @Builder/自定义组件拆分冒充减层（拆分不改变组件树，不计入收益）
resource_refs:
  - references/container_nesting_optimization.md
```
