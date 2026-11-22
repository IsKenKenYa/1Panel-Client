# 周边搜索 API

## 服务概述

通过用户传入自己的位置，返回周边地点列表。您可以通过提供关键字或指定要搜索的地点的类型来优化搜索结果。

- **版本**: 1.0
- **服务标识**: `nearbySearch`
- **官方文档**: <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-site>

### 接口定义

**函数**: `nearbySearch(params: NearbySearchParams): Promise<NearbySearchResult>`

**导入方式**:

```typescript
import { site } from '@kit.MapKit';
```

### 请求参数 (NearbySearchParams)

| 参数        | 类型                                  | 是否可选 | 描述             |
|-----------|-------------------------------------|------|----------------|
| query     | string                              | 是    | 搜索关键字          |
| location  | [LatLng](common.md#latlng坐标对象)      | 否    | 搜索中心经纬度        |
| radius    | number                              | 是    | 搜索半径（米），默认1000 |
| language  | string                              | 是    | 返回结果语言         |
| poiTypes  | Array\<string\>                     | 是    | POI类型筛选        |
| pageIndex | number                              | 是    | 页码，默认1         |
| pageSize  | number                              | 是    | 每页数量，默认20，最大20 |
| sortRule  | [SortRule](common.md#排序规则-SortRule) | 是    | 排序规则           |

### 响应结果 (NearbySearchResult)

| 字段         | 类型                                  | 是否可选 | 描述   |
|------------|-------------------------------------|------|------|
| totalCount | number                              | 否    | 结果总数 |
| sites      | Array\<[Site](common.md#地点信息Site)\> | 否    | 地点列表 |

详细类型定义请参考 [Site类型](common.md#地点信息Site)。

### 代码示例

详情见 ../assets/nearbySearchDemo.ets

**用户输入示例：**

| 用户输入            | 解析参数                                                      |
|-----------------|-----------------------------------------------------------|
| 搜索天安门附近的咖啡厅     | location=(116.397428, 39.90923), query="咖啡厅", radius=1000 |
| 在这个位置周围500米内找餐厅 | location=(用户指定坐标), query="餐厅", radius=500                 |
| 我北边能看到海吗        | location=(用户当前位置坐标), query="海", radius=1000               |

### 回复模板

```
📍 已搜索「{位置}」周边 {半径}米范围内的「{搜索类别}」，找到 {totalCount} 条结果：

1. {地点名称}
   📍 地址：{格式化地址}
   ⭐ 评分：{评分}
   📏 距离：{距离}米

2. {地点名称}
   📍 地址：{格式化地址}
   📏 距离：{距离}米
   ...

（共 {返回数量} 条）
```

### 常见问题

**Q: 周边搜索和关键字搜索有什么区别？**

A: 周边搜索必须提供location参数，以该位置为中心搜索周边地点；关键字搜索可以通过query搜索任意位置的地点。

**Q: 搜索半径如何设置？**

A: 半径默认1000米，取值范围1-50000米。根据实际需求设置，过大可能返回过多结果，过小可能无结果。

**Q: 如何按POI类型筛选？**

A: 使用poiType参数指定POI类型，如"餐饮服务"、"住宿服务"等。
