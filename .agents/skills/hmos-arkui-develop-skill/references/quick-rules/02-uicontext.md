# 2. UIContext — 全局接口必须通过 `getUIContext()`

## 规则

Stage 模型下一个 ArkTS 引擎可运行多个 ArkUI 实例，全局接口通过分析调用链中的上下文信息确定当前 UI 上下文，异步接口和非 UI 接口可能导致 UI 上下文跟踪失败。**禁止直接使用全局接口，必须通过 `UIContext` 获取替代接口。**

获取方式：组件内 `this.getUIContext()`；窗口侧 `windowClass.getUIContext()`。

## 全局接口 → UIContext 替换表（高频）

| ❌ 禁止的全局接口 | ✅ UIContext 替代 | 说明 |
|---|---|---|
| `AlertDialog.show` | `uiContext.showAlertDialog()` | |
| `ActionSheet.show` | `uiContext.showActionSheet()` | |
| `router.*` | `uiContext.getRouter().*` | |
| `promptAction.*` | `uiContext.getPromptAction().*` | |
| `vp2px/px2vp/fp2px/px2fp` | `uiContext.vp2px()` 等（直接方法） | |
| `animateTo` | `uiContext.animateTo()` | |
| `@ohos.mediaquery` | `uiContext.getMediaQuery()` | |
| `@ohos.font` | `uiContext.getFont()` | |
| `@ohos.measure` | `uiContext.getMeasureUtil()` | 文本计算 |
| `@ohos.animator` | `uiContext.createAnimator()` | |
| `@ohos.arkui.observer` | `uiContext.getUIObserver()` | 无感监听 |
| `@ohos.arkui.dragController` | `uiContext.getDragController()` | |
| `@ohos.arkui.componentSnapshot` | `uiContext.getComponentSnapshot()` | 组件截图 |
| `@ohos.arkui.componentUtils` | `uiContext.getComponentUtils()` | |
| `@ohos.arkui.inspector` | `uiContext.getUIInspector()` | 组件布局回调 |
| `focusControl` | `uiContext.getFocusController()` | |
| `cursorControl` | `uiContext.getCursorControl()` | |
| `getContext` | `uiContext.getHostContext()` | 获取当前 Ability 的 Context |
| `LocalStorage.getShared` | `uiContext.getSharedLocalStorage()` | |
| `CalendarPickerDialog.show` | `uiContext.runScopedTask(() => CalendarPickerDialog.show(...))` | 无直接替代，需 runScopedTask 包裹 |
| `DatePickerDialog` | `uiContext.showDatePickerDialog()` | |
| `TimePickerDialog` | `uiContext.showTimePickerDialog()` | |
| `TextPickerDialog` | `uiContext.showTextPickerDialog()` | |
| `ContextMenu` | `uiContext.getContextMenuController()` | |
| `lpx2px` / `px2lpx` | `uiContext.lpx2px()` 等（直接方法） | |
| `keyframeAnimateTo` | `uiContext.keyframeAnimateTo(param, keyframes)` | **存在**，但**不支持** springMotion/responsiveSpringMotion/interpolatingSpring |
| `animateToImmediately` | **无替换，禁止使用** | |

## 常见错误对比

| ❌ 错误写法 | ✅ 正确写法 |
|------------|-----------|
| `AlertDialog.show({ message: 'x' })` | `this.getUIContext().showAlertDialog({ message: 'x' })` |
| `router.pushUrl({ url: 'pages/Second' })` | `this.getUIContext().getRouter().pushUrl({ url: 'pages/Second' })` |
| `promptAction.showToast({ message: 'hi' })` | `this.getUIContext().getPromptAction().showToast({ message: 'hi' })` |
| `let px = vp2px(20)` | `let px = this.getUIContext().vp2px(20)` |
| `animateTo({ duration: 300 }, () => {})` | `this.getUIContext().animateTo({ duration: 300 }, () => {})` |

**根因**：AI 训练数据中直接调用全局接口的示例很多，且语法上不报错但在多实例场景会出问题。

## 参考

- 动画顺序与限制见 [05-state-v1](05-state.md) @Builder 部分和 [13-style](10-style.md) 动画约束
- 废弃接口替换见 [19-deprecated](14-deprecated.md)