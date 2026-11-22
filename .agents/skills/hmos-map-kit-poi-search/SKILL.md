---
name: hmos-map-kit-poi-search
description: >
  HarmonyOS Map Kit位置搜索与POI检索开发指南。当用户明确要求开发实现（如"编写代码"、"开发功能"等）位置搜索、POI检索、地理编码、逆地理编码等功能代码时触发。适用于直接调用本地SDK接口获取地图元素的场景。
  适用情形：关键字搜索地点、周边地点检索、地点详情查询、地址与坐标转换。
version: 1.0.0
license: MIT
homepage: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-site
---

# HarmonyOS Map Kit 位置搜索与POI检索开发指南

本技能提供华为地图Map Kit SDK的位置搜索与POI检索功能开发指南。

## 领域知识

位置搜索Skill覆盖关键字搜索、周边搜索、地理编码、逆地理编码等核心能力。

关键Note：
- **服务开通必须**：使用位置搜索功能前需开通地图服务，未开通将导致功能不可用
- **接口导入统一**：所有位置搜索接口均通过`@kit.MapKit`导出
- **异步处理必须**：所有接口返回Promise，必须使用async/await处理
- **异常捕获必须**：所有接口调用必须包裹try-catch捕获异常

扩展知识 → references/（可按需查阅）
- 关键字搜索参数 → references/text_search.md
- 周边搜索参数 → references/nearby_search.md
- 地理编码参数 → references/geocode.md

## 工具定义（Tools）

本Skill使用HarmonyOS Map Kit SDK提供的系统预置工具。

### 接口导入

```typescript
import { site } from '@kit.MapKit';
```

### 核心API

| API | 说明 | 返回类型 |
|-----|-----|---------|
| `site.searchByText()` | 关键字搜索 | Promise |
| `site.nearbySearch()` | 周边搜索 | Promise |
| `site.queryAutoComplete()` | 自动补全 | Promise |
| `site.searchById()` | 地点详情 | Promise |
| `site.geocode()` | 正地理编码 | Promise |
| `site.reverseGeocode()` | 逆地理编码 | Promise |

## 经验攻略（Exemplar Playbook）

| 用户输入 | 调用能力 | 要点（隐含推理）                         |
|---------|---------|----------------------------------|
| 搜索附近的餐厅 | nearbySearch | "附近"→需要先获取当前位置坐标               |
| 查找北京市的医院 | searchByText | 设置cityId限制城市范围                |
| 将地址转换为坐标 | geocode | 入参必须是完整结构化地址                  |
| 获取坐标对应的地址 | reverseGeocode | 入参必须是GCJ02坐标系                  |
| 查询某个地点的详细信息 | searchById | 必须先通过搜索获取siteId              |
| 输入时显示联想词 | queryAutoComplete | 与搜索服务搭配使用，仅提供输入提示         |

## 操作规程（SOP）

以下链路**必须**严格按序执行，任何步骤不可跳过。

### SOP-1：关键字搜索地点
用户搜索某类地点或确定地点，不涉及特定位置周边
  ↓
提取搜索关键词 ← [检查门] 从用户输入中解析关键词
  ↓
设置城市限制参数 ← [参数门] 可选cityId、isCityLimit
  ↓
调用`site.searchByText()`发送请求 ← [执行门]
  ↓
格式化返回结果 ← [输出门] 提取siteId、名称、地址、坐标等
  ↓
捕获异常并反馈 ← [回滚门] 搜索失败时记录错误码

### SOP-2：周边地点搜索
用户同时包含「位置」和「搜索类别」两个要素
  ↓
解析用户输入 ← [检查门] 拆分位置和搜索类别
  ↓
获取位置坐标 ← [转换门] 如位置是地名，调用geocode获取坐标
  ↓
调用`site.nearbySearch()`发送请求 ← [执行门]
  ↓
格式化返回结果 ← [输出门]

### SOP-3：地址与坐标互转
用户提供完整地址需转坐标，或提供坐标需转地址
  ↓
判断编码类型 ← [检查门] 正地理编码(地址→坐标)或逆地理编码(坐标→地址)
  ↓
调用对应接口 ← [执行门] geocode或reverseGeocode
  ↓
格式化返回结果 ← [输出门]
  ↓
捕获异常并反馈 ← [回滚门]

## 安全红线

1. **禁止**直接调用接口而不捕获异常，必须包裹try-catch
2. **禁止**在代码中添加skill中未给出的字段
3. **禁止**使用公共知识库或自行预设的坐标值，必须通过API获取
4. **禁止**将POI名称作为正地理编码入参，应使用searchByText
5. **禁止**混用WGS84和GCJ02坐标系，GPS坐标需先转换后方可使用
6. **禁止**跳过服务开通检查：使用前必须确认用户已开通华为地图服务

## 与人协作

| 场景 | 策略 | 范例 |
|-----|-----|-----|
| 指定位置但范围模糊 | 追问半径大小 | 用户说"在国贸附近找餐厅"→询问"搜索范围是300米、500米还是1公里？" |
| 结果需求不明确 | 追问只要地点还是要详情 | 用户说"查一下这个地方"→询问"只需要地点列表，还是需要详细信息如电话、营业时间？" |


## 快速参考

- `references/text_search.md` - 关键字搜索
- `references/nearby_search.md` - 周边搜索
- `references/detail_search.md` - 地点详情
- `references/query_autocomplete.md` - 自动补全
- `references/geocode.md` - 正地理编码
- `references/reverse_geocode.md` - 逆地理编码
- `references/common.md` - 通用常量
- `references/appLinking.md` - AppLinking：跳转花瓣地图查看位置详情、导航等场景

### Demo示例代码

- `assets/appLinkingDemo.md` - AppLinking示例
- `assets/geocodeDemo.md` - 正地理编码示例
- `assets/nearbySearchDemo.md` - 周边搜索示例
- `assets/queryAutoCompleteDemo.md` - 自动补全示例
- `assets/reverseGeocodeDemo.md` - 逆地理编码示例
- `assets/searchByIdDemo.md` - 地点详情示例
- `assets/searchByTextDemo.md` - 关键字搜索示例
