# 轨迹纠偏

## 服务概述

将用户行车轨迹上的坐标点匹配到道路上，解决GPS漂移问题，生成平滑准确的行驶路径。

- **版本**: 1.0
- **服务标识**: `snapToRoads`
- **官方文档**: <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-navi-api>

### 接口定义

**函数**: `navi.snapToRoads(params: SnapToRoadsParams): Promise<SnapToRoadsResult>`

**导入方式**:

```typescript
import { navi } from '@kit.MapKit';
```

### 请求参数 (SnapToRoadsParams)

| 参数     | 类型                               | 是否可选 | 描述       |
|--------|----------------------------------|------|----------|
| points | [LatLng](common.md#latlng坐标对象)[] | 否    | GPS坐标点数组 |

### 响应结果 (SnapToRoadsResult)

| 字段            | 类型                                          | 是否可选 | 描述        |
|---------------|---------------------------------------------|------|-----------|
| snappedPoints | [SnappedPoint](common.md#纠偏点snappedpoint)[] | 否    | 纠偏后的坐标点列表 |

### 代码示例

详情见 ../assets/snapToRoadsDemo.ets

### 常见问题

**Q: 轨迹纠偏支持多少个点？**

A: 建议单次请求的点数不超过100个，以获得最佳性能。

**Q: 轨迹点需要包含时间戳吗？**

A: 当前版本的轨迹纠偏只需要经纬度坐标，不需要时间戳。

**Q: 轨迹纠偏的返回结果是什么格式？**

A: 返回结果是纠偏后的坐标点列表，每个点包含匹配到的道路信息。
