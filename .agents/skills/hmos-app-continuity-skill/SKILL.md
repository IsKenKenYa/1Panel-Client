---
name: hmos-app-continuity-skill
description: This guide directs the incremental integration of HarmonyOS (鸿蒙 / ArkTS) app continuation (应用接续 / App Continuity), enabling users to resume the same task on a different device. It is applicable when planning, adding, extending, or fixing cross-device state migration for pages, navigation stacks, forms, editors, or large data, as well as when assessing the completeness of an existing implementation or identifying where it fails.
license: MIT
metadata:
  version: "1.0.0"
  keywords:
    - harmonyOS 应用开发
    - 鸿蒙应用开发
    - ArkTS
    - 自由流转
    - 创新特性
    - 接续
    - 应用接续
    - 跨设备使用
    - 数据迁移
    - 功能开发
---

# HarmonyOS 应用接续开发 Skill

## Overview

本 Skill 指导 agent 为 HarmonyOS (鸿蒙 / ArkTS) 项目**增量接入应用接续能力**（App Continuity）——让用户在手机、平板、PC 等多设备之间无缝继续同一任务。

**核心理念**：添加应用接续不是彻底重构项目，而是根据场景增量开发。只修改必要代码，不破坏项目现有功能。

**适用场景：**
- 项目要新增"跨设备继续使用"能力
- 需要评估现有项目是否能接入应用接续功能（哪些页面可接、哪些数据需要传递）
- 需要为列表/表单/Web页面/编辑器/音视频等特定场景设计接续方案
- 项目已部分实现了接续功能，需要进一步补齐应用接续能力
- 项目已配置应用接续，但迁移后遇到页面空白、状态丢失等问题需要解决

**不适用：**
- 项目尚在立项阶段、无任何可运行页面（应先做应用本身）
- 同一设备内的页面跳转（需用 Navigation/路由实现，与接续无关）
- 多设备应用适配（超出应用接续范围，建议考虑`一次开发，多端部署`相关内容）
- 跨应用、跨厂商的"任务流转"（超出应用接续范围，建议考虑分布式流转/元服务协同）

---

## Hard Constraints（硬约束）

以下约束在 Skill 执行过程中**必须全程遵守**，任何步骤不得违反：

| 约束 | 要求 |
|------|------|
| **未明确不修改代码** | 没有完全明确用户需求，没有完成详细设计规划前禁止修改项目代码 |
| **最小增量修改** | 只修改必要代码，不破坏现有项目功能。不另起工程，不替换现有架构 |
| **用户确认为准** | 如果存在问题或冲突，向用户提问确定解决方案，用户确认前不进行修改 |

---

## Decision Tree（决策树）

执行前按下列决策路径逐项判定；判定口径见 Execution Flow 对应步骤，本节只给执行路径指引，不包括具体细节。

```
用户请求
  │
  ▼
步骤0 意图判定
  ├─ 咨询型 ──────────────► 加载 references 直接回答 ──► 结束
  ├─ 实施/补齐接续 ───────► 步骤1
  └─ 评估现有实现 ────────► 步骤1（步骤3时输出问题定位报告，不出设计文档）
  │
  ▼
步骤1 执行条件检查（Skill 完整性 / API≥12 / 同 BundleName）
  ├─ 任一不满足 ──────────► 终止：说明原因与处理路径
  └─ 全部满足 ───────────► 场景类型
  │
  ▼
步骤2 场景类型确认 ────────► 确认在步骤3/4应该加载的场景资源类型（场景指南表），包括四个子内容
  │
  ▼
步骤2.1 路由与页面栈
  ├─ Router ─────────────► 系统自动恢复页面栈（目标端同步 restoreWindowStage）
  └─ Navigation ─────────► 关闭自动迁移，手动保存页面栈再重建
  │
  ▼
步骤2.2 数据通道选型
  ├─ 轻量状态 ───────────► want.parameters
  ├─ 复杂/可变状态 ──────► DDO
  ├─ 文件 ──────────────► Asset 根属性
  └─ 可重拉取数据 ───────► 只传数据标识
  │
  ▼
步骤2.3 装饰器版本
  ├─ V1 ─────────────────► @State → @StorageLink
  └─ V2 ─────────────────► @Local + @Monitor + 手动 AppStorage 绑定
  │
  ▼
步骤2.4 源端退出策略
  ├─ 默认 ───────────────► 退出
  ├─ 按需适配垂类 ────────► 与用户确认
  └─ 保留源端 ───────────► SourceProgress.ets
  │
  ▼
步骤3 输出开发方案 ───────► 用户确认？
  ├─ 否/未完全明确 ───────► 回到步骤2/3继续确认，禁止改码
  └─ 是 ─────────────────► 步骤4 改码
                              │
                     ┌────────┴────────┐
                     ▼                 ▼
                写入正常           写入异常（请求用户帮助→无果：改为输出待合并片段+列入人工清单）
                     │
                     ▼
                步骤5 自检
                     ├─ 不通过 ──► 回退步骤4修正后重检
                     └─ 通过 ────► 步骤6 报告（真机/人工未验证项如实标记）
```

## Execution Flow（六步执行流程）

所有实施工作按以下 6 步顺序推进，每步有明确的**目标、执行项、通过条件和失败处理**。

```
核验 → 确认 → 设计 → 改码 → 自检 → 报告
```

### 步骤 1：核验（Verify）

**目标**：核验执行条件，确认 Skill 可执行、用户意图明确、项目满足前提条件。

**执行项：**

1. **意图判定**
   - 用户仅**咨询**（"是什么？""怎么做？""有什么用？"）→ 加载相关 `references/` 直接回答，**不进入后续步骤**
   - 用户要**实施/补齐接续**（"帮我把 XX 接上应用接续"、"给项目增加接续能力"）→ 通过，进入步骤 2
   - 用户要求**评估现有实现**（"接续后状态丢了/白屏"）→ 通过，进入步骤 2，侧重问题定位，步骤3不输出设计文档，改为输出问题定位分析报告

2. **执行条件检查** — 以下条件**不可协商**，进入下一步骤前必须全部满足：

| 执行条件 | 要求 | 不满足时处理 |
|------|----|------|
| **Skill 完整性** | 参考子目录下`README.md`中的文件索引检查skill的整体目录结构, 确认`references/`、`assets/`（含 `examples/`、`templates/`、`checklists/`）、`scripts/` 目录及各子文件存在 | 终止，提醒用户本 Skill 不完整，请重新安装 |
| **API 版本** | SDK/API 版本 >= 12。**字段口径**：取 `build-profile.json5` 的 `compatibleSdkVersion`（老工程无此字段时取 `compileSdkVersion`）——字符串形态取**括号内数字**（如 `"6.0.0(20)"` = API 20），数值形态取数值本身，26.0.0及以上版本取首个数字，要求 >= 12 | 终止，告知用户先升级项目运行的API版本。本 Skill 不处理低版本（API 9–11）兼容性适配 |
| **边界条件** | 当前 Skill 仅支持同一 BundleName 下的 Ability 跨端迁移 | 终止，告知用户当前 Skill 版本尚不支持不同 BundleName 的 Ability 跨端迁移，敬请关注后续更新 |

**通过条件**：意图明确为实施或评估 + Skill 完整 + API 版本 >= 12 + 用户要求在 Skill 能力边界之内

### 步骤 2：确认（Confirm）

**目标**：初步阅读项目代码，与用户交互确认本次接续的全部必选要求。**先确认需求，再进入设计。**

**阅读项目代码，按场景盘点清单逐项确认以下内容，整理后再与用户交互确认（缺一不可）：**

1. **接续场景** — 加载 `assets/checklists/confirm-scene-inventory.md` 进行场景盘点；用户以业务垂类描述需求（如"备忘录""地图导航""会议""听书""股票行情"）时，直接查阅清单内 **附录 A 垂类场景推荐表** 给出默认值（发起接续页面与同步内容、源端退出方案、技术场景类型），与盘点结果一并整理
2. **当前项目是否已有任何接续配置**（`continuable`、`onContinue` 等）
3. **项目路由方式** — Navigation 还是 Router（影响页面栈迁移方案）
4. **页面栈是否迁移** — 默认迁移；仅 Router 支持系统自动恢复，目标端须在 `onCreate`/`onNewWant` 执行完成前同步调用 `restoreWindowStage()` 触发；Navigation 不支持自动恢复，须设置`SUPPORT_CONTINUE_PAGE_STACK_KEY = false` 关闭页面栈自动迁移后，走手动保存页面栈再重建的方案
5. **接续后源端应用如何处理** — 退出/保留/暂停/返回？默认退出；清单 附录 A 中各垂类有推荐默认值，其中影音/儿童/社媒/设计等"应用按需适配"垂类需与用户确认；源端退出方案详见清单 **附录 B**

**使用清单**：`assets/checklists/confirm-scene-inventory.md`（内含垂类场景推荐表与源端退出方案说明）

**产出物**：《接续场景清单》 · **通过条件**：必选内容完全确认

**轮次合并（可选）**：小型工程可将本步骤的读码预填结果与步骤 3 的开发方案**合并为一轮**交互确认（清单信息先从代码读出，一轮内同时呈现待确认项与方案）；硬约束不变——必选项未答清不进入改码、方案未获用户确认不动代码。

### 步骤 3：设计（Design）

**目标**：完整阅读项目现有代码，产出开发方案。**先确认方案，再进入改码。**

**执行项：**

1. **阅读项目代码** — Ability 结构、路由方式、页面状态管理、数据模型
2. **加载场景资源** — 根据步骤 2 确认的场景，从 [场景指南](#scenario-guide场景指南) 加载对应方案说明、代码示例和自检清单（按需加载，不全加载）
3. **加载通用参考文档**— 从 [通用资源](#cross-scenario-resources通用资源) 加载前提条件约束、API 细节、数据迁移策略（按需加载，不全加载）
4. **确定数据通道选型**（`want.parameters` / DDO / 文件资产迁移 / 数据标识重拉取，见 `references/data-migration-strategies.md`）
5. **输出开发方案** → 用户确认
   - 本次处理的场景范围
   - 涉及的文件清单与每处改动说明
   - 数据通道
   - 路由方式与页面栈迁移方案（**不改变项目现有路由方式**）
   - 预期效果

**产出物**：《应用接续开发方案》 · **通过条件**：用户确认开发方案

### 步骤 4：改码（Implement）

**目标**：按方案只进行最小增量修改，不破坏项目原本功能。

**纪律要求：**

1. **只改方案范围内的文件** — 不改、不重构、不优化无关代码
2. **接续逻辑通过 `launchReason` 判断分支执行** — 不侵入应用的正常启动路径
3. **加载场景资源** — 从 [场景指南](#scenario-guide场景指南) 加载对应示例代码和自检清单，逐项核对实施要点
4. **参照通用模板** — 从 [通用资源](#cross-scenario-resources通用资源) 加载模板代码修改项目配置和 Ability 生命周期
5. **使用正确的 API 签名、导入路径和类型定义** — 以 `references/api-reference.md` 与 `assets/examples/*.ets` 为准，禁止使用错误语法或假想 API
6. **接续全链路埋固定日志点** — 改码时在接续链路埋固定 `hilog` 日志（统一 testTag）
7. **工程文件写入异常处理** — 无法写入工程文件（缺失文件访问权限 / 只读 / 路径不可达等）时：先**向用户请求帮助**（说明所需权限与目标路径）；尝试无果后**不假装已完成接入**——对项目的修改更换为输出**待合并代码片段**（每个片段标注目标文件与插入/替换位置，可直接复制合并）并在**人工操作清单**中逐项列出待执行动作，如实标记为未完成

### 步骤 5：自检（Self-Check）

**目标**：验证改码结果是否满足方案要求。

**检查项：**

1. **代码正确性** — API 签名、导入路径、类型是否正确（依据 `references/api-reference.md` 核对；是否存在语法错误；是否只改了方案范围内的文件）
2. **完成度** — 方案中每一项是否都已实现；是否有未完成项（有则如实标记，**不谎称完成**）
3. **回归影响** — 是否影响了项目原有功能
4. **编译/静态语法检查** — 按环境能力降序选择检查手段，**优先跑工具、跑不了才标人工**：
   - **devecocli 已安装** → `devecocli check lint <改动文件>` 或 `devecocli build`
   - **无 devecocli 但装有 DevEco Studio（≥ 26.0.0.610）** → 运行本 Skill 内置脚本 `scripts/arkts-check.js`（详见 `scripts/README.md`；macOS 分支未真机验证，Linux 不支持）
   - **以上均不可用** → 编译验证纳入人工操作项，明确告知用户

   判定口径：error 级（severity=1）诊断必须修复后重检；warning/deprecation 记入报告。编译检查通过但无连接设备/无法真机验证时，真机验证项（组网、冷/热启动、双端数据核对）全部标记为需人工操作并明确告知用户——不阻断交付，也不得声称已真机验证
5. **场景自检清单** — 按场景类型逐项核对对应的 `assets/checklists/checklist-*.md`

**不通过处理**：回退到步骤 4 修正，修正后重新自检

**通过条件**：全部检查项通过，或未完成项已如实标记

### 步骤 6：报告（Report）

**目标**：向用户交付完整的结果报告。

**报告内容：**

1. **改动文件清单** — 每个文件改了什么、为什么改
2. **引导确认摘要** — 概括实施的方案和用户确认的内容，供用户核对实施与确认内容是否一致
3. **自检结果** — 哪些已通过，哪些未完成及原因
4. **需人工操作项** — NAPI（C/C++ 原生侧）、编译验证、真机验证、组网配置、权限授权等无法完成的内容，明确标记并告知用户
5. **已知风险** — 执行过程中发现的风险项
6. **后续建议** — 是否继续处理下一个场景

**纪律**：未完成的工作如实说明。无法用代码实现的项标记为"需人工操作"，**不声称"已全部完成"**。

---

## Scenario Guide（场景指南）

按场景类型索引对应的参考文档、代码示例和自检清单。**步骤 3（设计）和步骤 4（改码）时，根据确认的场景加载对应资源。** 各场景的实施要点和常见陷阱详见对应的自检清单。

> **资源加载规则**：各 reference 文件末尾的"关联资源"仅供扩展阅读，agent 无需自动跟随加载其他 reference。仅按本表和 Cross-Scenario Resources 表中的指引加载资源。

| 场景 | 适用 | 方案说明 | 自检清单 | 代码示例 |
|------|------|---------|---------|---------|
| UI 浏览类 | 列表、详情、Tab（含 Web） | `references/ui-progress-continuity.md` | `assets/checklists/checklist-ui-progress.md` | `assets/examples/UIProgress.ets`、`assets/examples/WebProgress.ets` |
| 内容编辑类 | 表单、文本编辑器 | `references/edit-progress-continuity.md` | `assets/checklists/checklist-edit-progress.md` | `assets/examples/EditProgress.ets` |
| 媒体播放类 | 音视频播放器 | `references/playback-progress-continuity.md` | `assets/checklists/checklist-playback-progress.md` | `assets/examples/PlaybackProgress.ets` |
| 页面栈迁移 | 多层 Navigation/Router | `references/navigation-continuity.md` | `assets/checklists/checklist-navigation.md` | `assets/examples/NavigationContinuity.ets`、`assets/examples/RouterContinuity.ets` |

---

## Cross-Scenario Resources（通用资源）

跨场景通用的配置模板、官方文档摘录和辅助示例。**步骤 3（设计）和步骤 4（改码）时按需加载。**

| 类型 | 文件 | 说明 | 加载时机 |
|------|------|------|---------|
| 模板 | `assets/templates/EntryAbility.ets` | UIAbility 生命周期接续模板（源端 onContinue；目标端 onCreate / onNewWant + 同步调用 restoreWindowStage 触发页面恢复；onWindowStageRestore 按需镜像 onWindowStageCreate 初始化） | 步骤 4 配置 Ability 时 |
| 模板 | `assets/templates/module.md` | `module.json5` 接续标准配置片段（continuable、launchType、权限） | 步骤 4 配置 module.json5 时 |
| 参考 | `references/api-reference.md` | API 签名、参数/返回值、错误码、版本矩阵 | 步骤 4 需要 API 细节时 |
| 参考 | `references/constraints-and-prereqs.md` | 设备/组网/权限前提条件与约束清单 | 步骤 2 评估前提条件时 |
| 参考 | `references/data-migration-strategies.md` | 数据迁移选型决策矩阵与代码示例 | 步骤 3 数据通道选型时 |
| 参考 | `references/state-decorator-migration.md` | V1/V2 状态装饰器改造规则：@State→@StorageLink 变换、@ComponentV2 手动绑定模式 | 步骤 3 识别页面装饰器版本时；步骤 4 改造状态变量时 |
| 示例 | `assets/examples/SourceProgress.ets` | 控制迁移后源端应用不退出 | 需要保留源端时 |

---

## Quick Reference（速查表）

### 关键 API 速查

| API / 配置 | 端 | 用途 | 版本 |
|------------|----|------|------|
| `continuable: true` | 配置 | 声明 UIAbility 可被接续 | API 9+ |
| `onContinue(wantParams)` | 源端 | 保存当前状态、返回结果码（同步版 API 9+；Promise 异步版 **API 18+**，12–17 仅同步版——口径见 `references/api-reference.md` §2.1） | API 9+ |
| `onCreate(want)` | 目标端 | 冷启动时接收迁移数据并恢复 | API 9+ |
| `onNewWant(want)` | 目标端 | 热启动时接收新迁移请求 | API 9+ |
| `onWindowStageRestore()` | 目标端 | 迁移启动时替代 onWindowStageCreate 触发；仅当 onWindowStageCreate 有初始化时镜像执行 | API 9+ |
| `restoreWindowStage(localStorage)` | 目标端 | 在 onCreate/onNewWant 执行完成前**同步**调用，触发带页面栈的页面恢复，**须 try/catch 兜底** | API 9+ |
| `setMissionContinueState()` | 双端 | 动态开启/关闭迁移能力 | API 10+ |
| `want.parameters` | 双端 | 轻量可序列化状态数据传递 | API 9+ |
| `DistributedDataObject` | 双端 | 复杂/可变状态数据跨设备同步 | API 9+ |
| `SUPPORT_CONTINUE_SOURCE_EXIT_KEY` | 源端 | 控制迁移后源端是否退出 | API 10+ |
| `SUPPORT_CONTINUE_PAGE_STACK_KEY` | 源端 | 控制是否迁移页面栈 | API 10+ |

> 完整签名与版本矩阵 → `references/api-reference.md`

### 数据迁移选型速查

| 状态特征 | 推荐方式 |
|----------|----------|
| 少量标量/短 JSON（< 100KB） | `want.parameters` |
| 列表、表单、可变对象（≥ 100KB） | 分布式数据对象（DDO） |
| 图片/视频等文件 | 写入 `distributedFilesDir` + **Asset 作为 DDO 根属性**（数组须展平 `attachments0..N`）或 API 20+ `setAssets`；❌ 只传文件名/URI 引用不可靠（对端不会自动同步文件） |
| 可重拉取的业务数据 | 只传数据标识，目标端重新获取 |

> 决策细节与边界 → `references/data-migration-strategies.md`

---

## Common Mistakes（常见误区）

按执行步骤分组的跨场景通用误区。场景特定的陷阱排查详见对应的 `assets/checklists/checklist-*.md`。

### ArkTS 语法（跨场景通用）

> LLM 对 ArkTS 语料掌握普遍不足，改码后须使用静态语法检查脚本验证。以下均为高频语法错误（违反即编译失败）：

- ❌ 用 `any`/`unknown` 兜底类型 → ArkTS 禁止，必须写具体类型（类/接口/联合类型）
- ❌ 对象字面量不标注类型，或用字面量初始化**带方法/含参构造函数/`readonly` 字段的类** → 显式标注类型；后者用 `new` + 逐字段赋值
- ❌ `obj['key']` 动态访问字段、`[key: string]: T` 索引签名 → 类显式字段 + 点访问；动态 key 用 `Map` 或 `Record`
- ❌ 解构赋值/解构声明（`let { a, b } = obj`、`[x, y] = arr`）→ 逐字段取临时变量
- ❌ `A & B` 交叉类型、条件类型/`infer`、映射类型、`as const` → `interface extends`、带显式约束的泛型、显式类、`const` + 显式类型
- ❌ 依赖 structural typing（结构相同的类互相赋值/传参）→ 通过 `implements` 同一接口或继承建立关系
- ❌ `is` 类型守卫、`Function.apply`/`call`/`bind`、`#` 私有字段、constructor 参数属性 → `instanceof` + `as`、直接调用/箭头函数、`private`、类体声明字段
- ❌ 函数体内用 `this`、函数内嵌套声明函数、生成器函数 → `this` 仅限类实例方法；顶层函数/箭头函数
- ❌ `let x!: T` 确定赋值断言、完整 TS Utility Types、`var` → 声明即赋值；仅支持 `Partial`/`Required`/`Readonly`/`Record`；一律 `let`
- ❌ 可空类型直接访问属性 → 用 `T | null` 联合类型 + `?.`/`??` 处理，不使用`!`处理
- ❌ 忽略编码规范（tab 缩进、双引号、非驼峰命名）→ 空格缩进、单引号、规范命名

### 步骤 1：核验

- ❌ 未确认用户意图直接改代码 → 用户可能只是咨询，应在明确"要求实施"后再动手
- ❌ 未检查 API 版本就施工 → 本 Skill 硬约束 API >= 12，低版本请先升级 SDK

### 步骤 3：设计

- ❌ 只确认了需求、未确认开发方案就改代码 → 应输出方案让用户确认后再改代码
- ❌ 未告知默认数据范围边界 → 用户默认"接续 = 数据全都带过去"，而默认方案仅迁移当前打开页面的状态与关联文件（本地库/其余记录不迁移），验收落差引发争议；设计阶段必须显式说明边界并确认是否需要整库/可选数据迁移（`assets/checklists/confirm-scene-inventory.md` §六）

### 步骤 4：改码

- ❌ 一次性把所有页面/数据全接上 → 周期长、难验收、回归面大（应按工作量，优先级评估，分场景逐个接入，小项目才考虑一次性全部接入）
- ❌ 完全不用 `restoreWindowStage()` → 使用系统页面栈恢复（Router 默认）时，推荐在 `onCreate()`/`onNewWant()` **执行完成前同步**调用 `restoreWindowStage()`，触发带页面栈的页面恢复；注意放进异步回调会导致迁移后页面加载失败
- ❌ 默认给 EntryAbility 添加 `onWindowStageRestore()` 并 `loadContent` → 仅当 `onWindowStageCreate()` 中有启动必要的初始化时，才需在 `onWindowStageRestore()` 中执行**同样的初始化**；系统页面栈恢复（Router 默认）时页面已由 `restoreWindowStage()` 恢复，此时 `loadContent` 反而会破坏已恢复的页面栈。`onWindowStageCreate` 无初始化时整段省略该回调（最小侵入）
- ❌ 滚动位置恢复在容器就绪前立即执行 → 原生 `Scroll` 布局未完成时 `scrollTo` 被**静默忽略**；Web 在 `onPageEnd` 时懒加载内容/H5 渲染高度常未就绪，立即恢复被**钳制**——均表现为接续后停留顶部（真机反馈高频失败）。必须延时执行：原生延迟到布局完成后（`setTimeout ≥ 50ms` 或 `onAreaChange`）；Web 按 continue-progress 官方模式用 `runJavaScript` 恢复 H5 `scrollTop`，且放在 `onPageEnd` 之后再延时 ≥300ms（模式见 `references/ui-progress-continuity.md` §3.2/§5.2、`assets/examples/WebProgress.ets`）
- ❌ 播放进度时间单位混淆（秒/毫秒）→ AVPlayer 全链路**毫秒**（`seek` 官方参数名即 `timeMs`，`currentTime`/`on('timeUpdate')` 同为毫秒时间基），ArkUI Video 组件全链路**秒**（`onUpdate`/`onPrepared`/`setCurrentTime` 官方单位均为 s）——采集与恢复两端单位不一致或缺换算时，表现为接续后进度跳至片尾或 ≈ 开头、形似"从头播放"（真机 debug 实证）。迁移通道统一约定单位（建议秒，与播放方案 §2 状态模型一致）：AVPlayer 采集端 ÷1000、恢复端 `seek(秒 × 1000)`；Video 组件直接用秒（见 `assets/checklists/checklist-playback-progress.md` §2-A）
- ❌ 读取本机 SDK 的 d.ts 文件核验 API 签名 → SDK 目录在工作区之外，执行流程严重绕远路且容易触发权限申请；签名以 `references/api-reference.md` 与示例代码为准（版本差异已给出兼容写法），验证统一走步骤 5 编译检查
- ❌ 目标端恢复写成同端自循环（`AppStorage.setOrCreate(k, AppStorage.get(k) ?? v)`）→ 迁移数据从未从 `want.parameters` 落地；编译/静态检查全过，仅表现为对端"正常打开空白/初始页"，极难排查。**数据流方向**：源端只 `AppStorage → wantParam`，目标端只 `want.parameters → AppStorage`（各 checklist §一）
- ❌ `restoreWindowStage()` 调用不做异常兜底 → 运行时可能抛异常导致对端白屏；try/catch 失败时置标记，在 `onWindowStageRestore` 中兜底 `loadContent` 落地页
- ❌ 图片/文件"只传引用"（仅把文件名/URI 放进 want.parameters 或 DDO，或只写 `distributedFilesDir` 就等对端可读）→ 对端**不会**自动同步该文件，这是"文本正常、图片空白"的头号根因。必须让 `commonType.Asset` 作为 DDO **根属性**（数组须 `flatAssets()` 展平为 `attachments0..N`）或用 API 20+ `setAssets`，由接续框架实际传输
- ❌ 未识别页面装饰器版本直接添加 `@StorageLink` → `@ComponentV2` 组件不支持 `@StorageLink`，应改用 `@Local` + `@Monitor` + 手动 AppStorage 绑定
- ❌ 改造 `@Prop` / `@Link` 时只改子组件不改父组件 → 父子数据链路断裂，需同步修改
- ❌ 工程文件写入失败（缺失访问权限 / 只读）后静默跳过或按"已完成"收尾 → 先向用户请求帮助（说明所需权限与目标路径）；无果则改为输出**待合并片段**（标注目标文件与插入位置）并在**人工操作清单**中如实标记未完成

### 步骤 6：报告

- ❌ 谎称"已完成"的内容实际未完成 → 未完成的工作必须如实说明，禁止将未完成内容当做已完成报告
- ❌ 未说明需人工验证 → 真机验证、双端组网、权限授权等无法用代码替代，必须明确标记
- ❌ 文件/图片类场景以"编译通过"上报迁移完成 → 文件是否真正到达对端只能真机实测验证；未实测时必须在报告中标记为**未验证项**

---

## Resource Index（资源索引）

| 目录 | 内容 | 说明 |
|------|------|------|
| `references/` | 8 份参考文档 + 索引 | 按需加载，详见 `references/README.md` |
| `assets/examples/` | 7 个场景化代码示例 | 实施时加载，详见 `assets/README.md` |
| `assets/templates/` | 配置文件 + 通用模板 | 配置接入时加载 |
| `assets/checklists/` | 场景盘点模板 + 4 份场景自检清单（ui/edit/playback/navigation） | 步骤 2（确认）和步骤 5（自检）时使用 |
| `scripts/` | ArkTS 静态语法检查脚本（`arkts-check.js` + ps1/sh 启动器；macOS 分支未真机验证，Linux 不支持） | 步骤 5（自检）编译/语法检查：无 devecocli 环境直接用 DevEco Studio 检查，详见 `scripts/README.md` |
| `test-cases/` | 测试用例 | `test-prompts.md`（测试用提示词）+ `test-case-*.md`（tc_001–tc_008 测试用例完整说明：场景、判定点、运行口径），用以验证 Skill 功能 |
