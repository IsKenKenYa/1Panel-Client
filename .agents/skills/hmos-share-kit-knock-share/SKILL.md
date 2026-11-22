---
name: hmos-share-kit-knock-share
description: Integrating HarmonyOS Share Kit knock share into projects. Use when requests involve knock share, touch-to-share file or link transfer. Provides manager injection, lifecycle listener registration, SharedData construction for files or App Linking, and API version compatibility checks.
license: MIT
metadata:
  version: "2.6.5"
  category: "HarmonyOS SDK"
  kit: "ShareKit"
  min_sdk: "6.0.0(20)"
---


# Share Kit 碰一碰接入助手

## 功能定位

引导式接入 **碰一碰**（`harmonyShare.on('knockShare')`）：先确认分享类型，再注入对应资产包、挂载生命周期；文件侧可选电脑接收/精准命中；链接侧可选 App Linking 接收拉起。

**停手条件（跨 Agent 必读）**
- 读不到与 `SKILL.md` 同级的 `assets/`，或打不开本次类型对应的 `assets/file/` / `assets/link/` / `assets/both/` 模板 → **立即停止改码并回滚本次已改文件**。只输出原因与人工清单。
- 升到 API 26+ 时打不开 `assets/sdk-profile-snippet.json5` → **停止改 SDK 字段并回滚已改的 build-profile.json5**，不得凭记忆写 `"7.0.0(26)"`。
- **禁止**凭记忆重写 Manager / Provider。禁止从宿主工程里其它页面或模块整份拷贝来代替本 Skill 模板。本 Skill 自包含，不依赖任何示例应用。
- 接线只读本次类型那一份：`wiring-snippet-file.ets` / `wiring-snippet-link.ets` / `wiring-snippet-both.ets`。禁止打开另外两份，禁止把三者内容拼进同一页。
- **任何停手/失败/用户中途放弃时，必须回滚本次会话已写入的所有文件变更**（见硬约束 A4）。

**范围**
- 做：文件分享、App Linking 链接分享、文件侧可选 `dataReceive` / API 26+ 精准命中、链接接收侧拉起（配置确认后）、静态检查 + 编译验证
- 不做：不替代手动签名、域名托管、设备开关与真机碰一碰联调

**接入版本要求（不满足则中止改码）**
- **SDK 目标按分享类型分档，禁止未问类型/Q8 就按 20 一刀切升级或中止**
  - **仅链接**（不含文件）：目标 **API 20+**，写入 `"6.0.0(20)"`。当前更低 → 确认升级到 20+；拒绝则停止改码。不问 Q8
  - **类型含文件**（仅文件 / 两者）：文件模板按 **22+** 交付（`clarifyNonShare` / `dataReceive`），**先确认 Q8** 再定 22 还是 26
    - Q8 = **yes** → 目标 **API 26+**，写入 **`"26.0.0"`**（SemVer，无括号）。当前更低 → 确认升级到 26+；拒绝升级则 **不做精准**，改按 **API 22+** 做文件发送（不要落到 20）
    - Q8 = **no** → 目标 **API 22+**，写入 `"6.0.2(22)"`。当前更低 → 确认升级到 22+；拒绝则停止改码
- 升 26 时必须打开 `assets/sdk-profile-snippet.json5` 的 `fileApi26` 字段合并进现有 product；**禁止**写成 `"7.0.0(26)"` / `"6.0.0(26)"` / `26`。细则见 [references/sdk-version.md](references/sdk-version.md)
- 含文件时 Q7 电脑接收已包含在 22+ 目标内，不必在 20 上再单独升 22。Q7=no 不降低文件侧 22 下限

## 运行环境

可在任意能加载 Agent Skill 目录、并能读写宿主工程的 Agent 上使用。不绑定特定 IDE / 产品；正文与资产不引用任何一家的专有工具名、MCP 名或安装路径。

- **安装**：把本 Skill 整目录放到当前 Agent 会扫描的 skills 路径即可。文中路径均相对 **本 Skill 根目录**（`SKILL.md` 所在目录），不是宿主工程根目录，也不是某一家 IDE 的专有目录。
- **整包加载**：必须能访问与 `SKILL.md` 同级的 `assets/`、`references/`。拷贝前先 **打开** 本次类型对应的 Manager / Provider 文件，确认读到内容再拷。
- **读不到模板则中止**：找不到、读失败、或只能看到 `SKILL.md` 而没有 `assets/` → **停止改码**；**禁止**凭记忆重写模板，也禁止从宿主工程已有页面整份拷贝来代替。
- **无法改宿主工程**：只输出待合并片段与人工清单。
- **无构建能力**：有则用 HarmonyOS / DevEco 检查与构建（名称因宿主而异，例如 ets 静态检查、工程构建，或 IDE 内置检查/构建）；没有则在报告写明未自动编译，人工清单加「请在 DevEco Studio 编译通过」。禁止未编译却宣称通过。
- **引导提问**：用当前环境可用的问答方式即可（对话选项、表单、逐条确认均可），**不依赖**某一家的专用提问工具。
- **非交互环境**：仍须引导确认；仅当开发者明确「由 skill 自行决定」才可对未答项自决。
- **`test-cases/`**：供人验收，执行接入时不必加载。

## 待办事项

按下列清单跟踪进度，完成后逐项勾选（用当前环境可用的待办/清单即可，不依赖特定工具名）。阶段编号与「决策路由」一致：

- [ ] 0. 只读预检查（当前 SDK / 是否已接入；**禁止写任何文件**；**先勿按 20 一刀切升级或中止**）
  - [ ] 0a. 准入硬约束校验（assets 可读 / sdk-profile 可读 / 宿主可读写）
  - [ ] 0b. 回滚能力预判（git 版控？）+ 基线快照（git status / HEAD 或关键文件清单）
- [ ] 1. 存量判定与能力清单（已有 → 输出能力清单 + 迁移标记，判定 新增 / 微调 / 迁移 / 下线）
- [ ] 2. 新增 / 增量补能力 / 迁移（**仅链接定 20+；含文件则先 Q8 再定 22+/26+；答完再改码**）
  - [ ] 2a. 变更预览确认（列出新增/修改/删除文件 + SDK 变更 + 资产拷入；开发者确认后才写文件）
  - [ ] 2b. 注入 / 增量扩展 Manager 与宿主 Provider / 迁移（旧类名/旧SDK/旧enable签名）
- [ ] 3. 微调已有能力（如适用；变更预览确认 → 重走 Q3/Q7/Q8 核验）
- [ ] 4. 挂载页面生命周期 + 挂载冲突预检（已有 knockShare 监听？钩子被占用？windowId 冲突？）
- [ ] 5. （可选）文件：电脑接收 / 精准命中 / **接收落点**；链接：App Linking 发送 + 接收侧
- [ ] 6. 业务规则校验（编译前独立校验：URI 可访问 / utd 一致 / apiAvailable 字面量 / canShare 逻辑 / 不混传）
- [ ] 7. 静态检查 + 编译验证
- [ ] 8. 回滚（如触发；变更写入后任何失败 / 取消）
- [ ] 9. 输出完成报告与人工清单（如发生过回滚，附回滚摘要）

## 决策路由

先按本节走完整决策链，再进「工作流程」执行细节。各步细则见「接入版本要求」「工作流程 §1 提问范围表」「资产分包表」与「硬约束」。

```
用户提出碰一碰相关问题
│
├─ 阶段 0：只读预检查（此阶段禁止写任何文件、禁止改 SDK）
│   ├── 仅为概念说明 / 对比，未要求接入或补齐？
│   │   └── 是 → 简要说明差异，不改工程，停
│   ├── 准入硬约束校验：
│   │   ├── 能读到本 Skill 整包（含对应 assets 模板与本次挂载示例）？否 → 停止改码，停
│   │   ├── 升 26 时能打开 assets/sdk-profile-snippet.json5？否 → 停止改 SDK 字段，停
│   │   └── 宿主工程可读写？否 → 只输出待合并片段与人工清单，停
│   ├── 读取 build-profile.json5，只记录当前 compatibleSdkVersion / targetSdkVersion
│   ├── 搜索 KnockShareManager / Provider / knockShare（含旧类名 KnockFileShareManager）
│   │   └── 记录检测结果（均无 / 已有），此阶段不做首次/增量判断
│   ├── 定位入口模块（默认 entry）
│   ├── 回滚能力预判：工程是否在 git 版控下？（记录结论，供阶段 5 使用）
│   └── 基线快照：git 版控下 → 记录当前 git status / HEAD commit（供回滚比对）
│                   非 git → 列出即将涉及的关键文件清单（供回滚还原）
│
├─ 阶段 1：存量判定与能力清单（仍只读，禁止写文件）
│   ├── 工程内是否已有碰一碰相关代码？
│   │   ├── 均无 → 新增，跳到阶段 2
│   │   └── 已有 → 输出当前能力清单（结构化）：
│   │         · 文件分享：✓ / ✗（getFileShareData / addRecord / FILE）
│   │         · 链接分享：✓ / ✗（getLinkShareData / HYPERLINK）
│   │         · 电脑接收：✓ / ✗（dataReceive / getReceiveCapabilities）
│   │         · 精准命中：✓ / ✗（KnockRectUtil / hitTestReceiveIndex）
│   │         · 当前 SDK 版本与已接入类型的目标档位
│   │         · 旧类名（KnockFileShareManager）/ 旧 enable 签名 / 旧 SDK 写法？（迁移标记）
│   │         └── 本次意图？
│   │               ├── 新增（补类型 / 接收 / 精准）→ 跳到阶段 2，按增量走
│   │               ├── 微调已有能力（改 URI 来源 / utd / 接收落点 / 可选字段）→ 跳到阶段 3
│   │               ├── 迁移（旧类名→新类名 / 旧 SDK 写法→新写法 / enable 签名升级）→ 跳到阶段 2 迁移子分支
│   │               └── 下线 / 拆除碰一碰 → 说明本 Skill 不处理下线（见「范围」），停
│   │
├─ 阶段 2：新增 / 增量补能力 / 迁移（决策通过后才写文件）
│   ├── 变更预览确认（写文件前必须先预览）：
│   │   ├── 列出本次将新增 / 修改 / 删除的文件清单 + 每处改动摘要
│   │   ├── 列出 SDK 版本变更（若有）
│   │   ├── 列出将拷入的资产文件
│   │   └── 开发者确认预览 → 才写文件；拒绝 → 停止（不触发回滚，因尚未写入）
│   ├── 分享类型是否已明确？
│   │   ├── 否 → 本轮只问类型（仅文件 / 仅链接 / 两者），不问其余项，停
│   │   └── 是 → 沿用，进入对应分支 ↓
│   ├── 仅链接
│   │   ├── 当前 SDK < 20？
│   │   │   ├── 是 → 确认升到 20+，写 "6.0.0(20)"；拒绝则停止改码（触发回滚）
│   │   │   └── 否（已 ≥ 20）→ 不改 SDK，继续
│   │   ├── 问挂载页、域名 / path / 落地页、端侧 skills 与签名、落盘目录
│   │   │   （禁止问文件数量 / 文件 uri / 电脑接收 / 精准）
│   │   ├── 打开并拷贝 assets/link/；只打开挂载示例 wiring-snippet-link.ets
│   │   └── 端侧是否就绪且开发者确认改配置？
│   │         ├── 是 → 合并 skills + Ability 落盘与跳转；云侧列人工清单
│   │         └── 否 → 不写生产拉端配置；不声称已可直达；列人工清单
│   ├── 仅文件
│   │   ├── 是否精准（Q8）未明确？→ 本轮先只问 Q8，停
│   │   ├── 要精准 → 目标 26+，写 "26.0.0"（SemVer）；须打开 sdk-profile-snippet.json5 的 fileApi26
│   │   │   ├── 已是 26.x.y 且满足 26+ → 不降回 "26.0.0"
│   │   │   └── 当前更低 → 确认升 26+；拒绝 → 不接入精准，改按 22+ 发送（不拷 KnockRectUtil）
│   │   ├── 不要精准 → 目标 22+，写 "6.0.2(22)"
│   │   │   └── 当前更低 → 确认升 22+；拒绝 → 停止改码（触发回滚）；已 ≥ 22 则不改 SDK
│   │   ├── 再问挂载页、文件数量 / 范围 / URI 宿主来源 / utd、是否电脑接收、落盘目录
│   │   ├── 打开并拷贝 assets/file/；只打开挂载示例 wiring-snippet-file.ets
│   │   ├── 精准 = 是 → 额外拷 KnockRectUtil.ets
│   │   ├── 电脑接收 = 是 → capabilities 与发送侧 utd 一致；maxSupportedCount ≤ 5
│   │   └── 电脑接收且精准均为是 → 先读挂载页 UI，再确认接收落点（含自定义）
│   ├── 两者
│   │   ├── 同「仅文件」路径定 SDK 与 Q8
│   │   ├── 文件一组（URI 来源、电脑接收等）+ 链接一组（域名、签名等）均问清，不混成一句
│   │   ├── 打开并拷贝 assets/both/；只打开挂载示例 wiring-snippet-both.ets
│   │   ├── 精准则拷 KnockRectUtil.ets；确认升级 SDK 时打开字段片段
│   │   └── 链接侧同「仅链接」的端侧就绪分支
│   ├── 增量补能力（已有 Manager/Provider）
│   │   ├── 补类型 → 升级为 assets/both/，禁止第二套监听；继续走上方类型分支定 SDK 与剩余提问
│   │   ├── 补接收 / 精准 → 按未定项继续问，不重复注入管理类
│   │   └── （补能力也适用阶段 2 对应类型的 SDK / 提问 / 资产拷贝规则）
│   ├── 迁移（旧类名 / 旧 SDK 写法 / 旧 enable 签名 → 新）
│   │   ├── 旧类名 KnockFileShareManager → KnockShareManager（全局重命名，页面同步改引用）
│   │   ├── 旧 SDK 括号写法 "6.0.x(22)" → 目标 26+ SemVer "26.0.0"（打开 fileApi26）
│   │   ├── 旧 enable 签名 → 新签名（+ mode / + options，按目标类型对号）
│   │   └── 迁移后跳到阶段 4 验证
│   │
├─ 阶段 3：微调已有能力（改动范围小于阶段 2，不新增 Manager/Provider）
│   ├── 变更预览确认（同阶段 2 预览规则，写文件前必须先预览）
│   ├── 确认要微调哪项已启用能力：
│   │   ├── 发送 URI 来源变更 → 重新核验 Q3（URI 在宿主中的来源、可访问性），改 Provider 写入处
│   │   ├── utd 变更 → 重新核验 Q3 utd；若 Q7=yes 须同步改 dataReceive.capabilities
│   │   ├── 接收落点调整（Q7=yes 且 Q8=yes）→ 先读宿主 UI，重新确认落点，改 hitTestReceiveIndex 解释逻辑
│   │   ├── 可选字段（title/description/thumbnailUri）→ 确认后加或去
│   │   └── 其它参数微调（maxSupportedCount 等）→ 确认后改
│   ├── 微调后重走对应核验：
│   │   ├── 类型含文件 → 重走 Q3 URI 核验
│   │   ├── Q7=yes → 核验 capabilities 与发送 utd 仍一致
│   │   └── Q8=yes → 核验 apiAvailable 字面量、命中 id 覆盖当前可见项
│   └── 跳到阶段 4 验证
│   │
├─ 阶段 4：页面挂载与业务规则校验（首次 / 增量 / 微调 / 迁移共用）
│   ├── 挂载冲突预检：
│   │   ├── 目标页面是否已有其它 knockShare 监听？→ 有 → 合并到同一 Manager，禁止第二套
│   │   ├── onShown / onPageShow 是否已被其它逻辑占用？→ 是 → 追加而非覆盖已有钩子
│   │   ├── NavDestination / @Entry 结构是否可探测？→ 探测失败 → 追问挂载钩子后再改
│   │   │   ├── NavDestination → onShown / onHidden
│   │   │   └── @Entry → onPageShow / onPageHide
│   │   └── 2in1 windowId 绑定是否冲突？→ 冲突 → 追问目标窗口
│   ├── 业务规则校验（编译前独立校验，不依赖编译器）：
│   │   ├── 类型含文件 → 发送 URI 可访问？utd 与真实文件匹配？
│   │   ├── Q7=yes → dataReceive.capabilities 的 utd 与发送侧一致？
│   │   ├── Q8=yes → apiAvailable 传入字面量？命中 id 覆盖当前可见项？
│   │   ├── canShare() 不按设备类型返回 false？
│   │   ├── 单次 SharedData 不混文件+链接记录？
│   │   └── 业务规则校验失败 → 修复后重校；无法修复 → 触发回滚（阶段 5）
│   ├── 静态检查 / 编译
│   │   ├── 环境有构建能力 → 检查并编译，修复到通过
│   │   └── 无构建能力 → 报告写明未自动编译；人工清单加 IDE 编译
│   │
├─ 阶段 5：回滚机制（变更写入后任何失败 / 取消均可触发）
│   ├── 触发条件（扩大范围）：
│   │   ├── 任何停手条件命中（assets 不可读、SDK 拒绝升级等）
│   │   ├── 变更写入后任何失败（文件写入失败、SDK 合并出错、资产拷贝中断等）
│   │   ├── 业务规则校验失败且无法修复
│   │   ├── 编译失败且无法修复
│   │   └── 用户中途放弃（明确表示停止 / 不再回答引导问题 / 拒绝变更预览）
│   ├── 回滚动作：
│   │   ├── 工程在 git 版控下（阶段 0 已预判）→ git checkout 还原本次会话改动的文件（先 git status 比对基线快照）
│   │   ├── 工程不在 git 下 → 按 阶段 0 记录的关键文件清单 + 每处改动摘要，供人工还原
│   │   └── 已拷入的资产文件（Manager/Provider/KnockRectUtil）若属于本次新增 → 一并还原/列出
│   └── 回滚后输出：回滚原因 + 已还原/待还原文件清单 + 人工下一步建议
│   │
└── 输出完成报告（含 URI 来源；电脑接收与精准都开时含 UI 与落点；人工清单与已知限制；
    若发生过回滚，附回滚摘要）
```

## 工作流程

> 本节为「决策路由」各节点的执行细节（怎么检测、怎么问、怎么接线）。决策走向以「决策路由」为准，禁令以「硬约束」为唯一定义点，本节不重复复述。

### 0. 前置检测

1. 读取 `build-profile.json5`，**只记录**当前 `compatibleSdkVersion` / `targetSdkVersion`，此时不要改 SDK、不要按 20 中止。
2. 搜索 `KnockShareManager` / `KnockShareProvider` / `knockShare`，以及旧类名 `KnockFileShareManager`：
   - **均不存在** → 按 Q1 首次接入（只拷本次类型）。
   - **已存在** → 说明现状；补另一种类型或补文件侧电脑接收/精准命中 → **增量**，勿第二套监听 / 第二套 Manager。
3. 定位入口模块（默认 `entry`）。
4. **SDK 目标按「接入版本要求」**：仅链接 → API 20+。类型含文件 → 必须先有 Q8 答案，再决定升到 API 22+ 或 26+（文件侧不要落到 20）。

### 1. 引导确认（固定问答，答完再改码）

**禁止跳过引导。** 不得仅凭工程代码推断后直接改码。  
**例外**：开发者明确「由 skill 自行决定 / 你来定」时，可对未答项自决，并在报告写明。

#### 先定类型，再按类型提问（禁止串问）

1. **确定类型（Q1）**
   - 已明确「仅文件 / 分享文件」→ 仅文件，**不要再问 Q1**。
   - 已明确「仅链接 / 分享链接 / App Linking」→ 仅链接，**不要再问 Q1**。
   - 已明确「两者都要 / 文件和链接」→ 两者，**不要再问 Q1**。
   - **未说明** → **只先问 Q1**（仅文件 / 仅链接 / 两者），本轮**不要**附带文件 uri / App Linking / 电脑接收 / 精准命中 / SDK 升级档位。
2. **含文件时先定精准，再定 SDK（插在 Q1 之后、Q2/Q3/Q7 之前）**
   - 已明确要精准 / 不要精准 → 直接定 Q8，**不要再问 Q8**。
   - **未说明 Q8** → **本轮只问 Q8**（是否接入精准碰一碰），不要夹杂 Q3 字段、Q7 接收目录、组件 `id`、接收落点。
   - 按 Q8 定目标并与当前 SDK 比较，**升级须开发者确认后再改** `build-profile.json5`（打开 `assets/sdk-profile-snippet.json5` 对号入座，只改现有 product 字段）：
     | Q8 | 升级目标 | 写入 `compatibleSdkVersion` / `targetSdkVersion` | 当前更低时 |
     |----|----------|--------------------------------------------------|------------|
     | yes | **API 26+** | **`"26.0.0"`**（新 SemVer，禁止括号写法） | 确认升到 26+；拒绝 → 不做精准，改按 **API 22+** 发送 |
     | no | **API 22+** | `"6.0.2(22)"`（旧括号写法） | 确认升到 22+；拒绝 → 停止改码 |
   - 当前 SDK 已达目标 → 不改 SDK，继续后续问题。比较方法见 [references/sdk-version.md](references/sdk-version.md)（旧 `"6.0.2(22)"` 与新 `"26.0.0"` 两套都要能读）。
   - **仅链接**：不问 Q8；当前 < 20 则确认升到 **API 20+**，写入 `"6.0.0(20)"`，拒绝则停止。含文件时禁止用 20 作为文件目标。
   - 已是 `"26.0.1"` 等 26.x.y 且满足 26+ 时，不要降回 `"26.0.0"`。
3. 类型与 SDK 目标都定了之后，**给出选项**问其余必问项；**同一轮只问本类型剩余项**。禁止把另一类型的字段写进问题或选项。提问方式不绑定特定产品。

| 已定类型 | 先问（定 SDK） | 其余必问 | **禁止出现在问题中** |
|----------|----------------|----------|----------------------|
| 仅文件 | **Q8** 是否精准碰一碰（已明确则跳过）→ 确认升 **22+** 或 **26+** | Q2 挂载页；**Q3** 文件数量 / 可分享范围 / **文件 `uri` 在宿主中的来源** / `utd` / 可选字段；**Q7 是否**电脑接收；Q6 落盘目录；**Q7=yes 且 Q8=yes** 时再问 **Q8 接收落点**（先陈述读到的实际 UI，再按该结构给插入位置选项，必须含自定义） | App Linking、域名、落地页、`applinking.json`、签名/AGC、`HYPERLINK`；Q8（是否精准）已答后不要再问是否精准；Q7 未定为 yes 时不要问接收目录；Q7+Q8 未同时为 yes 时不要问接收落点；问接收落点时禁止不读页面、禁止套用某种布局的现成选项表；Q8 未定为 yes 时不要问组件 `id` |
| 仅链接 | 当前 <20 则确认升到 **20+**（不问 Q8） | Q2 挂载页；**Q4** 域名 / path / 查询参数 / 落地页；**Q5** 端侧 skills 与签名是否就绪；Q6 落盘目录 | 文件数量、文件 `uri` / `file://`、`getUriFromPath`、`addRecord`、`dataReceive`、精准坐标、组件 `id`；**不要问 `appIdentifier` 填到哪（云侧）** |
| 两者 | 与仅文件相同：先 Q8 再定 **22+/26+** | 上两行「其余必问」（文件一组、链接一组，不要混成一句） | （无） |

题号对照：

| # | 问题 | 何时问 |
|---|------|--------|
| Q1 | 分享类型：仅文件 / 仅链接(App Linking) / 两者都要？ | 仅当开发者未指定类型 |
| Q2 | 挂载页面路径？（可分享页） | 始终（已指定则确认即可） |
| Q3 | 文件数量、可分享范围、**文件 `uri` 获取方式**、`utd`、可选字段 | **仅当类型含文件** |
| Q4 | App Linking 域名、path、查询参数、目标落地页 | **仅当类型含链接** |
| Q5 | 端侧：`module.json5` skills（host/path/`domainVerify`）与签名是否已就绪 | **仅当类型含链接** |
| Q6 | Manager 放入哪个模块目录？（默认 `ets/share/` 或 `ets/model/`） | 始终 |
| Q7 | 是否需要电脑端应用内接收 `dataReceive`？ | **仅当类型含文件**；已明确不要则定为 no；**排在 Q8 与 SDK 目标之后** |
| Q8 | 是否需要 API 26+ 电脑精准碰一碰？ | **仅当类型含文件**；**Q1 之后立刻问**，用于决定升 API **22+** 还是 **26+**；已明确不要则定为 no，不再问 |
| Q8 接收落点 | 先读宿主实际 UI，再按该结构给插入位置选项（含自定义） | 仅当类型含文件且 **Q7=yes 且 Q8=yes**；排在 Q8（是否精准）与 Q7 都定了之后。不是把「是否精准」再问一遍 |

未确认 Q4/Q5 前（**仅当类型含链接**），**不得**把 `www.example.com` 当作生产配置写入并宣称联调完成。  
**仅文件**不要提 Q4/Q5，也不要把域名 / skills host 写入工程。  
**仅链接**不要提 Q7/Q8，不要注册 `dataReceive`、不要拷 `KnockRectUtil`。  
Q8（是否精准）已在 SDK 步骤确认后，不要再问是否精准；**Q8 接收落点**是后续条件提问，仅 Q7+Q8 都 yes 时再问。

**`appIdentifier` 是云侧字段，端侧不涉及。** 禁止写入 `module.json5` / Ability / ets；禁止把 `assets/applinking.json` 拷进工程。

#### 文件 vs 链接：接入独立性

- 系统侧只有一条 `knockShare` 监听；单次 `SharedData` 不可文件+链接混传（硬约束 E10）。
- **资产分包**（首次按 Q1 拷贝，落盘文件名仍为 `KnockShareManager.ets` / `KnockShareProvider.ets`）：

| Q1 | 拷贝来源 | 接线示例（只读这一份） | 资产内是否含另一种类型 |
|----|----------|----------------------|------------------------|
| 仅文件 | `assets/file/` | `assets/wiring-snippet-file.ets` | **否**（无 `getLinkShareData`、无 LINK / HYPERLINK） |
| 仅链接 | `assets/link/` | `assets/wiring-snippet-link.ets` | **否**（无 `getFileShareData`、无 FILE / `dataReceive` / 精准命中） |
| 两者都要 | `assets/both/` | `assets/wiring-snippet-both.ets` | 是（`enable(ctx, mode, provider, options?)`） |

- **已接入其中一种、本次要补另一种**：
  - **已存在** Manager/Provider（含旧名 `KnockFileShareManager`）→ **不要**新建第二套；用 `assets/both/` 覆盖/合并，页面补缺失方法；`enable` 改为三参数（+ 可选第四参 options）。
  - **不存在** → 按首次只拷本次类型目录。

#### Q3 细则（**仅当类型含文件**）

`SharedRecord` 的 **`utd`、`uri` 为必填**。无法落实且未授权自决 → 追问或中止文件接入。
可先根据工程代码提出候选，仍须确认（除非明确让 skill 自决）。
**自决时也必须先读宿主**：搜现有 URI 字段、文件 path、选择器/下载/拷贝/接收等「文件就绪」回调。禁止不读宿主就拼接目录。

| 必确认项 | 向开发者确认什么 | 常见合法来源（举例，非穷尽） | Agent 核验要点 |
|----------|------------------|------------------------------|----------------|
| 分享文件数量 | 固定 1 个还是可能 >1？ | 单 URI / 业务列表 / 勾选子集 | >1 → collect + 循环 `addRecord` |
| 可分享范围 | 哪些文件算本次可分享？ | ① 勾选子集；② 无勾选则当前业务列表；③ 焦点项；④ 选择器/下载/接收结果 | **禁止臆造 `selected*`**；无有效项时 `canShare()===false` |
| **`uri` 获取方式** | 可分享项的 URI **在宿主里怎么来**？ | 见下方来源清单 | 必须落到可访问的 `file://`（或系统认可的文件 URI）。禁止裸 path 当 `uri`。禁止套用 Q7 接收目录或任何「默认沙箱根路径」 |
| **`utd`** | 按后缀还是业务 UTD | 扩展名 / 业务已有 UTD | 与真实类型匹配；多文件每条单独算 |
| 可选字段 | 是否要 title / description / thumbnailUri | 页面文案、封面 URI | **未确认则不写** |

**发送 URI 来源清单（按宿主实际情况选，不要预设某一种）：**
1. 页面/VM **已有** `file://` 字段 → 直接收集
2. 已有沙箱 path → `fileUri.getUriFromPath`。path 可能在 `filesDir` / `cacheDir` / `tempDir` / 业务子目录，**以宿主写入处为准**
3. 选择器、拍照、文档回调里带回的 URI/path
4. 下载、拷贝、解压、导出等「文件就绪」回调里的 path/URI（若宿主用 `request.agent`，其 `saveas` 相对 `cacheDir`——这是该 API 的行为，不是本 Skill 的默认发送目录）
5. 碰一碰接收进沙箱后的 URI（接收目录由 Q7 决定，再作为后续发送来源之一）

**禁令（与具体业务无关）：**
- 禁止把 Q7 的 `filesDir` 当成发送默认根目录。接收目录 ≠ 发送目录。
- 禁止用「文件名 + 某个常用目录」在分享回调里猜测 path。
- 推荐：在该宿主**文件就绪**的时机把合法 URI 写入 Provider（选中变化、选择器返回、下载完成、接收完成、预置拷贝……以宿主为准）；`getFileShareData` 只消费已收集 URI。
- 分享前应能确认对应文件可访问；确认不了则不要 `share`，走无内容。

确认话术（可一次抛出）：
1. 单文件还是多文件？
2. 可分享范围：勾选 / 当前列表 / 其它？
3. URI 在工程里从哪来（已有字段 / 哪段 path / 哪个回调）？是否已是 `file://`？
4. utd 按后缀还是业务 UTD？
5. 要不要可选字段？不要则明确说「不要」。

#### Q7 / Q8 细则（仅当类型含文件且对应项 = yes）

**Q7 电脑接收**：默认写入目录 `fileUri.getUriFromPath(context.filesDir)`（**仅 `receive` / `getReceiveDirUri`**，禁止当作发送 URI 的默认根路径）；`maxSupportedCount`≤**5**；`onDataReceived` 把文件交给宿主，由宿主按确认的落点策略更新 UI；默认不要视频抽帧。仅 2in1 注册。手机→电脑需同一华为账号；电脑须停在已 `enable(..., { pcReceive: true })` 的页面，并碰**该应用窗口**（碰桌面仍走系统接收）。发送 URI 只跟 Q3 在宿主中确认的来源，不跟本段默认目录。

**Q7=yes 且 Q8=no**：只确认接收结果更新哪份数据源（通常追加），不问坐标落点。

**接收与发送必须同一套 utd（Q7=yes 时必做，不要再单独问一遍）**：`dataReceive.capabilities` 的 `utd` 必须与 `getFileShareData` / `addRecord` 使用的发送 `utd` 一致（Q3 已确认的那些）。对不上时系统回退图库/文件管理，**不会**写入应用沙箱，也**不会**回调 `onDataReceived`。由宿主实现 `getReceiveCapabilities()`，按发送侧同样的规则生成；`off('dataReceive')` 的 `capabilities` 必须与 `on` 完全一致。

**界面刷新**：`onDataReceived` 可能不在 UI 线程；改 `@State` 须 `UIContext.runScopedTask`，或与官方示例一样用 `AppStorage`。

**Q8 精准命中（发送）**：可命中项必须 `.id()`（如 `file_item_0`），id 集合与当前用于命中的那批可见项一致。无勾选则分享命中项，**未命中回退** `getFileShareData`（已收集集合），不要直接无内容。`deviceInfo.apiAvailable('26.0.0')` **必须写字面量**。工程 SDK 未达 API 26 且开发者拒绝升级 → 不做 Q8（不拷 `KnockRectUtil`、不接线坐标），文件发送仍按 **API 22+**。

**Q8 接收落点（仅 Q7=yes 且 Q8=yes）**：
- **命中通用**：Manager 把坐标交给 `hitTestReceiveIndex`，得到命中下标（未命中为 `-1`）。不要在 Manager 里解释如何插入。
- **插入跟宿主**：问之前必须先读挂载页，并在问题里用一句话写出**实际读到的**结构（布局怎么排、几份数据源、哪些项有 id）。选项必须从该结构推导，**必须含自定义**。禁止不读页面；禁止套用某种布局的现成选项表或插入模板。读到多份数据源或无法按项命中时，把这些事实写进选项，不要换成另一套话术。
- 命中默认整框（`HitTypes.TYPE_SEND`）。开发者按实际 UI 确认了其它命中规则时，再改 `hitTestReceiveIndex`，不要预设。
- 自定义必须确认：① 改哪一份（或哪几份）`@State`；② `insertIndex`（或命中 id）怎么映射；③ 未命中（`-1`）时做什么（追加 / 忽略 / 提示）。说不清 → 不写插入代码，沙箱 `receive` 仍可接线，完成报告标明「接收定点未接线」。
- 禁止未确认落点就把接收项永远 `push` 到末尾，却声称已做精准接收。
- 命中用的 id 必须覆盖所选范围内**当前参与命中的可见项**；插入新项后若该项也应可被再次命中，要同步更新 id 列表。

#### Manager ↔ Provider

| 角色 | 职责 |
|------|------|
| **Provider** | `canShare()` 表示**当前有无可分享内容**（**禁止**按 `deviceType` / `is2in1` 返回 false）。`getFileShareData` / `getLinkShareData` 同步返回 `SharedData \| undefined`（失败时 hilog 后返回 `undefined`，对照模板）。文件可选：`getFileShareDataAt`、接收相关方法。`insertIndex` 只是命中下标，插入策略由宿主按确认的接收落点解释 |
| **Manager** | 注册/注销 `knockShare`（2in1 绑 `windowId`）。Q8=yes 时 **先精准命中，未命中再全量** `getFileShareData`；都没有 → `clarifyNonShare`（6.0.2+）或 `reject`。成功 `share().catch(...)`。`pcReceive` 仅 2in1 且 **FILE 模式** |

Q8 是全量之上的增强，不是替代。不要为了走精准而把 2in1 的 `canShare()` 关掉。

`enable` 签名：
- `assets/file`：`enable(context, provider, options?)`
- `assets/link`：`enable(context, provider)`
- `assets/both`：`enable(context, KnockShareMode, provider, options?)`（options 仅 FILE 生效；同一时刻一种 mode）

### 2. 注入 Manager 与宿主 Provider

#### 首次接入

1. 按 Q1 从 `assets/file/`、`assets/link/` 或 `assets/both/` 拷贝 Manager+Provider。
2. **仅当类型含文件且 Q8=yes**：再拷 `assets/KnockRectUtil.ets`。
3. 页面推荐 `class X implements KnockShareProvider`（见挂载示例；对象字面量易触发 ArkTS 限制，见 best-practices）：
   - 文件：`getFileShareData(): SharedData | undefined`
   - 链接：`getLinkShareData(): SharedData | undefined`
   - 两者：两方法都要
   - **Q7=yes**：必须实现 `getReceiveCapabilities()`，与发送 `utd` 一致；改 `@State` 用 `runScopedTask` / `AppStorage`
   - **Q7=yes 且 Q8=yes**：必须实现 `hitTestReceiveIndex`，且页面按 **Q8 接收落点** 的确认结果解释 `insertIndex`；禁止套用未确认的插入模板
4. 同步构造 SharedData；回调内约 3 秒；在该宿主文件就绪的时机预热可访问 URI，监听回调里只组装。
5. 接线只打开本次类型对应文件（见上表），**不要**打开另外两份。API 见 [references/api-reference.md](references/api-reference.md)。示例文件本身 **不要**拷进工程，只改编进目标页。
6. **写 Provider 前必须完成 Q3 URI 核验**（Q8/SDK 可已完成）：在宿主定位文件从哪来，再接到发送 URI。
7. 在该宿主文件就绪的时机写入 `file://`；`canShare()` 看这份列表，不看设备类型。

#### 增量规则

1. 检测 `KnockShareManager` / `KnockShareProvider` / `KnockFileShareManager` / `knockShare`。
2. **已存在** → 不新建第二套；补类型用 `assets/both/`；旧类名升级为 `KnockShareManager`；补缺失方法；更新 `enable` 签名。
3. 补文件：未答则先问 Q8 并定 SDK **22+/26+**，再问 Q3 及未定的 Q7；补链接只问 Q4/Q5（SDK < 20 则确认升 20+）；补电脑接收只问 Q7 细则（含文件时 SDK 已是 22+）；补精准只问 Q8 细则（SDK < 26 则确认升 26+）。补电脑接收且本次精准也开启时，未问过 **Q8 接收落点** 则先读挂载页 UI 再问。

### 3. 挂载页面生命周期

| 结构 | 注册 | 注销 |
|------|------|------|
| `NavDestination` | `onShown` → `enable(...)` | `onHidden` → `disable()` |
| `@Entry` | `onPageShow` → `enable(...)` | `onPageHide` → `disable()` |

手机/平板：`on('knockShare', callback)`。2in1：`{ windowId }`。`pcReceive` 时同一 `windowId` 注册 `dataReceive`。

### 4. 可选能力

**电脑接收 / 精准命中（仅类型含文件且 Q7/Q8=yes）**  
见 Q7/Q8 细则。Q7=yes 时宿主 Provider **必须**实现 `getReceiveCapabilities`，与发送 `utd` 一致。`off('dataReceive')` 必须与 `on` 同一 `windowId` + **同一** `capabilities`。Q7+Q8 都 yes 时还必须按读到的实际 UI 确认 **Q8 接收落点** 再接线，不要套用某种布局的插入模板。

**App Linking（仅当 Q1 含链接且开发者确认配置）**

发送侧：`getLinkShareData` 的 `utd = HYPERLINK`，`content` 为已关联真实 https 链接。卡片字段未确认不写。

端侧可改（确认后）：
1. 按 [references/app-linking-checklist.md](references/app-linking-checklist.md) 核对。
2. 合并 `assets/module-skills-snippet.json5`（替换真实 host/path，`domainVerify: true`）。
3. 按 `assets/app-linking-ability-snippet.ets`：`want.uri` 非空写入 `KnockShare_incomingUri`；按宿主路由跳确认的落地页；消费后清空。

云侧只提醒不改工程：`appIdentifier`、网站 `applinking.json`、AGC、手动/正式签名。**禁止**把 `assets/applinking.json` 拷入 HarmonyOS 工程。


### 5. 代码验证

1. 对新增/修改的 `.ets` 做语法/静态检查，修到无诊断。
2. 编译工程，修到编译通过。
3. **优先使用当前环境已有的 HarmonyOS / DevEco 检查与构建能力**（名称因宿主而异，例如 ets 静态检查、工程构建，或 IDE 内置检查/构建）。若当前环境没有这些能力：在完成报告「验证结果」写明未自动编译，并把「请在 DevEco Studio 编译通过」列入人工清单；**禁止**在未实际编译时宣称已通过。
4. **不要**把真机碰一碰成功当作本 Skill 自动完成条件。

### 6. 完成报告格式

| 字段 | 内容 |
|------|------|
| 修改摘要 | 新增/修改文件；首次或增量 |
| 分享类型 | 文件 / 链接 / 两者 |
| 引导确认摘要 | 含文件写 Q8（及因此选定的 API **22+ / 26+**）、Q3、Q7；含链接写 Q4/Q5 与 API **20+**；仅文件不要写域名；仅链接不要写文件 uri / 电脑接收 / 精准。含文件时必须写明**发送 URI 在宿主中的来源**（已有 file:// 字段 / 沙箱哪段 path / 哪个回调），以及如何确认可访问；不要只写「用了 getUriFromPath」。未写来源不算文件接入完成。**Q7+Q8 都 yes** 时必须写明：读到的 UI 结构、开发者选的接收落点（或自定义的三句映射）；未写落点不算精准接收完成 |
| 挂载点 | 页面路径 + 生命周期钩子；both 包另写 `KnockShareMode`（及确认后的 options） |
| 验证结果 | 静态检查 / 编译；无构建能力则列入人工清单 |
| 人工清单 | 设备开关、双机联调；含电脑接收：同账号、最多 5 文件、电脑停在已注册 `dataReceive` 的页面并碰应用窗口、发送与接收 `utd` 一致；含链接：手动签名、域名托管、云侧 `appIdentifier` + 网站 `applinking.json` |
| 已知限制 | SDK 档位（链接 20 / 文件 22 / 精准 26）、超时、单次不可文件+链接混传、`apiAvailable` 必须字面量等 |

## 硬约束

按主题分 7 组以便检索。

### A. 通用工程纪律

1. 最小改动；禁止无关重构。
2. 只以本 Skill `assets/` 为模板；禁止凭记忆重写；禁止把宿主工程里无关页面、媒体或占位域名（如 `example.com`）整份拷入接入结果。
3. 回调内约 3 秒内完成 `share` / `reject` / `clarifyNonShare`。
4. **回滚义务**：变更写入后任何失败或取消均可触发回滚。触发范围：停手条件命中、变更写入后任何失败（文件写入失败、SDK 合并出错、资产拷贝中断等）、业务规则校验失败且无法修复、编译失败且无法修复、用户中途放弃（明确停止 / 拒绝变更预览）。回滚须依据阶段 0 的回滚能力预判与基线快照：工程在 git 版控下 → `git checkout` 还原本次改动文件（先 `git status` 比对基线快照）；不在 git 下 → 按预判时记录的关键文件清单 + 每处改动摘要供人工还原。已拷入的资产文件若属于本次新增 → 一并还原/列出。回滚后须输出回滚原因与已还原/待还原清单。**变更预览被拒绝时（尚未写入）不触发回滚。**

### B. 提问与路由纪律

5. **禁止跳过引导**。提问范围必须与已定类型一致；未定类型时先只问 Q1。**仅链接按 API 20+ 判断和升级。类型含文件时必须先问 Q8（或沿用已明确的是否精准），再确认升级到 API 22+ 还是 26+**；禁止把文件侧目标定为 20；禁止未问精准就按 20 中止或按 26 升级。
6. Q7/Q8 仅类型含文件时提问与接线；仅链接禁止电脑接收/精准命中代码。含文件时 Q8 用于在 **22+ 与 26+** 之间选档，必须排在改 `build-profile.json5` 之前。

### C. SDK 升级写法

7. 从 **API 26.0.0** 起 SDK 字符串为三段式 `"26.0.0"`。升 26 必须用 `assets/sdk-profile-snippet.json5` 的 `fileApi26`；禁止 `"7.0.0(26)"` 等旧括号套 26。API 20/22 仍写 `"6.0.0(20)"` / `"6.0.2(22)"`。

### D. 资产与接线

8. 仅文件必须拷 `assets/file/` 且只读 `wiring-snippet-file.ets`，不得含 `getLinkShareData` / HYPERLINK/`example.com`；仅链接必须拷 `assets/link/` 且只读 `wiring-snippet-link.ets`，不得含文件分享 / `dataReceive` / 精准命中。两者或增量用 `assets/both/` + `wiring-snippet-both.ets`。
9. 读不到对应 `assets/` 模板（含本次类型的 Manager/Provider 与接线示例）则中止改码并触发回滚（A4）；禁止凭记忆补全。

### E. 内容构造

10. 单次分享只能是文件**或**链接，不可混合 `SharedData` 记录类型。
11. 文件可选字段未确认则不写；多文件用 collect + 循环 `addRecord`。发送 URI 必须来自宿主真实来源；禁止套用 Q7 `filesDir` 或用文件名猜 path。
12. **`deviceInfo.apiAvailable` 只能传入字符串字面量**（如 `'26.0.0'`），禁止变量/常量间接传入。

### F. 接收与精准（Q7/Q8）

13. 电脑端 `maxSupportedCount` 不要超过 **5**。
14. Q7=yes 时 `dataReceive.capabilities` 必须与发送侧 `SharedData` 的 `utd` 一致。对不上则系统进文件管理，沙箱和列表都不会更新。
15. `canShare()` 只表示当前有无可分享内容，禁止按设备类型返回 false。Q8 精准未命中必须回退 `getFileShareData`。
16. Q7=yes 且 Q8=yes 时，必须先读宿主实际 UI 再确认接收落点（选项从该结构推导，且含自定义）。禁止套用某种布局的现成选项表或插入模板，禁止未确认就把接收项 push 到末尾。自定义必须有数据源、下标映射、未命中行为；说不清则不写插入代码。

### G. 链接与云侧

17. 禁止在未确认域名时写入生产 App Linking 并声称已可直达。
18. `appIdentifier` 与网站 `applinking.json` 仅云侧；禁止拷进端侧模块。
19. 未确认则不要默认写入 `SET_WINDOW_TRANSPARENT`。

## 资源索引

| 路径 | 用途 |
|------|------|
| `assets/file/KnockShareManager.ets` | 仅文件 Manager |
| `assets/file/KnockShareProvider.ets` | 仅文件 Provider |
| `assets/link/KnockShareManager.ets` | 仅链接 Manager |
| `assets/link/KnockShareProvider.ets` | 仅链接 Provider |
| `assets/both/KnockShareManager.ets` | 文件+链接 Manager |
| `assets/both/KnockShareProvider.ets` | 文件+链接 Provider |
| `assets/KnockRectUtil.ets` | 仅 Q8：组件命中 |
| `assets/wiring-snippet-file.ets` | 仅文件接线示例（不要拷进工程） |
| `assets/wiring-snippet-link.ets` | 仅链接接线示例（不要拷进工程） |
| `assets/wiring-snippet-both.ets` | 文件+链接接线示例（不要拷进工程） |
| `assets/sdk-profile-snippet.json5` | SDK 字段模板：20 旧写法 / 22 旧写法 / **26+ SemVer**（不要拷进工程，只合并） |
| `assets/app-linking-ability-snippet.ets` | 接收侧 Ability 片段 |
| `assets/module-skills-snippet.json5` | skills 配置片段 |
| `assets/applinking.json` | 网站 `.well-known` 模板（云侧；**禁止拷入工程**） |
| `references/api-reference.md` | API 要点 |
| `references/sdk-version.md` | API 26 起版本号写法与比较 |
| `references/app-linking-checklist.md` | 配置确认清单 |
| `references/best-practices.md` | 实践与陷阱 |
| `test-cases/acceptance-checklist.md` | S1–S24 验收标准与完成报告字段 |
| `test-cases/test-prompts.md` | 场景 1–17 提示词 |
| `test-cases/test-case-file-share.md` | tc_001 仅文件分享 |
| `test-cases/test-case-link-share.md` | tc_002 仅链接（配置未就绪） |
| `test-cases/test-case-unsupported-sdk.md` | tc_003 SDK 过低 / 已是 20 须先定目标 |
| `test-cases/test-case-guide-unspecified.md` | tc_004 未指定类型 |
| `test-cases/test-case-incremental-both.md` | tc_005 增量补另一种类型 |
| `test-cases/test-case-file-no-link-stub.md` | tc_006 仅文件不混链接 |
| `test-cases/test-case-link-no-file.md` | tc_007 仅链接不混文件/接收 |
| `test-cases/test-case-no-integration-request.md` | tc_008 未要求接入不改码 |
| `test-cases/test-case-pc-receive-utd.md` | tc_009 电脑接收对齐发送类型标识 |
| `test-cases/test-case-uri-from-host.md` | tc_010 发送 URI 跟宿主来源 |
| `test-cases/test-case-uri-filesdir-ok.md` | tc_011 对照：文件本就在 filesDir |
| `test-cases/test-case-receive-precise-landing.md` | tc_012 电脑接收 + 精准问落点 |
| `test-cases/test-case-assets-unreadable.md` | tc_013 读不到 assets 中止 |
| `test-cases/test-case-no-build-env.md` | tc_014 无构建环境 |
| `test-cases/test-case-rollback-git.md` | tc_015 git 环境失败回滚 |
| `test-cases/test-case-rollback-no-git.md` | tc_016 非 git 回滚 + 用户放弃 |
| `test-cases/test-case-mount-conflict.md` | tc_017 挂载冲突预检 |
