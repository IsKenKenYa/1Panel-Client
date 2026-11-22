---
name: hmos-share-kit-gestures-share
description: 为 HarmonyOS 工程接入 Share Kit 隔空传送文件 / App Linking 链接，支持首次接入与增量升级。当开发者提到隔空传送、gesturesShare、一抓一放或要求接入时使用。提供首次接入模板注入、生命周期接线、入口 Ability 加载检测、App Linking 端侧合并、异构实现迁移、两阶段骨架回填等能力。
version: "1.0.0"
license: MIT
metadata:
  category: "HarmonyOS SDK"
  kit: "ShareKit"
  min_sdk: "6.0.0(20)"
---

# Share Kit 隔空传送接入助手

## 认知目标

### 定位

HarmonyOS 工程接入隔空传送（gesturesShare）的助手：先向开发者确认接入信息，再注入隔空传送文件并完成接线，实现设备间「一抓一放」跨设备文件 / 链接分享。

### 执行概览

改码任务按序分两段推进，先检测后实施，逐项勾选推进：

**前置步骤（只读工程）**
- [ ] Step 0：任务性质判定
- [ ] Step 1：版本门槛核验
- [ ] Step 2：接入状态探测
- [ ] Step 3：模块与挂载页候选定位

**工作流程（确认后实施）**
- [ ] Step 0：引导确认
- [ ] Step 1：注入 Manager 与 Provider
- [ ] Step 2：挂载页面生命周期
- [ ] Step 3：入口 Ability 加载检测
- [ ] Step 4：App Linking
- [ ] Step 5：代码验证
- [ ] Step 6：完成报告

任一环节信息不足或需授权 → 就地补全后**从该环节继续**，不重头跑。

### 使用场景与范围

**文件分享**
- ✅ 首次接入仅文件分享
- ✅ 既有链接实现增量补文件分享

**链接分享（App Linking）**
- ✅ 首次接入仅链接分享
- ✅ 既有文件实现增量补链接分享
- ✅ 接收侧 App Linking 拉起配置（域名确认后接线）

**两者**
- ✅ 文件 + 链接同时支持
- ✅ 异构分享实现迁移为模板结构

### 运行环境

1. 接入需 HarmonyOS SDK，`targetSdkVersion` 不低于 `6.0.0(20)`；静态检查与编译需 DevEco Studio / HarmonyOS 工具链
2. 真机「一抓一放」验收需两台支持隔空传送的华为设备，双端亮屏解锁、开启华为分享与设备隔空传送开关后人工联调

### 路径约定与加载 / 卸载

- 文中 `assets/`、`references/` 均相对本 Skill 根目录；`test-cases/` 仅供人工验收，不当作用户当前需求执行
- 接入或补齐隔空传送、且将修改工程代码前，必须完整加载本 Skill（含 `assets/`、`references/`，未加载整包不得按本规范改码）；满足以下任一条件时卸载：开发者明确表示本次接入结束、完成报告已输出且无后续增量需求、或开发者主动要求卸载；同一会话内继续补另一分享类型或接入其他页面则保持加载

---

## 前置步骤（必须执行）

### Step 0: 任务性质判定

- **仅咨询**——开发者仅询问概念 / 对比 / 用法，未要求接入或补齐 → 只解答，不执行 前置步骤 Step 1-3、不修改工程
- **改码**——存在明确的接入 / 补齐请求 → 继续执行 前置步骤 Step 1-3
- **升级**——仅咨询的任务在后续会话中升级：开发者明确提出接入 / 补齐请求 → 自 前置步骤 Step 1 起补跑前置步骤再进入工作流程

### Step 1: 版本门槛检测

**接入版本要求（不满足则中止改码）**：`targetSdkVersion` ≥ `6.0.0(20)`（gesturesShare 起始版本）；`compatibleSdkVersion` 可低于 `6.0.0(20)`，不作为中止条件。

读 `build-profile.json5`（版本门槛基准为 `6.0.0(20)`）：
1. 确认 `targetSdkVersion` ≥ `6.0.0(20)` → 通过；低于此版本 → **警告并停止自动改码**（按错误处置表 E1 处置）
2. `compatibleSdkVersion` 若 < `6.0.0(20)` → **不因此中止**，compat_low = true；提醒低版本设备无 gesturesShare，须走 canIUse 降级（不注册 / 提示不支持），并写入完成报告（「已知限制」首条写明兼容区间与降级行为）
3. `targetSdkVersion` 或 `compatibleSdkVersion` 任一字段缺失，或文件不可读 → **无法判定版本，视同未通过**，按 E1 中止并说明

### Step 2: 接入状态检测

搜 `harmonyShare.on('gesturesShare'`——唯一可靠的接入指纹；勿按文件名 / 类名搜，实现命名不固定。注释或字符串字面量里的匹配不算；唯一命中是注释掉的死代码 → 视为未检测到，记入相似分享实现清单。

**检测到监听** → 判定是否来自本 Skill 模板，判据是**结构与调用面，不是文件名**（文件名只能辅助印证，不能单独作判据）：
1. 同构：独立文件承载的单例 Manager（`enable(...)` / `disable()` 成对、内部含 `harmonyShare.on/off('gesturesShare')`、注册按 windowId 绑定）+ 独立 Provider 接口（`canShare()` 及 `getFileShareData()` / `getLinkShareData()` 模板签名）→ mode = homogeneous
2. 异构：不满足上述结构特征——如自写 `ShareModel.ets`、注册直接内联在页面 / Ability 中（无独立文件）、无独立 Provider 接口，或文件名虽为模板名但结构不符 → mode = heterogeneous，按错误处置表 E8 处置
3. 多处监听：全部同构 → mode = homogeneous；任一异构 → mode = heterogeneous，同构部分照常升级、异构部分逐一按 E8 处置

**未检测到监听** → 扫描相似分享实现（文件名 / 类名含 share / gestures，或引用 `SharedData` 等分享符号的文件）：
1. 发现疑似文件 → mode = first，记录其路径，供 工作流程 Step 0 的基线裁决，不静默忽略
2. 未发现 → mode = first

**增量判定的唯一标准：是否存在已注册监听。相似文件不构成增量；唯一例外是 E2 的目标路径文件冲突——转同构还是异构仍按上述结构判定（E2（1）「结构符合模板」检查兜底，不因同名自动转同构）。**

### Step 3: 定位模块与挂载页候选

1. mount.module 默认 `entry`；挂载页位于其他模块时，以挂载页所在模块为准；均记入 mount.module
2. 扫描页面清单（`@Entry` 页 / NavDestination 路由表）与可分享数据模型，产出页面候选列表，供 工作流程 Step 0 的 Q2 探测使用

---

## 工作流程（必须执行）

### Step 0: 引导确认（答完再改码）

**唯一来源** [references/guide-confirmation.md](references/guide-confirmation.md)：三层分流（能不问就不问）、题号对照（Q1-Q5）、按类型提问矩阵、默认值表、固定选项集、**环节级约束（类型门控、输出红线）**、Q2-Q5 探测与核验细则、基线裁决、云侧边界——全部以该文件为准，本节不复述，本节只负责产出状态。

#### 本节为 integration_state 赋值

内部记账，禁止在回复中以记号形式呈现；完整结构、赋值与消费环节见 [references/integration-state.md](references/integration-state.md)。本节赋值字段：share_type、mode_switch、mount.page、file.scope、file.multi、file.uri_source、link.domain、link.verified、link.path_query、link.landing_page；其余字段（mode、compat_low、mount.module、mount.dir、mount.lifecycle、mount.entry_ability、validation.*）按对应产出环节分别在 前置步骤 Step 1-3、工作流程 Step 1-3、工作流程 Step 5 赋值。

### Step 1: 注入 Manager 与 Provider

按 mode 执行对应分支，三个分支互斥，只走一条。

#### 首次接入（mode = first）
1. 按 share_type 拷贝资产包，禁止拷错：file → `assets/file/`；link → `assets/link/`；both → `assets/both/`。
2. 拷入位置按默认值表「Manager/Provider 位置」落盘（见 [references/guide-confirmation.md](references/guide-confirmation.md)）；文件名保持 `GestureShareManager.ets` / `GestureShareProvider.ets`。落盘目录记入 mount.dir。
3. 拷贝前查重：目标路径已有同名文件 → 按错误处置表 E2 处置——前置步骤 Step 2 的 API 搜索可能漏掉手写同名文件。
4. mount.page 实现 Provider：`class X implements GestureShareProvider`，勿用对象字面量；同步构造、失败返回 `undefined`。写法见 [assets/wiring-snippet.ets](assets/wiring-snippet.ets)，模板注释即契约说明。
5. 页面 import Manager / Provider 的相对路径按页面实际目录调整，勿照抄 snippet 的 `./`。
6. 宿主已有文件的每处改动——挂载页、后续 `module.json5` / EntryAbility——在完成报告「修改摘要」中定位到文件与段落，保证人工可回退；新增文件单独列出。

#### 增量（同构）（mode = homogeneous）
1. 用 `assets/both/` 升级既有实现。
2. 冲突闭环：未获开发者明确授权不得覆盖，按错误处置表 E3 处置。
3. 页面 Provider 补缺失方法；`enable` 改三参签名 `enable(ctx, GestureShareMode, provider)`。
4. 只问本次新增类型的问题：新增类型 = 目标类型 − 既有实现已具备的能力（E2 转换时目标类型取已确认的类型结论）；补文件 → 只问 Q3；补链接 → 只问 Q4；补齐后更新 share_type，若由此成为 both → 加问 Q5（mode_switch）。
5. 两阶段回填（既有端侧骨架待补域名）：跳过新增类型询问，仅回填 link.domain、清除 TODO，执行 工作流程 Step 5 验证后报告。

#### 增量（异构）（mode = heterogeneous）
1. 按错误处置表 E8 三选一处置（禁止直接拷模板新建文件——会与既有监听并行形成双监听，见硬约束 3）；处置未完成前不得宣称接入完成。

### Step 2: 挂载页面生命周期

| 页面结构 | 注册 | 注销 |
|----------|------|------|
| `NavDestination` | `onShown` → `enable(...)` | `onHidden` → `disable()` |
| 普通 `@Entry` 页 | `onPageShow` → `enable(...)` | `onPageHide` → `disable()` |

1. `enable` 签名：file/link 包 `enable(ctx, provider)`；both 包 `enable(ctx, GestureShareMode, provider)`，模式按 mode_switch 决定。
2. enable 后页面内数据变化：页面持**同一 Provider 实例**直接改其字段（引用同步），勿重复 new。
3. 接线结果记入 mount.lifecycle。
4. 挂载点为 Tab 内容 / 自定义子组件等其他结构时：向上找持有它的 `NavDestination` / `@Entry` 宿主页，按上表规则接线；找不到宿主页或无法成对 enable/disable → 与开发者确认挂载点，仍无法解决 → 按 E5 中止该项接入。

### Step 3: 入口 Ability 加载检测（确保页面可被加载）

页面生命周期接线的前置条件：宿主入口 Ability 必须实现 `onWindowStageCreate` 并调用 `windowStage.loadContent('<挂载页路径>')`，否则应用启动后停留在白屏，Step 2 接的 `onPageShow`/`onShown` 永远不会触发。

1. 读 `module.json5` 定位入口 Ability（`mainElement` 字段）对应的 `srcEntry` 文件路径。
2. 检测该文件是否已实现 `onWindowStageCreate` 且调用 `loadContent` 加载挂载页（mount.page）：
   - **已实现且加载页与 mount.page 一致** → 跳过，记入 mount.entry_ability = ok。
   - **已实现但加载页与 mount.page 不一致** → 提示开发者确认入口页是否应为 mount.page；未获授权改动 → 保留现状，报告「已知限制」注明入口页与挂载页不一致。
   - **未实现 `onWindowStageCreate`，或类体为空** → 自动补全：读 `main_pages.json` 取首条 `src` 作为入口页路径（与 mount.page 应一致；不一致时以 mount.page 为准），保留宿主已有的 `onCreate` / `onNewWant` / `onWindowStageDestroy` 等其他方法与 import，仅新增 `onWindowStageCreate`。最小实现：
     ```typescript
     import { UIAbility } from '@kit.AbilityKit';
     import { window } from '@kit.ArkUI';

     export default class EntryAbility extends UIAbility {
       onWindowStageCreate(windowStage: window.WindowStage): void {
         windowStage.loadContent('<mount.page>', (err) => {
           if (err.code) {
             // 加载失败处理
           }
         });
       }
     }
     ```
     记入 mount.entry_ability = patched。
   - **文件不存在或不可读** → 按 E7 处置（输出待合并片段 + 人工清单，不假装已接入）。
3. `loadContent` 的页面路径格式：`pages/Index`（不带 `.ets` 后缀、不带 `src/main/ets/` 前缀），与 `main_pages.json` 的 `src` 条目一致；误用 `loadPageByName` 会编译失败（WindowStage 无此方法）。
4. share_type ∈ {link, both} 时，Step 4 的 App Linking `onCreate`/`onNewWant` 合并仍按「合并非覆盖」进行，本步骤的 `onWindowStageCreate` 补全不与之冲突。

### Step 4: App Linking（条件执行：仅当 share_type ∈ {link, both}；share_type = file 时跳过本节）

1. 发送侧：`utd = HYPERLINK`，`content` 为 link.domain 下已关联的真实 https 链接（可带业务 query）。
2. link.verified = false → 两阶段：先做端侧骨架（skills host 留 `TODO` 占位并在报告高亮），域名确认后回填；**TODO 未清除前禁止宣称「直达可用」**。
3. 端侧：按 [references/app-linking-checklist.md](references/app-linking-checklist.md) 核对。两处均为**合并非覆盖**：`module.json5` 将 [assets/app-linking-tools/module-skills-snippet.json5](assets/app-linking-tools/module-skills-snippet.json5) 的 App Linking 条目作为**独立 skill 对象**追加进 skills 数组（官方要求：链接配置禁止并入 home 入口条目，混置则拉起不生效；宿主已有条目保留原样，host 换 link.domain，`domainVerify: true`）；Ability 只取 [assets/app-linking-tools/app-linking-ability-snippet.ets](assets/app-linking-tools/app-linking-ability-snippet.ets) 中的 `handleAppLinkWant` 方法与 `onCreate`/`onNewWant` 接线**并入宿主已有 EntryAbility**，禁止整文件替换（只存非空 `want.uri`，导航到 link.landing_page 跟宿主路由风格）。
4. 云侧（不碰工程）：`appIdentifier`、网站 `applinking.json`、AGC → 人工清单；域名未确认 → **禁止写入生产 App Linking 并声称已可直达**。

### Step 5: 代码验证

1. 新增 / 修改的 `.ets` 静态检查 → 无诊断；编译工程 → 通过。
2. 编译失败 → 按错误处置表 E4 处置。环境无检查 / 构建能力 → 报告写明「未自动编译」，人工清单加「请在 DevEco Studio 编译通过」。**禁止未编译宣称通过**。
3. 真机「一抓一放」属人工验收，不作为自动完成条件。

### Step 6: 完成报告

按表输出各字段摘要（早期环节即中止时：中止原因 + 恢复条件即可，无值字段省略）：

| 字段 | 内容 |
|------|------|
| 修改摘要 | 新增 / 修改文件分开列出；宿主已有文件定位到改动段落，保证可回退；接入形态用一句话说明是首次接入、升级既有实现还是迁移重构 |
| 分享类型 | 仅写已确认类型，不加注另一类型的任何说明 |
| 引导确认摘要 | 已确认事项的结论、探测结果、采用的默认值与自决项 |
| 挂载点 | 挂载页路径与生命周期钩子名称；两者类型另写分享模式的切换时机 |
| 验证结果 | 静态检查与编译逐项写明：通过 / 失败 / 未执行；无构建能力即「未执行」；禁止以「已验证」笼统带过 |
| 人工清单 | 设备开关、双机联调；含链接再加：手动签名、域名托管、云侧 applinking、安装后域名校验（排障见 [references/app-linking-checklist.md](references/app-linking-checklist.md)） |
| 已知限制 | 存在低版本兼容时，首条写明兼容区间与降级行为：低版本设备无 gesturesShare，运行时靠 canIUse 降级，不注册或提示不支持；3 秒超时、单次不可文件+链接混传、enable-disable 异步竞态（快速切页）；基线裁决选择「按标准模板新建」时的既有保留文件附路径 |

---

## 决策树

流程执行地图见 [references/decision-tree.md](references/decision-tree.md)：只保留判定分支与落点 Step，不重复处置细节——各分支的具体动作以对应 Step 正文为准，冲突与失败一律以错误处置表、退出条件·收尾规则为唯一依据。开始执行前置步骤前加载。

---

## 状态绑定

全程维护**唯一一份** `integration_state`，下游只消费、不重新推断；状态属内部记账，呈现遵守硬约束 7。字段结构、赋值与消费环节见 [references/integration-state.md](references/integration-state.md)。

---

## 错误处置表

处置选项按序**用自然语言**呈现给开发者，禁止报出 E 编号；每个处置点一行。

| # | 错误场景 | 处置选项 |
|---|----------|----------|
| E1 | `targetSdkVersion` < `6.0.0(20)` | （1）**中止改码**（唯一无恢复路径项）；（2）输出版本要求与升级建议 |
| E2 | 目标路径已有同名 Manager/Provider | （1）结构符合模板 → 转 mode = homogeneous，diff 后请求授权覆盖；结构不符 → 按 E8 异构处置；（2）未授权 → 只输出待合并片段 + 人工清单；（3）中止 |
| E3 | 增量 diff 发现宿主自改 | （1）授权覆盖（报告记录被覆盖内容）；（2）保留宿主修改 → 输出待合并片段 + 人工清单；（3）中止升级 |
| E4 | 静态检查 / 编译失败 | （1）失败源于环境故障（SDK / 工具链 / 签名缺失等）而非代码错误 → 不进修复循环，视同无构建能力：报告写明 + 人工清单；（2）对照 [references/best-practices.md](references/best-practices.md) 陷阱表「编译 / 静态检查」组修复后重跑（至多 2 轮）；（3）仍失败 → 报告写明失败原因与已改动文件定位，人工清单加「请在 DevEco Studio 修复编译」；禁止谎称通过 |
| E5 | 必问项开发者拒答 / 不回应 | （1）换表述追问一次；（2）仍无回应 → 中止该项接入（禁止臆造兜底）；文件/链接单项中止不影响另一类型；挂载页等全局项无法确定 → 整体中止，报告写明原因与恢复条件 |
| E6 | 模板（assets/）不可读 | （1）**中止改码**，禁止凭记忆重写；提示 skill 安装不完整 |
| E7 | 无法修改宿主工程（只读等） | （1）只输出待合并片段与人工清单，不假装已接入 |
| E8 | 检测到既有监听但实现与本 Skill 模板异构（如自写 `ShareModel.ets`，或内联在页面 / Ability 中的注册） | （1）授权后以模板为参照迁移重构（内联注册须**抽取到模板结构并移除原注册**；报告列明被替换内容与被删除文件）；（2）保留既有实现 → 只输出待合并片段 + 人工清单；（3）中止该项接入；⚠️（1）（2）（3）均适用：**禁止并行新建第二套监听** |

---

## 硬约束

只保留跨环节、不落在单一 Step 内的红线；单一步骤内的强制要求（模板落盘 / App Linking 独立对象 / 两阶段骨架等）以对应 Step 正文与错误处置表为准，不在此重复。

### 改码纪律
1. 最小改动，禁止无关重构；严格按工作流程各步依次执行，不得跳步（工作流程 Step 4 条件执行、其余必做）。
2. 接入实现只以本 Skill `assets/` 为模板：按分享类型选对资产包，先打开模板再落盘，禁止凭记忆重写；读不到模板 → 按错误处置表 E6 中止改码。
3. 冲突处置（目标路径已有同名文件、已注册监听、宿主自改）以错误处置表 E2 / E3 / E8 为唯一依据：先 diff 并向开发者说明将改动什么，获授权后才写入；禁止静默覆盖、禁止绕过既有实现并行新建第二套监听 / 单例；宿主文件每次写入后读回核对。
4. 文件操作与报告引用路径使用绝对路径；代码 import 按页面实际相对路径调整。

### 运行时契约
5. 单次分享只能是文件**或**链接，不可混合；手势回调内 3 秒内完成 `share` / `reject`。

### 引导与输出
6. 禁止跳过引导确认；未确认事项（uri / 域名 / 勾选标志 / 模式切换逻辑）禁止臆造，禁止替开发者自决。
7. 面向开发者的输出仅三类：提问与选项确认、覆盖授权等 diff 提示、完成报告（含中止说明）；检测过程、中间结论一律内部完成，不播报、不附括号旁白，仅需开发者决策时才转成提问或授权请求。内部记号（状态字段 / 题号 / 错误码 / 标准号 / 层级 / 内部文件名）一律转自然语言表达（如「已确认分享类型」而非 `share_type=file`）。

### 验证与报告
8. 无构建能力时禁止宣称编译通过：报告写明未自动编译，人工清单加「请在 DevEco Studio 编译通过」。

---

## 退出条件

### 仅咨询

按前置步骤 Step 0 判定为仅咨询时：解答完成即结束，不适用自查清单。

### 改码

按前置步骤 Step 0 判定为改码时：自查清单全部满足才可宣称「接入完成」；否则按下述收尾规则如实写明，不设状态标签。

- [ ] 前置步骤 Step 0-3 已执行，mode 已赋值
- [ ] 工作流程 Step 0 必问项已确认（或经授权自决并记录自决项）
- [ ] 工作流程 Step 1 处置完成：first 已落盘 mount.dir / homogeneous 升级完成且 diff 已提示 / heterogeneous 或基线裁决改造已按 E8 处置并经开发者确认
- [ ] 工作流程 Step 2 生命周期已接线（enable/disable 成对）
- [ ] 工作流程 Step 3 入口 Ability 已检测：已实现 onWindowStageCreate + loadContent 加载挂载页（ok / patched），或入口页与挂载页不一致已在已知限制注明
- [ ] share_type ∈ {link, both} 时：Step 4 完成——独立 skill 对象 + Ability 合并；或域名未就绪时骨架 + TODO 已高亮（两阶段）
- [ ] Step 5 验证：静态检查无诊断、工程编译通过（环境具备时）；不具备时报告已写明
- [ ] 完成报告各字段齐全（工作流程 Step 6 全表），人工清单已列出全部仓外项
- [ ] compat_low = true 时，「已知限制」已写明兼容区间与降级行为（低版本设备靠 canIUse 降级：不注册 / 提示不支持）

### 收尾规则

报告各字段如实承载，不输出状态标签：

- 自查清单全部满足 → 可宣称「接入完成」
- 存在未解决项——编译修复两轮仍失败（E4）、仅输出待合并片段（E7 或 E2（2）/ E3（2）/ E8（2）支线）、域名未就绪仅完成端侧骨架（工作流程 Step 4 两阶段）、某类型因必问项拒答中止而其余类型完成（E5 单项中止）→ 对应字段如实写明，即使其余清单项全部满足也禁止宣称「完全接入」
- 命中中止支线——版本门槛不过（E1）、模板不可读（E6）、必问项全部拒答（E5）或错误处置表选中中止 → 停止改码，报告写明原因与恢复条件

---

## 资源索引

| 路径 | 用途 |
|------|------|
| `assets/file/` | 仅文件接入的代码模板 |
| `assets/link/` | 仅链接接入的代码模板 |
| `assets/both/` | 文件+链接接入与增量升级的代码模板 |
| `assets/wiring-snippet.ets` | 接线写法参考，禁止拷入工程 |
| `assets/app-linking-tools/` | App Linking 接收侧合并工具，按「合并非拷贝」使用；网站部署模板属云侧，禁止拷入工程 |
| `references/guide-confirmation.md` | 工作流程 Step 0 引导确认全部细则（含环节级约束：类型门控、输出红线） |
| `references/decision-tree.md` | 流程执行地图，前置步骤开始前加载 |
| `references/integration-state.md` | integration_state 结构与产出 / 消费环节 |
| `references/app-linking-checklist.md` | 工作流程 Step 4 的配置确认与拉起验证清单 |
| `references/best-practices.md` | 实践与陷阱，编译失败时的排障入口 |
| `test-cases/` | 人工验收用例 |
