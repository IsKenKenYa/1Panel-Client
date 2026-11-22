# 决策树（流程执行地图）

只保留判定分支与落点 Step，不重复处置细节——各分支的具体动作以 SKILL.md 对应 Step 正文为准，冲突与失败一律以错误处置表、退出条件·收尾规则为唯一依据。开始执行前置步骤前加载。

```text
用户提出隔空传送相关问题
│
├─ 前置步骤 Step 0 任务性质判定：仅咨询？
│   ├─ 是 → 只解答，不改工程（退出条件·仅咨询）
│   └─ 否（改码 / 升级）→ 依次执行 前置步骤 Step 1-3
│
├─ 前置步骤 Step 1 版本门槛：targetSdkVersion ≥ 6.0.0(20)？
│   ├─ 否 → 按 E1 中止改码
│   ├─ 是，但 compatibleSdkVersion < 6.0.0(20) → 不中止，canIUse 降级
│   └─ 通过 → 继续
│
├─ 前置步骤 Step 2 接入状态：检测到已注册监听？
│   ├─ 无 → mode = first
│   └─ 有 → 按结构判定（非文件名）
│       ├─ 同构 → mode = homogeneous
│       └─ 异构 → mode = heterogeneous，按 E8 处置
│
├─ 前置步骤 Step 3 → 定位 mount.module 与挂载页候选
│
├─ 工作流程 Step 0 引导确认：按分享类型锁定问题集（细则见 guide-confirmation.md）
│   ├─ 类型未定 → 本轮只问类型
│   ├─ 仅文件 → 问文件侧项（Q2、Q3）
│   ├─ 仅链接 → 问链接侧项（Q2、Q4）
│   └─ 两者 → 文件组 + 链接组 + 模式切换（Q2-Q5）
│
├─ 工作流程 Step 1 注入：按 mode 走对应分支（assets/ 不可读 → E6 中止）
│   ├─ first → 拷对应类型资产包，页面实现 Provider
│   ├─ homogeneous → 用 both 包升级既有实现（冲突按 E3）
│   └─ heterogeneous → 按 E8 三选一处置
│
├─ 工作流程 Step 2 生命周期：按页面结构成对接线
│   ├─ NavDestination → onShown / onHidden
│   ├─ 普通 @Entry → onPageShow / onPageHide
│   └─ Tab / 子组件 → 向上找宿主页；找不到 → 追问挂载点
│
├─ 工作流程 Step 3 入口 Ability 加载检测：onWindowStageCreate + loadContent
│   ├─ 已实现且加载挂载页 → ok
│   ├─ 未实现/类体为空 → 补全（patched）
│   ├─ 加载页不一致 → 追问；未授权 → 已知限制注明
│   └─ 文件不存在 → 按 E7 输出待合并片段
│
├─ 工作流程 Step 4（仅 share_type ∈ {link, both}）：App Linking 端侧合并
│   ├─ 域名已确认且授权改配置 → 合并非覆盖 skills + Ability
│   └─ 未确认 → 两阶段：端侧骨架 + TODO 高亮，不声称可直达
│
├─ 工作流程 Step 5 代码验证：静态检查 → 编译
│   ├─ 有构建能力 → 检查并编译，失败按 E4 处置
│   └─ 无构建能力 → 报告写明未自动编译，人工清单加 IDE 编译
│
└─ 工作流程 Step 6 → 完成报告（修改摘要 / 验证结果 / 人工清单 / 已知限制）
```
