# 弹出框焦点策略 (focusable)

从 API version 19 开始，通过 `focusable` 参数控制弹出框是否获取焦点。

| `focusable` | 行为 |
|-------------|------|
| `true`（默认） | 弹出框获取焦点，中断用户当前操作（如关闭软键盘） |
| `false` | 弹出框不获取焦点，不中断用户操作（软键盘保持打开、焦点保留在输入框） |

> **使用约束**：仅 [openCustomDialog](arkts-open-custom-dialog.md) 和 [CustomDialog](arkts-common-components-custom-dialog.md) 支持 focusable 参数。只有覆盖在当前窗口之上的弹出框才可以获取焦点。

## 示例：输入时不中断焦点

```typescript
TextInput()
  .onChange(() => {
    // 弹出时不关闭软键盘，焦点保留在 TextInput
    this.getUIContext().getPromptAction().openCustomDialog({
      builder: () => {
        this.customDialogComponent()
      },
      focusable: false  // 关键：不获取焦点
    }).then((dialogId: number) => {
      setTimeout(() => {
        this.getUIContext().getPromptAction().closeCustomDialog(dialogId)
      }, 3000)
    })
  })
```

## 典型场景

| 场景 | focusable 设置 | 说明 |
|------|---------------|------|
| 用户输入时弹出提示 | `false` | 不打断输入，软键盘保持打开 |
| 确认对话框 | `true`（默认） | 需要用户立即关注并操作 |
| 后台通知类弹窗 | `false` | 不中断用户当前操作 |


