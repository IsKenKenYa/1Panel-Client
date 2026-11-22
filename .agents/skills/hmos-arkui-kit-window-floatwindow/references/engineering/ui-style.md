# 页面视觉（写程序必读）

权威：OpenHarmony UX《视觉基础》《色彩》《按钮》（分层参数 ID 见视觉基础表）。实现一律 `$r('sys.color.*')` / `$r('sys.float.*')`，深浅色自动切。本页是可执行摘要，不是 UX 规范全文。

**设计语言：系统默认视觉。** 主色蓝 `#007DFF`（`ohos_id_color_emphasize`），8vp 网格，`vp` 量尺寸、`fp` 量字号。不要 Material / iOS / 霓虹自造色。用户给了设计稿才偏离本页。

三类窗能改的 UI 不同：

| 能力 | 应用能画什么 |
|------|----------------|
| 画中画 | 只画**主窗宿主页**；小窗框和控制条是系统的 |
| 闪控球 | 只填 title/content/icon；**不能**自定义球 UI |
| 闪控窗 | **FloatPanel 整页**按本页画；主窗启动页同样 |

## Token（一律 `$r('sys.*')`，禁止写死色值）

| 用途 | 资源 |
|------|------|
| 页背景 | `$r('sys.color.ohos_id_color_background')` |
| 卡片/次按钮底 | `$r('sys.color.ohos_id_color_component_normal')` |
| 主色 / 强调按钮 | `$r('sys.color.ohos_id_color_emphasize')` |
| 主文案 | `$r('sys.color.ohos_id_color_text_primary')` |
| 次文案 | `$r('sys.color.ohos_id_color_text_secondary')` |
| 警告 | `$r('sys.color.ohos_id_color_warning')` |
| 卡片圆角 | `$r('sys.float.ohos_id_corner_radius_card')` |
| 标题 | `20fp` + `FontWeight.Medium` |
| 正文 | `16fp` |
| 辅助 | `14fp`，次文案色 |
| 页边距 | `16vp`（8 的倍数） |
| 区块间距 | `12vp` |
| 按钮高 | `40vp`；主按钮通栏；文案 2–4 个汉字、居中、不换行 |

## 主窗启动页（PiP / 球 / 点按钮开窗）

一个标题 + 一句说明 + **一个**强调按钮；次操作（停止）用灰底胶囊，不要两个都蓝。

**叠加 demo 的 Index 是能力列表**：强调按钮只留一个主入口（如「进入会议」）；启动/停止球窗、拉起蒙层用灰底次按钮。不要两个都蓝。

```ts
Column() {
  Text('画中画')
    .fontSize(20)
    .fontWeight(FontWeight.Medium)
    .fontColor($r('sys.color.ohos_id_color_text_primary'))
    .width('100%')
  Text('退出后以系统小窗继续播放')
    .fontSize(14)
    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
    .margin({ top: 8 })
    .width('100%')
  Blank()
  Button('启动')
    .type(ButtonType.Capsule)
    .height(40)
    .width('100%')
    .fontSize(16)
    .fontColor(Color.White)
    .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
    .onClick(() => { this.start(); })
  Button('停止')
    .type(ButtonType.Capsule)
    .height(40)
    .width('100%')
    .fontSize(16)
    .fontColor($r('sys.color.ohos_id_color_text_primary'))
    .backgroundColor($r('sys.color.ohos_id_color_component_normal'))
    .margin({ top: 8 })
    .onClick(() => { this.pip?.stopPiP(); })
}
.width('100%')
.height('100%')
.padding({ left: 16, right: 16, top: 24, bottom: 24 })
.backgroundColor($r('sys.color.ohos_id_color_background'))
```

有画面时：布局 `XComponent` 在上，按钮条贴底，间距仍 12vp。不要 `.clip(true)`（会裁掉 surface，一镜到底也没了）。不要先画一页只有按钮的启动页再把画面漏掉。组件写法跟 [pip-xcomponent.md](../../assets/pip-xcomponent.md)：`XComponent(this.options)`，高 `800px`。不要旧 `{ id, type, controller }`，不要 `height(200)` 当一镜到底样例。

## 闪控窗内容页（`pages/FloatPanel`）

小窗里不要再套大标题栏。留白 12vp；正文 16fp；可点控件避开 `avoidArea`。

```ts
Column() {
  Text('盯盘')
    .fontSize(16)
    .fontWeight(FontWeight.Medium)
    .fontColor($r('sys.color.ohos_id_color_text_primary'))
  Text('沪指 +0.8%')
    .fontSize(14)
    .fontColor($r('sys.color.ohos_id_color_text_secondary'))
    .margin({ top: 4 })
}
.width('100%')
.height('100%')
.padding(12)
.justifyContent(FlexAlign.Center)
.backgroundColor($r('sys.color.ohos_id_color_background'))
```

横条模板（`HORIZONTAL_BAR`）：改成 `Row` + 单行 14fp，左右 padding 12，不要 Column 堆两段标题。

## 禁止

- 根节点只有一个裸 `Button`，无边距、无背景
- `fontSize(50)`、随机 `#0D9FFB` / 渐变霓虹
- 单能力页主按钮超过一个；按钮文案英文长句（用「启动」「停止」）。叠加 Index 见上文
- 给闪控球 `setUIContext` 或自绘球
- 给 PiP 小窗套自定义框去「美化」系统控制条
