# @cross-device-app-dev — 一次开发多端部署规则

检查跨设备（手机/平板/PC）开发的 UI 适配规范。

## 规则集

- `plugin:@cross-device-app-dev/recommended` — 8 条
- `plugin:@cross-device-app-dev/all` — 10 条

> `all` 是 `recommended` 的超集。另有 `color-contrast` 和 `color-value` 不在任何预设中。

## 全部规则列表（12 条）

> **预设列说明**：`rec+all` = 在 recommended 和 all 中；`all` = 仅在 all 中；`—` = 不在任何预设中。

| 规则 ID | 预设 | 默认级别 | 说明 |
|---------|------|:--------:|------|
| `@cross-device-app-dev/color-contrast` | — | warn | 颜色对比度检查（文本与背景对比度至少 4.5:1） |
| `@cross-device-app-dev/color-value` | — | warn | 颜色值格式校验 |
| `@cross-device-app-dev/font-size` | rec+all | warn | 字体大小至少 8fp |
| `@cross-device-app-dev/font-size-unit` | rec+all | warn | 字体应使用 fp 单位 |
| `@cross-device-app-dev/grid-columns-span` | rec+all | warn | 不推荐 GridCol 只设 span 且等于 columns |
| `@cross-device-app-dev/grid-span-value` | rec+all | warn | GridCol 的 span/offset 不建议用小数 |
| `@cross-device-app-dev/immersive-effect-check` | all | suggestion | 沉浸式效果开发（setWindowLayoutFullScreen + getWindowAvoidArea） |
| `@cross-device-app-dev/one-multi-breakpoint-check` | rec+all | warn | 使用断点而非设备类型作为响应式布局基础 |
| `@cross-device-app-dev/sidebar-navigation` | rec+all | warn | 2in1/平板设备 Tabs 应设为侧边导航栏 |
| `@cross-device-app-dev/size-unit` | rec+all | warn | width/height/size 应使用 vp 单位 |
| `@cross-device-app-dev/touch-target-size` | rec+all | warn | 可触摸热区不小于 40vp×40vp |
| `@cross-device-app-dev/window-size-change-listener-check` | all | suggestion | 尽可能启用窗口大小变化监听 |

## 示例

```json
{
  "ruleSet": ["plugin:@cross-device-app-dev/all"],
  "rules": {}
}
```
