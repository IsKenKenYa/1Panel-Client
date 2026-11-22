# 局部深浅色

WithTheme 用于设置局部区域的深浅色。**使用它不需要开启高性能开关，也不需要初始化 Native C API 或配置反色。**

## 使用前提

- 使用 API 12+ 和 Stage 模型，目标组件在当前 SDK 的 WithTheme 支持范围内。
- 默认主题样式和系统颜色资源已有系统提供的深浅色配色，无需在应用中重复定义它们的 dark 值。应用自定义资源要显示不同配色时，再准备相应的 base/dark 定义或主题配置。
- 无应用 dark 资源时，检查应用已有的颜色模式配置。应用本来需要跟随系统、但局部深色仍显示为浅色时，可在页面创建前通过 `setColorMode(COLOR_MODE_NOT_SET)` 明确声明跟随系统；保留业务已经固定的应用模式。不能仅因使用 WithTheme 就强制新增 dark 文件。
- WithTheme 根据作用域选择主题和资源，不会把任意硬编码色值自动转换成另一套配色。

## 最小用法

```ts
WithTheme({ colorMode: ThemeColorMode.DARK }) {
  Column() {
    Text('固定深色的区域')
  }
  .backgroundColor($r('sys.color.ohos_id_color_background'))
}
```

`ThemeColorMode.SYSTEM`、`LIGHT`、`DARK` 分别表示跟随系统、固定浅色和固定深色。

- WithTheme 支持一个直接子组件；多个内容由容器承载。
- WithTheme 不支持通用属性、事件；尺寸、背景等放在内部容器上。
- 核对目标 SDK 支持的组件及其资源条件，不承诺任意自绘内容、弹窗或脱离该子树的节点都会受到相同影响。
- 开发者只要求局部效果时，不使用应用级 setColorMode 改变其他区域。

来源与版本见 [API 依据](api-facts.md)。
