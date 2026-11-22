# 页面栈迁移自检清单

> 适用场景：多层 Navigation/Router 页面的导航栈完整迁移。
> 代码示例：`assets/examples/RouterContinuity.ets`、`assets/examples/NavigationContinuity.ets`
> 方案说明：`references/navigation-continuity.md`

---

## 一、基础接入前提（红线节）

> 如果项目尚未完成基础接入，先逐项完成。
> 配置模板：`assets/templates/module.md`；Ability 模板：`assets/templates/EntryAbility.ets`
> ⚠️ 本节为红线项：任何情况下不得以其他文档（reference/示例注释）表述为由降级、跳过或放宽；违反即步骤 5 自检不通过。

- [ ] `module.json5` 目标 UIAbility 已添加 `"continuable": true`
- [ ] `onContinue(wantParam)` 已实现
- [ ] `onCreate(want)` / `onNewWant(want)` 中处理 `launchReason === CONTINUATION` 分支
- [ ] **数据流方向红线**：源端只做 `AppStorage → wantParam` 导出；目标端只做 `want.parameters → AppStorage` 落地（迁移数据唯一来源）；目标端恢复**禁止**读同端 AppStorage 同 key 充当数据源——`setOrCreate(k, AppStorage.get(k) ?? v)` 式自循环会让迁移数据永不落地，且编译/静态检查全过，仅表现为对端"正常打开空白/初始页"
- [ ] 目标端页面恢复按路由方式接线：Router → `onCreate`/`onNewWant` 执行完成前**同步**调用 `restoreWindowStage()`（须 try/catch 兜底）；Navigation → `onWindowStageRestore` 中 `loadContent` 加载根页面
- [ ] `onWindowStageRestore` 仅当 `onWindowStageCreate` 有启动必要的初始化时才添加并镜像执行；系统页面栈恢复时不 `loadContent`（无初始化时整段省略）

---

## 二、路由方式确认

> **核心约束：不修改项目现有路由方式。**

- [ ] 已确认项目路由方式：□ Navigation □ Router
- [ ] Navigation 项目保留 Navigation，Router 项目保留 Router
- [ ] **绝不可**为了"简化接续"把 Navigation 改成 Router

---

## 三、Navigation 路由 — 手动重建

> Navigation 路由系统**不**支持自动恢复页面栈，必须手动处理。
> 代码示例：`assets/examples/NavigationContinuity.ets`

### 3.1 源端快照采集

- [ ] 已实现 `NavStackSnapshot` 数据结构（`entries: NavStackEntry[]` + `currentIndex: number`）
- [ ] 已实现 `NavStackCodec` 序列化/反序列化
- [ ] 采集使用 **`setInterception({ didShow })` 单一钩子**（API 12+，签名见 `references/api-reference.md` §3-B.2）——任何页面展示（push/replace/系统返回 pop）统一刷新，**勿在每个 push 点各改一处**（漏改即丢层）
- [ ] 快照采集调用 `pathStack.getPathStack()`（API 名与"**栈不含 NavBar 根页**"口径见 api-reference §3-B.1）
- [ ] 快照 JSON 写入 `AppStorage['currentNavStack']`
- [ ] **空快照边界**：启动后从未进入任何子页（未触发 didShow）即迁移 → `entries` 为空是**合法**状态，目标端落根页为正确行为——勿误判为重建失败、勿造假数据
- [ ] `onContinue` 中设置 `SUPPORT_CONTINUE_PAGE_STACK_KEY = false`
- [ ] `onContinue` 中读取快照并写入 `wantParam['navStack']`

### 3.2 目标端导航栈重建

- [ ] 已实现 `NavStackRebuilder.rebuild()` 按快照重建导航栈
- [ ] `onCreate` / `onNewWant` 中从 `want.parameters['navStack']` 读取快照 JSON（⚠️ `want` 只在这两个回调中可读，`onWindowStageRestore` 拿不到 `want`；**冷/热启动统一在 CONTINUATION 分支暂存 AppStorage**）
- [ ] 快照 JSON 写入 `AppStorage['migratedNavStack']`，并同步调用 `restoreWindowStage()`（try/catch 兜底，见 §一）
- [ ] `onWindowStageRestore` 中 `loadContent` 加载根页面
- [ ] **entries[0] 语义已核证**：`getPathStack()` 快照**不含 NavBar 根页**（api-reference §3-B.1），`entries[0]` 是第一个真实子页——重建时**全部 push，不跳过任何 entry**（旧版 `rootLoaded=true` 跳过 entries[0] 会丢第一层子页）
- [ ] 根页 `aboutToAppear` 中消费快照并**消费即清**（防重复重建），调用 `NavStackRebuilder.rebuild(pathStack, snapshot)`
- [ ] **热启动联动**（`launchType: singleton` 必配，module.md 约定必测）：根页 `@StorageProp('migratedNavStack') + @Watch` 感知 `onNewWant` 落地的新快照——**先捕获本地副本再清空**（@StorageProp 单向同步会把成员刷空，先清后读必翻车），`clear()` 本机会话栈后重建（接线见 navigation-continuity §3.6）
- [ ] **clear() 产品语义已确认**：热启动重建会丢弃目标端本机会话栈（接续意图优先）——属产品决策，须在方案确认与完成报告中向用户说明
- [ ] 重建后 Navigation 停留在 `snapshot.currentIndex` 对应层
- [ ] 每页入参通过 `NavPathInfo.param` 传入（仅限 JSON 可序列化数据）

---

## 四、Router 路由 — 系统自动恢复

> Router 路由系统自动恢复页面栈，只需补充自定义状态。
> 代码示例：`assets/examples/RouterContinuity.ets`

- [ ] 无需设置 `SUPPORT_CONTINUE_PAGE_STACK_KEY`（系统默认自动恢复；因业务需要关闭自动恢复走手动重建时见本节末条）
- [ ] `onCreate` / `onNewWant` 的 CONTINUATION 分支中、方法执行完成前**同步**调用 `restoreWindowStage(new LocalStorage())`，触发带页面栈的页面恢复（禁止放进异步回调，否则迁移后页面加载失败）
- [ ] `restoreWindowStage` 调用已 **try/catch 兜底**：失败置标记，`onWindowStageRestore` 中兜底 `loadContent` 落地页，避免对端白屏（该接口可抛异常，见 `references/api-reference.md` §3.2）
- [ ] **真机门（真机优先）**：真机验证系统页面栈恢复实际生效（迁移后深层页直出、非白屏）；排除时序/异常问题后仍白屏时，切换手动落地页模式（`SUPPORT_CONTINUE_PAGE_STACK_KEY = false` + `onWindowStageRestore` 中 `loadContent` 根页 + 业务转发栈顶，见 `references/navigation-continuity.md` §2.4），并记入已知风险
- [ ] `onWindowStageRestore` 不 `loadContent`（页面栈已由 `restoreWindowStage` 恢复，重复加载会破坏已恢复的栈）；仅当 `onWindowStageCreate` 有初始化时镜像执行，无初始化则省略该回调
- [ ] 自定义状态（滚动位置、表单数据等）补充到 `wantParam`
- [ ] 目标端 `onCreate` / `onNewWant` 中恢复自定义状态
- [ ] （可选）如需手动维护完整栈入参：记录 `router.getState()?.index` + 每页入参——⚠️ `router.getState()` 在 UIAbility 作用域真机返回不可靠且已 deprecated，仅作辅助核对；栈顶/可达性判定以页面可见性事件为主（onPageShow/onPageHide 维护标记，见 `references/ui-progress-continuity.md` §2.3）
- [ ] （按需迁移）Router 项目已设 `SUPPORT_CONTINUE_PAGE_STACK_KEY = false` 时：entryPage 标记 + 根页 `aboutToAppear` 中 `pushUrl` 手动还原深层栈（两层栈模式），见 `references/navigation-continuity.md` §2.4

---

## 五、每页状态恢复（与 UI/编辑/播放场景联动）

- [ ] **push 后页面内状态变更**（quantity/submitted 等不触发重新 push 的 `@State`）已接实时态链路：页内 `@Watch` 实时上报 live key → 快照采集时合并进**顶层 entry** 的 `stateJson` → 目标端新实例 `onReady` 从**本实例入参**接管（per-instance 传递不落共享 key，防同页名多实例串染）——完整片段见 `references/navigation-continuity.md` §4.1
- [ ] `NavStackEntry.stateJson` 携带该页的 PageState 快照（多页面/懒加载场景，可选）
- [ ] 页面在 `aboutToAppear` 中通过 `PageStateRegistry` 恢复交互状态（多页面场景；单页面可键直连，模式选择见各场景 checklist）
- [ ] 状态恢复发生在导航栈重建之后（页面已进入栈才触发 `aboutToAppear` / `onReady`）

---

## 六、多 Ability 场景（如适用）

- [ ] 已明确哪个 Ability 承接迁移（通常主 Ability 代理转发）
- [ ] 多 Ability 间 `continueType` 取值一致
- [ ] 非主 Ability 页面迁移时，主 Ability 接收迁移并根据 `continueType` 分发给对应 Ability

---

## 七、双设备实测步骤

1. **首页迁移**：A 在首页 → 接续 → 验证 B 显示首页（回归确认）
2. **单层 push 迁移**：A 首页 → push 到子页 A → 接续 → B 停留在子页 A
3. **三层深链迁移**：A 首页 → push 子页 B → push 子页 C（第三层）→ 接续 → B 停留在子页 C
4. **返回行为验证**：B 从子页 C → 按返回 → 回到子页 B（不跳回首页、不栈断裂）
5. **回退/重建后导航**：B 从子页 C 返回后继续 push 子页 D → 行为正常
6. **混合状态**：子页 C 有 TextInput/滚动（交互状态）→ 迁移后状态与导航栈均正确
7. **多 Ability 迁移**（如适用）：A 在非主 Ability 页面 → 接续 → B 正确打开对应 Ability 对应页面
8. **热启动迁移**（singleton 必测）：B 已在运行（前台/后台）→ A 从深层页接续 → 验证 B 走 `onNewWant`、导航栈切换为迁移快照（本机会话栈按产品语义丢弃）、停留层级与源端一致
9. **首页空快照**：A 启动后未进任何子页直接接续 → 验证 B 落根页（空快照为正确行为，非重建失败）

---

## 八、常见陷阱排查（现象 → 根因 → 修法）

| 现象 | 根因 | 修法 |
|------|------|------|
| Router 迁移后只有首页/白屏 | 未调用 `restoreWindowStage()`、将其放进异步回调（Promise/回调函数），或调用抛异常未兜底 | 在 `onCreate`/`onNewWant` 执行完成前的同步方法体中调用 `restoreWindowStage(new LocalStorage())`（try/catch 兜底，失败时 `onWindowStageRestore` 中兜底 `loadContent`，见 api-reference §3.2） |
| Router 迁移后深层页面丢失又重复加载 | `onWindowStageRestore` 中 `loadContent` 破坏了系统已恢复的页面栈 | 系统页面栈恢复时不在 `onWindowStageRestore` 中 `loadContent`，仅镜像 `onWindowStageCreate` 的初始化 |
| 迁移后只有首页，深层页面丢失 | `SUPPORT_CONTINUE_PAGE_STACK_KEY` 未设 `false`，系统尝试自动恢复 Navigation 栈但失败 | 设置该 key 为 false；改手动重建 |
| 导航栈乱了（页面顺序颠倒/重复） | 重建时机重复消费同一快照，或 didShow 采集中又触发重建形成循环 | 消费即清（`aboutToAppear`/`@Watch` 处理后立即置空标记）；采集与重建互斥 |
| 迁移后**丢第一层子页**（如"分类"页，直接落在第二层） | 误把 `entries[0]` 当根页跳过（旧版 `rootLoaded=true` 错误假设）——`getPathStack()` 快照**不含 NavBar 根页**，entries[0] 是第一个真实子页 | 重建**全部** push，不跳过任何 entry；实施前核证 entries[0] 语义（api-reference §3-B.1） |
| 采集代码编译 ERROR（方法不存在） | 用了不存在的 `getAllPathStack()`（历史错名） | 改为 `getPathStack()`（api-reference §3-B.1 单点定义） |
| 热启动接续无反应（B 已运行，栈不切换） | 只实现了冷启动 `aboutToAppear` 消费——热启动根页不重建，快照落地 AppStorage 后无人感知 | 根页 `@StorageProp + @Watch` 联动（§3.2 / navigation-continuity §3.6）；`onNewWant` 同分支暂存 |
| 热启动消费读到空快照 | `@StorageProp` 单向同步：先清 AppStorage 再读本地成员，成员已被刷成空串 | **先捕获本地副本、再清空**；空串守卫防清空回触发重入 |
| 返回时乱跳/栈断裂 | `currentIndex` 记录错误或重建后未 pop 到正确层 | 确认 `currentIndex = pathStack.size() - 1` 在快照时刻正确 |
| 页面入参丢失 | `NavStackEntry.params` 中含非序列化对象（如函数/类实例） | 入参仅限于 `Record<string, Object \| undefined>` 可序列化数据 |
| 页面状态与导航栈恢复顺序紊乱 | `restoreState` 在 `aboutToAppear` 执行时尚未拿到导航栈上下文 | `restoreState` 内部判断页面是否有完整入参再执行；或由根页统一控制顺序 |
| 把 Navigation 改为 Router 来"简化接续" | 违反项目路由架构约束 | 保留原路由方式：Navigation 手动重建，Router 系统自动恢复 |
