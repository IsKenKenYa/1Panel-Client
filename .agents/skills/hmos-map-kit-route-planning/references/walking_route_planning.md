# 步行路线规划

## 服务概述

提供两点之间的步行路径规划能力，返回详细的路线信息、距离、耗时等。

- **版本**: 1.0
- **服务标识**: `getWalkingRoutes`
- **官方文档**: <https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-navi-api>

### 接口定义

**函数**: `navi.getWalkingRoutes(params: RouteParams): Promise<RouteResult>`

**导入方式**:

```typescript
import { navi } from '@kit.MapKit';
```

### 请求参数 (RouteParams)

| 参数          | 类型                               | 是否可选 | 描述     |
|-------------|----------------------------------|------|--------|
| origins     | [LatLng](common.md#latlng坐标对象)[] | 否    | 起点坐标数组 |
| destination | [LatLng](common.md#latlng坐标对象)   | 否    | 终点坐标   |
| language    | string                           | 是    | 返回结果语言 |
| avoids      | number[]                         | 是    | 避让选项   |
| extension   | number                           | 是    | 额外信息   |

#### avoids 避让选项

| 值 | 说明  |
|---|-----|
| 0 | 速度快 |

#### extension 额外信息

| 值 | 说明         |
|---|------------|
| 0 | 基础路况信息（默认） |
| 1 | 新增路况信息     |

### 响应结果 (RouteResult)

| 字段     | 类型                             | 是否可选 | 描述   |
|--------|--------------------------------|------|------|
| routes | [Route](common.md#路线信息Route)[] | 否    | 路线列表 |

### 代码示例

详情见 ../assets/walkingRouteDemo.ets

### 回复模板

```
🔗 步行路线规划结果：

起点: {起点名称} ({起点坐标})
终点: {终点名称} ({终点坐标})
距离: {距离}米 | 预计时间: {时间}分钟

🗺️ 在 Petal Maps 中查看:
[点击打开路线](https://www.petalmaps.com/routes?...)

原链接为 https://www.petalmaps.com/routes?
```

### 常见问题

**Q: 步行路线规划支持途经点吗？**

A: 步行路线规划不支持途经点，如需途经点请使用驾车路线规划。

**Q: 如何获取更精确的路线？**

A: 可以通过 extension 参数获取更详细的路线信息。
