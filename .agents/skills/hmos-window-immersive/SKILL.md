---
name: hmos-window-immersive
description: 为鸿蒙（HarmonyOS/OpenHarmony）应用提供窗口沉浸式效果接入指引，覆盖 @ohos.window（ArkTS，Stage 模型）与 ArkUI 组件级属性。当任务涉及以下场景时使用：沉浸式状态栏/导航条隐藏与显示、安全区域避让（avoidArea 查询与监听）、扩展沉浸式（内容延伸到状态栏/导航条/挖孔区）、系统栏样式定制（颜色、透明度、内容色）、沉浸式状态切换（进入/退出/动态切换）、多设备适配（直板机/平板/折叠屏/自由窗口标题栏沉浸）。提供三种沉浸式方案对比选型、方案选型决策树、避让区类型映射表、核心接口速查表和实战场景代码。
license: MIT
metadata:
  version: "1.0.0"
  keywords:
    - 沉浸式
    - 全屏
    - 安全区避让
    - expandSafeArea
    - setWindowLayoutFullScreen
    - avoidArea
    - 状态栏隐藏
    - 自由窗口标题栏
---

# 窗口沉浸式效果接入技能（hmos-window-immersive）

本技能覆盖鸿蒙（HarmonyOS/OpenHarmony）应用窗口沉浸式效果的接入与适配，基于 Stage 模型 + ArkTS（`@ohos.window`）+ ArkUI 组件属性，**提供组件级与窗口级两套沉浸式方案**。

## 沉浸式效果概述

> **概念澄清**：沉浸式布局（`setWindowLayoutFullScreen`）≠ 隐藏状态栏和导航条。沉浸式布局是指**布局范围从安全区扩展到整个窗口（包括状态栏和导航条区域）**，但状态栏和导航条仍然可见，只是布局不再避让它们。隐藏系统栏是另一个独立操作（`setSpecificSystemBarEnabled`），两者可以配合使用但不是一回事。很多开发者误以为"沉浸式"就是状态栏和导航条都隐藏，实际上沉浸式布局下系统栏仍然显示，需要手动做避让处理。

典型应用全屏窗口的 UI 元素包括：顶部**状态栏**、应用界面、底部**导航区域**（导航条或三键导航）。状态栏和导航区域在沉浸式布局下称为**避让区**，避让区之外的区域称为**安全区**。

沉浸式效果通过将应用页面延伸至状态栏和导航区域，实现：
- **视觉统一**：应用页面与避让区色调统一，避免界面割裂
- **布局扩展**：充分利用屏幕可视区域
- **沉浸体验**：游戏、视频等场景隐藏系统元素，提供无干扰全屏体验

## 三种沉浸式方案（核心，优先阅读）

| 方案 | 层级 | 核心 API/属性 | 特点 |
| --- | --- | --- | --- |
| A. 组件页面沉浸 | 组件级 | `.ignoreLayoutSafeArea()` + `.height(LayoutPolicy.matchParent)` | 背景与内容均延伸，需手动避让 |
| B. 安全区域拓展 | 组件级 | `.expandSafeArea([SafeAreaType], [SafeAreaEdge])` | 指定延伸区域和方向，内容在安全区 |
| C. 窗口沉浸式显示 | 窗口级 | `setWindowLayoutFullScreen(true)` | 全局所有页面沉浸，需手动避让 |

方案对比与选型详见 [imm-01-immersive-strategies.md](references/imm-01-immersive-strategies.md)。

## 使用流程

1. 先读上方 **三种沉浸式方案** 要点，理解各方案差异；
2. 按下方 **任务路由表** 阅读对应场景文档后再编码；
3. 按下方 **方案选型决策树** 确定使用哪种方案；
4. 编码时遵循本文件末尾的 **约束与最佳实践**。

## 任务路由表

| 场景 ID | 任务/需求 | 参考文档 |
| --- | --- | --- |
| IMM-01 | 理解沉浸式原理、三种方案对比与选型 | [imm-01-immersive-strategies.md](references/imm-01-immersive-strategies.md) |
| IMM-02 | 组件级沉浸实现（expandSafeArea / ignoreLayoutSafeArea） | [imm-02-component-immersive.md](references/imm-02-component-immersive.md) |
| IMM-03 | 窗口级沉浸实现（setWindowLayoutFullScreen + 系统栏显隐 + 避让） | [imm-03-window-immersive.md](references/imm-03-window-immersive.md) |
| IMM-04 | 安全区域避让处理（avoidArea 查询/监听/挖孔避让/按需适配） | [imm-04-avoid-area-handling.md](references/imm-04-avoid-area-handling.md) |
| IMM-05 | 实战场景（背景图/视频/滚动容器/底部页签/自由窗口标题栏） | [imm-05-practical-cases.md](references/imm-05-practical-cases.md) |

## 方案选型决策树

```
需要沉浸式效果？
├─ 仅背景延伸，内容在安全区
│   └─ 上下颜色不同 → .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP/BOTTOM])
├─ 背景与内容均延伸到避让区
│   ├─ 仅单个页面 → .ignoreLayoutSafeArea() + .height(LayoutPolicy.matchParent) + 手动避让
│   └─ 所有页面全局 → setWindowLayoutFullScreen(true) + 手动避让
├─ 需要隐藏状态栏/导航条（游戏/视频全屏，无需 setWindowLayoutFullScreen）
│   └─ setSpecificSystemBarEnabled(name, false)
└─ 自由窗口标题栏沉浸（PC/平板自由多窗）
    └─ setWindowDecorVisible(false) + setWindowDecorHeight() + getTitleButtonRect() 避让

需要适配哪些避让区？（按需选择）
├─ 仅底部 → TYPE_NAVIGATION_INDICATOR（bottom）
├─ 顶部+底部 → TYPE_SYSTEM + TYPE_NAVIGATION_INDICATOR（top + bottom）
├─ 含挖孔屏 → 上述 + TYPE_CUTOUT（top + bottom + left + right，挖孔方位随旋转变化）
├─ 含三键导航 → 上述 + TYPE_FLOAT_NAVIGATION（需 setFloatNavigationAvoidAreaEnabled 前置）
└─ 全部 → 所有 5 种避让区，各方向独立提取后合并取较大值
```

## 30 秒上手

**方式一：隐藏系统栏（游戏/视频全屏，无需 setWindowLayoutFullScreen）**

```typescript
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

// onWindowStageCreate 中（loadContent 之后调用）
const mainWindow = windowStage.getMainWindowSync();
// 隐藏状态栏和导航条（无需调用 setWindowLayoutFullScreen）
mainWindow.setSpecificSystemBarEnabled('status', false);
mainWindow.setSpecificSystemBarEnabled('navigationIndicator', false);
```

**方式二：安全区域拓展（方案 B，上下不同色）**

```typescript
Column() {
  Row() { Text('Top').width('100%') }
    .backgroundColor('#2786d9')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])  // 顶部延伸至状态栏

  // 中间内容...

  Row() { Text('Bottom').width('100%') }
    .backgroundColor('#96dffa')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])  // 底部延伸至导航条
}
```

## 核心接口速查

| 接口/属性 | 说明 | API 版本 |
| --- | --- | --- |
| setWindowLayoutFullScreen(isLayoutFullScreen) | 设置沉浸式布局（布局是否避让系统栏，不改变窗口模式和大小，返回 Promise） | API 9+ |
| setImmersiveModeEnabledState(enabled) | 同步设置沉浸式布局（void 返回） | API 12+ |
| setWindowSystemBarEnable(names: Array<'status' \| 'navigation'>) | 批量设置系统栏显隐（'navigation' 实际无效） | API 9+ |
| setSpecificSystemBarEnabled(name, enable, enableAnimation?) | 精细设置单个系统栏显隐（'status'/'navigationIndicator'，第三参数控制动画，API 12+） | API 11+ |
| getWindowAvoidArea(type: AvoidAreaType) | 查询避让区域（返回 AvoidArea，同步，系统栏隐藏时返回 0） | API 9+ |
| getWindowAvoidAreaIgnoringVisibility(type) | 查询避让区域（忽略系统栏显隐状态，隐藏时仍可获取，不支持 TYPE_KEYBOARD） | API 22+ |
| on('avoidAreaChange') / off('avoidAreaChange') | 监听/注销避让区变化（回调类型 AvoidAreaOptions） | API 9+ |
| on('windowSizeChange') / off('windowSizeChange') | 监听/注销窗口尺寸变化（旋转、折叠开合时触发，可在回调中一次性查询全部避让区） | API 7+ |
| setFloatNavigationAvoidAreaEnabled(enabled) | 启用三键导航避让区查询（TYPE_FLOAT_NAVIGATION 前置条件，仅 Stage 模型） | API 26.0.0+ |
| setWindowSystemBarProperties(properties: SystemBarProperties) | 设置系统栏颜色/内容色（statusBarColor/statusBarContentColor/navigationBarColor/navigationBarContentColor） | API 9+ |
| isImmersiveLayout() | 查询当前窗口是否处于沉浸式布局（返回 boolean，同步） | API 20+ |
| .expandSafeArea(types, edges) | 组件安全区域拓展 | API 10+ |
| .ignoreLayoutSafeArea() | 组件布局突破安全区 | API 20+ |
| .safeAreaPadding | 组件级安全区域 padding | API 12+ |
| .clipContent(ContentClipMode.SAFE_AREA) | 滚动容器内容裁剪延伸至避让区 | API 12+ |
| setWindowDecorVisible(isVisible) | 设置自由窗口标题栏显隐（同步 void） | API 11+ |
| setWindowDecorHeight(height) | 设置标题栏高度（范围 [37, 112] vp，同步 void） | API 11+ |
| setDecorButtonStyle(dectorStyle) | 设置三键样式（注意参数名为 dectorStyle） | API 14+ |
| getTitleButtonRect() | 获取三键区位置和大小（返回 TitleButtonRect，同步） | API 11+ |
| on('windowTitleButtonRectChange') / off(...) | 监听/注销三键区变化（回调类型 TitleButtonRect） | API 11+ |

**避让区类型（AvoidAreaType）**：`TYPE_SYSTEM`（状态栏）/ `TYPE_NAVIGATION_INDICATOR`（底部导航区域，三键导航显示时始终存在，可通过 `setSpecificSystemBarEnabled('navigationIndicator', false)` 隐藏）/ `TYPE_CUTOUT`（挖孔）/ `TYPE_KEYBOARD`（键盘）/ `TYPE_FLOAT_NAVIGATION`（三键导航区域，需先调用 `setFloatNavigationAvoidAreaEnabled` 启用，API 26.0.0+，仅 Stage 模型）

**安全区域枚举**：SafeAreaType — `SYSTEM` / `CUTOUT` / `KEYBOARD`；SafeAreaEdge — `TOP` / `BOTTOM` / `LEFT` / `RIGHT` / `ALL`

## 约束与最佳实践（必须遵守）

1. **expandSafeArea 边界要求**：组件必须与安全区域边界重合（如顶部组件紧贴屏幕顶部）才生效。
2. **expandSafeArea 尺寸限制**：配置 expandSafeArea 的组件不能设固定宽高（百分比除外）。
3. **滚动容器限制**：父容器是滚动容器时，子组件 expandSafeArea 无效；需对父容器设 expandSafeArea 或 `clipContent(ContentClipMode.SAFE_AREA)`。
4. **Video 组件限制**：Video 组件 expandSafeArea 扩展后，视频显示内容区域不支持扩展（仅背景扩展）。
5. **避让区可能为 0**：
   - 系统栏被隐藏时，`getWindowAvoidArea()` 返回 0；需获取隐藏状态下的避让区时使用 `getWindowAvoidAreaIgnoringVisibility()`（API 22+）
   - 自由多窗模式下状态栏避让区为 0（分屏、智慧多窗悬浮窗不为 0）
   - 全局悬浮窗需先调用 `setSystemAvoidAreaEnabled(true)` 使能后才能获取避让区，否则为 0
6. **getWindowAvoidArea 仅用于初始值**：返回调用时刻的快照，不随状态变化自动更新。必须配合 `on('avoidAreaChange')` 动态监听，否则旋转/折叠/窗口模式切换后避让区变化不会反映到布局中。
7. **单位为 px**：avoidArea 返回值单位是 px，布局中使用需 `getUIContext().px2vp()` 转换。
8. **on/off 成对调用**：`on('avoidAreaChange')` 与 `off('avoidAreaChange')` 必须成对调用，避免内存泄漏。建议在 `onWindowStageCreate`（`loadContent` 回调后）注册、`onWindowStageDestroy` 中注销，避免在组件生命周期中操作（组件销毁时窗口可能也正在销毁，window 对象可能无效）。
9. **避让区变化触发场景**：窗口模式切换（全屏/悬浮/分屏）、旋转、折叠态切换、多设备流转时避让区会变化，需动态监听。但以下场景可能收不到回调：
   - 避让区数据未变化时不重复回调（变化前后避让区数据相同则不触发）
   - 某些场景被解注册了（如组件销毁时 off 被调用）
   - 自由多窗模式下窗口不随屏幕旋转，旋转时避让区不变，不触发回调
   - 折叠开合过程中窗口模式未变化时（如始终分屏），避让区可能不变，不触发回调
   - 全局悬浮窗、模态窗、系统窗口未调用 `setSystemAvoidAreaEnabled(true)` 使能，收不到回调
10. **Navigation/Tabs 内置延伸**：Navigation 和 Tabs 组件默认实现了页签延伸处理，只需底部边界与导航区域重合。
11. **自由窗口标题栏需单独适配**：组件沉浸策略不适用于自由窗口标题栏，需用 `setWindowDecorVisible` 等接口单独处理。
12. **错误处理**：接口多用 Promise，需捕获 `BusinessError`；常见错误码：401（参数错误）、801（设备能力不支持）、1300002（窗口状态异常）、1300003（窗口管理服务异常）、1300004（非法操作）。
13. **Stage 模型时序**：`setWindowDecorVisible`、`setWindowDecorHeight`、`setDecorButtonStyle`、`on('windowTitleButtonRectChange')` 必须在 `loadContent()` 或 `setUIContent()` 生效后调用。
14. **setWindowLayoutFullScreen 不生效场景**：
    - 仅对主窗口和应用子窗口生效，其余窗口调用不生效也不报错
    - HarmonyOS 5.0.2 ~ 5.1.1 之前：处于自由窗口状态的设备上不生效也不报错
    - HarmonyOS 5.1.1 起：PC/2in1 设备、其他设备的电脑模式下不生效也不报错
    - 返回成功不代表布局已变更完成
    - `setWindowSystemBarEnable`、`setSpecificSystemBarEnabled`、`setWindowSystemBarProperties` 在非全屏/最大化模式（自由悬浮窗、分屏等）下不生效，进入全屏后才生效；自由窗形态下亦无效果
15. **三键导航避让区前置条件**：查询/监听 `TYPE_FLOAT_NAVIGATION` 避让区前，必须先调用 `setFloatNavigationAvoidAreaEnabled(true)`（API 26.0.0+，仅 Stage 模型），否则返回空。底部导航与三键导航是两种不同系统导航模式，用户可在设置 > 系统 > 系统导航 > 更多设置切换；切换三键导航后导航条隐藏，但底部导航区域（TYPE_NAVIGATION_INDICATOR）仍然存在。
16. **导航条与三键多方向避让**：旋转后导航条始终在底部，但三键可能出现在左侧/右侧/顶部，两者可能同时存在于不同方向。必须独立提取各方向（top/bottom/left/right）避让值后合并取较大值，不能简单只处理 bottom。详见 imm-04-avoid-area-handling.md。
17. **旋转/折叠中间态问题**：`on('avoidAreaChange')` 每次只回调一种避让区类型，旋转/折叠时多种避让区同时变化会产生中间态。系统暂无一次性返回所有避让区变化的接口（7.1 版本将提供），以下为兜底方案：通过 `on('windowSizeChange')`（API 7+）监听窗口尺寸变化，在回调中一次性查询全部避让区类型合并更新（推荐）。详见 imm-04-avoid-area-handling.md。
