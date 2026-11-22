# UI 浏览类接续自检清单

> 适用场景：列表页、详情页、Tab 页面等只读浏览场景（含原生 UI 和 Web 组件）。
> 代码示例：`assets/examples/UIProgress.ets`、`assets/examples/WebProgress.ets`
> 方案说明：`references/ui-progress-continuity.md`

---

## 一、基础接入前提（红线节）

> 以下为 UI 浏览类接续的最小接入前提。如果项目尚未完成基础接入，先逐项完成。
> 配置模板：`assets/templates/module.md`；Ability 模板：`assets/templates/EntryAbility.ets`
> ⚠️ 本节为红线项：任何情况下不得以其他文档（reference/示例注释）表述为由降级、跳过或放宽；违反即步骤 5 自检不通过。

- [ ] `module.json5` 目标 UIAbility 已添加 `"continuable": true`
- [ ] 已确认 `launchType`（默认 `singleton`）
- [ ] `onContinue(wantParam)` 已实现，可迁移页面返回 `AGREE`，不可迁移返回 `REJECT`
- [ ] `onCreate(want)` 中处理 `launchReason === CONTINUATION` 分支，从 `want.parameters` 读取数据并暂存
- [ ] `onNewWant(want)` 中同样处理 `CONTINUATION` 分支（热启动场景）
- [ ] **数据流方向红线**：源端只做 `AppStorage → wantParam` 导出；目标端只做 `want.parameters → AppStorage` 落地（迁移数据唯一来源）；目标端恢复**禁止**读同端 AppStorage 同 key 充当数据源——`setOrCreate(k, AppStorage.get(k) ?? v)` 式自循环会让迁移数据永不落地，且编译/静态检查全过，仅表现为对端"正常打开空白/初始页"
- [ ] **滚动恢复时序红线（Web 与原生通用）**：滚动恢复必须在容器就绪后**延时**执行——原生 `scrollTo` 延迟到布局完成后（`setTimeout ≥ 50ms` 或 `onAreaChange`）；Web `runJavaScript` 恢复 H5 scrollTop 放在 `onPageEnd` 之后再延时 ≥300ms（onPageEnd ≠ 内容高度就绪，立即执行被钳制→停留顶部，真机反馈高频失败）。❌ `aboutToAppear`/`loadUrl` 后立即执行（详见 §二 / §四）
- [ ] 目标端页面恢复已按路由方式接线：
  - [ ] Router（默认系统页面栈恢复）：`onCreate`/`onNewWant` 的 CONTINUATION 分支中、方法执行完成前**同步**调用 `restoreWindowStage(new LocalStorage())`（禁止放进异步回调；须 try/catch 兜底）
  - [ ] 禁用页面栈迁移（Navigation/按需）：`onWindowStageRestore` 中 `loadContent` 加载落地页
- [ ] `onWindowStageRestore` 仅当 `onWindowStageCreate` 中有启动必要的初始化时才添加，并镜像执行同样的初始化；系统页面栈恢复时**不** `loadContent`（`onWindowStageCreate` 无初始化时整段省略，最小侵入）；Router 系统恢复路径可加**白屏兜底探测**（延迟 ≥1500ms 探测可见页面，有内容绝不干预、仅空栈时按落地页重建——探测过早会摧毁正在恢复的栈）
- [ ] **一次性标记卫生（isContinuation 等）**：恢复成功消费即清；**任何兜底分支（白屏兜底 loadContent / 落地非目标页 / 迁移取消失败路径）同样负责清理**——残留标记会让下次正常导航误入接续分支（见 SKILL.md Common Mistakes 键残留条目）
- [ ] 写入 wantParam 的数据总量 < 100KB
- [ ] Navigation 路由项目：已在 `onContinue` 设置 `SUPPORT_CONTINUE_PAGE_STACK_KEY = false`

---

## 二、滚动位置恢复

- [ ] `exportState()` 记录 `scroller.currentOffset().yOffset`（**不要直接用 `onDidScroll` 回调参数**，其 `yOffset` 可能是每帧增量而非累计位置）
- [ ] `restoreState()` 中 `scrollTo()` 延迟到布局完成后执行：
  - `setTimeout(() => { scroller.scrollTo(...) }, 50)` 或更长延迟
  - 或在 `onAreaChange` / `postFrameCallback` 中触发
  - ⚠️ `aboutToAppear` 中直接执行或 `setTimeout(0)` 时 Scroll 尚未完成布局，`scrollTo` 会被静默忽略

---

## 三、Tab 状态恢复

- [ ] Tabs 的 `selectedIndex` 已导出与恢复
- [ ] 页面标识（`pageId`）与注册表 key 一致

---

## 四、Web 组件状态（如适用）

- [ ] 源端 **live URL 持续追踪（三管采集，❌ 非一次性）**：① `onLoadIntercept` 主框架导航即时捕获 ② 滚动事件节流 `getUrl()`（~500ms，兜底捕获锚点跳转——`#section` **不触发任何加载回调**）③ `onPageEnd` 以 `getUrl()` 为准校准最终 URL；只记入参 URL 会导致"章节跳转让进度失效"（偏移打到另一篇文档，见 `references/ui-progress-continuity.md` §5.1、`assets/examples/WebProgress.ets`）
- [ ] 目标端：`loadUrl` 加载**带 `#fragment` 的完整 URL**（H5 自行锚点定位）+ `runJavaScript` 恢复滚动偏移（**锚点定位与偏移恢复双保险**，官方 continue-progress 模式）
- [ ] **源端已采集滚动偏移并随 wantParam 迁移**：`onTouch`（`TouchType.Up`）经 `runJavaScript` 读 H5 scrollTop 写 AppStorage、`onPageEnd` 校准，`onContinue` 随 `webUrl` 一并导出（❌ 只传 URL 不传偏移——目标端无从恢复）
- [ ] **目标端滚动恢复时序**：`onPageEnd` 之后再延时 ≥300ms 执行 `runJavaScript` 恢复 scrollTop（❌ `aboutToAppear`/`loadUrl` 后立即执行——页面未加载；`onPageEnd` 内立即执行——内容高度未就绪被钳制，停留顶部；真机反馈高频失败）
- [ ] **不**将 H5 内部状态当原生状态序列化（H5 内部状态需 H5 侧配合：URL 参数编码 / postMessage）

---

## 五、初始值保护（懒加载组件）

> 背景：Tabs 懒加载下未访问过的 Tab 组件从未创建（handler 未注册），`exportAll()` 收集不到其状态；
> 若 payload 对应字段为默认值（如 `''`），目标端恢复时会覆盖组件本地初始值（如 `'Hello HarmonyOS'`）。

- [ ] payload 中未从 handler 获得的字段保持 `undefined`（collect 时不填充默认值）
- [ ] `restoreState()` 中仅覆盖 `!== undefined` 的字段，保护组件本地初始值
- [ ] 已用"从未操作该 Tab 直接迁移"的场景实测：目标端该 Tab 初始文案/默认值未被清空

> **具体案例：** 某演示项目（Tabs 三标签页）曾因 payload 接口硬编码必选 + `collect()` 预填 `''`，未访问 Tab 的初始文案 `'Hello HarmonyOS'` 被空串覆盖——修法即上述三条（字段改可选、collect 不填默认值、restore 仅覆盖非 undefined 字段）。

---

## 五-B、装饰器迁移（状态变量改造）

> 改造规则详见 `references/state-decorator-migration.md`

### V1 组件（@Component）
- [ ] 需要迁移的 `@State` 变量已改为 `@StorageLink('key')`
- [ ] 不需要迁移的 `@State` 变量保持不变
- [ ] 涉及的 `@Prop` / `@Link` 改造已同步修改父组件
- [ ] `@Watch` 与新 `@StorageLink` 共用时回调时序已验证
- [ ] AppStorage key 全局唯一，无命名冲突

### V2 组件（@ComponentV2）
- [ ] `@Local` 变量未被错误改为 `@StorageLink`（V2 不支持）
- [ ] 需要迁移的 `@Local` 变量已添加 `@Monitor` 写入 AppStorage
- [ ] `aboutToAppear` 中已从 AppStorage 读取迁移数据
- [ ] Ability 侧的 `onContinue` / `onCreate` 写法与 V1 一致

---

## 六、状态模型与 Ability 集成

> **模式选择（二选一，勿默认重模型）**：多页面/懒加载 Tab 场景**必须** registry（§五 初始值保护依赖其按页收集状态）；**单页面轻量场景（Web 页/详情页等 3 个左右标量）走"直接平铺写 wantParam"**——`onContinue` 中把约定字段逐个从 AppStorage 读出直写 `wantParam`（无 PageState 接口/Registry/Codec，参照 `assets/examples/WebProgress.ets`、`RouterContinuity.ets` 的平铺导出），目标端 `onCreate` 逐 key 落地。轻量场景建注册表属过度设计（registry 模式参照 `UIProgress.ets`）。

- [ ] 已按模式选择确认档位：registry / 直接平铺写 wantParam（轻量）
- [ ] registry 模式：已定义 `PageState` 接口，含 `pageId` / `version` / `payload`（见 `assets/examples/UIProgress.ets`）；已实现 `PageStateRegistry` 单例（页面 `aboutToAppear` 注册、`aboutToDisappear` 注销）与 `PageStateCodec`（JSON 解析失败有降级）
- [ ] 平铺模式：已维护约定 key 清单（页面侧实时写入 AppStorage，`onContinue` 逐 key 导出、`onCreate` 逐 key 落地）
- [ ] `onContinue` 中调用 `PageStateRegistry.getInstance().exportAll()`（registry 模式）或逐 key 平铺导出（平铺模式）
- [ ] `onCreate` / `onNewWant` 的 CONTINUATION 分支中将状态 JSON（registry）或逐 key（平铺）写入 `AppStorage`
- [ ] 页面 `aboutToAppear` 中从 `AppStorage` 读取状态并恢复

---

## 七、双设备实测步骤

1. **冷启动迁移**：A 打开详情页 → 从任务栏/Dock 接续到 B → 验证 B 冷启动打开且停留在同一详情页、数据正确
2. **热启动迁移**：B 已在运行（前台）→ A 再次接续 → 验证 B 走 `onNewWant` 且页面刷新
3. **滚动恢复**：A 长列表滚动到第 N 行 → 接续到 B → 验证 B 同样位置（若首次测试停留在顶部，排查恢复时机和采集语义）
4. **Tab 恢复**：A 切换到 Tab 3 → 接续到 B → 验证 B 选中 Tab 3
5. **拒绝场景**：在"不支持迁移"的页面触发接续 → 验证源端提示拒绝且不迁移
6. **懒加载保护**：A 从未切换至某 Tab → 直接接续 → 验证 B 该 Tab 默认值未被清空
7. **Web 组件**（如适用）：A 在 Web 页面浏览 → 接续到 B → 验证 B 加载同一 URL
8. **返回行为**：B 上返回键 → 行为合理（无栈断裂、无黑屏）
9. **图标出现条件**：A 处于可迁移页面时 B 显示接续图标；离开可迁移页后图标消失

---

## 八、常见陷阱排查（现象 → 根因 → 修法）

| 现象 | 根因 | 修法 |
|------|------|------|
| B 端完全不显示接续图标 | ① 蓝牙/接续开关/账号未满足 ② `continuable` 未设或设错 Ability ③ `setMissionContinueState(INACTIVE)` 被误调用 | 按 `constraints-and-prereqs.md` 第 6 节顺序排查 |
| 迁移后 B 白屏 | ① Router 默认场景未同步调用 `restoreWindowStage`（或放进了异步回调）② 禁用页面栈迁移但未在 `onWindowStageRestore` 中 `loadContent` ③ `onWindowStageCreate` 初始化未镜像 | Router：在 `onCreate`/`onNewWant` 执行完成前同步调用 `restoreWindowStage`；禁栈：补 `loadContent`；有初始化：镜像到 `onWindowStageRestore` |
| **Web/文章页闪现后回落首页** | `onWindowStageRestore` 无条件 `loadContent`，或白屏看门狗**探测过早**（800ms 级：栈仍在恢复中即被判空）——`loadContent` 摧毁了系统恢复出的栈 | 条件式 `loadContent`（仅禁栈/restore 失败时）；看门狗探测延迟 ≥1500ms 且**有内容绝不干预** |
| **章节跳转后进度失效**（偏移打到另一篇文档） | 只在 onContinue 一次性 `getUrl()`——`#section` 锚点跳转**不触发任何加载回调**，迁移数据停留在旧地址 | live URL 三管采集：`onLoadIntercept` + 滚动节流 `getUrl()` + `onPageEnd` 校准（§四 / ui-progress §5.1）；目标端带 fragment URL + 延时 `runJavaScript` 偏移恢复双保险（§5.2）|
| B 已在运行，第二次迁移无反应 | `onNewWant` 未实现或未处理 CONTINUATION | 补 `onNewWant`；`singleton` 热启动必测 |
| 滚动位置恢复但偏差 | 页面内容未加载完就 `scrollTo` | 延迟到布局完成后执行 |
| 滚动位置迁移失败（停留在顶部） | 恢复时机过早 + 采集语义歧义 | 延迟 `scrollTo` + 改用 `scroller.currentOffset().yOffset` |
| **Web 页滚动位置未恢复（停留顶部）** | ① 恢复过早：`aboutToAppear`/`loadUrl` 后立即执行，或 `onPageEnd` 内立即执行（内容高度未就绪被钳制）② 只迁移了 URL、未采集偏移量 | 源端 `onTouch`/`onPageEnd` 经 `runJavaScript` 采集 scrollTop 随 wantParam 迁移；目标端 `onPageEnd` 后延时 ≥300ms `runJavaScript` 恢复（§四 / ui-progress §5.2，官方 continue-progress 模式） |
| 懒加载 Tab 初始值被覆盖 | Tabs 懒加载下未创建组件，payload 默认值覆盖本地初始值 | payload 字段改可选、collect 不填默认值、restore 仅覆盖 `!== undefined` |
| Web 组件 H5 状态丢失 | H5 内部状态当原生状态直接序列化 | H5 状态需 H5 侧配合，原生侧只传 URL + WebController 状态 |
| 状态恢复但 UI 未刷新 | 恢复用了同名对象引用而非重新赋值 | 恢复时显式 `= newValue` |
| 触发接续时应用闪退 | `onContinue` 同步回调里做了耗时/异常操作 | 只做轻量同步保存 |
