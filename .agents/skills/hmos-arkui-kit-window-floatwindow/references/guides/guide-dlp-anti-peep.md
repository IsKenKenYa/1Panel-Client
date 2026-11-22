# 防窥保护开发指导（Skill 落盘）

官网：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/devicesecurity-dlpantipeep  
与闪控窗组合：见 [guide-float-view.md](guide-float-view.md)「复杂场景与防窥保护组合使用」。

刷新时用官网现行页覆盖本文。

## 能力与权限

- 导入：`import { dlpAntiPeep } from '@kit.DeviceSecurityKit'`
- syscap：`SystemCapability.Security.DlpAntiPeep`，调用前 `canIUse`，不支持则整段跳过
- 权限：`ohos.permission.DLP_GET_HIDE_STATUS`（见 [restricted-permissions-float.md](../permissions/restricted-permissions-float.md)）
  - 级别 system_basic，授权方式 system_grant（声明 + ACL，不弹窗）
  - 支持设备：Phone；API20 起对普通应用开放
- 用户须在「设置 > 隐私与安全 > 防窥保护」打开本应用。声明 `DLP_GET_HIDE_STATUS` **不会**自动打开该开关
- 未开：页面 hint + `requestAntiPeepOptions(context)`；不要静默跳过

## 接口

| 接口 | 作用 |
|------|------|
| `isDlpAntiPeepSwitchOn(): Promise<boolean>` | 本应用是否已开防窥保护 |
| `requestAntiPeepOptions(context): Promise<...>` | 拉起设置弹窗请用户打开开关 |
| `on('dlpAntiPeep', callback)` | 订阅窥视状态 |
| `off('dlpAntiPeep', callback?)` | 取消订阅 |
| `getDlpAntiPeepInfo(): DlpAntiPeepStatus` | 同步当前窥视状态 |
| `setAntiPeepMaskLayer(windowId: number): Promise<void>` | 对指定窗口拉起系统级蒙层。闪控窗组合不要裸调，走骨架 `showSystemMaskLayer` |
| `passDlpAntiPeepInfo(): void` | 直到锁屏或退出前视为非窥视 |
| `publishAntiPeepInformation(): Promise<void>` | 发布防窥实况窗提醒 |

## 状态

| `DlpAntiPeepStatus` | 含义 | 应用 |
|---------------------|------|------|
| `PASS` | 无人窥视（或仅机主） | 清蒙层标志，便于下次 HIDE 再拉 |
| `HIDE` | 机主与非机主同时看屏 | `showSystemMaskLayer(windowId)` → `setAntiPeepMaskLayer` |

## 推荐顺序

```text
canIUse → isDlpAntiPeepSwitchOn
  → 未开：页面 hint「设置 → 隐私与安全 → 防窥保护」+ requestAntiPeepOptions
  → getDlpAntiPeepInfo 同步一次
  → listenOnAntiPeepStatus(antiPeepCB)
  → HIDE：MAIN_WINDOW.getUIContext().getWindowId()（先判空，不要 as number）→ showSystemMaskLayer
  → aboutToDisappear：off
```

`showSystemMaskLayer` / `setAntiPeepMaskLayer` 的 windowId **必须**来自 `UIContext.getWindowId()`，且该接口返回 `number | undefined`：

- 主界面：`AppStorage.get('MAIN_WINDOW')` → `getUIContext().getWindowId()`，`!== undefined` 再蒙（官网 `antiPeepCB` 就是这条；不要抄官网的 `as number`）
- 闪控窗页：`FloatPanel` 里同样先判空，再存 `FLOAT_WINDOW_ID`

不要用 `window.getLastWindow`，也不要用 `FloatViewProperties.windowId`（和蒙层接口要的 id 不是同一套）。

系统「防窥提醒」和蒙层分开：有提醒 ≠ 已蒙层。蒙层只在 `antiPeepCB` 里 `HIDE` 时由应用拉起。

一人看屏是 `PASS`，注册了回调也不会出蒙层。真机验证：设置打开本应用防窥保护，再让另一人看屏走 `HIDE`；或主动调 `showSystemMaskLayer`。`201` → 签名 ACL 缺 `DLP_GET_HIDE_STATUS`。

## 与闪控窗

防窥不是 `floatView` 的 API，也不是改页面/球上的文字。组合规则写在 [guide-float-view.md](guide-float-view.md)：抄官网 `antiPeepCB`，`HIDE` 对主窗 `getWindowId()` 调 `showSystemMaskLayer`。本仓 OpenHarmony 树可能没有 `@kit.DeviceSecurityKit` DTS，**仍按本指导写应用侧示例**（以官网为准）。
