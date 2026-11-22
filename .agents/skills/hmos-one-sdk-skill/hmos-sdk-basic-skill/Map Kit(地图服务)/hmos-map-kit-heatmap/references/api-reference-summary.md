# 热力图API参考文档汇总

本文档汇总了热力图功能相关的API参考文档链接。

## 核心API

### HeatmapParams（热力图参数）

**定义位置**：map-common.md

**API参考链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common

**核心参数**：
- id: string - 热力图ID（必填）
- data: WeightedLatLng[] - 热力图数据（必填，建议小于10000条）
- color: Record<number, number> - 热力图颜色（可选，ARGB格式）
- intensity: number | Record<number, number> - 热力图强度（可选）
- opacity: number | Record<number, number> - 热力图透明度（可选，范围[0,1]）
- radius: number | Record<number, number> - 热力图半径（可选，默认10）
- radiusUnit: RadiusUnit - 半径单位（可选，PIXEL_UNIT或METER_UNIT）
- visible: boolean - 是否可见（可选，默认true）

### WeightedLatLng（加权经纬度）

**定义位置**：map-common.md

**API参考链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common

**核心参数**：
- point: LatLng - 经纬度坐标（必填）
- intensity: number - 强度权重（可选，默认1，范围[0,+∞））

### RadiusUnit（半径单位）

**定义位置**：map-common.md

**API参考链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common

**枚举值**：
- PIXEL_UNIT = 0 - 像素px
- METER_UNIT = 1 - 米

### addHeatmap（添加热力图方法）

**定义位置**：map-map-mapcomponentcontroller.md

**API参考链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller

**方法签名**：
```typescript
addHeatmap(params: mapCommon.HeatmapParams): Promise<Heatmap>
```

**参数**：
- params: HeatmapParams - 热力图参数（必填）

**返回值**：
- Promise<Heatmap> - 热力图对象

**错误码**：
- 1002601001 - 操作对象不存在
- 1002600015 - 热力图ID已存在

### Heatmap（热力图对象）

**定义位置**：map-map-heatmap.md

**API参考链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-heatmap

**核心方法**：
- setData(data: WeightedLatLng[]): void - 更新热力图数据
- getData(): WeightedLatLng[] - 获取热力图数据
- setColor(color: Record<number, number>): void - 更新热力图颜色
- getColor(): Record<number, number> - 获取热力图颜色
- setIntensity(intensity: number | Record<number, number>): void - 更新热力图强度
- getIntensity(): number | Record<number, number> - 获取热力图强度
- setOpacity(opacity: number | Record<number, number>): void - 更新热力图透明度
- getOpacity(): number | Record<number, number> - 获取热力图透明度
- setRadius(radius: number | Record<number, number>): void - 更新热力图半径
- getRadius(): number | Record<number, number> - 获取热力图半径
- setRadiusUnit(radiusUnit: RadiusUnit): void - 更新热力图半径单位
- getRadiusUnit(): RadiusUnit - 获取热力图半径单位
- setVisible(visible: boolean): void - 更新热力图是否可见
- isVisible(): boolean - 获取热力图是否可见
- remove(): void - 删除热力图

## LatLng（经纬度）

**定义位置**：map-common.md

**API参考链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common

**核心参数**：
- latitude: number - 纬度（必填，范围[-90,90]）
- longitude: number - 经度（必填，范围[-180,180)）

## MapComponentController（地图控制器）

**定义位置**：map-map-mapcomponentcontroller.md

**API参考链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller

**相关方法**：
- addHeatmap - 添加热力图
- clear - 清除所有覆盖物（包括热力图）

## 错误码参考

**定义位置**：map-errorcode.md

**API参考链接**：https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-errorcode

**热力图相关错误码**：
- 1002601001 - 操作对象不存在
- 1002600015 - 热力图ID已存在
- 401 - 输入参数非法

## API版本要求

- **起始版本**：6.0.0(20)
- **元服务API**：从版本6.0.0(20)开始支持
- **系统能力**：SystemCapability.Map.Core

## 使用建议

1. **数据量控制**：建议数据量小于10000条，确保渲染性能
2. **参数校验**：添加前校验坐标范围、颜色格式、参数范围
3. **错误处理**：使用try-catch捕获异常，根据错误码进行降级处理
4. **ID管理**：使用唯一的热力图ID，避免重复添加
5. **性能优化**：批量更新数据，避免频繁调用setData方法