# 可抄骨架（本地）

签名以 [references/](../references/index.md) 落盘为准。写程序只按下表**对应那一行**读齐，不要通读本目录，不要抄 `js-apis` 示例。

先保证页面能加载：`main_pages.json` 与加载 API 字符串一致。画中画枚举按 [pip.md](pip.md) 三列表改，不要只改 `tpl`。播放器落 `ets/model/AVPlayer.ets`。

| 能力 | 按序读 | 不要 |
|------|--------|------|
| 画中画 | [merge.md](merge.md) → [pip.md](pip.md) → 默认 [pip-xcomponent.md](pip-xcomponent.md)；用户明确迁节点才 [pip-typenode.md](pip-typenode.md) | 同时抄 XC 和 typeNode；跳过 `pip.md` |
| 闪控窗 | [merge.md](merge.md) → [permissions.md](permissions.md) → [float-view.md](float-view.md) | 把启动逻辑写进 FloatPanel |
| 闪控球 | [merge.md](merge.md) → [permissions.md](permissions.md) → [floating-ball.md](floating-ball.md) | 给球新建页面 / `setUIContext` |
| 绑定 | [merge.md](merge.md) → [permissions.md](permissions.md) → [float-view.md](float-view.md)（Index 外壳 + FloatPanel）→ [bind.md](bind.md)（只换 `start()`） | 再抄一份 [floating-ball.md](floating-ball.md)；再调 `startFloatingBall` |
| 闪控窗+防窥 | 上表闪控窗 → [peep.md](peep.md)；权限再加 `DLP_GET_HIDE_STATUS` | 另起一页做防窥 |
| 绑定+防窥 | 上表绑定 → [peep.md](peep.md)；权限再加 `DLP_GET_HIDE_STATUS` | 另起一页做防窥 |
| 画中画 + 球窗（+防窥） | [merge.md](merge.md) 叠加节 → [pip.md](pip.md) → [pip-xcomponent.md](pip-xcomponent.md) → 上表绑定（防窥再加 peep） | 运行时同时 `startPiP` 和 `floatView.start` |

抄之前核对：

1. 能力探测：syscap + `isXxxEnabled`
2. 权限按 [permissions.md](permissions.md) 裁剪；仅 `FLOAT_VIEW` 弹窗。PiP 无特殊权限
3. 调用顺序、`BusinessError` 与该行骨架一致；状态回调；退出 `stop*` + `off*`
4. 若画中画：同一 controller + `create(config)` 无第二参；进 PiP 不摘组件；`controlGroups` / `controlEvent` 与 `tpl` 同族
5. 若绑定：`floatView.bind`，听 `IN_FLOATING_BALL`；只要一套 Index
6. 若防窥：开关、回调、蒙层见 [peep.md](peep.md)，往已有页里加
7. 能编过：会抛 API 要 try/catch；见 [arkui-syntax.md](../references/engineering/arkui-syntax.md)「写出来必须能编过」
