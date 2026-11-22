# 功能性测试（机测）

验证 skill 在完整接入工作流中的功能行为是否正确执行。每个用例模拟一个真实的工程接入场景，验收 skill 是否按 `SKILL.md` 规范完成对应环节的动作。

**测试约束**：
- 每个用例的输入已自带工程上下文，无需追问基础信息。
- 用例模拟实际接入流程，验收范围覆盖前置检测、引导确认、模板注入、生命周期接线、SDK 升级、入口 Ability 检测、报告输出、回滚等环节。
- 无真实工程时，验收人可在提示中声明"模拟工程"并给出关键工程事实（build-profile 版本、已有文件、挂载页等），skill 应据此推进流程并产出可验收的中间结论与待合并片段。
- 每个用例的"预期输出"列出必须命中的行为锚点与禁止出现的行为，逐项核对。

---

### 测试用例：FUNC-001（仅文件 + 已 ≥22，不走精准）

**skill**：hmos-share-kit-knock-share
**类型**：functional

#### 输入

```
【模拟工程】
工程 compatibleSdkVersion=6.0.2(22)、targetSdkVersion=6.0.2(22)
未检测到已有 KnockShareManager / KnockShareProvider / knockShare 监听
挂载页：pages/Detail（普通 @Entry 页）
assets/file/ 可读

帮我在当前工程接入碰一碰传送文件。挂载页 pages/Detail，不要电脑接收，不要精准。基于模拟前置条件给出完整的工作流程，无需探测真实工程。
```

#### 预期输出

**验证标准**：

- 前置步骤执行：当前 SDK `"6.0.2(22)"` 已达 22+ 目标 → 不改 `build-profile.json5`
- 接入状态检测：未检测到已有接入 → 首次接入
- 引导确认：已指定"仅文件"→ 不再问 Q1；已明确不要精准 → 不再问 Q8；按仅文件场景提问（Q2 挂载页、Q3 文件数量/范围/URI 来源/utd/可选字段、Q6 落盘目录），禁止出现 App Linking / 域名 / HYPERLINK / `gesturesShare` / 接收目录 / 组件 id 等链接侧或精准相关问题
- 模板注入：拷贝来源为 `assets/file/`，落盘位置经确认；未拷 `KnockRectUtil.ets`、未拷 `assets/link/` 或 `assets/both/`
- Provider 实现：无 `getLinkShareData`、无 HYPERLINK；无 `dataReceive` 注册、无 `getReceiveCapabilities`
- 生命周期接线：`onPageShow → enable(context, provider)` 两参签名、`onPageHide → disable()`
- 完成报告字段齐全（修改摘要 / 分享类型 / 引导确认摘要 / 挂载点 / 验证结果 / 人工清单 / 已知限制）；URI 来源写明在宿主中的来源

**应包含**：`assets/file/`、`enable(context, provider)`、`onPageShow`、`onPageHide`、utd
**不应包含**：`App Linking`、`HYPERLINK`、`example.com`、`KnockRectUtil`、`dataReceive`、`pcReceive`、`preciseKnock`、`"26.0.0"`、`"7.0.0(26)"`
**格式**：markdown

---

### 测试用例：FUNC-002（仅文件 + 低 SDK + 要精准 → 升 26）

**skill**：hmos-share-kit-knock-share
**类型**：functional

#### 输入

```
【模拟工程】
工程 compatibleSdkVersion=6.0.2(22)、targetSdkVersion=6.0.2(22)
未检测到已有碰一碰接入
挂载页：pages/Detail（普通 @Entry 页）
assets/file/、assets/KnockRectUtil.ets、assets/sdk-profile-snippet.json5 可读

接入碰一碰文件分享。要精准碰一碰。挂载页 pages/Detail。基于模拟前置条件给出完整的工作流程，无需探测真实工程。
```

#### 预期输出

**验证标准**：

- 引导确认：已明确要精准 → 不再问 Q8；本轮可继续问 Q2/Q3/Q7/Q6，但不在 Q8 未定前夹杂 Q3/Q7
- SDK 升级：目标 API 26+，先确认升级再写入；写入 `"26.0.0"`（三段式 SemVer，无括号）；`compatibleSdkVersion` 与 `targetSdkVersion` 都改成 `"26.0.0"`；须打开 `assets/sdk-profile-snippet.json5` 的 `fileApi26` 字段合并
- 模板注入：拷贝 `assets/file/` + `KnockRectUtil.ets`（Q8=yes）
- enable 签名：`enable(context, provider, { preciseKnock: true })`
- 精准实现：`deviceInfo.apiAvailable('26.0.0')` 用**字符串字面量**，非变量/常量
- 完成报告字段齐全

**应包含**：`"26.0.0"`、`fileApi26`、`KnockRectUtil`、`preciseKnock: true`、`apiAvailable('26.0.0')`
**不应包含**：`"7.0.0(26)"`、`"6.0.0(26)"`、`26`、`"26"`、变量间接传入 `apiAvailable`
**格式**：markdown

---

### 测试用例：FUNC-003（仅文件 + 当前 20 + 未说明精准 → 先问 Q8）

**skill**：hmos-share-kit-knock-share
**类型**：functional

#### 输入

```
【模拟工程】
工程 compatibleSdkVersion=6.0.0(20)、targetSdkVersion=6.0.0(20)
未检测到已有碰一碰接入
assets/sdk-profile-snippet.json5、references/sdk-version.md 可读

接入碰一碰文件分享。无需询问问题，基于模拟前置条件给出完整的工作流程步骤，无需探测真实工程。
```

#### 预期输出

**验证标准**：

- 引导确认首轮：已指定仅文件 → 不再问 Q1；本轮**只问 Q8**（是否精准碰一碰），不夹杂 Q3 字段、Q7 接收目录、组件 id、接收落点
- 未答 Q8 前**不**改 `build-profile.json5`、不注入 Manager
- 禁止未问 Q8 就按 20 一刀切升级或中止
- 禁止未问 Q8 就把文件侧升到 20（当前已是 20，文件侧不能停在 20）
- 后续分支（验收人按 Q8 答案推进）：
  - 若答 Q8=yes → 目标 API 26+，写 `"26.0.0"`，打开 `fileApi26`；禁止 `"7.0.0(26)"`；禁止"SDK 不够，该项停止"
  - 若答 Q8=no → 目标 API 22+，写 `"6.0.2(22)"`；禁止停留在 20 发送文件；禁止 `"6.0.0(20)"` 作为文件目标

**应包含**：Q8、是否精准、`"26.0.0"`、`"6.0.2(22)"`
**不应包含**：Q3 字段、Q7 接收目录、组件 id、接收落点（首轮）、未问 Q8 就升级
**格式**：markdown

---

### 测试用例：FUNC-004（仅链接 + 低 SDK → 升 20，不问 Q8）

**skill**：hmos-share-kit-knock-share
**类型**：functional

#### 输入

```
【模拟工程】
工程 compatibleSdkVersion=5.0.0(12)、targetSdkVersion=5.0.0(12)
未检测到已有碰一碰接入
挂载页：pages/VideoPlay
assets/link/ 可读

接入碰一碰链接分享（App Linking）。挂载页 pages/VideoPlay，域名 share.myapp.com，落地页 pages/VideoPlay。签名和 applinking.json 还没配好。无需询问问题，基于模拟前置条件给出完整的工作流程，无需探测真实工程。
```

#### 预期输出

**验证标准**：

- 引导确认：已指定仅链接 → 不再问 Q1；**不问 Q8**（仅链接不问精准）；只问 Q2 挂载页、Q4 域名/path/落地页、Q5 端侧 skills 与签名、Q6 落盘目录
- 提问中不得出现文件数量、文件 uri / `file://`、`getUriFromPath`、`dataReceive`、精准命中、组件 id
- SDK 升级：仅链接目标 API 20+，确认升级后写 `"6.0.0(20)"`；禁止 `"6.0.2(22)"` / `"26.0.0"`；拒绝升级 → 停止改码
- 模板注入：拷贝 `assets/link/`；未拷 `assets/file/` / `assets/both/` / `KnockRectUtil.ets`
- Provider 实现：无 `getFileShareData`、无 `dataReceive`；`enable(context, provider)` 两参签名；无 `pcReceive` / `preciseKnock` 选项
- 云侧边界：签名/applinking 未就绪 → 列入人工清单，不声称链接已可直达；禁止把 `assets/applinking.json` 拷进工程；禁止把 `appIdentifier` 写入 `module.json5` / Ability / ets；未确认域名前禁止把 `www.example.com` 写入生产 host
- 完成报告字段齐全

**应包含**：`assets/link/`、`"6.0.0(20)"`、`enable(context, provider)`、人工清单
**不应包含**：`dataReceive`、`KnockRectUtil`、`preciseKnock`、`pcReceive`、`"26.0.0"`、`applinking.json` 拷入工程、`appIdentifier` 写入端侧
**格式**：markdown

---

### 测试用例：FUNC-005（增量补链接 → assets/both，禁止第二套监听）

**skill**：hmos-share-kit-knock-share
**类型**：functional

#### 输入

```
【模拟工程】
工程 compatibleSdkVersion=6.0.2(22)、targetSdkVersion=6.0.2(22)
已有文件侧碰一碰接入：
  - ets/share/KnockFileShareManager.ets（旧类名）
  - ets/share/KnockShareProvider.ets
  - pages/Detail.ets 已接 enable(context, provider)
assets/both/ 可读
工程已有碰一碰文件分享，请再接入链接分享。无需询问问题，基于模拟前置条件给出完整的工作流程，无需探测真实工程。
```

#### 预期输出

**验证标准**：

- 存量判定：检测到已有 `KnockFileShareManager`（旧类名）+ Provider；输出现状能力清单（文件✓、链接✗）
- 增量升级：用 `assets/both/` 覆盖/合并升级，禁止新建第二套 Manager / 第二套 `knockShare` 监听（硬约束 A4/S5）
- 旧类名迁移：`KnockFileShareManager` → `KnockShareManager`（全局重命名，页面同步改引用）
- enable 签名改为带 `KnockShareMode`：`enable(ctx, KnockShareMode, provider, options?)`
- Provider 补 `getLinkShareData`
- 增量提问：只问本次新增链接侧必问项（Q4/Q5），不重复问整份 Q3；不问 Q8（链接侧不问精准，文件侧已有不补精准）
- SDK：当前 22 已满足 both 包文件侧 22+ 目标 → 不改 SDK；不写 `"26.0.0"`

**应包含**：`assets/both/`、`KnockShareMode`、`getLinkShareData`、第二套监听
**不应包含**：新建 Manager、并行监听、`"26.0.0"`、重复问整份 Q3
**格式**：markdown

---

### 测试用例：FUNC-006（电脑接收 + 精准 → 先读 UI 再问落点）

**skill**：hmos-share-kit-knock-share
**类型**：functional

#### 输入

```
【模拟工程】
工程 compatibleSdkVersion=26.0.0、targetSdkVersion=26.0.0
未检测到已有碰一碰接入
assets/file/、assets/KnockRectUtil.ets 可读

接入碰一碰分享文件。要电脑端应用内接收，也要精准碰一碰。无需询问问题，基于模拟前置条件给出完整的工作流程，无需探测真实工程。
```

#### 预期输出

**验证标准**：

- 提问顺序：Q8 第一轮只问是否精准（本例已答 yes），不夹杂接收落点；Q7=yes 且 Q8=yes 都定了之后，再问接收落点
- 接收落点确认：问之前先读挂载页，在问题里陈述实际读到的结构（布局、数据源、项 id）；落点选项从该结构推导，**必须含自定义**；禁止套用现成选项表 / 插入模板；禁止未确认就把接收项 push 到末尾却声称已做精准接收
- SDK：当前 `"26.0.0"` 已满足 26+ → 不改 SDK；禁止 `"7.0.0(26)"` / `"6.0.0(26)"`
- 模板注入：拷贝 `assets/file/` + `KnockRectUtil.ets`；`enable(context, provider, { pcReceive: true, preciseKnock: true })`
- Provider 实现：实现 `getReceiveCapabilities()`，utd 与 `getFileShareData` 一致；`maxSupportedCount` ≤ 5；实现 `hitTestReceiveIndex`；`onDataReceived` 改 `@State` 用 `runScopedTask` 或 `AppStorage`
- 精准实现：`deviceInfo.apiAvailable('26.0.0')` 字面量
- 完成报告：写明读到的 UI 结构与所选落点；人工清单含同账号、电脑停在已注册页、碰应用窗口

**应包含**：先读挂载页、接收落点、自定义、`getReceiveCapabilities`、`hitTestReceiveIndex`、`runScopedTask`、`maxSupportedCount`
**不应包含**：套用现成选项表、未确认 push 到末尾、`"7.0.0(26)"`、变量传入 `apiAvailable`
**格式**：markdown
