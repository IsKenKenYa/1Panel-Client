# 闪控窗开发指导（Skill 落盘）

官网：https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/float-view-guide  
锚点「复杂场景与防窥保护组合使用」：https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/float-view-guide#%E5%A4%8D%E6%9D%82%E5%9C%BA%E6%99%AF%E4%B8%8E%E9%98%B2%E7%AA%A5%E4%BF%9D%E6%8A%A4%E7%BB%84%E5%90%88%E4%BD%BF%E7%94%A8

完整接口签名、示例代码以 [js-apis-floatView.md](../apis/js-apis-floatView.md)、[js-apis-floatingBall.md](../apis/js-apis-floatingBall.md) 为准。刷新时用官网指导页覆盖本文。

## 选型

见 [window-type-overview.md](window-type-overview.md)。

- 视频画面迁到系统小窗、系统画控制条 → 画中画，不是闪控窗
- 贴边小球、不能自定义 UI → 闪控球
- 系统画窗框、应用 `setUIContext` 加载自己的页 → 闪控窗
- 点球展开窗、点窗缩小回球 → `floatView.bind`
- `TYPE_FLOAT` 全局悬浮窗、`createSubWindow` 子窗：不是本指导范围

## 开发步骤

1. `canIUse('SystemCapability.Window.SessionManager')` 且 `floatView.isFloatViewEnabled()`
2. 权限见 [restricted-permissions-float.md](../permissions/restricted-permissions-float.md) + [declare-permissions.md](../permissions/declare-permissions.md) + [declare-permissions-in-acl.md](../permissions/declare-permissions-in-acl.md)：`ohos.permission.FLOAT_VIEW`（user_grant，要 reason/usedScene 和运行时弹窗）；绑定还要 `ohos.permission.USE_FLOAT_BALL`（system_grant，不弹窗）
3. `floatView.create(config)` 只拿控制器，不建窗。**只 create 一次**，不要每次点启动都 new
4. `setUIContext(path)` 或 `setUIContextByName`；path 与 `main_pages.json` 的 src 一致。加载的是另一份 `@Entry`（`FloatPanel`），不是 Index
5. `onStateChange`；主窗前台后 `start()`
6. **`start()` 的 Promise 返回不表示启动完成**，以回调 `STARTED` 为准（见接口文档）
7. 退后台要继续展示：不要在 `aboutToDisappear` / `onPageHide` 里 `stop`。用户点停止再 `stop` + 销毁时 `offStateChange`

## 球窗绑定

见接口文档 `floatView.bind` / `unbind`。

- 两边都 `create` 且都未 start、未绑定再 bind
- 之后 `start()` 或 `startFloatingBall()` 会同时创建两个窗口，同一时刻只展示一个；先调谁谁先亮
- 用户点窗左上角缩小 ↔ 点球展开，由系统切换
- 窗状态 `IN_FLOATING_BALL`；停因 `FLOATING_BALL_STOP` / `FLOAT_VIEW_STOP`
- `stop` 任一即两边一起停；都停下后才能 unbind
- 权限：`FLOAT_VIEW` + `USE_FLOAT_BALL`

未绑定同时 start 窗和球、或与已启动 PiP 并行 → `1300034`，见 [errorcode-window-float.md](../permissions/errorcode-window-float.md)。

## 复杂场景与防窥保护组合使用

权威：[闪控窗开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/float-view-guide)「复杂场景：与防窥保护组合使用」。

闪控窗负责持续展示；防窥是 **DeviceSecurityKit `dlpAntiPeep` 的系统蒙层**，不是改 `FloatPanel` / 闪控球文案。传感器把长期人脸解锁用户标为机主；非机主与机主同时看屏时回调 `HIDE`。**系统防窥提醒可以自己弹，蒙层不会自动加**，必须走官网 `antiPeepCB.onStatusChanged` → `handleAntiPeepStatus(HIDE)` → `setAntiPeepMaskLayer`。用户可手动解除。不要在 `FloatViewController` 上编防窥方法。

接口细节见 [guide-dlp-anti-peep.md](guide-dlp-anti-peep.md)。组合要点（按官网示例抄）：

1. 声明 `ohos.permission.DLP_GET_HIDE_STATUS`（受限、system_grant、ACL），与 `FLOAT_VIEW` 并列
2. 开关未开：按 [guide-dlp-anti-peep.md](guide-dlp-anti-peep.md) + [peep.md](../../assets/peep.md)，不要静默跳过
3. `EntryAbility` 把主窗写入 `AppStorage.setOrCreate('MAIN_WINDOW', ...)`
4. 页面 `aboutToAppear`：`getDlpAntiPeepInfo()` 同步一次，再 `listenOnAntiPeepStatus(this.antiPeepCB)`。**不要等闪控窗 STARTED**
5. `HIDE`：取出 `MAIN_WINDOW` 后 `const windowId: number | undefined = w.getUIContext().getWindowId(); if (windowId !== undefined) { showSystemMaskLayer(windowId); }`。闪控窗页同样先判空再存/再蒙。官网写成 `as number` 会 `10605999`。**不要**用 `getLastWindow` / `FloatViewProperties.windowId`
6. 不要把页面字段改成 `****`，也不要 `updateFloatingBall` 改 title/content 当防窥
7. 页面销毁：`off('dlpAntiPeep')`；不要在闪控窗 `STOPPED` 时关掉监听

错误码见防窥指导。
