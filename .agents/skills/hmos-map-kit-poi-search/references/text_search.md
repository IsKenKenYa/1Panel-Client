# 关键字搜索

## 服务概述

通过关键字搜索地点。您可以提供关键字或指定要搜索的地点的类型来优化搜索结果。

- **版本**: 1.0
- **服务标识**: `searchByText`
- **官方文档**: <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-site>

### 接口定义

**函数**: `searchByText(params: SearchByTextParams): Promise<SearchByTextResult>`

**导入方式**:

```typescript
import { site } from '@kit.MapKit';
```

### 请求参数 (SearchByTextParams)

| 参数           | 类型                             | 是否可选 | 描述              |
|--------------|--------------------------------|------|-----------------|
| query        | string                         | 否    | 搜索关键字           |
| location     | [LatLng](common.md#latlng坐标对象) | 是    | 搜索结果偏向的经纬度      |
| radius       | number                         | 是    | 搜索半径（米），默认50000 |
| language     | string                         | 是    | 返回结果语言          |
| poiTypes     | Array\<string\>                | 是    | POI类型筛选         |
| countryCodes | Array\<string\>                | 是    | 国家码筛选           |
| cityId       | string                         | 是    | 城市编码            |
| isCityLimit  | boolean                        | 是    | 是否强限制在指定城市      |
| isChildren   | boolean                        | 是    | 是否返回子节点         |
| pageIndex    | number                         | 是    | 页码，默认1          |
| pageSize     | number                         | 是    | 每页数量，默认20，最大20  |

### 响应结果 (SearchByTextResult)

| 字段         | 类型                                  | 是否可选 | 描述   |
|------------|-------------------------------------|------|------|
| totalCount | number                              | 否    | 结果总数 |
| sites      | Array\<[Site](common.md#地点信息Site)\> | 否    | 地点列表 |

### 代码示例

详情见 ../assets/searchByTextDemo.ets

### 回复模板

```

🔍 已为你搜索「{关键词}」，找到 {totalCount} 条结果：

1. {地点名称}
   📍 地址：{格式化地址}
   ⭐ 评分：{评分}
   📏 距离：{距离}米

2. {地点名称}
   📍 地址：{格式化地址}
   ...

（共 {返回数量} 条，点击查看详情）


```

### 常见问题

**Q: 搜索结果如何排序？**

A: 搜索结果默认按照相关性排序，可通过location参数偏向某个位置，距离近的会优先返回。

**Q: 如何限制搜索城市？**

A: 使用cityId参数指定城市编码，设置isCityLimit=true强制限制在该城市内搜索。

**Q: 如何获取更多结果？**

A: 使用pageIndex和pageSize进行分页，每页最多20条，总共最多500条。
