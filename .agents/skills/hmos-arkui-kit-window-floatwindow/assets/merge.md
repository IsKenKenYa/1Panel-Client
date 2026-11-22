# 三种能力：页面怎么加载

Ability 只 `loadContent('pages/Index')`。每种能力自己的页必须进 `main_pages.json`，字符串和加载 API **逐字相同**，否则主页空白、二级页白屏、闪控窗空框。

路径写 `pages/Xxx`，禁止 `./pages/Xxx`。`module.json5` 用 `"pages": "$profile:main_pages"`。

| 能力 | 谁画界面 | 必须登记 | 怎么加载到屏上 |
|------|----------|----------|----------------|
| 闪控球 | 系统画贴边球，应用**没有球页面** | 只要主页 `pages/Index` | Index 按钮 `startFloatingBall`。禁止 `setUIContext`、禁止新建球页 |
| 画中画 | 应用视频页 + 系统小窗 | 宿主 `@Entry`（`Index` 或 `PipHost`） | 见 [pip.md](pip.md)。`Page1` 根节点必须是 `NavDestination()` |
| 闪控窗 | 另一份 `@Entry` 内容页 | `pages/Index` **和** `pages/FloatPanel` | Index `setUIContext('pages/FloatPanel')` 再 `start()`。窗里加载的**不是** Index |

```json
{
  "src": [
    "pages/Index",
    "pages/PipHost",
    "pages/FloatPanel"
  ]
}
```

只做一条就只登记那条用到的 `@Entry`。没登记的 `@Entry`：`router.pushUrl` / `setUIContext` / `loadContent` 都会失败。`Page1` 不是 `@Entry`，不要登记。

不要三条同时 `start`（`1300034`）。本文件只讲登记/加载；骨架按 [skeleton.md](skeleton.md) 表读。叠加才读下一节。

---

## 叠加 Index（画中画 + 球窗，可选防窥）

同一 demo 可以同时有会议画中画和球窗，**运行时只 start 一套**。登记 `pages/Index`、`pages/PipHost`、`pages/FloatPanel`。

- **进入会议**：`this.getUIContext().getRouter().pushUrl({ url: 'pages/PipHost' })`（PiP 尚未 start）。球窗已 start 则不准进，上屏「请先停止球窗」
- **启动球窗**：`floatView.bind` 后 `start()`。`1300034` 上屏「请先停止画中画」
- 强调按钮只留一个主入口（进入会议）；启动/停止球窗、拉起蒙层用灰底次按钮
- 不要同时 `startPiP` 和 `floatView.start`

防窥：[peep.md](peep.md)。Index `aboutToAppear` 就监听，不要等球窗 STARTED。球窗启动逻辑用 [bind.md](bind.md)，不要再抄一份 [floating-ball.md](floating-ball.md) Index。
