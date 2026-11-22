# Petal Maps AppLinking 技术指南

## 概述

AppLinking 是 Petal Maps 提供的深度链接技术，允许开发者通过特定的 URI 格式直接拉起 Petal Maps 应用并执行相应操作。本指南详细介绍了所有支持的 AppLinking 场景及其 URI 构造方法。

## 基本实现方式

### 获取 bundleName

`utm_source` 参数值需要动态获取当前应用的包名：

```typescript
import { common } from '@kit.AbilityKit';

let bundleName = 'mapSkill';
const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
if (context.applicationInfo && context.applicationInfo.name) {
  bundleName = context.applicationInfo.name;
}
```

### 坐标系类型
- **国内站点**：中国大陆、中国香港和中国澳门使用 **GCJ02** 坐标系，中国台湾使用 **WGS84** 坐标系
- **海外站点**：统一使用 **WGS84** 坐标系
- **参数说明**：
  - `coordinateType`: 0-WGS84，1-GCJ02，默认 GCJ02


## 支持的场景类型

### 1. 拉起 Petal 地图首页

**URI 格式：**
```
https://www.petalmaps.com?utm_source=${bundleName}
```

**参数配置：**
- `utm_source` (必填)：接入方业务名或包名，即应用的 bundleName

**代码示例：**
```typescript
const uri = `https://www.petalmaps.com?utm_source=${bundleName}`;
```

### 2. 拉起 Petal 地图查看位置详情

**URI 格式：**
```
https://www.petalmaps.com/place?z=16&marker=纬度,经度&placeId=位置ID&utm_source=${bundleName}
```

**参数配置：**
- `utm_source` (必填)：接入方业务名或包名，即应用的 bundleName
- `marker` (必填)：位置经纬度，纬度在前，经度在后
- `placeId` (可选)：即该位置的siteId，有则优先使用
- `z` (可选)：层级范围 3~20 的整数
- `coordinateType` (可选)：坐标系类型，0-WGS84，1-GCJ02，默认 GCJ02

**代码示例：**
```typescript
// 基础用法
const uri1 = `https://www.petalmaps.com/place?marker=39.9042,116.4074&utm_source=${bundleName}`;

// 带层级和坐标类型
const uri2 = `https://www.petalmaps.com/place?z=12&marker=39.9042,116.4074&coordinateType=0&utm_source=${bundleName}`;

// 带位置 ID
const uri3 = `https://www.petalmaps.com/place?marker=39.9042,116.4074&placeId=12345&utm_source=${bundleName}`;
```


### 3. 拉起 Petal 地图查看路径规划

**URI 格式：**
```
https://www.petalmaps.com/routes?saddr=起点经纬度&daddr=终点经纬度&type=交通类型&utm_source=${bundleName}
```

**参数配置：**
- `utm_source` (必填)：Link 请求来源，即应用的 bundleName
- `saddr` (可选)：起点经纬度(纬度在前，经度在后)，默认取当前位置
- `daddr` (必填)：终点经纬度(纬度在前，经度在后)
- `type` (可选)：交通出行工具(drive/taxi/bus/walk/bicycle)，不填或错误格式默认驾车
- `coordinateType` (可选)：坐标系类型
- `originPoiId` (可选)：起点 POI ID
- `destinationPoiId` (可选)：终点 POI ID

**代码示例：**
```typescript
// 基础驾车路线规划
const uri1 = `https://www.petalmaps.com/routes?saddr=39.9042,116.4074&daddr=31.2304,121.4737&utm_source=${bundleName}`;

// 步行路线规划
const uri2 = `https://www.petalmaps.com/routes?saddr=39.9042,116.4074&daddr=31.2304,121.4737&type=walk&utm_source=${bundleName}`;

// 公交路线规划
const uri3 = `https://www.petalmaps.com/routes?saddr=39.9042,116.4074&daddr=31.2304,121.4737&type=bus&utm_source=${bundleName}`;
```

### 4. 拉起 Petal 地图发起导航

**URI 格式：**
```
https://www.petalmaps.com/navigation?saddr=起点经纬度&daddr=终点经纬度&type=交通类型&utm_source=${bundleName}
```


**参数配置：**
- `utm_source` (必填)：Link 请求来源，即应用的 bundleName
- `saddr` (可选)：起点经纬度(纬度在前，经度在后)
- `daddr` (必填)：终点经纬度(纬度在前，经度在后)
- `type` (可选)：交通出行工具(drive/bus/walk/bicycle)，不填或错误格式默认驾车，填 bus 停留在路线规划页面
- `coordinateType` (可选)：坐标系类型
- `originPoiId` (可选)：起点 POI ID
- `destinationPoiId` (可选)：终点 POI ID

**代码示例：**
```typescript
// 发起驾车导航
const uri1 = `https://www.petalmaps.com/navigation?saddr=39.9042,116.4074&daddr=31.2304,121.4737&utm_source=${bundleName}`;

// 发起步行导航
const uri2 = `https://www.petalmaps.com/navigation?saddr=39.9042,116.4074&daddr=31.2304,121.4737&type=walk&utm_source=${bundleName}`;

// 发起公交导航
const uri3 = `https://www.petalmaps.com/navigation?saddr=39.9042,116.4074&daddr=31.2304,121.4737&type=bus&utm_source=${bundleName}`;
```

### 5. 位置搜索

**URI 格式：**
```
https://www.petalmaps.com/search?q=搜索关键词&utm_source=${bundleName}
```

**参数配置：**
- `utm_source` (必填)：Link 请求来源，即应用的 bundleName
- `q` (必填)：位置名称

**代码示例：**
```typescript
// 搜索餐厅
const uri1 = `https://www.petalmaps.com/search?q=${encodeURIComponent('星巴克')}&utm_source=${bundleName}`;

// 搜索景点
const uri2 = `https://www.petalmaps.com/search?q=${encodeURIComponent('故宫博物院')}&utm_source=${bundleName}`;
```


## 技术要点

### 编码规范
1. **经纬度格式**：纬度在前，经度在后
2. **支持经纬度+名称的模式**：`纬度,经度(位置名称)`

### 特殊位置标识
1. **支持家(home)和公司(company)关键字**
2. **没有设置家或公司则拉起设置页**


## 注意事项

1. **坐标转换**：根据目标地区选择合适的坐标系，国内主要使用 GCJ02，海外使用 WGS84
2. **参数编码**：确保特殊字符和中文字符正确编码，使用 encodeURIComponent
3. **utm_source**：所有场景都需要提供 `utm_source` 参数，值需通过 `context.applicationInfo.name` 获取当前应用的 bundleName
4. **经纬度格式**：始终遵循纬度在前、经度在后的格式
5. **鸿蒙将支持在没有安装应用时，牵引用户到应用市场进行下载**

## 相关资源
- [通过AppLinking拉起Petal Maps鸿蒙应用APP](https://wiki.huawei.com/domains/66617/wiki/101245/WIKI202412185445545)
- [Petal Maps 开发者文档](https://developer.huawei.com/consumer/cn/service/josp/ag/index.html)
- [HarmonyOS 深度链接开发指南](https://developer.harmonyos.com/cn/docs/documentation/doc-references/js-apis-app-ability-context-0000001427584828)
