# 内容编辑类接续自检清单

> 适用场景：表单、文本编辑器等内容输入场景。
> 代码示例：`assets/examples/EditProgress.ets`
> 方案说明：`references/edit-progress-continuity.md`

---

## 一、基础接入前提（红线节）

> 如果项目尚未完成基础接入，先逐项完成。
> 配置模板：`assets/templates/module.md`；Ability 模板：`assets/templates/EntryAbility.ets`
> ⚠️ 本节为红线项：任何情况下不得以其他文档（reference/示例注释）表述为由降级、跳过或放宽；违反即步骤 5 自检不通过。

- [ ] `module.json5` 目标 UIAbility 已添加 `"continuable": true`
- [ ] `onContinue(wantParam)` 已实现，可迁移页面返回 `AGREE`，不可迁移返回 `REJECT`
- [ ] `onCreate(want)` / `onNewWant(want)` 中处理 `launchReason === CONTINUATION` 分支
- [ ] **数据流方向红线**：源端只做 `AppStorage → wantParam`（DDO 场景含 DDO 属性）导出；目标端只做 `want.parameters → AppStorage` 落地（迁移数据唯一来源）；目标端恢复**禁止**读同端 AppStorage 同 key 充当数据源——`setOrCreate(k, AppStorage.get(k) ?? v)` 式自循环会让迁移数据永不落地，且编译/静态检查全过，仅表现为对端"正常打开空白/初始页"（双端数据流对照表见 `assets/examples/EditProgress.ets` 文件头）
- [ ] 目标端页面恢复已按路由方式接线：Router（默认）→ `onCreate`/`onNewWant` 执行完成前**同步**调用 `restoreWindowStage()`（须 try/catch 兜底）；禁用页面栈迁移（Navigation/按需）→ `onWindowStageRestore` 中 `loadContent` 加载落地页
- [ ] `onWindowStageRestore` 仅当 `onWindowStageCreate` 有启动必要的初始化时才添加并镜像执行；系统页面栈恢复时不 `loadContent`（无初始化时整段省略）
- [ ] Navigation 路由项目：已在 `onContinue` 设置 `SUPPORT_CONTINUE_PAGE_STACK_KEY = false`

---

## 二、编辑器三态恢复

> 编辑器类页面须同步三个独立状态：**可得的缺一不可**；组件不可得的状态按下表处理——**记为已知缺口上报**（完成报告"已知风险"），禁止为凑齐三态造假实现。

**输入组件三态可得性：**

| 状态 | TextInput | TextArea | 说明 |
|------|-----------|----------|------|
| 文本内容 | ✅ 可得 | ✅ 可得 | 绑定的状态变量直接导出 |
| 滚动位置 | ⚠️ 须经外层 `Scroll` + `Scroller` 改造 | ⚠️ 同左 | 未经改造的页面没有采集入口；改造成本过高时记为已知缺口上报 |
| 光标位置 | ✅ `TextInputController` | ❌ 无公开光标 API（`caretPosition` 属 `TextInputController`） | TextArea 场景记为已知缺口上报，不伪造恢复 |

- [ ] **文本内容（text）**：export 记录当前文本，restore 赋值
- [ ] **滚动位置（scrollOffset）**：export 记录 `scroller.currentOffset().yOffset`，restore 中 `scrollTo()`
  - ⚠️ 恢复时机须延迟到布局完成后（`setTimeout(50)` 或 `onAreaChange`）
  - ⚠️ 不要用 `onDidScroll` 回调参数（可能是每帧增量而非累计位置）
  - ⚠️ 页面未经 Scroll + Scroller 改造时无采集入口：改造或记为已知缺口上报（二选一，不得静默跳过）
- [ ] **光标位置（caretPosition）**：TextInput 场景 export 记录 `TextInputController` 光标并 restore；TextArea 无公开光标 API——记为已知缺口上报，不伪造恢复
- [ ] 选中内容范围（如有）一并记录
- [ ] 三个状态独立导出与恢复，不合并为单一 blob

---

## 三、表单状态恢复

- [ ] 表单各字段的当前填写值已导出与恢复
- [ ] 未填写字段保持为空（不填充默认值）
- [ ] 下拉选择框、单选/多选等控件状态已覆盖

---

## 四、初始值保护（懒加载组件）

> Tabs 懒加载下未访问过的 Tab 组件从未创建（handler 未注册），`exportAll()` 收集不到其状态；
> 若 payload 对应字段为默认值（如 `''`），目标端恢复时会覆盖组件本地初始值。

- [ ] payload 中未从 handler 获得的字段保持 `undefined`（collect 时不填充默认值）
- [ ] `restoreState()` 中仅覆盖 `!== undefined` 的字段，保护组件本地初始值
- [ ] 已用"从未操作该 Tab 直接迁移"的场景实测：目标端该 Tab 初始值未被清空

---

## 四-B、装饰器迁移（状态变量改造）

> 改造规则详见 `references/state-decorator-migration.md`

- [ ] TextInput/TextArea 绑定的变量已通过 `@StorageLink`（V1）或 `@Local` + `@Monitor`（V2）绑定到 AppStorage
- [ ] onChange 回调逻辑未因装饰器改造而破坏
- [ ] 光标位置（TextInputController）保持 private，未误改为响应式装饰器
- [ ] 涉及的 `@Prop` / `@Link` 改造已同步修改父组件（V1）
- [ ] V2 组件的 `@Monitor` 已覆盖所有需要迁移的 `@Local` 变量

---

## 五、数据通道选型

每页根据状态数据量确认迁移方式（见 `references/data-migration-strategies.md`）：

- [ ] **轻量**（< 100KB）：序列化 JSON 走 `want.parameters`
- [ ] **复杂/可变**（≥ 100KB / 需要实时双向同步）：改 DDO，wantParam 只传 `distributedSessionId`
  - [ ] 源端 DDO 流程：`create()` → `genSessionId()` → `setSessionId()` → `save()` → 传 sessionId
  - [ ] 目标端 DDO 流程：空 DDO（属性 undefined）→ 先 `on('status')` 注册 → `setSessionId()` → restored 回调更新 UI
  - [ ] status 判断兼容 `'restored'`/`'restore'` 双字面量（版本间字面量不一致，双兼容写法已覆盖，无需查证本机 SDK；见 `references/api-reference.md` §4.5）
  - [ ] 遵循"先监听再激活"时序（`on('status')` 在 `setSessionId()` 之前注册）
  - [ ] 已处理 DDO 生命周期释放：**回调之外、延后数秒或 onDestroy 统一注销**（`off` + `setSessionId('')`）——⚠️ DDO 回调红线：`on()` 回调内禁止 `off()`/`setSessionId('')`/丢弃 DDO 引用/大 I/O（回调内同步注销真机实证触发 SIGSEGV，见 SKILL.md 硬约束、api-reference §4.7 延后收尾模式）
- [ ] **涉及文件资产（图片/附件/文档）时必须逐项通过**（只传文件名/URI 引用 = 文件不会到达对端，见 `references/data-migration-strategies.md` 方式三）：
  - [ ] 文件已实际写入 `distributedFilesDir`（迁移前逐一 stat 校验；构建失败记日志并跳过该张，不中断迁移）
  - [ ] 每个 `commonType.Asset` 以**根属性**进 DDO：source 必须是 `flatAssets()` 展平结果（`attachments0..N`）；资产数组整体作根属性不被官方支持
  - [ ] `imageNames` 与 `attachments` 顺序/索引严格对齐；对端按 `attachments{i}` 下标读回，数量以名称列表为准
  - [ ] Asset 六个字段（name/uri/path/createTime/modifyTime/size）均为 string（@since 11 类型定义）
  - [ ] 对端复制路径用**对端本地** `distributedFilesDir + '/' + asset.name` 拼接；禁止使用 `asset.path`（那是源端设备绝对路径）
  - [ ] 对端先把文件复制到本地 `filesDir` 再解码 PixelMap（脱离分布式文件生命周期）
  - [ ] PixelMap / Resource / 函数引用等不可序列化对象未混入 DDO（Resource 迁移前 `getStringSync` 解析为 string）
  - [ ] 运行端 API 20+ 且资产数量动态时，评估改用框架托管的 `setAssets` + `on('progressChanged')`（须先于 setSessionId，见 `references/api-reference.md` §4.8/§4.9）
- [ ] ⚠️ **文件迁移无法靠编译验证**：在完成 §八 "图片/文件资产迁移" 真机实测之前，报告中图片/文件恢复必须标记为**未验证项**，禁止以"编译通过、清单已核"声称完成

---

## 六、并发写冲突策略

> 编辑类场景保留源端应用（`SUPPORT_CONTINUE_SOURCE_EXIT_KEY = false`）时，双端可能同时编辑同一数据。

- [ ] 已定义冲突策略：
  - [ ] **乐观锁**（版本号比对，冲突提示）或
  - [ ] **后写者胜**（明确声明，接受覆盖）
- [ ] 策略有代码实现，且双端一致

---

## 七、状态模型与 Ability 集成

- [ ] 已定义 `PageState` 接口（见 `assets/examples/UIProgress.ets` 中的框架代码）
- [ ] 已实现 `PageStateRegistry` 单例，**或等效 AppStorage 键直连**——**多页面/懒加载 Tab 场景必须 registry**（§四 初始值保护依赖其按页收集状态）；**单编辑器页可走键直连**（onContinue / 页面侧直接读写约定 key，参照 `assets/examples/EditProgress.ets`），两种方案按场景二选一
- [ ] `onContinue` 中调用 `PageStateRegistry.getInstance().exportAll()`（或键直连导出）
- [ ] `onCreate` / `onNewWant` 的 CONTINUATION 分支中将状态 JSON 写入 `AppStorage`（或逐 key 落地）
- [ ] 页面 `aboutToAppear` 中从 `AppStorage` 读取状态并恢复

---

## 八、双设备实测步骤

1. **文本编辑恢复**：A 输入多行文本（含中英文/符号）→ 接续到 B → 验证内容一致
2. **光标位置恢复**：A 光标停在文本中部 → 接续到 B → 验证光标位置合理（TextInput 场景；TextArea 无公开光标 API，记缺口则跳过本步并在报告标注）
3. **滚动位置恢复**：A 编辑长文本滚动到底部 → 接续到 B → 验证 B 同一位置
4. **表单恢复**：A 填写表单部分字段 → 接续到 B → 验证已填字段完整、未填字段为空
5. **DDO 复杂状态**（如适用）：A 编辑长内容 → 接续到 B → 验证完整恢复 → A 继续编辑 → B 实时同步
6. **懒加载保护**：A 从未切换至某编辑 Tab → 直接接续 → 验证 B 该 Tab 默认值未被清空
7. **并发写冲突**（如适用）：A、B 同时编辑同一数据 → 触发定义好的冲突策略
8. **版本升级兼容**：状态 `version` 变更后旧快照仍可降级解析
9. **图片/文件资产迁移**：A 选择多张图片（含大图、多张混选）→ 接续到 B → 验证 B 端张数与图片内容一致、可继续加图且已恢复图片不丢失；A 选图后**立即**接续 → 验证未落盘的图片被记日志跳过而非崩溃
10. **文件通道回归**：确认没有任何"只传文件名/URI 引用"的旁路残留（文本正常但图片空白即此症状）
11. **迁移后新建回归**：迁移完成后，对端执行 新建笔记 → 输入内容 → 保存 → 返回列表 → 验证生成的是**新**记录、原迁移笔记未被覆盖（防全局键残留污染，见 §九末行）

---

## 九、常见陷阱排查（现象 → 根因 → 修法）

| 现象 | 根因 | 修法 |
|------|------|------|
| 接续后文本内容恢复但光标跳到末尾 | 光标位置未单独导出/恢复 | 补充 `caretPosition` 的导出与恢复 |
| 滚动位置迁移失败（停留在顶部） | 恢复时机过早 + 采集语义歧义 | 延迟 `scrollTo` + 改用 `scroller.currentOffset().yOffset` |
| 状态恢复但 UI 未刷新 | 恢复用了同名对象引用而非重新赋值 | 恢复时显式 `= newValue` |
| DDO 对端收到 undefined | 目标端创建空 DDO 时属性未设为 `undefined` | 必须 `new ContinuationData(undefined, undefined, ...)` |
| DDO restored 回调未触发 | 未在 `setSessionId` 之前注册 `on('status')` | 交换顺序 |
| want.parameters 超限 | 状态序列化后 > 100KB | 改为 DDO 或数据标识重拉 |
| 懒加载 Tab 初始值被覆盖 | payload 默认值覆盖本地初始值 | payload 字段改可选、collect 不填默认值、restore 仅覆盖 `!== undefined` |
| 双端数据互相覆盖 | 未定义冲突策略或双端策略不一致 | 统一乐观锁/后写者胜并在两端一致实现 |
| 源端退出后目标端读不到数据 | 未调用 `DDO.save()` 或未 `await` save 完成 | `await save(targetDevice)` 确保持久化 |
| 接续后文本正常、**图片缺失/空白** | 只把文件名/URI 引用放进 DDO 或 want.parameters，指望 `distributedFilesDir` 自动同步——文件从未被传输 | 改文件资产迁移：Asset 经 `flatAssets()` 展平为 DDO 根属性 `attachments0..N`（或 API 20+ `setAssets`），见 data-migration 方式三 |
| 对端 `attachments{i}` 为 undefined | source 未用 `flatAssets()` 展平（资产数组整体塞入不受支持） | 按 `references/edit-progress-continuity.md` §2.1 / `assets/examples/EditProgress.ets` 展平 |
| 对端 restored 到达但复制文件失败 | 直接使用了 `asset.path`/`asset.uri`（源端设备绝对路径） | 用 `asset.name` 拼对端本地 `distributedFilesDir` 路径 |
| 恢复回调迟迟不触发 | 仅判断 `'restored'`，而运行系统发出的字面量是 `'restore'`（或相反） | `status === 'restored' \|\| status === 'restore'` 双兼容（api-reference §4.5） |
| 对端"正常打开"但内容为空白/初始值（编译全过） | 目标端恢复写成同端自循环：`setOrCreate(k, AppStorage.get(k) ?? v)`，迁移数据从未从 `want.parameters` 落地 | 改为 `want.parameters → AppStorage` 单向落地（数据流方向红线，见 §一；双端对照表见 EditProgress.ets 文件头） |
| 迁移后对端"新建/另开条目"显示上一条数据，保存互相覆盖（新建功能失效） | 用全局可持久状态残留值（token/id 非空）启发式判定"接续落地"，或 `@StorageLink` 共享键消费后不清——AppStorage 跨页面重进持续存在，非接续入口误命中接续分支 | 一次性显式标记（路由参数/消费即清除的 flag）；非接续入口按 id 空值显式重置（`references/state-decorator-migration.md` §3） |
