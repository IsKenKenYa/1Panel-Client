# 地点详情 API

## 服务概述

根据地点的唯一主键地点ID（siteId）获取地点详情。地点详细信息请求返回有关指定地点的更全面的信息，如地点名称、地址详细信息、经纬度等。

- **版本**: 1.0
- **服务标识**: `searchById`
- **官方文档**: <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-site>

### 接口定义

**函数**: `searchById(params: SearchByIdParams): Promise<SearchByIdResult>`

**导入方式**:

```typescript
import { site } from '@kit.MapKit';
```

### 请求参数 (SearchByIdParams)

| 参数         | 类型      | 是否可选 | 描述      |
|------------|---------|------|---------|
| siteId     | string  | 否    | 地点唯一标识  |
| language   | string  | 是    | 返回语言    |
| isChildren | boolean | 是    | 是否返回子节点 |

### 响应结果 (SearchByIdResult)

| 字段   | 类型                         | 是否可选 | 描述     |
|------|----------------------------|------|--------|
| site | [Site](common.md#地点信息Site) | 否    | 地点详细信息 |

详细类型定义请参考 [Site类型](common.md#地点信息Site)。

### 代码示例

详情见 ../assets/searchByIdDemo.ets

### 常见问题

**Q: 如何获取大型场所的子区域信息？**

A: 设置isChildren=true参数，可以获取机场、商场等大型场所的子区域信息。

**Q: siteId从哪里获取？**

A: siteId可以从searchByText、nearbySearch、queryAutoComplete等API的响应结果中获取。

**Q: 地点已下架怎么办？**

A: 如果siteId对应的地点已下架或不存在，API会返回相应的错误码。
