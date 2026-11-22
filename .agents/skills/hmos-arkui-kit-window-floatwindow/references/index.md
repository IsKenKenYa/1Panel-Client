# Skill 内资料（官网落盘）

**以本目录接口落盘为日常契约。** 接口 / 查错 / 答接口时按下面「文档分类」打开对应文件，不要通读本目录，也不要把本仓 `docs/zh-cn` / DTS 当权威。官网现行正文只在用户要求刷新且抓到完整正文时覆盖本目录。

**写程序不要用本索引当骨架目录。** 骨架只走 [../assets/skeleton.md](../assets/skeleton.md)。

冲突：刷新成功的官网正文 > 本目录落盘 > `misuse/misuse-*.md`。

```text
references/
├── index.md                       本索引
├── requirement-review.md          需求评审稿
├── apis/                          接口全文（只 Grep 节，禁止整文件 Read）
│   ├── js-apis-pipWindow.md
│   ├── js-apis-floatView.md
│   └── js-apis-floatingBall.md
├── guides/                        开发指导摘要（球无独立 guide）
│   ├── guide-pip.md
│   ├── guide-float-view.md
│   ├── guide-dlp-anti-peep.md
│   └── window-type-overview.md
├── permissions/                   权限三处 + 窗口错误码
│   ├── restricted-permissions-float.md
│   ├── declare-permissions.md
│   ├── declare-permissions-in-acl.md
│   └── errorcode-window-float.md
├── misuse/                        误用清单（查错先读）
│   ├── misuse-pip.md
│   ├── misuse-float-view.md
│   └── misuse-floating-ball.md
└── engineering/                   写程序落点 / 语法 / 视觉
    ├── stage-layout.md
    ├── arkui-syntax.md
    └── ui-style.md
```

## 文档分类

| 目录 | 类 | 文件 | 何时读 |
|------|----|------|--------|
| `apis/` | 接口落盘 | [js-apis-pipWindow.md](apis/js-apis-pipWindow.md)、[js-apis-floatView.md](apis/js-apis-floatView.md)、[js-apis-floatingBall.md](apis/js-apis-floatingBall.md) | 接口模式：Grep 标题后只读该节 |
| `guides/` | 开发指导 | [guide-pip.md](guides/guide-pip.md)、[guide-float-view.md](guides/guide-float-view.md)、[guide-dlp-anti-peep.md](guides/guide-dlp-anti-peep.md)、[window-type-overview.md](guides/window-type-overview.md) | 接口/查错先读摘要。闪控球无独立 guide |
| `permissions/` | 权限与错误码 | [restricted-permissions-float.md](permissions/restricted-permissions-float.md)、[declare-permissions.md](permissions/declare-permissions.md)、[declare-permissions-in-acl.md](permissions/declare-permissions-in-acl.md)、[errorcode-window-float.md](permissions/errorcode-window-float.md) | 权限三处；错误码只 Grep 对上的 `13000xx` |
| `misuse/` | 误用清单 | [misuse-pip.md](misuse/misuse-pip.md)、[misuse-float-view.md](misuse/misuse-float-view.md)、[misuse-floating-ball.md](misuse/misuse-floating-ball.md) | 查错先读对应能力这一份 |
| `engineering/` | 工程 / 语法 / 视觉 | [stage-layout.md](engineering/stage-layout.md)、[arkui-syntax.md](engineering/arkui-syntax.md)、[ui-style.md](engineering/ui-style.md) | 写程序对照落点和能否编过 |
| （根） | 需求评审 | [requirement-review.md](requirement-review.md) | 需求设计只读这一份 |
| （根） | 目录说明 | 本文件 | 选文件，不要当骨架 |

## 刷新

仅当用户说「同步官网 / 刷新 skill」：WebFetch 下表 URL，用现行正文覆盖对应文件。官网页若是空壳（只有「文档中心」），保持本目录不动并说明未覆盖成功。

接口文档初次落盘可能来自与官网同构的 OpenHarmony 文档。刷新一律以官网覆盖。

## 缺口（不要把摘要当官网全文）

| 能力 | 已落盘 | 未落盘 / 非全文 |
|------|--------|-----------------|
| 画中画 | [js-apis-pipWindow.md](apis/js-apis-pipWindow.md) 接口全文 + [guide-pip.md](guides/guide-pip.md) 步骤摘要 | `guide-pip.md` 不是官网全文。写程序以指导摘要 + `assets/pip.md` 为准，日常不打开官网 |
| 闪控球 | [js-apis-floatingBall.md](apis/js-apis-floatingBall.md) 接口全文 | 无独立 `guide-*.md`。开发步骤以接口文档 + `assets/floating-ball.md` 为准 |
| 闪控窗 | 接口全文 + [guide-float-view.md](guides/guide-float-view.md) | `guide-float-view.md` 是要点摘要，不是官网指导全文。官网：https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/float-view-guide |
| 防窥 | [guide-dlp-anti-peep.md](guides/guide-dlp-anti-peep.md) | 同样是要点摘要。官网：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/devicesecurity-dlpantipeep |
| Stage 工程 / ArkUI 语法 | [stage-layout.md](engineering/stage-layout.md)、[arkui-syntax.md](engineering/arkui-syntax.md) | 摘要，不是入门全文。装饰器专章不落盘 |
| 页面视觉 | [ui-style.md](engineering/ui-style.md) | 系统分层参数摘要，不是 UX 规范全文 |

用户要求「同步官网」且抓到完整指导正文时，再覆盖或新增 `guide-*.md`。

## 按能力读（接口 / 查错）

不要通读 `js-apis`。不要把本表当写程序文件清单。

| 能力 | 先读 | 再按需 Grep |
|------|------|-------------|
| 选型 | [window-type-overview.md](guides/window-type-overview.md) | — |
| 画中画 | [misuse-pip.md](misuse/misuse-pip.md) + [guide-pip.md](guides/guide-pip.md) | `apis/js-apis-pipWindow.md` 对应节 |
| 闪控窗 | [misuse-float-view.md](misuse/misuse-float-view.md) + [guide-float-view.md](guides/guide-float-view.md) | `apis/js-apis-floatView.md` 对应节 |
| 闪控球 | [misuse-floating-ball.md](misuse/misuse-floating-ball.md) | `apis/js-apis-floatingBall.md` 对应节 |
| 绑定 | [guide-float-view.md](guides/guide-float-view.md)「球窗绑定」+ [misuse-float-view.md](misuse/misuse-float-view.md) | `apis/js-apis-floatView.md` bind/unbind |
| 防窥组合 | [guide-float-view.md](guides/guide-float-view.md) 组合节 + [guide-dlp-anti-peep.md](guides/guide-dlp-anti-peep.md) | — |
| 错误码 | 对上的码再 Grep [errorcode-window-float.md](permissions/errorcode-window-float.md) | 禁止整文件 Read |
| 权限 | [restricted-permissions-float.md](permissions/restricted-permissions-float.md) | 声明/ACL 两份按需 |
| 工程 / 语法 / 视觉 | [stage-layout.md](engineering/stage-layout.md)、[arkui-syntax.md](engineering/arkui-syntax.md)、[ui-style.md](engineering/ui-style.md) | — |
| 需求设计 | [requirement-review.md](requirement-review.md) | — |

## 落盘 ↔ 官网

| 本目录文件 | 用途 | 官网 |
|------------|------|------|
| [js-apis-pipWindow.md](apis/js-apis-pipWindow.md) | 画中画接口 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-pipwindow |
| [js-apis-floatView.md](apis/js-apis-floatView.md) | 闪控窗接口（含 bind/unbind） | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-floatview |
| [js-apis-floatingBall.md](apis/js-apis-floatingBall.md) | 闪控球接口 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-floatingball |
| [window-type-overview.md](guides/window-type-overview.md) | 窗口类型 / 球窗对比 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/window-type-overview |
| [guide-pip.md](guides/guide-pip.md) | 画中画开发步骤 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/window-pipwindow |
| [guide-float-view.md](guides/guide-float-view.md) | 闪控窗开发指导（含绑定、防窥组合） | https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/float-view-guide |
| [guide-dlp-anti-peep.md](guides/guide-dlp-anti-peep.md) | 防窥保护开发指导 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/devicesecurity-dlpantipeep |
| [errorcode-window-float.md](permissions/errorcode-window-float.md) | 窗口错误码 13000xx | 官网窗口错误码页对应章节 |
| [restricted-permissions-float.md](permissions/restricted-permissions-float.md) | FLOAT_VIEW / USE_FLOAT_BALL / DLP_GET_HIDE_STATUS 等 | 官网受限权限页对应条目 |
| [declare-permissions.md](permissions/declare-permissions.md) | module.json5 声明 | 官网「声明权限」 |
| [declare-permissions-in-acl.md](permissions/declare-permissions-in-acl.md) | ACL | 官网「申请受限权限」 |
| [stage-layout.md](engineering/stage-layout.md) | Stage 单模块工程树与落点 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/start-with-ets-stage |
| [arkui-syntax.md](engineering/arkui-syntax.md) | 基本语法 + 装饰器总表 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-basic-syntax-overview |
| [ui-style.md](engineering/ui-style.md) | 系统默认视觉 | OpenHarmony UX 视觉基础/色彩/按钮 |
| [requirement-review.md](requirement-review.md) | 给用户需求的评审稿模板 | 无官网 |

## 本仓实现对照（选读，非权威）

仅当**当前工作区是 WMS / window_window_manager 源码**、要查「框架是否拒绝 / 日志从哪打」时读。用户应用工程里不要打开这些路径。不要用它们覆盖官网签名。

| 用途 | 仓库路径 |
|------|----------|
| 闪控窗控制器 | `window_window_manager/wm/src/float_view_controller.cpp` |
| 绑定 | `window_window_manager/wm/src/float_window_manager.cpp` |
| 闪控球 | `window_window_manager/wm/src/floating_ball_controller.cpp` |
| 查错 YAML | `Watchman/modules/pip/module.yaml`、`float_view/module.yaml`、`floating_ball/module.yaml` |
