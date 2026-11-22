# 自动补全 API

## 服务概述

获取自动补全结果。当用户输入部分查询时，返回可能的完整查询词列表，并高亮显示用户输入的匹配部分。

- **版本**: 1.0
- **服务标识**: `queryAutoComplete`
- **官方文档**: <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-site>

### 接口定义

**函数**: `queryAutoComplete(params: QueryAutoCompleteParams): Promise<QueryAutoCompleteResult>`

**导入方式**:

```typescript
import { site } from '@kit.MapKit';
```

### 请求参数 (QueryAutoCompleteParams)

| 参数          | 类型                             | 是否可选 | 描述              |
|-------------|--------------------------------|------|-----------------|
| query       | string                         | 否    | 查询关键字（最大512字符）  |
| location    | [LatLng](common.md#latlng坐标对象) | 是    | 搜索结果偏向的经纬度      |
| radius      | number                         | 是    | 搜索半径（米），默认50000 |
| language    | string                         | 是    | 搜索结果返回的语言       |
| poiTypes    | Array\<string\>                | 是    | POI类型筛选         |
| cityId      | string                         | 是    | 城市编码            |
| isCityLimit | boolean                        | 是    | 是否限制在城市内        |
| isChildren  | boolean                        | 是    | 是否返回子节点         |

### 响应结果 (QueryAutoCompleteResult)

| 字段    | 类型                                  | 是否可选 | 描述       |
|-------|-------------------------------------|------|----------|
| sites | Array\<[Site](common.md#地点信息Site)\> | 否    | 自动补全结果列表 |

详细类型定义请参考 [Site类型](common.md#地点信息Site)。

### 代码示例

详情见 ../assets/queryAutoCompleteDemo.ets

### 常见问题

**Q: 自动补全和搜索建议有什么区别？**

A: 自动补全返回的是匹配的地点列表（Site对象），每个结果都包含完整的地点信息；搜索建议返回的是独立的查询词列表。

**Q: 如何获取更精确的建议？**

A: 提供location参数可以让结果偏向用户当前位置；使用cityId限制城市可以提高准确性。
