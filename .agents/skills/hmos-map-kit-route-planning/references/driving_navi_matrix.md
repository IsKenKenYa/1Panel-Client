# 驾车批量算路

## 服务概述

提供多点之间驾车路径批量计算功能，适用于物流配送、网约车派单等高并发场景。

- **版本**: 1.0
- **服务标识**: `getDrivingMatrix`
- **官方文档**: <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-navi-api>

### 接口定义

**函数**: `navi.getDrivingMatrix(params: DrivingMatrixParams): Promise<MatrixResult>`

**导入方式**:

```typescript
import { navi } from '@kit.MapKit';
```

### 请求参数 (DrivingMatrixParams)

| 参数           | 类型                               | 是否可选 | 描述     |
|--------------|----------------------------------|------|--------|
| origins      | [LatLng](common.md#latlng坐标对象)[] | 否    | 起点坐标数组 |
| destinations | [LatLng](common.md#latlng坐标对象)[] | 否    | 终点坐标数组 |
| language     | string                           | 是    | 返回结果语言 |
| avoids       | number[]                         | 是    | 避让选项   |
| trafficMode  | number                           | 是    | 时间预估模型 |
| extension    | number                           | 否    | 额外信息   |

#### avoids 避让选项

| 值 | 说明   |
|---|------|
| 1 | 避免收费 |
| 2 | 避免高速 |

#### trafficMode 时间预估模型

| 值 | 说明         |
|---|------------|
| 0 | best guess |
| 1 | 路况差于历史平均水平 |
| 2 | 路况优于历史平均水平 |

### 响应结果 (MatrixResult)

| 字段                   | 类型                                    | 是否可选 | 描述     |
|----------------------|---------------------------------------|------|--------|
| originAddresses      | string[]                              | 否    | 起点地址列表 |
| destinationAddresses | string[]                              | 否    | 终点地址列表 |
| rows                 | [MatrixRow](common.md#矩阵行MatrixRow)[] | 否    | 矩阵行列表  |

### 代码示例

详情见 ../assets/drivingMatrixDemo.ets

### 常见问题

**Q: 批量算路支持多少个起终点？**

A: 建议单次请求的起点和终点各不超过10个，以获得最佳性能。

**Q: 如何设置避让收费道路？**

A: 在 avoids 参数中传入 [1] 即可避免收费道路。

**Q: 批量算路的返回结果包括哪些信息？**

A: 返回结果包括每个起点到每个终点的距离和预计时间。
