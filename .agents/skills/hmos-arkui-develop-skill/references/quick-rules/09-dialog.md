# 12. 对话框与半模态约束

## 规则

| 规则 | 说明 | 错误码 |
|------|------|--------|
| 多弹窗堆叠 | 多个弹窗按**后弹优先**原则堆叠，退出时从高到低 | — |
| 系统弹窗阻塞自定义弹窗 | 系统弹窗显示时，非系统弹窗显示接口被阻塞 | — |
| 不建议后台弹窗 | 应用不在前台时不建议调用弹窗显示接口 | — |
| bindSheet onWillDismiss | 声明后所有关闭操作必须通过 `dismiss()` 调用处理，否则无法关闭 | — |
| bindSheet UIExtension 限制 | Sheet 内嵌入 UIExtension 时，不支持在 UIExtension 内再启动额外的 sheet/dialog | — |
| bindSheet 悬停避让限制 | 悬停/中轴避让不支持子窗口模式（showInSubWindow 为 true 时） | — |
| CustomDialogController 不推荐 | API 12 起不推荐，用 `promptAction.openCustomDialog` | — |
| **AlertDialog 调用方式** | 通过 `this.getUIContext().showAlertDialog()` 或全局 `AlertDialog.show()`（全局可用，建议走 UIContext） | — |

### AlertDialog 按钮字段

```ts
// ❌ WRONG -- 用 text 字段 → 10505001
this.getUIContext().showAlertDialog({
  message: '确认？',
  buttons: [{ text: '取消', action: () => {} }]
})

// ✅ RIGHT -- 用 value + action
this.getUIContext().showAlertDialog({
  message: '确认？',
  buttons: [{ value: '取消', action: () => {} }, { value: '确认', action: () => {} }]
})
```

`AlertDialog` 最多 `primaryButton` + `secondaryButton` 两个按钮字段，**无 `tertiaryButton`**；要更多按钮用 `buttons` 数组。

### bindSheet

```ts
// ✅ RIGHT
.bindSheet($$this.isShow, this.sheetBuilder, {
  height: SheetSize.MEDIUM,   // SheetSize 只有 MEDIUM/LARGE，没有 HALF
  dragBar: true,
  showClose: true
})
```

`SheetSize` 只有 `MEDIUM`/`LARGE`，**没有 `HALF`**（`10505001`）。`$$` 双向绑定必填，否则 sheet 关不掉。用 `detents`/`height`，**没有 `sheetSize` 字段**。

### ActionSheet 用 `sheets`，不是 `buttons`

```ts
// ❌ WRONG
ActionSheet.show({ buttons: [{ title: 'x', action: () => {} }] })
// ✅ RIGHT
this.getUIContext().showActionSheet({ sheets: [{ title: 'x', action: () => {} }] })
```

### bindContextMenu 第二参数用枚举

`.bindContextMenu(this.menu, ResponseType.LongPress)`，不要传字符串 `'longpress'`。

## 常见错误对比

| ❌ 错误写法 | ✅ 正确写法 | 说明 |
|------------|-----------|------|
| `buttons: [{ text: '取消' }]` | `buttons: [{ value: '取消', action: () => {} }]` | AlertDialog 按钮用 value 非 text |
| `height: SheetSize.HALF` | `height: SheetSize.MEDIUM` | SheetSize 无 HALF，只有 MEDIUM/LARGE |
| `ActionSheet.show({ buttons: [...] })` | `showActionSheet({ sheets: [...] })` | ActionSheet 用 sheets |
| `CustomDialogController` | `promptAction.openCustomDialog` | 已废弃 |

## 参考

- 废弃接口替换见 [19-deprecated](14-deprecated.md)
- 导航与路由见 [11-navigation](08-navigation.md)