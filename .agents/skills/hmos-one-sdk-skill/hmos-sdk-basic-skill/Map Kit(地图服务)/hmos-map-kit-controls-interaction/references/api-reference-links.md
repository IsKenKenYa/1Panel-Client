# 参考文档链接

本文档列出控件交互技能相关的参考文档链接。

## API开发指南

### 控件交互开发指南
**原文路径**: `D:\z00810349\APIDevice\output\md_output\harmonyos-guides\应用服务\Map Kit（地图服务）\地图交互\控件交互\map-controls-and-interaction.md`

**在线文档**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-controls-and-interaction

**主要内容**:
- 控件交互场景介绍
- 接口说明
- 开发步骤（缩放控件、比例尺、指南针、Logo、审图号）
- 示例代码

### 显示地图开发指南
**原文路径**: `D:\z00810349\APIDevice\output\md_output\harmonyos-guides\应用服务\Map Kit（地图服务）\创建地图\显示地图\map-presenting.md`

**在线文档**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-presenting

**主要内容**:
- 地图初始化
- MapOptions参数设置
- mapController对象获取

## API参考文档

### MapComponentController API
**原文路径**: `D:\z00810349\APIDevice\output\md_output\harmonyos-references\应用服务\Map Kit（地图服务）\ArkTS API\map（地图显示功能）\map-map-mapcomponentcontroller.md`

**在线文档**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller

**主要接口**:
- setZoomControlsEnabled - 设置缩放控件
- setScaleControlsEnabled - 设置比例尺
- setScalePosition - 设置比例尺位置
- setAlwaysShowScaleEnabled - 设置比例尺常显
- getScaleLevel - 获取比例尺层级
- getScaleControlsHeight - 获取比例尺高度
- getScaleControlsWidth - 获取比例尺宽度
- setCompassControlsEnabled - 设置指南针
- setCompassPosition - 设置指南针位置
- setMyLocationEnabled - 设置我的位置图层
- setMyLocationControlsEnabled - 设置我的位置按钮
- setLogoAlignment - 设置Logo对齐
- setLogoPadding - 设置Logo间距
- setApproveNumberEnabled - 设置审图号（API 6.1.0(23)+）

### mapCommon API
**原文路径**: `D:\z00810349\APIDevice\output\md_output\harmonyos-references\应用服务\Map Kit（地图服务）\ArkTS API\map-common.md`

**在线文档**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common

**主要类型**:
- MapOptions - 地图初始化参数
- MapPoint - 屏幕坐标点
- LogoAlignment - Logo对齐方式枚举
- Padding - 边距参数
- LatLng - 经纬度坐标
- CameraPosition - 相机位置

## 版本要求

| 功能 | 最低API版本 | 说明 |
|------|------------|------|
| 基础控件功能 | 4.1.0(11) | 缩放、指南针、比例尺、定位按钮 |
| Logo对齐扩展 | 5.1.1(19) | TOP_CENTER、BOTTOM_CENTER |
| 比例尺位置/尺寸 | 5.0.0(12) | setScalePosition、getScaleControlsHeight/Width |
| 比例尺常显 | 5.0.0(12) | setAlwaysShowScaleEnabled |
| 审图号显示 | 6.1.0(23) | setApproveNumberEnabled |

## 系统要求

- **系统能力**: SystemCapability.Map.Core
- **模型约束**: 仅可在Stage模型下使用
- **元服务支持**: 所有接口均支持元服务API（从对应版本开始）