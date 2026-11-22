# 不依赖UI组件的全局自定义弹出框 (openCustomDialog)

通过 `UIContext.getPromptAction().openCustomDialog()` 创建自定义弹出框。相比 [CustomDialogController](arkts-common-components-custom-dialog.md) 优势：页面解耦，支持动态刷新内容。

> **注意**：
> - ComponentContent 不支持 @Reusable、@Link、@Provide、@Consume 等状态同步装饰器。需通过 `update()` 方法手动更新内容。
> - 关闭弹窗后务必调用 `contentNode.dispose()` 释放 ComponentContent 资源。

## 两种入参方式

| 方式 | 特点 | 适用场景 |
|------|------|---------|
| ComponentContent | 与 UI 解耦，灵活封装，`customStyle` 默认 true（内容样式完全按 contentNode 自定义显示） | 需要封装复用、动态更新 |
| Builder | 与上下文绑定，有默认弹窗样式 | 需要与系统弹窗风格一致 |

本文档以 ComponentContent 方式为主。

## 模态与非模态

| `isModal` | 行为 |
|-----------|------|
| `true`（默认） | 模态弹窗，蒙层区**不支持点击和手势等向下透传** |
| `false` | 非模态弹窗，蒙层区可以透传，可与周围组件交互 |

## 生命周期

按触发顺序：`onWillAppear` → `onDidAppear` → `onWillDisappear` → `onDidDisappear`

| 回调 | 说明 |
|------|------|
| `onWillAppear` | 显示动效前 |
| `onDidAppear` | 弹出后 |
| `onWillDisappear` | 退出动效前 |
| `onDidDisappear` | 消失后 |

## 基本用法：创建、打开、关闭

```typescript
// 1. 定义参数类
class Params {
  text: string = ''
  constructor(text: string) { this.text = text }
}

// 2. 定义自定义组件
@Builder
function buildText(params: Params) {
  Column() {
    Text(params.text)
    Button('Close')
      .onClick(() => {
        // 关闭弹窗（需持有 ctx 和 contentNode 引用）
        ctx.getPromptAction().closeCustomDialog(contentNode)
      })
  }
}

// 3. 创建 ComponentContent 并打开
const ctx: UIContext = this.getUIContext()
const contentNode = new ComponentContent(ctx, wrapBuilder(buildText), new Params('hello'))

ctx.getPromptAction().openCustomDialog(contentNode, {
  alignment: DialogAlignment.Center
})

// 4. 关闭后释放资源
ctx.getPromptAction().closeCustomDialog(contentNode)
contentNode.dispose() // 释放 ComponentContent
```

## 更新弹窗内容 (ComponentContent.update)

弹出后动态更新组件内容（不重建弹窗）：

```typescript
contentNode.update(new Params('updated text'))
```

## 更新弹窗属性 (updateCustomDialog)

动态更新弹出框属性。**仅支持以下 4 个属性**：`alignment`、`offset`、`autoCancel`、`maskColor`。

```typescript
ctx.getPromptAction().updateCustomDialog(contentNode, {
  alignment: DialogAlignment.Bottom,
  offset: { dx: 0, dy: -50 },
  autoCancel: true,
  maskColor: '#80000000'
})
```

> **注意**：更新属性时，未设置的属性会恢复为默认值，不会保留上次设置的值。例如初始设置 `{ alignment: Top, offset: { dx: 0, dy: 50 } }`，更新时设置 `{ alignment: Bottom }`，则 offset 会恢复为默认值而非保留 `{ dx: 0, dy: 50 }`。

## 自定义动画 (dialogTransition / maskTransition)

从 API 19 起，可分别为弹窗内容和蒙层设置不同的过渡动画：

```typescript
ctx.getPromptAction().openCustomDialog(contentNode, {
  isModal: true,
  dialogTransition: TransitionEffect.translate({ y: 300 })
    .animation({ duration: 400, curve: Curve.Smooth }),
  maskTransition: TransitionEffect.opacity(0)
    .animation({ duration: 400, curve: Curve.Smooth })
})
```

> `maskTransition` 仅在 `isModal: true` 时生效。更多关于蒙层动画的内容请参考[弹出框蒙层控制](arkts-dialog-mask-control.md)。

## 软键盘避让

| 属性 | 说明 |
|------|------|
| `keyboardAvoidMode` | 设为 `KeyboardAvoidMode.DEFAULT` 启用避让 |
| `keyboardAvoidDistance` | 与软键盘的间距（默认 16vp） |

```typescript
ctx.getPromptAction().openCustomDialog(contentNode, {
  alignment: DialogAlignment.Bottom,
  keyboardAvoidMode: KeyboardAvoidMode.DEFAULT,
  keyboardAvoidDistance: LengthMetrics.vp(0) // 贴紧键盘
})
```

## BaseDialogOptions 常用属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `alignment` | DialogAlignment | 对齐方式（默认 Center） |
| `offset` | { dx, dy } | 基于对齐方式的偏移 |
| `autoCancel` | boolean | 点击蒙层是否自动关闭（默认 true） |
| `maskColor` | ResourceColor | 蒙层颜色 |
| `maskRect` | { x, y, width, height } | 蒙层区域 |
| `isModal` | boolean | 是否模态（默认 true） |
| `showInSubWindow` | boolean | 是否在子窗口显示 |
| `dialogTransition` | TransitionEffect | 内容过渡动画 (API 19+) |
| `maskTransition` | TransitionEffect | 蒙层过渡动画 (API 19+) |
| `keyboardAvoidMode` | KeyboardAvoidMode | 软键盘避让模式 |
| `keyboardAvoidDistance` | LengthMetrics | 软键盘间距 |
| `onDidAppear` | () => void | 弹出后回调 |
| `onDidDisappear` | () => void | 消失后回调 |
| `onWillAppear` | () => void | 显示动效前回调 |
| `onWillDisappear` | () => void | 退出动效前回调 |


