# 固定样式弹出框

固定布局格式，只需输入文本内容和按钮操作。不支持自定义内容区字体样式（颜色、大小、换行），需自定义样式请用 [openCustomDialog](arkts-open-custom-dialog.md)。

> **调用约束**：建议通过 UIContext 调用。showActionMenu/showDialog 需先 `getPromptAction()`；AlertDialog/ActionSheet/PickerDialog 通过 UIContext 直接调用。CalendarPickerDialog 依赖 UI 执行上下文，不可在异步中使用。
>
> **生命周期** (API 19+)：showDialog、ActionSheet、AlertDialog 支持以下生命周期回调：

| 回调 | 说明 |
|------|------|
| `onWillAppear` | 弹出框显示动效前 |
| `onDidAppear` | 弹出框弹出后 |
| `onWillDisappear` | 弹出框退出动效前 |
| `onDidDisappear` | 弹出框消失后 |

## 弹窗类型总览

| 弹窗 | 调用方式 | 返回值 | 适用场景 |
|------|---------|--------|---------|
| [AlertDialog](ts-methods-alert-dialog-box.md) | `uiContext.showAlertDialog()` | 按钮回调 | 二次确认、重要提示 |
| [ActionSheet](ts-methods-action-sheet.md) | `uiContext.showActionSheet()` | Sheet 回调 | 多操作选项列表 |
| showActionMenu | `promptAction.showActionMenu()` | Promise → 按钮索引 | 异步获取选中按钮 |
| showDialog | `promptAction.showDialog()` | 回调 → 按钮索引 | 异步返回选中结果 |
| [DatePickerDialog](ts-methods-datepicker-dialog.md) | `uiContext.showDatePickerDialog()` | onDateAccept 回调 | 日期选择 |
| [TimePickerDialog](ts-methods-timepicker-dialog.md) | `uiContext.showTimePickerDialog()` | onAccept 回调 | 时间选择 |
| [TextPickerDialog](ts-methods-textpicker-dialog.md) | `uiContext.showTextPickerDialog()` | onAccept 回调 | 文本/级联选择 |
| [CalendarPickerDialog](ts-methods-calendarpicker-dialog.md) | `CalendarPickerDialog.show()` | onAccept 回调 | 日历视图选择 |

> title 字段字体最大放大倍数为 2。showActionMenu、showDialog、ActionSheet、AlertDialog 可设 `isModal: false` 变为非模态。

## AlertDialog (警告弹窗)

```typescript
this.getUIContext().showAlertDialog({
  title: 'title',
  message: 'text',
  autoCancel: true,
  alignment: DialogAlignment.Center,
  offset: { dx: 0, dy: -20 },
  buttons: [
    { value: 'cancel', action: () => {} },
    {
      enabled: true,
      defaultFocus: true,
      style: DialogButtonStyle.HIGHLIGHT,
      value: 'ok',
      action: () => {}
    }
  ]
})
```

### AlertDialog ButtonOptions

| 属性 | 类型 | 说明 |
|------|------|------|
| `value` | string | 按钮文本 |
| `action` | () => void | 点击回调 |
| `enabled` | boolean | 是否可点击 |
| `defaultFocus` | boolean | 是否默认聚焦 |
| `style` | DialogButtonStyle | 按钮样式（DEFAULT / HIGHLIGHT） |

更多参数详见 [AlertDialog API参考](ts-methods-alert-dialog-box.md)。

## ActionSheet (列表选择弹窗)

```typescript
this.getUIContext().showActionSheet({
  title: 'ActionSheet title',
  message: 'message',
  autoCancel: false,
  confirm: { value: 'Confirm', action: () => {} },
  alignment: DialogAlignment.Center,
  sheets: [
    { title: 'option1', action: () => {} },
    { title: 'option2', action: () => {} },
    { title: 'option3', action: () => {} }
  ]
})
```

### ActionSheet 样式属性

| 属性 | 说明 |
|------|------|
| `width` / `height` | 弹窗尺寸 |
| `cornerRadius` | 圆角 |
| `borderWidth` / `borderStyle` / `borderColor` | 边框 |
| `backgroundColor` | 背景色 |
| `transition` | TransitionEffect 过渡动画 |

更多参数详见 [ActionSheet API参考](ts-methods-action-sheet.md)。

## showActionMenu (操作菜单)

```typescript
const promptAction = this.getUIContext().getPromptAction()
promptAction.showActionMenu({
  title: 'Menu Title',
  buttons: [
    { text: 'item1', color: '#666666' },
    { text: 'item2', color: '#000000' }
  ]
}).then(data => {
  // data.index 为选中按钮索引
})
```

## showDialog (对话框)

```typescript
const promptAction = this.getUIContext().getPromptAction()
promptAction.showDialog({
  title: 'Dialog Title',
  message: 'Message',
  buttons: [
    { text: 'button1', color: '#000000' },
    { text: 'button2', color: '#000000' }
  ]
}, (err, data) => {
  // data.index 为选中按钮索引
})
```

## DatePickerDialog (日期选择器)

```typescript
this.getUIContext().showDatePickerDialog({
  start: new Date('2000-1-1'),
  end: new Date('2100-12-31'),
  selected: this.selectTime,
  lunarSwitch: true,  // 显示农历开关
  showTime: true,     // 显示时间
  onDateAccept: (value: Date) => {
    this.selectTime = value  // 记住选择，下次弹出显示
  }
})
```

### DatePickerDialog 自定义样式属性

| 属性 | 说明 |
|------|------|
| `textStyle` | 未选中文本样式 { color, font: { size, weight } } |
| `selectedTextStyle` | 选中文本样式 |
| `disappearTextStyle` | 消失文本样式 |
| `acceptButtonStyle` | 确认按钮样式 { fontColor, fontSize, backgroundColor, borderRadius } |
| `cancelButtonStyle` | 取消按钮样式 |

更多参数详见 [DatePickerDialog API参考](ts-methods-datepicker-dialog.md)。

## TimePickerDialog (时间选择器)

```typescript
this.getUIContext().showTimePickerDialog({
  selected: this.selectTime,
  onAccept: (value: Date) => {
    this.selectTime = value
  }
})
```

> 自定义样式属性同 DatePickerDialog（textStyle、selectedTextStyle、acceptButtonStyle 等）。更多参数详见 [TimePickerDialog API参考](ts-methods-timepicker-dialog.md)。

## TextPickerDialog (文本选择器)

支持单列和多列（级联）选择：

```typescript
// 单列
this.getUIContext().showTextPickerDialog({
  range: ['option1', 'option2', 'option3'],
  selected: 0,
  onAccept: (value: TextPickerResult) => {
    // value.value: 选中文本, value.index: 索引
  }
})

// 级联多列 (TextCascadePickerRangeContent[])
const data: TextCascadePickerRangeContent[] = [
  {
    text: '辽宁省',
    children: [
      { text: '沈阳市', children: [{ text: '沈河区' }, { text: '和平区' }] },
      { text: '大连市', children: [{ text: '中山区' }, { text: '金州区' }] }
    ]
  }
]
this.getUIContext().showTextPickerDialog({
  range: data,
  selected: 0,
  onAccept: (value: TextPickerResult) => {
    // value.index 为数组（多列各列索引）
  }
})
```

更多参数详见 [TextPickerDialog API参考](ts-methods-textpicker-dialog.md)。

## CalendarPickerDialog (日历选择器)

```typescript
CalendarPickerDialog.show({
  selected: this.selectedDate,
  onAccept: (date: Date) => {
    this.selectedDate = date
  }
})
```

> CalendarPickerDialog 不通过 UIContext 调用，直接用 `CalendarPickerDialog.show()`。支持 `acceptButtonStyle` / `cancelButtonStyle` 自定义按钮样式。更多参数详见 [CalendarPickerDialog API参考](ts-methods-calendarpicker-dialog.md)。


