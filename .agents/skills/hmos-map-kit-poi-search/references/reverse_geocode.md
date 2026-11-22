# 逆地理编码 API

## 服务概述

将经纬度坐标解析为结构化地址信息。您可以通过该功能获取坐标对应的详细地址、行政区划等信息。

- **版本**: 1.0
- **服务标识**: `reverseGeocode`
- **官方文档**: <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-site>

### 接口定义

**函数**: `reverseGeocode(params: ReverseGeocodeParams): Promise<ReverseGeocodeResult>`

**导入方式**:

```typescript
import { site } from '@kit.MapKit';
```

### 请求参数 (ReverseGeocodeParams)

| 参数          | 类型                                 | 是否可选 | 描述                             |
|-------------|------------------------------------|------|--------------------------------|
| location    | [LatLng](common.md#latlng坐标对象)     | 否    | 经纬度坐标                          |
| radius      | number                             | 是    | 搜索半径（米），默认1000，取值范围[0, 1000]   |
| language    | string                             | 是    | 返回结果的语言                        |
| isExtension | boolean                            | 是    | 是否扩展返回POI、AOI、ROAD信息           |
| poiTypes    | Array\<string\>                    | 是    | POI类型筛选                        |
| isNearbyAoi | boolean                            | 是    | 是否返回附近AOI（isExtension为true时生效） |
| sortRule    | [SortRule](common.md#排序规则SortRule) | 是    | POI排序规则                        |

### 响应结果 (ReverseGeocodeResult)

| 字段                 | 类型                                                                 | 是否可选 | 描述                      |
|--------------------|--------------------------------------------------------------------|------|-------------------------|
| addressComponent   | AddressComponent                                                   | 否    | 地址组件信息                  |
| addressDescription | string                                                             | 否    | 地址描述                    |
| aois               | Array\<[Aoi](common.md#AOI Area of Interest)\>                     | 否    | AOI（Area of Interest）列表 |
| pois               | Array\<[ReverseGeocodePoi](common.md#逆地理编码POI ReverseGeocodePoi)\> | 否    | POI列表                   |
| roads              | Array\<[Road](common.md#道路信息Road)\>                                | 否    | 道路列表                    |
| intersections      | Array\<[Intersection](common.md#交叉路口Intersection)\>                | 否    | 交叉路口列表                  |

详细类型定义请参考 [common.md](common.md) 中的Aoi、ReverseGeocodePoi、Road、Intersection类型定义。

### 代码示例

详情见 ../assets/reverseGeocodeDemo.ets

**用户输入示例：**

| 用户输入                          | 解析参数                            |
|-------------------------------|---------------------------------|
| 坐标(116.397428, 39.90923)对应的地址 | location=(116.397428, 39.90923) |
| 这个位置在哪里                       | location=(用户指定坐标)               |

### 常见问题

**Q: 逆地理编码返回的地址可能不精确吗？**

A: 是的，逆地理编码的精度取决于坐标的精度。如果坐标精度较低，返回的可能是近似地址。

**Q: 如何获取更精确的地址？**

A: 可以通过radius参数扩大搜索范围，让API返回附近最匹配的POI。

**Q: 坐标在海洋中会返回什么？**

A: 如果坐标在海洋中或无法匹配到有效地址，API可能返回错误或模糊结果。
