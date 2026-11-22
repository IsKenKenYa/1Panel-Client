# 隔空传送接入实践与陷阱

## 目录

- 推荐做法
- 常见陷阱
  - 编译 / 静态检查（E4 排障首查）
  - 运行时
  - App Linking 拉起
  - 引导与流程（验收自查）
- 模板来源
- 官方参考与版本事实
- 验证

## 推荐做法

1. **仅在可分享界面监听**：进入注册，离开/退后台注销，避免误触与串页。
2. **预热数据**：选中变化时更新可分享 URI / 链接字段；手势回调里只做组装与 `share`/`reject`。
3. **绑定 windowId**：PC/平板自由窗依赖焦点窗口判断。
4. **能力降级**：`canIUse` 为 false 时隐藏入口或 Toast，不要抛未捕获异常。
5. **类型单一与分包**：一次分享只发文件或链接，同一时刻 `enable` 只带一种 `GestureShareMode`；按 SKILL.md 工作流程 Step 1 分包拷贝 `assets/file` / `assets/link` / `assets/both`，补另一种时用 `both` 升级现有 Manager/Provider。
6. **业务类失败路径**：推荐返回 `undefined`（由 Manager `reject`），与 `assets/`、`wiring-snippet.ets` 一致；多文件用 collect + 循环 `addRecord`，避免 N 段复制粘贴。
7. **业务类实现方式**：推荐 `class X implements GestureShareProvider`（见 wiring）；对象字面量 `{ canShare: ... }` 易触发 `arkts-no-untyped-obj-literals`。
8. **接收侧**：Ability 只落盘非空 `want.uri`，用 `incomingUri` 判断，不设 `fromAppLink`；导航跟宿主路由风格一致。**不要**改成 `onCreate` 里直接跳转——原因见陷阱表「冷启动闪退」行。

引导确认的提问范围、默认值与核验细则**以 [guide-confirmation.md](guide-confirmation.md) 为唯一来源**，本文件不复述。

## 常见陷阱

### 编译 / 静态检查（E4 排障首查）

| 问题 | 原因 | 处理 |
|------|------|------|
| `arkts-no-untyped-obj-literals` | wiring 用对象字面量当 Provider | 对照 wiring：改为 `class implements GestureShareProvider` |
| 写死 router API | 与宿主 Navigation 等风格冲突 | 探测后按现有栈跳转 |
| 整文件替换宿主 EntryAbility / skills | 把 ability/skills 片段当完整文件拷 | 两片段均为合并形态：方法并入已有类；App Linking 作为新增独立 skill 对象追加进 skills 数组，勿动 home 入口条目 |
| App Linking 混入 home 入口 skill 对象 | 官方明确链接必须独立对象，混置无法生效 | skills 数组分两条：home 入口一条（home/action.home），链接一条（browsable/viewData/https/domainVerify），对照 module-skills-snippet |
| Ability 硬编码 host 与 skills 不一致 | 二次校验漏改/大小写 | host 交给 skills；Ability 只存非空 uri |

### 运行时

| 问题 | 原因 | 处理 |
|------|------|------|
| 应用启动白屏（页面不加载） | 入口 Ability 未实现 `onWindowStageCreate` + `loadContent`，或 `loadContent` 页面路径与挂载页不一致 | 工作流程 Step 3 已自动检测并补全；手工排查：读 `module.json5` 的 `mainElement` 定位入口 Ability，确认已实现 `onWindowStageCreate` 且 `windowStage.loadContent('<挂载页路径>')`（路径格式 `pages/Index`，不带 `.ets` 后缀与 `src/main/ets/` 前缀；误用 `loadPageByName` 会编译失败） |
| 手势无回调 | 未注册 / 已 off / 窗口无焦点 / 系统开关未开 | 查生命周期与设备开关 |
| 分享超时失败 | 回调内下载或重 IO | 预热；3 秒内 `share`/`reject` |
| 文件对端失败 | URI 无效或权限 | 使用可分享沙箱 URI |
| 混用 clarifyNonShare | 文档标明偏碰一碰且版本更高 | 隔空传送用 `reject(NO_CONTENT_ERROR)` |
| 快速切页后监听状态错乱 | enable/disable 异步竞态（`getLastWindow` promise 交错） | 已知限制：避免快速连续切换；按完成报告「已知限制」声明 |
| 页面数据变化后分享内容不更新 | 每次变化重新 `new` Provider，引用不同步 | 页面持**同一 Provider 实例**直接改字段（SKILL.md 工作流程 Step 2） |

### App Linking 拉起

| 问题 | 原因 | 处理 |
|------|------|------|
| 对端打不开应用 | 域名校验未通过 / 签名 / 云侧配置 | 走 [app-linking-checklist.md](app-linking-checklist.md)「域名校验与排障」节（20 秒等待、hidumper 查询）；勿用 example.com |
| 冷启动闪退（UIAbility 未正常启动） | `onCreate` 里直接处理链接参数并跳转页面（官方 FAQ） | 只落盘 `incomingUri`，由页面侧消费后再导航——ability 片段即此设计，勿改 |
| 推送 / NFC 跳转失效 | 把 uris 配进推送等场景共用的 skill 对象 | 各跳转场景**独立 skill 对象**，勿与 App Linking 条目合并（官方建议） |

### 引导与流程（验收自查）

引导提问类问题（跳过引导直接改码、问错类型项、问可检测项、问有默认值的项、漏问 uri 获取方式、把勾选当唯一模型等）一律以 [guide-confirmation.md](guide-confirmation.md) 为唯一来源（三层分流 / 题号对照 / 矩阵 / 默认值 / Q3 细则），本节不复述，只保留两条非引导层的坑：

| 问题 | 原因 | 处理 |
|------|------|------|
| 用异常表示无内容 | 把 throw 当控制流 | 对照模板：返回 `undefined`，由 Manager reject |
| 社区写「5.0 即可」 | 指 HarmonyShare 能力族，非 gesturesShare | 以 **targetSdk `6.0.0(20)`** 为准；compatible 可更低，靠 `canIUse` 降级 |

## 模板来源

- 接入代码以本 Skill `assets/` 为准（按 Q1 拷贝、先打开模板、禁止凭记忆重写；读不到模板中止）——此纪律以 SKILL.md 硬约束 2 与错误处置表 E6 为唯一依据，本节不复述。
- 不要沿用未确认的占位域名（如 `www.example.com`），或把宿主无关的存储键名写进接入结果。
- **`appIdentifier` 只在云侧 / 网站 `applinking.json`**；不要写入端侧工程，也不要把 `assets/app-linking-tools/applinking.json` 拷进模块。

## 官方参考与版本事实

整体门槛以 **targetSdk `6.0.0(20)`** 为准（见 SKILL.md 前置步骤）；下表细分版本仅排障 / 答疑时用：

| API | 起始版本 |
|-----|---------|
| `on/off('gesturesShare')` 及 `SendCapabilityRegistry`（`windowId`）重载 | 6.0.0(20) |
| `SharableTarget.share` | 5.0.0(12) |
| `SharableTarget.reject` | 5.0.3(15) |
| `clarifyNonShare` | 6.0.2(22)，文档标明仅碰一碰 → 隔空传送无内容场景用 `reject(NO_CONTENT_ERROR)` |

能力检测：`canIUse('SystemCapability.Collaboration.HarmonyShare')`

`SharedData` 可选字段（`title` / `description` / `thumbnailUri`）不能代替必填项：文件分享必填 `utd` + `uri`，链接分享必填 `HYPERLINK` + `content`；可选字段默认不写。

官方文档（排障 / 深入时读）：

- [harmonyShare API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-harmony-share)
- [隔空传送指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/gestures-share)
- [SharedRecord 定义](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/share-system-share#sharedrecord)
- [utd 规范](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/share-access-utd)

## 验证

验证流程以 SKILL.md 工作流程 Step 5 为唯一来源（静态检查 → 编译 → 失败按错误处置表 E4 处置；真机「一抓一放」属人工验收），本节不复述。
