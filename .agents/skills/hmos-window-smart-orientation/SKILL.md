---
name: hmos-window-smart-orientation
description: 为鸿蒙（HarmonyOS/OpenHarmony）应用提供窗口旋转策略接入与智感旋转适配指引，覆盖 @ohos.window（ArkTS，Stage 模型）。当任务涉及以下场景时使用：智感旋转接入与机制说明、旋转策略选择（AUTO_ROTATION、USER_ROTATION、FOLLOW_DESKTOP、UNSPECIFIED 等 18 种 Orientation 枚举）、setPreferredOrientation 运行时设置、module.json5 orientation 静态配置、视频类横竖屏切换、直板机/平板/折叠屏多设备方向适配、旋转锁定、rotationChange 旋转监听、convertOrientationAndRotation 屏幕方向与窗口方向互转、扫描项目并将固定方向策略改造为支持智感旋转的策略。提供智感旋转机制说明、两种设置方式对比、18 种策略映射表、策略选型决策树和「扫描→评估→改造→验证」迁移流程。
license: MIT
metadata:
  version: "1.0.0"
  keywords:
    - 智感旋转
    - 旋转策略
    - 横竖屏切换
    - orientation
    - setPreferredOrientation
    - module.json5
    - rotationChange
    - convertOrientationAndRotation
---

# 窗口旋转策略接入技能（hmos-window-smart-orientation）

本技能覆盖鸿蒙（HarmonyOS/OpenHarmony）应用窗口旋转策略的接入与适配，基于 Stage 模型 + ArkTS（`@ohos.window`），**核心突出智感旋转能力**。

## 智感旋转（核心能力，优先阅读）

智感旋转是系统级方向感知增强能力：搭载 **OpenHarmony 7.0.0 及以上版本** 且支持**智感传感器**的设备，用户通过 **设置 > 系统 > 智感旋转** 开启开关后，应用最终显示方向由**重力传感器和智感传感器共同作用**决定，方向跟随更精准自然。

**应用侧接入要点（零新增 API，一套代码全设备覆盖）：**

1. 无需调用任何新接口。应用只要设置**自动旋转类策略**（`AUTO_ROTATION` 系列 7 种 / `USER_ROTATION` 系列 4 种）、**`FOLLOW_DESKTOP`**（跟随桌面）或**未显式设置的默认 `UNSPECIFIED`**（系统判定），在支持智感旋转的设备上即自动获得智感旋转体验；在不支持的设备上自动回退为纯重力传感器旋转。
2. 使用**固定方向策略**（`PORTRAIT`/`LANDSCAPE` 等）的应用不参与智感旋转，如需体验智感能力必须改用自动旋转类策略（存量项目的扫描与改造流程见 [migrate-to-smart-rotation.md](references/migrate-to-smart-rotation.md)）。
3. 交互规则：系统旋转锁定开关打开时，`*_RESTRICTED` 类策略既不跟随重力传感器，也**不跟随智感传感器**；非 RESTRICTED 的 `AUTO_ROTATION` 系列不受旋转锁定开关控制。
4. 智感旋转与普通旋转共用同一套生效条件：仅主窗口、前台全屏生效，分屏/智慧多窗悬浮窗/自由多窗/后台场景被系统忽略，无传感器设备（TV 等）不生效。

详见 [smart-rotation.md](references/smart-rotation.md)。

## 使用流程

1. 先读上方 **智感旋转** 要点，理解方向判定机制；
2. 按下方 **任务路由表** 阅读对应场景文档后再编码；
3. 用户要求**改造/迁移存量项目**（如"把固定横竖屏改成智感旋转"）时，按 [migrate-to-smart-rotation.md](references/migrate-to-smart-rotation.md) 的流程执行：**扫描项目 → 评估 → 按映射表改造 → 验证**，并输出扫描清单报告；
4. 编码时遵循本文件末尾的 **约束与最佳实践**。

## 任务路由表

| 场景 ID | 任务 / 需求 | 参考文档 |
| --- | --- | --- |
| ROT-01 | 理解智感旋转机制、生效条件、与各策略类型/旋转锁定的关系 | [smart-rotation.md](references/smart-rotation.md) |
| ROT-02 | 选择旋转策略（18 种 Orientation 枚举、直板机/平板差异、场景选型） | [orientation-strategies.md](references/orientation-strategies.md) |
| ROT-03 | 编码：两种设置方式（module.json5 静态配置 / 运行时 API）、查询/监听旋转、方向互转 | [rotation-api.md](references/rotation-api.md) |
| ROT-04 | 实战：多设备差异化适配（断点机制）、视频类横竖屏切换、锁定当前方向 | [rotation-practical-cases.md](references/rotation-practical-cases.md) |
| ROT-05 | **扫描当前项目**、将固定旋转策略（PORTRAIT/LANDSCAPE 等）改造为支持智感旋转的策略 | [migrate-to-smart-rotation.md](references/migrate-to-smart-rotation.md) |

## 策略选型决策树

```
应用需要固定方向吗？
├─ 是（游戏、相机取景等强固定布局）
│   └─ 固定方向类型：PORTRAIT / LANDSCAPE / PORTRAIT_INVERTED / LANDSCAPE_INVERTED
│       （不跟随传感器，不参与智感旋转）
└─ 否，希望跟随用户握持
    ├─ 需要调用时立即旋转到指定方向（视频进全屏）
    │   └─ USER_ROTATION 系列 4 种（之后自动旋转，OH 7.0.0+ 参与智感旋转）
    ├─ 限定竖向/横向两方向（阅读类）
    │   └─ AUTO_ROTATION_PORTRAIT(_RESTRICTED) / AUTO_ROTATION_LANDSCAPE(_RESTRICTED)
    ├─ 与桌面方向保持一致（桌面工具类）
    │   └─ FOLLOW_DESKTOP（参与智感旋转；直板机桌面固定竖屏）
    └─ 四方向自由旋转
        ├─ 希望受控制中心旋转锁定开关控制 → AUTO_ROTATION_RESTRICTED（推荐）
        └─ 不希望受开关控制 → AUTO_ROTATION
        （未显式设置时默认 UNSPECIFIED：平板等设备系统判定并参与智感，直板机固定竖屏不可旋转）
```

## 30 秒上手（两种接入方式）

**方式一：module.json5 静态配置**（启动即生效，适合固定方向/初始方向）

```json5
// module.json5 → abilities
"orientation": "auto_rotation_restricted"   // 取值与 window.Orientation 枚举一一对应（小写蛇形）
```

**方式二：运行时 API**（动态切换方向）

```typescript
import { window } from '@kit.ArkUI';

// onWindowStageCreate 中获取主窗口（仅主窗口支持旋转策略）
const mainWindow = windowStage.getMainWindowSync();
// 自动旋转类策略：支持智感旋转的设备上自动获得智感体验，其余设备回退重力传感器旋转
mainWindow.setPreferredOrientation(window.Orientation.AUTO_ROTATION_RESTRICTED);
```

两种方式设置的枚举含义完全一致，运行时接口可覆盖静态配置。18 个取值映射与选型建议见 [rotation-api.md](references/rotation-api.md)。

## 核心接口速查

| 接口（`Window` 实例） | 说明 | 版本 |
| --- | --- | --- |
| setPreferredOrientation(orientation) | 设置旋转策略（callback/promise） | API 9+ |
| setPreferredOrientationWithResult(orientation) | 设置旋转策略并返回执行结果（APPLIED/IGNORED/PENDING） | API 26+ |
| getPreferredOrientation() | 查询当前旋转策略 | API 12+ |
| on('rotationChange') / off('rotationChange') | 监听窗口旋转（即将旋转/旋转完成），可返回矩形干预旋转布局 | API 19+ |
| convertOrientationAndRotation(from, to, value) | 窗口方向 / 屏幕方向 / 屏幕角度互转 | API 23+ |
| setRotationLocked(locked) / getRotationLocked() | 系统窗口旋转锁（**@systemapi**，普通应用不可用） | API 22+ |

方式一（静态配置）：module.json5 `abilities` 标签的 `"orientation"` 字段，18 个取值与枚举一一对应（如 `"portrait"`/`"landscape"`/`"auto_rotation_restricted"`/`"follow_desktop"`），启动即生效，完整映射表见 [rotation-api.md](references/rotation-api.md)。

## 约束与最佳实践（必须遵守）

1. **仅主窗口支持**：设置旋转策略；对非主窗口设置不生效也不报错（OH 6.1+ 例外：`TYPE_WALLET_SWIPE_CARD` 系统窗口）。
2. **生效时机**：主窗口全屏时设置立即生效；未全屏时需进入全屏后才生效。分屏、智慧多窗悬浮窗、自由多窗、多任务、后台等场景系统忽略策略（接口可正常调用但方向不变）。
3. **设备要求**：无重力传感器设备（TV 等）设置不生效；智感旋转额外要求设备支持智感传感器 + 系统版本 OpenHarmony 7.0.0+ + 用户开启智感旋转开关。
4. **两套 Orientation 概念勿混淆**：旋转策略的 `window.Orientation` 与屏幕属性的 `display.Orientation` 名称相同但含义不同；不要用屏幕 Orientation/rotation 判断窗口方向做布局适配，需要判断时用 `convertOrientationAndRotation()` 换算。
5. **数字编码 ≠ 枚举值**：`rotationChange`/`convertOrientationAndRotation` 返回的窗口方向数字（0竖屏/1反向横屏/2反向竖屏/3横屏）与 `window.Orientation` 枚举值（1竖屏/2横屏/3反向竖屏/4反向横屏）不同，映射关系见 [rotation-practical-cases.md](references/rotation-practical-cases.md)。
6. **策略选型建议**：优先单一策略（`FOLLOW_DESKTOP`/`AUTO_ROTATION_UNSPECIFIED`）适配多设备；直板机要"自动旋转且可锁定当前方向"用 `USER_ROTATION` 系列（`AUTO_ROTATION_RESTRICTED`/`UNSPECIFIED` 在直板机不支持锁定横屏）；视频小窗进全屏用 `USER_ROTATION_LANDSCAPE`；要体验智感旋转须用自动旋转类策略、`FOLLOW_DESKTOP` 或默认 `UNSPECIFIED`（后两者在直板机上等效固定竖屏不旋转，如需旋转需显式改 auto 类）。
7. **监听成对注销**：`on(...)` 与 `off(...)` 成对调用，避免内存泄漏。
8. **布局适配基于窗口尺寸**：旋转后布局适配监听 `on('windowSizeChange')`，不要基于屏幕 Orientation。
9. **错误处理**：接口多用 Promise，需捕获 `BusinessError`；高频错误码：401（参数错误）、801（设备能力不支持）、1300002（窗口状态异常）、1300003（窗口管理服务异常）。
