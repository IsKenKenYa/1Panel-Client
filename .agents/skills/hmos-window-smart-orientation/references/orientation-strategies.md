# 旋转策略详解（Orientation 枚举，18 种）

应用通过 module.json5 `"orientation"` 字段（静态配置，取值如 `"auto_rotation_restricted"`，与枚举一一对应，完整映射表见 [rotation-api.md](rotation-api.md) 第 7 节）或运行时 `setPreferredOrientation()` 设置旋转策略，两种方式设置的 `window.Orientation` 枚举含义一致。按使用场景分为四类。

> **仅主窗口支持**设置旋转策略，非主窗口设置不生效不报错。

## 固定方向类型（4 种）

不论用户如何握持设备，应用方向均不变化。适合游戏等固定方向应用。

| 名称 | 值 | 说明 |
| --- | --- | --- |
| PORTRAIT | 1 | 竖屏 |
| LANDSCAPE | 2 | 横屏 |
| PORTRAIT_INVERTED | 3 | 反向竖屏 |
| LANDSCAPE_INVERTED | 4 | 反向横屏 |

> 固定方向类型不跟随任何传感器，**不参与智感旋转**。

## 自动旋转方向类型（7 种）

跟随传感器自动旋转，使用户握持设备时应用始终保持正向显示。OH 7.0.0+ 设备上**参与智感旋转**：最终方向由重力传感器和智感传感器共同作用决定。

| 名称 | 值 | 说明 | 受旋转锁定开关控制 |
| --- | --- | --- | --- |
| AUTO_ROTATION | 5 | 四方向自动旋转（竖/横/反竖/反横） | 否 |
| AUTO_ROTATION_PORTRAIT | 6 | 仅竖屏/反向竖屏 | 否 |
| AUTO_ROTATION_LANDSCAPE | 7 | 仅横屏/反向横屏 | 否 |
| AUTO_ROTATION_RESTRICTED | 8 | 四方向自动旋转 | 是 |
| AUTO_ROTATION_PORTRAIT_RESTRICTED | 9 | 仅竖向两方向 | 是 |
| AUTO_ROTATION_LANDSCAPE_RESTRICTED | 10 | 仅横向两方向 | 是 |
| AUTO_ROTATION_UNSPECIFIED | 12 | 自动旋转，可旋转方向受系统判定 | 是 |

RESTRICTED 类在旋转锁定打开时固定在锁定方向，不再跟随重力传感器，也不跟随智感传感器。

### AUTO_ROTATION_RESTRICTED 与 AUTO_ROTATION_UNSPECIFIED 的差异

功能相似（都支持自动旋转 + 受旋转锁定控制），但不同产品形态有区别：

| 场景 | AUTO_ROTATION_RESTRICTED | AUTO_ROTATION_UNSPECIFIED |
| --- | --- | --- |
| 旋转锁定关闭（直板机/类直板机形态） | 可旋转到四个方向 | 仅竖屏、横屏、反向横屏三方向，**无法反向竖屏** |
| 旋转锁定关闭（平板/类平板形态） | 可旋转到四个方向 | 可旋转到四个方向 |
| 旋转锁定打开（直板机/类直板机形态） | 不支持锁定横屏，开启锁定时被强制回竖屏 | 同左 |
| 旋转锁定打开（平板/类平板形态） | 支持锁定横屏 | 支持锁定横屏 |

> 直板机上要"自动旋转且可锁定当前方向"，推荐优先使用 `USER_ROTATION` 系列旋转策略。

## 临时方向类型（4 种）

调用时**立即临时旋转到指定方向**，之后跟随传感器自动旋转（受控制中心旋转锁定控制，可旋转方向受系统判定）。OH 7.0.0+ 设备上传感器跟随**包含智感传感器**。典型用于视频类应用小窗播放进入全屏播放。

| 名称 | 值 | 说明 |
| --- | --- | --- |
| USER_ROTATION_PORTRAIT | 13 | 临时旋转到竖屏，之后自动旋转 |
| USER_ROTATION_LANDSCAPE | 14 | 临时旋转到横屏，之后自动旋转 |
| USER_ROTATION_PORTRAIT_INVERTED | 15 | 临时旋转到反向竖屏，之后自动旋转 |
| USER_ROTATION_LANDSCAPE_INVERTED | 16 | 临时旋转到反向横屏，之后自动旋转 |

> **USER_ROTATION_PORTRAIT_INVERTED 设备差异**：
> - 直板机/类直板机形态：无法临时旋转为反向竖屏（仍以竖屏显示），自动旋转仅支持竖屏、横屏、反向横屏三方向；
> - 平板/类平板形态：旋转锁定关闭时可四方向旋转。

## 其他方向类型（3 种）

| 名称 | 值 | 说明 |
| --- | --- | --- |
| UNSPECIFIED | 0 | 未定义方向（默认）。系统判定：直板机默认竖屏不可旋转；平板四方向且受旋转锁定开关控制（参与智感旋转） |
| LOCKED | 11 | 锁定模式。被其他应用拉起时保持与前一个应用相同的方向；方向也可能因应用切换等原因改变 |
| FOLLOW_DESKTOP | 17 | 跟随桌面。直板机桌面固定竖屏不可旋转；平板可旋转；折叠机折叠态同直板机、展开态同平板 |

> `FOLLOW_DESKTOP` 与 `UNSPECIFIED` 同样参与智感旋转（OH 7.0.0+ 设备）：开启智感旋转的设备上，系统/桌面方向判定融合智感传感器信号，应用随之获得智感体验。注意：两者在直板机上等效固定竖屏（桌面固定竖屏 / 默认竖屏不可旋转），方向不变化；如需旋转请显式使用自动旋转类策略。

## 策略选型速查

| 场景 | 推荐策略 |
| --- | --- |
| 游戏/固定横屏 | LANDSCAPE（竖屏游戏用 PORTRAIT） |
| 跟随传感器旋转（含智感旋转体验） | AUTO_ROTATION_RESTRICTED（受开关控制）或 AUTO_ROTATION（不受开关控制） |
| 仅竖向跟随（阅读类） | AUTO_ROTATION_PORTRAIT_RESTRICTED |
| 直板机自动旋转且可锁定当前方向 | USER_ROTATION 系列 |
| 视频小窗 → 全屏播放 | USER_ROTATION_LANDSCAPE（进全屏）/ 恢复自动旋转（退全屏） |
| 多设备免适配（推荐优先尝试单一策略） | FOLLOW_DESKTOP（支持智感旋转）或 AUTO_ROTATION_UNSPECIFIED |
| 被拉起时保持上一应用方向 | LOCKED |
