# 地点搜索建议 API

## 服务概述

获取查询建议。当用户输入部分查询时，返回可能的完整查询词列表，帮助用户快速找到目标地点。

- **版本**: 1.0
- **服务标识**: `querySuggestion`
- **官方文档**: <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-site>

### 说明

本SDK中搜索建议功能通过`queryAutoComplete`接口实现，该接口返回匹配的地点列表和建议词。

### 接口定义

**函数**: `queryAutoComplete(params: QueryAutoCompleteParams): Promise<QueryAutoCompleteResult>`

**导入方式**:

```typescript
import { site } from '@kit.MapKit';
```

### 请求参数 (QueryAutoCompleteParams)

| 参数          | 是否必选 | 类型                             | 描述              | 示例                                          |
|-------------|------|--------------------------------|-----------------|---------------------------------------------|
| query       | 是    | string                         | 查询关键字（最大512字符）  | "海底捞"                                       |
| location    | 否    | [LatLng](common.md#latlng坐标对象) | 搜索结果偏向的经纬度      | {longitude: 116.397428, latitude: 39.90923} |
| radius      | 否    | number                         | 搜索半径（米），默认50000 | 10000                                       |
| cityId      | 否    | string                         | 城市编码            | "110000"                                    |
| isCityLimit | 否    | boolean                        | 是否限制在城市内        | true                                        |
| language    | 否    | string                         | 返回语言            | "zh_CN"                                     |
| poiTypes    | 否    | Array\<string\>                | POI类型筛选         | ["餐饮服务"]                                    |

### 响应结果 (QueryAutoCompleteResult)

| 字段    | 类型                                  | 描述      |
|-------|-------------------------------------|---------|
| sites | Array\<[Site](common.md#地点信息Site)\> | 建议的地点列表 |

详细类型定义请参考 [Site类型](common.md#地点信息Site) 和 [LatLng类型](common.md#latlng坐标对象)。

### 代码示例

详情见 ../assets/queryAutoCompleteDemo.ets

### 常见问题

**Q: querySuggestion和queryAutoComplete有什么区别？**

A: querySuggestion返回完整的查询建议词列表和对应的地点列表；queryAutoComplete更侧重于输入联想，返回的sites包含完整的地点信息。

**Q: 如何限制建议的城市？**

A: 使用cityId参数指定城市，设置isCityLimit=true强制限制。
