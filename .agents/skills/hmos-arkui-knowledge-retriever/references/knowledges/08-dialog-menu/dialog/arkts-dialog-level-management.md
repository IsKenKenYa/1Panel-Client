# 弹出框层级管理 (levelOrder)

从 API version 18 开始，通过 `levelOrder` 参数管理弹出框显示顺序，确保层级较高的弹窗覆盖在层级较低的弹窗之上。

## 挂载规则

- 弹出框节点直接挂载在根节点上，按层级从小到大依次挂载
- 同一层级的弹窗按创建先后顺序排列
- 新创建的弹窗根据层级大小插入对应位置

## 使用约束

| 约束项 | 说明 |
|--------|------|
| 支持的弹窗类型 | [openCustomDialog](arkts-open-custom-dialog.md)、[CustomDialog](arkts-common-components-custom-dialog.md)、[AlertDialog](ts-methods-alert-dialog-box.md)、[ActionSheet](ts-methods-action-sheet.md)、showDialog |
| 子窗口不支持 | `showInSubWindow: true` 时 `levelOrder` 无效 |
| 不支持动态刷新 | 弹窗打开后不能更新层级顺序 |

## 设置弹窗层级 (levelOrder)

`levelOrder` 为 `LevelOrder` 类型，需通过 `LevelOrder.clamp()` 创建，数值越大层级越高，越靠近用户：

```typescript
import { LevelOrder } from '@kit.ArkUI';

// 低层级弹窗（被覆盖）— 通过 openCustomDialogWithController 绑定控制器
const controller: promptAction.CommonController = new promptAction.DialogController()
this.getUIContext().getPromptAction().openCustomDialogWithController(contentNode, controller, {
  levelOrder: LevelOrder.clamp(0),
  // ...
})

// 高层级弹窗（覆盖在上）— 通过 openCustomDialogWithController 绑定控制器
const controller2: promptAction.CommonController = new promptAction.DialogController()
this.getUIContext().getPromptAction().openCustomDialogWithController(contentNode2, controller2, {
  levelOrder: LevelOrder.clamp(100000),
  // ...
})
```

> 绑定控制器的方式请参考[弹出框控制器](arkts-dialog-controller.md)。

## 查询当前层级 (getTopOrder / getBottomOrder)

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `promptAction.getTopOrder()` | LevelOrder | 获取当前最高层级 |
| `promptAction.getBottomOrder()` | LevelOrder | 获取当前最低层级 |

```typescript
import { LevelOrder } from '@kit.ArkUI';

const promptAction = this.getUIContext().getPromptAction()
const topOrder: LevelOrder = promptAction.getTopOrder()     // 当前最高层级
const bottomOrder: LevelOrder = promptAction.getBottomOrder() // 当前最低层级
```

## 各弹窗类型设置 levelOrder 示例

```typescript
import { LevelOrder } from '@kit.ArkUI';

// AlertDialog
this.getUIContext().showAlertDialog({
  levelOrder: LevelOrder.clamp(10),
  title: 'title',
  message: 'message',
  buttons: [{ value: 'ok', action: () => {} }]
})

// ActionSheet
this.getUIContext().showActionSheet({
  levelOrder: LevelOrder.clamp(20),
  title: 'title',
  sheets: [{ title: 'option1', action: () => {} }]
})

// showDialog
this.getUIContext().getPromptAction().showDialog({
  levelOrder: LevelOrder.clamp(30),
  title: 'title',
  message: 'message',
  buttons: [{ text: 'ok', color: '#000' }]
})
```


