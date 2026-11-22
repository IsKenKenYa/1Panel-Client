# 受限权限（悬浮类摘录）

> Skill 落盘。权威：HarmonyOS 官网受限权限页对应条目。刷新时以官网覆盖 `USE_FLOAT_BALL` / `AUTO_RESTORE_MAIN_WINDOW` / `DLP_GET_HIDE_STATUS` / `FLOAT_VIEW`。

## ohos.permission.USE_FLOAT_BALL

允许应用使用闪控球的能力。

<!--RP46--><!--RP46End-->

**权限级别**：system_basic

**授权方式**：系统授权（system_grant）

**支持设备**：Phone | PC/2in1 | Tablet

**起始版本**：20

**变更信息**：从API版本26.0.0开始，增加支持在PC/2in1上申请。


## ohos.permission.AUTO_RESTORE_MAIN_WINDOW

允许应用使用闪控球的自动恢复到应用主窗口的能力。

**申请条件**：需要与闪控球权限[ohos.permission.USE_FLOAT_BALL](#ohospermissionuse_float_ball)一起，才可申请此权限。

<!--RP69--><!--RP69End-->

**权限级别**：system_basic

**授权方式**：系统授权（system_grant）

**支持设备**：Phone | Tablet

**起始版本**：24


## ohos.permission.DLP_GET_HIDE_STATUS

允许应用使用信息隐藏接口，获取信息隐藏状态的能力。

获取此权限后，应用可以获取当前屏幕窥视状态，即当前是机主一人注视屏幕，还是有他人偷窥机主屏幕。

<!--RP44--><!--RP44End-->

**权限级别**：system_basic

**授权方式**：系统授权（system_grant）

**支持设备**: Phone

**起始版本**：18

**变更信息**：在API18-19，该权限面向系统应用开放；从API20开始，面向普通应用开放。


## ohos.permission.FLOAT_VIEW

允许应用使用闪控窗。

<!--RP78--><!--RP78End-->

**权限级别**：system_basic

**授权方式**：用户授权（user_grant）

**支持设备**：Phone | PC/2in1 | Tablet

**起始版本**：26.0.0

