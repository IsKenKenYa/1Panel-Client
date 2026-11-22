# 闪控窗误用清单

签名以 [js-apis-floatView.md](../apis/js-apis-floatView.md) 为准。本文件不列接口表。绑定/防窥步骤见 [guide-float-view.md](../guides/guide-float-view.md)（摘要，非官网全文）。

模块：`import { floatView } from '@kit.ArkUI'`  
起始：API 26；仅 Stage。权限：`FLOAT_VIEW`（start）；bind 再加 `USE_FLOAT_BALL`。

**做什么**：系统画窗框，应用 `setUIContext` 加载自己的页。  
**不要用来**：视频迁窗（PiP）、贴边球（闪控球）、`TYPE_FLOAT`。

## 权限（三处，缺一即 201）

`FLOAT_VIEW`：受限 + system_basic + **user_grant**。

| 层 | 写什么 |
|----|--------|
| `module.json5` | `name` + `reason` + `usedScene` |
| ACL Profile | `allowed-acls` 加入该权限；`apl` ≥ `system_basic` |
| 运行时 | 仅对 `FLOAT_VIEW` `requestPermissionsFromUser` |

bind 时声明+ACL 再加 `USE_FLOAT_BALL`（system_grant，**不弹窗**）。防窥 `DLP_GET_HIDE_STATUS` 同样 system_grant，不弹窗。

## 调用顺序

`isFloatViewEnabled` → `create` → `setUIContext`（path 与 `main_pages.json` 的 src **完全一致**，禁止 `./`）  
→ `onStateChange` → 主窗 **foreground** → `start()` → **回调 STARTED** → `stop`

`start()` Promise resolve ≠ 启动完成。`getWindowProperties` 须 STARTED 之后。防窥不要等 STARTED，也不要用这里的 `windowId`。

窗框只有两种：用户说圆角/面板 → `ROUNDED_RECTANGLE`；横条/细条 → `HORIZONTAL_BAR`。未说则圆角。可用 `switchTemplate` 切换。页内容不是系统模板。

## 绑定（易错，不是接口抄录）

入口只有 `floatView.bind` / `unbind`。两边都 create、都未 start、都未绑定才能 bind。bind 后 `start()` 或 `startFloatingBall()` 会同时建两个窗，先调谁谁先亮。stop 任一即两边都停。窗状态 `IN_FLOATING_BALL=5`。已绑定后点球由系统展开窗，不要当「只还原主窗」。

禁止：先 start 再 bind；未 bind 同时 start 窗和球（`1300034`）。

## 防窥组合

`FloatViewController` 没有防窥 API。用 `dlpAntiPeep` 拉系统蒙层，开关和抄写见 [peep.md](../../assets/peep.md)。`getWindowId()` 先判空，不要 `as number`。不要用 `getWindowProperties().windowId`，不要改文案当防窥。系统提醒 ≠ 蒙层。

## 错误码（应用侧）

| 码 | 改什么 |
|----|--------|
| 201 | 声明 + ACL；FLOAT_VIEW 要弹窗 |
| 401 | 组件内取 `UIAbilityContext` |
| 801 | 先 `isFloatViewEnabled` |
| 1300016 | path/模板/尺寸 |
| 1300030 | 重复 start/stop/重复注册 |
| 1300031 | 状态不允许（含 bind 时机、未 start 就 get） |
| 1300032 | restore：用户须先点过窗；主窗非 PAUSED |
| 1300033 | 只 start 一个；等主窗 foreground |
| 1300034 | 先停 PiP/未绑定的球，或走 bind |

## 误用清单（查错用）

查错按本清单逐条扫，命中就写 E。

1. `create` 后没 `start`，或 `start()` then 里当已显示，未等 STARTED
2. `context` 不是 `UIAbilityContext` → 401
3. start 前没 `setUIContext`；path 与 `main_pages.json` 不一致或写成 `./pages/Index`；或把启动逻辑写进 FloatPanel
4. 没写 `module.json5` / 没进 ACL / `FLOAT_VIEW` 没弹窗；对球权限或 DLP 弹窗
5. 主窗未前台就 start → 1300033
6. 与 PiP 或未绑定的闪控球同时 start → 1300034
7. 先 start 再 bind
8. `restoreMainWindow` 在用户未点窗或主窗 PAUSED 时调用 → 1300032
9. 手势按钮放在 `avoidArea`
10. 用子窗 / `TYPE_FLOAT` 冒充闪控窗
11. 重复 `onStateChange` 不 off；或每次点击都 `create`
12. 尺寸 ≤ 0 或远超 limits
13. 编造 `fv.setAntiPeep`；蒙层用 `getLastWindow` / `FloatViewProperties.windowId`；等 STARTED 才注册 `antiPeepCB`；`getWindowId()` 赋给 `number` 或 `as number`（10605999）；把文案改 `****` / `updateFloatingBall` 当防窥；开关未开静默跳过（须上屏 + `requestAntiPeepOptions`）
14. 在 `aboutToDisappear` / `onPageHide` 里 `stop`，退后台被自己停掉
