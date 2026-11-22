# 闪控球误用清单

签名以 [js-apis-floatingBall.md](../apis/js-apis-floatingBall.md) 为准。本文件不列接口表。与窗联动见 [misuse-float-view.md](misuse-float-view.md) 绑定节。

模块：`import { floatingBall } from '@kit.ArkUI'`  
起始：API 20。权限：`USE_FLOAT_BALL`（start）；bind 时窗侧还要 `FLOAT_VIEW`。

**做什么**：系统画贴边小球，应用只填标题/内容/图标。  
**不要用来**：自定义 UI（闪控窗）、视频画面（PiP）。球模块没有 bind。

## 权限（两处，缺一即 201）

`USE_FLOAT_BALL`：受限 + system_basic + **system_grant**。声明 + ACL 即可，**不要** `requestPermissionsFromUser`。

可选 `AUTO_RESTORE_MAIN_WINDOW`：同样 system_grant，且必须和 `USE_FLOAT_BALL` 一起申请。

## 调用顺序

`isFloatingBallEnabled` → `create({ context })` → `on('stateChange'|'click')`  
→ 主窗 **已 show** → `startFloatingBall(params)` → `STARTED`  
→ `updateFloatingBall`（同 template；STATIC 禁止）→ `stopFloatingBall`

## 易错约束

- `title` 必填、非空、**≤ 64 字节**（不是 64 字符）
- 用户说法 → 模板：静态图标 `STATIC`（title+icon，禁止 update）；标题+内容 `NORMAL`；强调带图标 `EMPHATIC`；一行标题 `SIMPLE`。未说则 `EMPHATIC`
- `STATIC` 必传 `icon`，且禁止 update（1300028）
- update 不能改 `template`（1300027）
- 未 bind：点球走 `on('click')`，`restoreMainWindow(want)` 必传 `Want`（bundleName + abilityName），不要空参
- 已 bind：点球由系统展开窗

## 错误码（应用侧）

| 码 | 改什么 |
|----|--------|
| 201 | 声明 + ACL；不要对球权限弹窗 |
| 801 | 先 `isFloatingBallEnabled` |
| 1300019 | title/content/icon/颜色非法 |
| 1300021 / 1300022 | 一应用一个球；状态机 |
| 1300027 | update 保持原 template |
| 1300028 | STATIC 不要 update |
| 1300034 | 已有闪控窗则先停或 bind |

## 误用清单（查错用）

查错按本清单逐条扫，命中就写 E。

1. `create` 后没 `startFloatingBall`，或把 create 成功当成球已显示
2. `context` 不是 `UIAbilityContext` → 401
3. 给闪控球 `setUIContent` / `setUIContext`
4. `STATIC` 启动后还 `updateFloatingBall`，或 update 时改了 template
5. `title: ''` 或超 64 字节；STATIC 没传 `icon` → 1300019
6. 没写 `module.json5` / 没进 ACL；或对 `USE_FLOAT_BALL` 弹窗
7. 主窗未 show 就 start
8. 已有闪控窗或 PiP 未 bind 再 start 球 → 1300034
9. 没听 `click`；或已 bind 后还把 click 当「只还原主窗」
10. `restoreMainWindow` 在用户未点击或主窗 PAUSED 时调用
11. 把闪控球当 PiP 或自定义画布
12. 连点 start 多个球 → 1300021 / 1300022；或每次点击都 `create`
13. 在 `aboutToDisappear` 里 `stopFloatingBall`
