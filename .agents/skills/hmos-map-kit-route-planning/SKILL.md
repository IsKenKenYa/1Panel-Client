---
name: hmos-map-kit-route-planning
description: >
  HarmonyOS Map Kit路径规划开发指南。
  适用情形：用户明确要求开发实现（如"编写代码"、"开发功能"等）路径规划、批量算路、轨迹纠偏等功能代码时触发。
version: 1.0.0
license: MIT
homepage: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-navi-api
---

# HarmonyOS Map Kit 路径规划开发指南

本技能提供华为地图Map Kit SDK的路径规划功能开发指南。

## 领域知识

路径规划Skill覆盖驾车、步行、骑行、公共交通路线规划、批量算路、轨迹纠偏等核心能力。

关键Note：
- **服务开通必须**：使用路径规划功能前需开通地图服务，未开通将导致功能不可用
- **接口导入统一**：所有路径规划接口均通过`@kit.MapKit`导出
- **异步处理必须**：所有接口返回Promise，必须使用async/await处理
- **异常捕获必须**：所有接口调用必须包裹try-catch捕获异常

扩展知识 → references/（可按需查阅）
- 驾车路线规划参数 → references/driving_route_planning.md
- 批量算路参数 → references/driving_navi_matrix.md
- 轨迹纠偏参数 → references/snap_to_roads.md

## 工具定义（Tools）

本Skill使用HarmonyOS Map Kit SDK提供的系统预置工具。

### 接口导入

```typescript
import { navi } from '@kit.MapKit';
```

### 核心API

| API | 说明 | 返回类型 |
|-----|-----|---------|
| `navi.getWalkingRoutes()` | 步行路线规划 | Promise |
| `navi.getCyclingRoutes()` | 骑行路线规划 | Promise |
| `navi.getDrivingRoutes()` | 驾车路线规划 | Promise |
| `navi.getTransitRoutes()` | 公共交通路线 | Promise |
| `navi.getWalkingMatrix()` | 步行批量算路 | Promise |
| `navi.getCyclingMatrix()` | 骑行批量算路 | Promise |
| `navi.getDrivingMatrix()` | 驾车批量算路 | Promise |
| `navi.snapToRoads()` | 轨迹纠偏 | Promise |

## 经验攻略（Exemplar Playbook）

| 用户输入      | 调用能力             | 要点（隐含推理）           |
|-----------|------------------|--------------------|
| 从A到B步行怎么走 | getWalkingRoutes | 必须获取起点终点坐标         |
| 开车去某地最优路线 | getDrivingRoutes | 默认时间最短策略           |
| 找最近的骑手配送  | getDrivingMatrix | 多点批量算路取最近          |
| 规划多个配送点路线 | getDrivingMatrix | origins多个，批量计算距离矩阵 |
| 优化GPS轨迹   | snapToRoads      | 轨迹点需按时间排序          |

## 操作规程（SOP）

以下链路**必须**严格按序执行，任何步骤不可跳过。

### SOP-1：路线规划
用户要求规划从A到B的路线（步行/骑行/驾车）
  ↓
解析起点终点 ← [检查门] 从用户输入提取起点终点，地名需调用searchByText转坐标
  ↓
确定出行方式 ← [参数门] 步行getWalkingRoutes/骑行getCyclingRoutes/驾车getDrivingRoutes
  ↓
调用路线规划API ← [执行门]
  ↓
格式化返回结果 ← [输出门] 提取路线距离、时间、途经点等
  ↓
捕获异常并反馈 ← [回滚门] 规划失败时记录错误码

### SOP-2：批量算路
用户要求计算多点之间的距离矩阵
  ↓
收集起终点坐标 ← [检查门] 所有地名需先转坐标
  ↓
调用批量算路API ← [执行门] getWalkingMatrix/getCyclingMatrix/getDrivingMatrix
  ↓
格式化返回结果 ← [输出门] 提取距离矩阵、时间矩阵
  ↓
捕获异常并反馈 ← [回滚门]

### SOP-3：轨迹纠偏
用户要求将GPS轨迹匹配到道路
  ↓
收集轨迹点 ← [检查门] 按时间排序，需包含时间戳
  ↓
调用snapToRoads ← [执行门]
  ↓
格式化返回结果 ← [输出门] 提取纠偏后轨迹点
  ↓
捕获异常并反馈 ← [回滚门]

## 安全红线

1. **禁止**直接调用接口而不捕获异常，必须包裹try-catch
2. **禁止**在代码中添加skill中未给出的字段
3. **禁止**使用公共知识库或自行预设的坐标值，必须通过API获取
4. **禁止**混用WGS84和GCJ02坐标系，GPS坐标需先转换后方可使用
5. **禁止**跳过服务开通检查：使用前必须确认用户已开通华为地图服务

## 与人协作

| 场景          | 策略             | 范例                                     |
|-------------|----------------|----------------------------------------|
| 为指定起点       | 追问是否按照当前位置作为起点 | 用户说"帮我规划去某地的路线"→追问起点是否选取用户当前位置         |
| 出行方式未指定     | 追问交通方式驾车/骑行/不行 | 用户说"从A到B怎么去"→追问用户具体的出行方式               |
| 批量算路点数未知    | 追问具体数量或提供列表    | 用户说"计算多点距离"→询问"请问有多少个起点和终点？"           |


## 快速参考

### 路线规划

- `references/driving_route_planning.md` 驾车路线规划：提供两点之间驾车路径规划能力
- `references/walking_route_planning.md` 步行路线规划：提供两点之间步行路径规划能力
- `references/bicycling_route_planning.md` 骑行路线规划：提供两点之间骑行路径规划能力

### 批量算路

- `references/driving_navi_matrix.md`  提供多点之间驾车路径规划功能
- `references/walking_navi_matrix.md`  提供多点之间步行路径规划功能
- `references/bicycling_navi_matrix.md`  提供多点之间骑行路径规划功能

### 轨迹纠偏

- `references/snap_to_roads.md` 用于将用户行车轨迹上的坐标点匹配到道路上

### 基础概念

- `references/common.md` - 通用常量：错误码、状态码
- `references/appLinking.md` - AppLinking：跳转花瓣地图查看位置详情、导航等场景

### Demo示例代码

- `assets/appLinkingDemo.md` - AppLinking代码示例
- `assets/walkingRouteDemo.ts` - 步行路线规划示例
- `assets/cyclingRouteDemo.ts` - 骑行路线规划示例
- `assets/drivingRouteDemo.ts` - 驾车路线规划示例
- `assets/transitRouteDemo.ts` - 公共交通路线规划示例
- `assets/walkingMatrixDemo.ts` - 步行批量算路示例
- `assets/cyclingMatrixDemo.ts` - 骑行批量算路示例
- `assets/drivingMatrixDemo.ts` - 驾车批量算路示例
- `assets/snapToRoadsDemo.ts` - 轨迹纠偏示例



