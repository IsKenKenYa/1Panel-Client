---
name: hmos-arkui-kit-window-floatwindow
description: 辅助 OpenHarmony 悬浮类需求开发：画中画（PiPWindow）、闪控窗（floatView）、闪控球（floatingBall）。覆盖能力分流、接口指南、代码查错（指出文件/行/错在哪并直接改）、按需求改用户工程里的 ArkTS、按评审稿写需求设计。Use when the user mentions 画中画、PiP、PiPWindow、闪控窗、floatView、闪控球、floatingBall、悬浮小窗、球窗绑定、防窥保护组合，或要为这三类写代码/查误用/写需求。不覆盖子窗口 createSubWindow、全局悬浮窗 TYPE_FLOAT、模态窗 TYPE_DIALOG。
license: MIT
metadata:
  version: "1.0.0"
---

# 悬浮类需求开发（画中画 / 闪控窗 / 闪控球）

只处理三类应用辅助窗口。用户提到子窗 / `TYPE_FLOAT` / 模态窗时：**明确说不在本 Skill 范围**，给一句分流理由后停手。

签名、权限、错误码以 [references/](references/index.md) 落盘为准。日常不要 WebFetch。不要凭本文件直接写页面。有应用工程就改现有文件。骨架只读 [assets/](assets/skeleton.md) 对应文件。`references/misuse/misuse-*.md` 只放误用要点。指导缺口见 [references/index](references/index.md)「缺口」。

## 目录

```text
hmos-arkui-kit-window-floatwindow/
├── SKILL.md                      分流、模式、铁律（本文件）
├── assets/                        可抄骨架；写程序只走这里
│   └── skeleton.md
├── test-cases/                   分流冒烟 + 写程序功能评测
│   └── README.md
└── references/                    官网落盘与评审；按子目录打开，不要通读
    ├── index.md                  七类索引
    ├── requirement-review.md     需求评审稿
    ├── apis/                     js-apis 全文（只 Grep 节）
    ├── guides/                   开发指导摘要
    ├── permissions/              权限 + 错误码
    ├── misuse/                   误用清单
    └── engineering/              Stage / 语法 / 视觉
```

## 何时用哪种模式

| 用户意图 | 模式 |
|----------|------|
| 这是哪种窗 / 该用哪个模块 | **分流** |
| 有哪些接口、权限、错误码、调用顺序 | **接口** |
| 贴了代码 / 报错 / 小窗出不来 | **查错** |
| 给需求，写程序 / 示例 | **写程序** |
| 写需求、评审稿、规格、用例 | **需求设计** |

一次请求可叠加。**先分流，再动手。**

**分流 / 纯问答（含评测）：** 先用一行给出能力 id（`pip` / `float_view` / `floating_ball` / `bind` / `out_of_scope`），再展开。用户说「不要读任何文件」时：**禁止 Read** `assets/` / `references/`，只凭本文件分流表作答。

## 工作流

```text
进度:
- [ ] 1. 判定能力：pip | float_view | floating_ball | bind | float_view+peep | pip+bind | pip+bind+peep | out_of_scope
- [ ] 2. 按模式读文件（见下表），不要把 references/ 整目录读完；纯分流问答可跳过本步
- [ ] 3. 按模式产出；写程序只抄 assets/，不要抄 js-apis 示例
- [ ] 4. 写程序改了 ets / json5：先做语法自检（arkui-syntax「写出来必须能编过」），再自己跑 hvigorw；交卷必须带 CompileArkTS 通过。无工程 / 无 hvigorw 则写明停手原因，禁止让用户去 DevEco 代编
```

| 模式 | 读什么 |
|------|--------|
| **分流** | 本文件分流表。拿不准先问一句，不要 Read `references/` |
| **接口** | 先读对应 `references/guides/guide-*.md`（球无 guide 则 [misuse-floating-ball.md](references/misuse/misuse-floating-ball.md)）。`references/apis/js-apis-*.md` **只 Grep 标题后 Read 该节**，禁止整文件 Read |
| **查错** | 先读对应 `references/misuse/misuse-*.md`。路径/权限再对 [stage-layout.md](references/engineering/stage-layout.md)。错误码只 Grep `references/permissions/errorcode-window-float.md` **对上的那一条**，禁止整文件 Read。**能定位到工作区文件就改掉** |
| **写程序** | 只按 [assets/skeleton.md](assets/skeleton.md) **表里那一行**读齐，再对照 [stage-layout.md](references/engineering/stage-layout.md) / [arkui-syntax.md](references/engineering/arkui-syntax.md) / [ui-style.md](references/engineering/ui-style.md)。禁止通读 `references/apis/js-apis-*.md`；签名对不上才 Grep `references/apis/` 该节 |
| **需求设计** | [references/requirement-review.md](references/requirement-review.md)。写接口章时 Grep `references/apis/js-apis` **对应节**，禁止整文件 Read |

### 1. 分流（必做）

本步不要 Read 接口文档。按用户目标选（绑定标 `bind`；闪控窗+防窥标 `float_view+peep`；会议画中画+球窗标 `pip+bind`）：

| 判定 | 能力 | 模块 |
|------|------|------|
| 视频播放 / 通话 / 会议 / 直播；画面迁到系统小窗；系统画控制条；**一镜到底** | **画中画** | `PiPWindow`（默认 `create(config)` 无第二参 + 同一 controller + AVPlayer。用户明确迁自定义节点才走 typeNode） |
| 退后台后继续展示**自定义页面内容** | **闪控窗** | `floatView` |
| 贴边小球；不能自定义 UI | **闪控球** | `floatingBall` |
| 点击球展开窗、点窗缩小回球 | **绑定** | `floatView.bind` |
| 闪控窗持续展示 + 窥视时系统蒙层 | **闪控窗 + 防窥** | `floatView` + `dlpAntiPeep` |
| 会议/视频画中画 **和** 球窗出现在同一 demo | **叠加** | 入口列表；运行时互斥，见 [assets/merge.md](assets/merge.md) |
| `createSubWindow` / `TYPE_FLOAT` / 模态窗 | **范围外** | 停手 |
| 视频小窗但不要 PiP 控制条、要自定义页 | **不要用 PiP**；用闪控窗 |

拿不准时先问一句。不要把未绑定的三套同时 `start`。

**模板对照（用户说某一种 → 用对应枚举）**

画中画 `PiPTemplateType`（`controlGroups` **和** `controlEvent` 必须同族，否则 401）：

| 用户说法 | 模板 |
|----------|------|
| 播放、点播、看视频 | `VIDEO_PLAY` |
| 通话、语音/视频电话 | `VIDEO_CALL` |
| 会议、开会 | `VIDEO_MEETING` |
| 直播 | `VIDEO_LIVE` |

对照 [assets/pip.md](assets/pip.md) 三列表，不要只改枚举却留播放事件。

闪控球 `FloatingBallTemplate`：静态 `STATIC`（title+icon，禁 update）；标题+内容 `NORMAL`；强调 `EMPHATIC`；一行标题 `SIMPLE`。未说则 `EMPHATIC`。

闪控窗：圆角/面板 `ROUNDED_RECTANGLE`；横条 `HORIZONTAL_BAR`。未说则圆角。

未说样式时：PiP=`VIDEO_PLAY`，球=`EMPHATIC`，窗=`ROUNDED_RECTANGLE`。

**互斥：** 已启动闪控窗不能 `startPiP`；已启动画中画或未绑定的球不能 `floatView.start`；已启动闪控窗不能 `startFloatingBall`（皆 `1300034`）。bind 成功后启停任一即两边一起；同一时刻只展示其中一个。

### 2. 三条铁律

1. **`create` 只拿控制器，不建窗。** 看得见要等 `start*`，以状态回调 `STARTED` 为准（闪控窗 `start()` Promise 返回 ≠ 启动完成）。
2. **主窗口必须已显示/前台。** Ability `onCreate` 里直接 start 会失败。
3. **先能力探测再调用。** `canIUse('SystemCapability.Window.SessionManager')` + `isPiPEnabled` / `isFloatViewEnabled` / `isFloatingBallEnabled`。防窥另加 `canUseAntiPeep()`；`HIDE` 走 `showSystemMaskLayer`，不要裸调 `setAntiPeepMaskLayer`。

### 3. 接口模式

按能力输出一张表：导入与 API 等级、权限三处、调用顺序、模板约束、常见错误码。

读法：**先**对应 `references/guides/guide-*.md`（闪控球没有 guide，改读 `references/misuse/misuse-floating-ball.md`）。需要签名时再 Grep `references/apis/js-apis-*.md` 的导入 / create·start / 权限 / 错误码**标题**，只 Read 命中的那一节。禁止 Read 整个 `js-apis-*.md`，禁止 Grep 工作区框架仓。

### 4. 查错模式

对照对应能力的 `references/misuse/misuse-*.md`；能改文件就改。不要先打开 `js-apis-*.md` 或整份错误码。对上具体码再 Grep `references/permissions/errorcode-window-float.md` **那一条**。输出按出现顺序：

```markdown
### E<n> [<能力>] <一句话问题>
- **位置**：`文件路径:行号`
- **现状** / **错因** / **表现**（错误码）
- **改法**：已写入 `路径` 的最小改动
```

🔴 必改 401/201/801/13000xx；🟡 生命周期/绑定；🟢 风格/漏 off。禁止不标位置；不要把框架缺陷说成应用误用。跨能力先对文末反模式。

### 5. 写程序模式

**先读骨架再改文件。** 不要抄 `references/apis/js-apis-*.md` 示例当可粘贴代码。

1. 只按 [assets/skeleton.md](assets/skeleton.md) 的表读齐。不要在本文件另开捷径；不要跳过 `pip.md` 直接抄 xcomponent；绑定不要再抄一份 `floating-ball.md` 整页 Index。
2. [references/engineering/stage-layout.md](references/engineering/stage-layout.md) 落点。有 `module.json5` + `main_pages.json`、用户给了路径、即使 `ets/pages` 为空也补文件。仅无应用模块时停手问路径。
3. [references/engineering/arkui-syntax.md](references/engineering/arkui-syntax.md)「写出来必须能编过」+ [references/engineering/ui-style.md](references/engineering/ui-style.md)
4. **自己编译**：命令见 [references/engineering/stage-layout.md](references/engineering/stage-layout.md)；交卷带 `CompileArkTS` 通过（失败则改 ets 再编）。签名对不上才 Grep `references/apis/js-apis` **某一节**，禁止 Read 整个 `js-apis-*.md`
5. 表里有防窥才读 [assets/peep.md](assets/peep.md)，往已有页里加，不要另起一页

**交卷前必检（写程序）：**

```text
有工程（module.json5 + hvigorw）时：
- [ ] 语法规范：对照 arkui-syntax「写出来必须能编过」——try/catch+BusinessError；getWindowId 禁止 as number；PiP 只用 setAutoStartEnabled；XComponent 用 Options 形态；无 deprecated 顶层 router
- [ ] 编译成功：自己跑 hvigorw assembleHap；输出含 CompileArkTS 通过。失败改 ets 再编。禁止让用户去 DevEco 代编

无工程 / 无 hvigorw 时（不要假装编过）：
- [ ] 可先分流再停手问工程路径；不要在当前仓根新建 entry/
```

评测用例见 [test-cases/](test-cases/README.md)（冒烟 + 功能均聚焦问答分流/答疑，不卡编译）。

- ArkTS error / throw / deprecated / `as number` → 改刚写的 ets
- 缺 `DeviceSecurityKit` DTS → 说明 SDK，不要改成文案防窥

### 6. 需求设计模式

Read [references/requirement-review.md](references/requirement-review.md)。不要引用其他 skill。

## 调用顺序

以对应 `assets/*.md` 为准，不要另写一套。速记：PiP 默认 XComponent 无第二参、视频页 `setAutoStartEnabled(true)`、进 PiP 不摘组件；窗 `setUIContext` 后 `start` 等 STARTED；球无页面；bind 两边未 start 再 bind；防窥见 [assets/peep.md](assets/peep.md)。

## 反模式

- 用 `TYPE_FLOAT` / `createSubWindow` 冒充闪控或画中画
- 把 `create` 成功当成已显示；只抄接口空壳没有 XComponent/AVPlayer
- 未 bind 同时 start 窗和球，或与已启动 PiP 并行
- `getWindowId()` 写成 `as number`；把页面/球文案改 `****` 当防窥
- 声明了 `DLP_GET_HIDE_STATUS` 就当防窥已开；开关未开只在注释里写「去设置」、不上屏、不调 `requestAntiPeepOptions`
- 改完 ets 不自己编，让用户去 DevEco 点编译
- 在 `aboutToAppear` 里 start；在 `aboutToDisappear` 里 `stop` 导致退后台被自己关掉
- 应用侧写 `setAutoStart`（必须 `setAutoStartEnabled`）

其余见对应 `references/misuse/misuse-*.md`。
