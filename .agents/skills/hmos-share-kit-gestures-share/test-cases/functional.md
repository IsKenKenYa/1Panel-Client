# 功能性测试（机测）

验证 skill 在完整接入工作流中的功能行为是否正确执行。每个用例模拟一个真实的工程接入场景，验收 skill 是否按 `SKILL.md` 规范完成对应环节的动作。

**测试约束**：
- 每个用例的输入已自带工程上下文，无需追问基础信息。
- 用例模拟实际接入流程，验收范围覆盖前置检测、引导确认、模板注入、生命周期接线、入口 Ability 检测、报告输出等环节。
- 无真实工程时，验收人可在提示中声明"模拟工程"并给出关键工程事实（build-profile 版本、已有文件、挂载页等），skill 应据此推进流程并产出可验收的中间结论与待合并片段。
- 每个用例的"预期输出"列出必须命中的行为锚点与禁止出现的行为，逐项核对。

---

### 测试用例：FUNC-001（首次接入文件分享完整流程）

**skill**：hmos-share-kit-gestures-share
**类型**：functional

#### 输入

```
【模拟工程】
工程 targetSdkVersion=6.0.0(20)、compatibleSdkVersion=5.0.0(12)
未检测到已有 harmonyShare.on('gesturesShare') 注册
挂载页：pages/Detail（普通 @Entry 页）
分享内容：当前页已选中的本地文件 URI 列表，可能多文件
文件 uri 来自 picker 选择结果（已为 file:// 沙箱 URI）
assets/file/ 可读

请接入隔空传送文件分享，挂载页 pages/Detail，分享当前页已选中的本地文件 URI 列表。基于模拟前置条件给出完整的工作流程，无需探测真实工程。
```

#### 预期输出

**验证标准**：

- 前置步骤执行：版本门槛通过（target ≥ 20），compat_low 标记为 true 并提示运行时 canIUse 降级
- 接入状态检测：未检测到已有监听 → mode = first
- 引导确认：已指定"仅文件"→ 不再问分享类型；按仅文件场景提问（文件数量、可分享范围、uri 来源、utd、是否多文件），禁止出现 App Linking / 域名 / 落地页等链接侧问题
- 模板注入：拷贝来源为 `assets/file/`，落盘位置经确认；Manager 单例 + Provider 用 `class implements GestureShareProvider`
- Provider 实现：多文件场景用 `collect + 循环 addRecord`；无内容时 `canShare()===false` 或返回 `undefined`，Manager `reject(NO_CONTENT_ERROR)`
- 生命周期接线：`onPageShow → enable(ctx, provider)` 两参签名、`onPageHide → disable()`
- 入口 Ability 检测：检查 EntryAbility 是否实现 `onWindowStageCreate + loadContent('pages/Detail')`
- 完成报告字段齐全（修改摘要 / 分享类型 / 引导确认摘要 / 挂载点 / 验证结果 / 人工清单 / 已知限制）；已知限制首条写明兼容区间与降级行为

**应包含**：`assets/file/`、`enable(ctx, provider)`、`onPageShow`、`onPageHide`、`addRecord`、`canIUse`
**不应包含**：`App Linking`、`HYPERLINK`、`example.com`、`第二套监听`、对象字面量 Provider
**格式**：markdown

---

### 测试用例：FUNC-002（增量补链接升级为 both）

**skill**：hmos-share-kit-gestures-share
**类型**：functional

#### 输入

```
【模拟工程】
工程 targetSdkVersion=6.0.0(20)
已有文件侧隔空传送接入：GestureShareManager.ets（单例、enable/disable 成对、内部含 harmonyShare.on/off）
GestureShareProvider.ets（实现 canShare + getFileShareData）
挂载页 pages/Detail 已接 enable(ctx, provider)
现在要增量补链接分享（App Linking）
域名：share.myapp.com，落地页 pages/Content，query 参数 contentId
签名与 applinking.json 未就绪
assets/both/ 可读

工程已有文件隔空传送，请再接入链接分享（App Linking）。
域名 share.myapp.com，参数 contentId，落地页 pages/Content。签名和 applinking.json 还没配好。基于模拟前置条件给出完整的工作流程，无需探测真实工程。
```

#### 预期输出

**验证标准**：

- 接入状态检测：检测到已有监听且结构符合模板 → mode = homogeneous
- 增量升级：用 `assets/both/` 升级既有实现，禁止新建第二套 Manager / 第二套 gesturesShare 监听（硬约束 3）
- enable 签名改为三参 `enable(ctx, GestureShareMode, provider)`
- 增量提问：只问本次新增的链接侧必问项（Q4 域名/query/落地页），不重复问文件侧已确认细节
- App Linking 两阶段：域名未确认 → 端侧骨架（Provider 链接送数 + module.json5 skills 独立对象 + Ability handleAppLinkWant），host 留 TODO 占位并在报告高亮；TODO 未清除前禁止宣称"直达可用"
- module.json5 中 App Linking 作为**独立 skill 对象**（含 browsable/viewData/https/domainVerify），禁止混入 home 入口条目
- 云侧（appIdentifier / applinking.json / AGC / 签名）列入人工清单，不写入端侧工程
- 完成报告字段齐全；验证结果如实写明编译状态

**应包含**：`assets/both/`、`enable(ctx, GestureShareMode, provider)`、`第二套监听`、独立 skill 对象、TODO
**不应包含**：新建 Manager、并行监听、云侧配置写入工程
**格式**：markdown

---

### 测试用例：FUNC-003（未指定类型的引导分流）

**skill**：hmos-share-kit-gestures-share
**类型**：functional

#### 输入

```
【模拟工程】
工程 targetSdkVersion=6.0.0(20)
未检测到已有隔空传送接入
无明显可分享页面与数据模型

接入隔空传送gesturesShare。基于模拟前置条件给出完整的工作流程，无需探测真实工程创建真实文件。
```

#### 预期输出

**验证标准**：

- 前置步骤执行：版本门槛通过、接入状态检测 mode = first、模块与挂载页候选定位产出页面候选列表
- 引导确认首轮：未指定类型 → 本轮**只先问**分享类型（文件 / 链接 / 两者），不附带文件 uri、App Linking 域名等任何另一类型细节
- 类型门控：类型一经确认，问题集锁定，集外问题禁止出现在后续任何一轮
- 未答清不修改代码、不注入实现
- 不输出内部记号（如 `share_type=file`、题号 Q1-Q5、mode 字段值等）

**应包含**：分享类型、文件 / 链接 / 两者
**不应包含**：文件 uri、App Linking 域名、落地页（首轮）、内部记号
**格式**：markdown

---

### 测试用例：FUNC-004（targetSdkVersion 过低中止）

**skill**：hmos-share-kit-gestures-share
**类型**：functional

#### 输入

```
【模拟工程】
工程 build-profile.json5：
  targetSdkVersion=5.0.0(12)
  compatibleSdkVersion=5.0.0(12)

帮我接入隔空传送 gesturesShare，挂载页 pages/Detail。
```

#### 预期输出

**验证标准**：

- 前置步骤 Step 1 版本门槛检测：targetSdkVersion < 6.0.0(20) → 警告并**停止自动改码**（按 E1 处置）
- 明确提示需将 targetSdkVersion 升级到 6.0.0(20)+（gesturesShare 起始版本）
- 未注入管理类、未修改业务页
- 不以"HarmonyOS 5.0 即可用 gesturesShare"放行
- 报告写明中止原因与恢复条件（升级 targetSdkVersion 后可重新接入）

**应包含**：`6.0.0(20)`、中止、targetSdkVersion
**不应包含**：`enable`、`disable`、`GestureShareManager`、注入
**格式**：markdown

---

### 测试用例：FUNC-005（异构实现迁移处置）

**skill**：hmos-share-kit-gestures-share
**类型**：functional

#### 输入

```
【模拟工程】
工程 targetSdkVersion=6.0.0(20)
已有隔空传送接入但是异构实现：
  - 自写 ShareModel.ets（非模板结构）
  - harmonyShare.on('gesturesShare') 注册内联在 pages/Detail 的 aboutToAppear 中
  - 无独立 Provider 接口
未检测到模板结构的管理类

我们工程里有个自写的 ShareModel.ets，想把它迁移重构为 Share Kit 隔空传送的标准模板结构。挂载页 pages/Detail。基于模拟前置条件给出完整的工作流程，无需探测真实工程。
```

#### 预期输出

**验证标准**：

- 接入状态检测：检测到已有监听但结构不符合模板 → mode = heterogeneous
- 按 E8 三选一处置（自然语言呈现，不报 E 编号）：
  (1) 授权后以模板为参照迁移重构（内联注册抽取到模板结构并移除原注册）
  (2) 保留既有实现 → 只输出待合并片段 + 人工清单
  (3) 中止该项接入
- 关键红线：禁止并行新建第二套监听（E8 三选项均适用）
- 处置未完成前不得宣称接入完成
- 报告列明被替换内容与被删除文件路径

**应包含**：迁移、第二套监听、异构、授权
**不应包含**：直接拷模板新建文件并行存在
**格式**：markdown

---

### 测试用例：FUNC-006（入口 Ability 未实现 loadContent 自动补全）

**skill**：hmos-share-kit-gestures-share
**类型**：functional

#### 输入

```
【模拟工程】
工程 targetSdkVersion=6.0.0(20)
挂载页 pages/Index
module.json5 mainElement 指向 EntryAbility
EntryAbility 文件存在但类体为空（未实现 onWindowStageCreate，也未调用 loadContent）
main_pages.json 首条 src: "pages/Index"
assets/file/ 可读

请接入隔空传送文件分享，挂载页 pages/Index。基于模拟前置条件给出完整的工作流程，无需探测真实工程。
```

#### 预期输出

**验证标准**：

- 工作流程 Step 3 入口 Ability 加载检测：发现 EntryAbility 未实现 `onWindowStageCreate`
- 自动补全：读 main_pages.json 取首条 src（pages/Index）作为入口页路径，仅新增 `onWindowStageCreate` + `loadContent('pages/Index')`，保留宿主已有其他方法与 import
- loadContent 页面路径格式：`pages/Index`（不带 .ets 后缀、不带 src/main/ets/ 前缀）
- 不误用 `loadPageByName`（WindowStage 无此方法，会编译失败）
- mount.entry_ability 记入 patched
- 报告修改摘要中定位到 EntryAbility 文件与新增段落

**应包含**：`onWindowStageCreate`、`loadContent`、`pages/Index`、补全
**不应包含**：`loadPageByName`、整文件替换、删除宿主已有方法
**格式**：markdown

---



### 测试用例：FUNC-007（读不到 assets 模板中止）

**skill**：hmos-share-kit-gestures-share
**类型**：functional

#### 输入

```
【模拟工程】
工程 targetSdkVersion=6.0.0(20)
验收时模拟：assets/file/ 目录打不开 / 读失败（或仅 SKILL.md 可见）

请接入隔空传送文件分享gesturesShare，挂载页 pages/Detail。基于模拟前置条件给出完整的工作流程，无需探测真实工程。
```

#### 预期输出

**验证标准**：

- 工作流程 Step 1 尝试打开 `assets/file/` 模板失败 → 按 E6 中止改码
- 明确说明需完整安装本 Skill 目录（含与 SKILL.md 同级的 `assets/`）
- 停止自动改码、未注入管理类 / 业务类
- 禁止凭记忆重写管理类或业务类模板内容

**应包含**：`assets/`、完整安装、中止
**不应包含**：凭记忆重写、注入、`enable`
**格式**：markdown

---

### 测试用例：FUNC-008（Provider 实现规范校验）

**skill**：hmos-share-kit-gestures-share
**类型**：functional

#### 输入

```
【模拟工程】
工程 targetSdkVersion=6.0.0(20)
挂载页 pages/Detail（普通 @Entry 页）
仅文件分享、单文件场景
assets/file/ 可读

请接入隔空传送文件分享gesturesShare，挂载页 pages/Detail，分享当前页单个本地文件 URI。基于模拟前置条件给出完整的工作流程，无需探测真实工程。
```

#### 预期输出

**验证标准**：

- Provider 实现使用 `class implements GestureShareProvider`，禁止对象字面量（原因：对象字面量易触发 `arkts-no-untyped-obj-literals`）
- 无内容时 `getFileShareData` 返回 `undefined`（由 Manager reject），禁止用 throw 异常表示无内容
- 手势回调内无下载或重 IO；可分享数据在监听前备好
- 页面持有同一 Provider 实例直接改其字段（引用同步），不重复 new
- `enable(ctx, provider)` 两参签名（file 包），非三参

**应包含**：`class implements`、`undefined`、同一 Provider 实例
**不应包含**：对象字面量、throw、重复 new
**格式**：markdown

---

### 测试用例：FUNC-009（仅链接分享完整流程）

**skill**：hmos-share-kit-gestures-share
**类型**：functional

#### 输入

```
【模拟工程】
工程 targetSdkVersion=6.0.0(20)
未检测到已有隔空传送接入
挂载页：pages/Content（NavDestination）

域名：share.myapp.com，已确认关联
query 参数：contentId
落地页：pages/Content
签名与 applinking.json 已就绪
assets/link/ 可读

请接入隔空传送链接分享（App Linking）。挂载页 pages/Content，域名 share.myapp.com，参数 contentId，落地页 pages/Content。基于模拟前置条件给出完整的工作流程，无需探测真实工程。
```

#### 预期输出

**验证标准**：

- 已指定仅链接 → 不再问分享类型；引导只问链接侧必问项及未指定的挂载/落盘目录
- 提问中不得出现文件数量、可分享文件范围、文件 uri / file://、getUriFromPath、按后缀算文件 utd
- 拷贝来源为 `assets/link/`，业务类无文件取数实现
- 生命周期接线：NavDestination 的 `onShown → enable(ctx, provider)`、`onHidden → disable()`
- App Linking 端侧：module.json5 中 App Linking 作为**独立 skill 对象**（含 browsable/viewData/https/domainVerify），禁止混入 home 入口条目；Ability 合并 handleAppLinkWant 到 onCreate/onNewWant，禁止整文件替换
- 云侧配置不写入工程
- 完成报告字段齐全；人工清单含签名、域名、设备开关等

**应包含**：`assets/link/`、`onShown`、`onHidden`、独立 skill 对象
**不应包含**：文件数量、文件 uri、`getUriFromPath`、文件 utd
**格式**：markdown

---
