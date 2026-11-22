# 卡片配置文件字段说明

## 配置文件位置

卡片配置文件通常命名为form_config.json，位于`resources/base/profile/`目录下。

## 主要字段说明

### forms（必需）
应用的全部卡片配置信息，数组类型，最多支持16个卡片。

### name（必需）
卡片的名称，用于开发者区分不同的卡片，最大长度127字节。

### displayName（必需）
卡片的展示名称，用于卡片管理页面显示，最大长度30字节。

### description（可选）
卡片的描述，用于卡片管理页面展示功能描述，最大长度255字节。

### src（必需）
卡片对应的UI代码完整路径。
- ArkTS卡片：需包含后缀，如`"./ets/widget/pages/WidgetCard.ets"`
- JS卡片：无需后缀，如`"./js/widget/pages/WidgetCard"`

### uiSyntax（可选）
卡片类型：
- `arkts`：ArkTS卡片
- `hml`：JS卡片（默认值）

### isDefault（必需）
是否为默认卡片，每个应用有且只有一个默认卡片。

### supportDimensions（必需）
卡片支持的外观规格：
- `1*1`：一宫格（仅支持锁屏）
- `1*2`：二宫格
- `2*2`：四宫格
- `2*4`：八宫格
- `2*3`：六宫格（仅支持手表）
- `3*3`：九宫格（仅支持手表）
- `4*4`：十六宫格
- `6*4`：二十四宫格

### defaultDimension（必需）
卡片的默认尺寸，必须在该卡片supportDimensions配置的列表中。

### updateEnabled（必需）
是否支持周期性刷新：
- `true`：支持（可选择定时刷新或定点刷新）
- `false`：不支持

### scheduledUpdateTime（可选）
定点刷新时刻，24小时制，精确到分钟，如"10:30"。

### updateDuration（可选）
定时刷新周期，单位为30分钟，取值为自然数。

### isDynamic（可选）
是否为动态卡片（仅对ArkTS卡片生效）：
- `true`：动态卡片（默认）
- `false`：静态卡片

### renderingMode（可选）
卡片渲染模式（API version 15+）：
- `autoColor`：自动模式
- `fullColor`：全彩模式（默认）
- `singleColor`：单色模式

## 特殊字段

### window（可选，仅JS卡片）
显示窗口配置，包含designWidth和autoDesignWidth。

### metadata（可选）
卡片的自定义信息。

### dataProxyEnabled（可选）
是否支持卡片代理刷新（API version 12+）。

### transparencyEnabled（可选）
是否为背板透明卡片。

### enableBlurBackground（可选）
是否使用模糊背板（API version 23+，仅旗舰机型）。

### supportShapes（可选）
卡片显示形状：rect（矩形）、circle（圆形）。

### resizable（可选）
是否可以拖拽调整大小（API version 20+）。

### groupId（可选）
一组卡片的共同ID，用于共享尺寸配置（API version 20+）。

### standby（可选）
待机屏保显示页面配置（API version 23+）。

## 扩展字段

### funInteractionParams（可选）
趣味交互类型互动卡片扩展字段（API version 20+）。

### sceneAnimationParams（可选）
场景动效类型互动卡片扩展字段（API version 20+）。

### supportDeviceTypes（可选）
卡片支持的设备类型（API version 22+）。

### supportDevicePerformanceClasses（可选）
卡片支持的设备性能等级（API version 22+）。

## 完整配置示例文档链接

详细配置说明请参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-configuration