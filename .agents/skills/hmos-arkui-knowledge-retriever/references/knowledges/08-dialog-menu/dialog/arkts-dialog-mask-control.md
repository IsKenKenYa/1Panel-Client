# 弹出框蒙层控制

控制弹出框蒙层的显隐、区域、颜色和动画等特性。

## 各弹窗类型蒙层能力矩阵

### 基础蒙层能力

| 弹窗类型 | autoCancel | maskRect | isModal | immersiveMode |
|---------|-----------|----------|---------|---------------|
| [openCustomDialog](arkts-open-custom-dialog.md) | ✓ | ✓ | ✓ | ✓ |
| openCustomDialogWithController | ✓ | ✓ | ✓ | ✓ |
| presentCustomDialog | ✓ | ✓ | ✓ | ✓ |
| updateCustomDialog | ✓ | ✗ | ✗ | ✗ |
| [CustomDialog](arkts-common-components-custom-dialog.md) | ✓ | ✓ | ✓ | ✓ |
| showDialog | ✗ | ✓ | ✓ | ✓ |
| [showAlertDialog](ts-methods-alert-dialog-box.md) | ✓ | ✓ | ✓ | ✓ |
| [showActionSheet](ts-methods-action-sheet.md) | ✓ | ✓ | ✓ | — |
| showActionMenu | ✗ | ✗ | ✓ | ✓ |
| [DatePickerDialog](ts-methods-datepicker-dialog.md) | ✗ | ✓ | ✗ | ✗ |
| [CalendarPickerDialog](ts-methods-calendarpicker-dialog.md) | ✗ | ✗ | ✗ | ✗ |
| [TimePickerDialog](ts-methods-timepicker-dialog.md) | ✗ | ✓ | ✗ | ✗ |
| [TextPickerDialog](ts-methods-textpicker-dialog.md) | ✗ | ✓ | ✗ | ✗ |

> - 设置 `autoCancel` 参数，可控制弹出框蒙层被点击时是否消失。
> - 设置 `maskRect` 参数，可定制弹出框蒙层的大小和位置。此外，蒙层范围内的事件无法透传，而蒙层范围外的事件可以透传。
> - 设置 `isModal` 参数，可定制弹出框的模态状态：非模态弹出框无蒙层，支持与周围组件交互；模态弹出框有蒙层，禁止与周围组件交互。
> - 从 API version 15 开始，当 `levelMode` 属性设置为 `LevelMode.EMBEDDED` 时，设置 `immersiveMode` 参数，可定制弹出框蒙层是否延伸至状态栏及导航栏。详见[页面级弹出框](arkts-embedded-dialog.md)。

### 蒙层样式/动画能力

| 弹窗类型 | maskColor | transition | maskTransition |
|---------|----------|-----------|---------------|
| [openCustomDialog](arkts-open-custom-dialog.md) | ✓ | ✓ | ✓ (API 19+) |
| openCustomDialogWithController | ✓ | ✓ | ✓ (API 19+) |
| presentCustomDialog | ✓ | ✓ | ✓ (API 19+) |
| updateCustomDialog | ✓ | ✗ | ✗ |
| [CustomDialog](arkts-common-components-custom-dialog.md) | ✓ | ✗ (用 open/closeAnimation 替代) | ✗ |
| [showAlertDialog](ts-methods-alert-dialog-box.md) | ✗ | ✓ | ✗ |
| [showActionSheet](ts-methods-action-sheet.md) | ✗ | ✓ | ✗ |
| showDialog | ✗ | ✗ | ✗ |
| showActionMenu | ✗ | ✗ | ✗ |
| [DatePickerDialog](ts-methods-datepicker-dialog.md) | ✗ | ✗ | ✗ |
| [CalendarPickerDialog](ts-methods-calendarpicker-dialog.md) | ✗ | ✗ | ✗ |
| [TimePickerDialog](ts-methods-timepicker-dialog.md) | ✗ | ✗ | ✗ |
| [TextPickerDialog](ts-methods-textpicker-dialog.md) | ✗ | ✗ | ✗ |

> - 设置 `maskColor` 参数，可定制弹出框蒙层的颜色。
> - 设置 `transition` 参数，可定制弹出框的进入和退出动画，**同时影响蒙层动画**。
> - CustomDialog 不支持 `transition`，但可通过 `openAnimation` / `closeAnimation` 替代，同样同时影响蒙层动画。该接口仅支持简单的动画设置，不支持复杂动画定制。
> - 从 API version 19 开始，设置 `maskTransition` 参数，可独立定制弹出框的蒙层动画（不影响内容动画）。

## 蒙层显隐控制

### autoCancel — 点击蒙层是否关闭

```typescript
this.getUIContext().getPromptAction().openCustomDialog({
  builder: () => { this.myBuilder() },
  autoCancel: false  // 点击蒙层不关闭
})
```

### isModal — 模态与非模态

| `isModal` | 行为 |
|-----------|------|
| `true`（默认） | 模态弹窗，有蒙层，不可与周围组件交互 |
| `false` | 非模态弹窗，无蒙层，可与周围组件交互 |

```typescript
this.getUIContext().getPromptAction().openCustomDialog({
  builder: () => { this.myBuilder() },
  isModal: false  // 非模态，蒙层区域可透传
})
```

## 蒙层样式控制

### maskRect — 蒙层区域

蒙层范围内事件不可透传，范围外可透传：

```typescript
this.getUIContext().getPromptAction().openCustomDialog({
  builder: () => { this.myBuilder() },
  maskRect: { x: 0, y: 10, width: '100%', height: '90%' }
})
```

### maskColor — 蒙层颜色

```typescript
this.getUIContext().getPromptAction().openCustomDialog({
  builder: () => { this.myBuilder() },
  maskColor: '#33AA0000'  // 半透明红色
})
```

### immersiveMode — 蒙层延伸至状态栏/导航栏

从 API 15 开始，`levelMode: LevelMode.EMBEDDED` 下可设置：

| `immersiveMode` | 说明 |
|-----------------|------|
| `ImmersiveMode.DEFAULT` | 蒙层不延伸至状态栏/导航栏 |
| `ImmersiveMode.EXTEND` | 蒙层延伸至状态栏/导航栏 |

```typescript
this.getUIContext().getPromptAction().openCustomDialog({
  builder: () => { this.myBuilder() },
  levelMode: LevelMode.EMBEDDED,
  immersiveMode: ImmersiveMode.EXTEND
})
```

## 蒙层动画控制

### transition — 内容 + 蒙层整体动画

```typescript
this.getUIContext().getPromptAction().openCustomDialog({
  builder: () => { this.myBuilder() },
  transition: TransitionEffect.OPACITY.animation({ duration: 300 })
})
```

### maskTransition — 仅蒙层动画 (API 19+)

可独立于内容动画单独设置蒙层过渡：

```typescript
this.getUIContext().getPromptAction().openCustomDialog({
  builder: () => { this.myBuilder() },
  maskTransition: TransitionEffect.OPACITY
    .animation({ duration: 2000 })
    .combine(TransitionEffect.rotate({ z: 1, angle: 180 }))
})
```

### CustomDialog 的动画 (openAnimation / closeAnimation)

CustomDialog 不支持 `transition`，使用 `openAnimation` / `closeAnimation` 替代：

```typescript
const controller = new CustomDialogController({
  builder: MyDialogBuilder(),
  openAnimation: { duration: 2000 },
  closeAnimation: { duration: 2000 }
})
controller.open()
```

更多 CustomDialog 动画内容请参考[基础自定义弹出框 (CustomDialog)](arkts-common-components-custom-dialog.md)。


