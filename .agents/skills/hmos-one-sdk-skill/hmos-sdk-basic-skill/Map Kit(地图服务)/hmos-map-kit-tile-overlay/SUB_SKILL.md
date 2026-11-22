---
name: hmos-map-kit-tile-overlay
description: 在地图上添加瓦片图层,支持在线下载和本地加载两种方式,瓦片分辨率256*256,建议最多添加10个图层,适用于商场室内地图、景区详情等自定义地图覆盖场景
---

# 瓦片图层技能

## 功能描述

瓦片图层(TileOverlay)支持在地图底图之上添加自有瓦片数据,包括在线下载和本地加载两种方式。瓦片图层可随地图的平移、缩放、旋转等操作做相应变换,仅位于底图之上,不遮挡其他图层。适用于开发者拥有某一区域的地图并希望使用此区域地图覆盖相应位置的华为地图,如商场室内信息、景区详情等。

从API版本5.0.3(15)开始支持瓦片图层功能,从6.0.0(20)开始支持瓦片数据缓存功能,从6.1.1(24)开始支持高层级复用低层级瓦片的规则。

## 使用场景

### 触发词
- "添加瓦片图层"
- "瓦片图层"
- "tile overlay"
- "自定义地图图层"
- "地图瓦片"
- "室内地图"
- "商场地图"
- "景区地图"

### 能做
- 添加在线瓦片图层(通过URL)
- 添加本地瓦片图层(通过自定义Provider)
- 配置瓦片图层透明度
- 开启瓦片图层淡入效果
- 配置磁盘缓存
- 清除瓦片缓存
- 设置高层级复用低层级瓦片规则
- 更新和查询瓦片图层属性

### 绝不做
- 不处理超出10个瓦片图层限制的场景
- 不处理瓦片分辨率非256*256的情况
- 不处理瓦片URL不包含{x}、{y}、{z}占位符的情况
- 不直接处理瓦片数据的生成或转换

### 补充
- 建议最多添加10个TileOverlay
- 瓦片分辨率必须是256*256
- 在线瓦片URL必须以http或https开头且包含{x}、{y}、{z}占位符
- 本地加载方式需开发者自行实现tileProvider方法
- 磁盘缓存路径必须配置且应用需要有写入权限

## 调用规范和规则

### 输入约束
- 瓦片URL格式: 必须以http或https开头,包含{x}、{y}、{z}占位符
- 瓦片数量: 最多10个瓦片图层
- 瓦片分辨率: 必须256*256像素
- 透明度范围: [0, 1], 0表示不透明, 1表示全透明
- 磁盘缓存大小: 默认20480KB,单位KB
- 磁盘缓存路径: 必须是有效的沙箱路径

### 执行约束
- 瓦片加载超时: 建议设置网络请求超时时间
- 磁盘缓存限制: 缓存大小不超过应用可用存储空间
- tileProvider方法: 必须返回Promise<ArrayBuffer>
- 瓦片数据格式: 必须是有效的图片字节数据

### 内容约束
- 禁止使用无效的瓦片URL
- 禁止使用非256*256分辨率的瓦片
- 禁止超出10个瓦片图层限制
- 禁止在无权限的路径创建缓存
- tileProvider禁止返回非ArrayBuffer数据

### 降级约束
- 网络失败: 使用本地缓存瓦片或显示空白
- 瓦片加载失败: 跳过该瓦片继续加载其他瓦片
- 缓存空间不足: 清除旧缓存或减小缓存大小
- tileProvider异常: 返回空ArrayBuffer并记录错误日志

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 确认地图组件已初始化完成
2. 确认MapComponentController已获取
3. 确认瓦片数据源准备完毕(在线URL或本地资源)
4. 确认应用权限配置正确(如需磁盘缓存需存储权限)

**参数准备**:
```typescript
import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

let mapOptions: mapCommon.MapOptions = {
  position: {
    target: {
      latitude: 31.98,
      longitude: 118.7
    },
    zoom: 7
  }
};

let mapController: map.MapComponentController | undefined;
let tileOverlay: map.TileOverlay | undefined;
```

### 步骤2: 添加在线瓦片图层

**示例代码**:
```typescript
let callback: AsyncCallback<map.MapComponentController> = async (err, controller) => {
  if (!err) {
    mapController = controller;
    
    let params: mapCommon.TileOverlayOptions = {
      tileUrl: 'https://example.com/tiles?x={x}&y={y}&z={z}',
      transparency: 0.5,
      fadeIn: true,
      diskCacheEnabled: true,
      diskCacheSize: 20480,
      diskCachePath: '/data/storage/el2/database'
    };
    
    try {
      tileOverlay = mapController?.addTileOverlay(params);
      console.info('TileOverlay added successfully');
    } catch (e) {
      console.error(`Failed to add TileOverlay, code:${e.code}, message:${e.message}`);
    }
  } else {
    console.error(`Failed to initialize map, code:${err.code}, message:${err.message}`);
  }
};
```

### 步骤3: 添加本地瓦片图层

**示例代码**:
```typescript
let callback: AsyncCallback<map.MapComponentController> = async (err, controller) => {
  if (!err) {
    mapController = controller;
    
    let tileOverlayOption: mapCommon.TileOverlayOptions = {
      tileProvider: tileProviderMethod,
      fadeIn: true,
      transparency: 0.5,
      visible: true
    };
    
    if (mapController !== undefined) {
      try {
        tileOverlay = mapController.addTileOverlay(tileOverlayOption);
        console.info('Local TileOverlay added successfully');
      } catch (e) {
        console.error(`Failed to add local TileOverlay, code:${e.code}, message:${e.message}`);
      }
    }
  }
};

function tileProviderMethod(x: number, y: number, z: number): Promise<ArrayBuffer> {
  return new Promise((resolve, reject) => {
    let tilePath = `tiles/${z}/${x}/${y}.png`;
    try {
      let tileData = loadLocalTile(tilePath);
      resolve(tileData);
    } catch (error) {
      console.error(`Failed to load tile at ${tilePath}`);
      resolve(new ArrayBuffer(0));
    }
  });
}

function loadLocalTile(path: string): ArrayBuffer {
  return new ArrayBuffer(0);
}
```

### 步骤4: 配置高层级复用低层级瓦片

**示例代码**:
```typescript
let params: mapCommon.TileOverlayOptions = {
  tileUrl: 'https://example.com/tiles?x={x}&y={y}&z={z}',
  diskCacheEnabled: true,
  diskCacheSize: 20480,
  diskCachePath: '/data/storage/el2/database',
  tileDataReuse: [2, 3, 4, 5, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7]
};

try {
  tileOverlay = mapController?.addTileOverlay(params);
} catch (e) {
  console.error(`Failed to add TileOverlay with reuse config, code:${e.code}, message:${e.message}`);
}
```

### 步骤5: 错误处理

**示例代码**:
```typescript
try {
  tileOverlay = mapController?.addTileOverlay(params);
} catch (error) {
  switch (error.code) {
    case 401:
      console.error('Invalid input parameter');
      break;
    case 1002601001:
      console.error('The object to be operated does not exist');
      break;
    default:
      console.error(`Unknown error: ${error.message}`);
  }
}
```

### 步骤6: 清理缓存

**示例代码**:
```typescript
aboutToDisappear(): void {
  if (tileOverlay) {
    tileOverlay.remove();
    tileOverlay.clearTileCache();
    tileOverlay.clearDiskCache();
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Invalid input parameter | 检查参数格式和取值范围 |
| 1002601001 | The object to be operated does not exist | 确认MapComponentController已初始化 |
| 网络错误 | 瓦片URL无法访问 | 检查URL有效性,使用本地缓存降级 |
| 缓存错误 | 磁盘缓存路径无效或无权限 | 检查路径权限,使用应用沙箱路径 |
| tileProvider异常 | 本地瓦片加载失败 | 检查瓦片文件路径和格式 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.MapKit": ">=5.0.3(15)",
    "@kit.BasicServicesKit": ">=4.1.0(11)"
  }
}
```

### 环境要求
- HarmonyOS API版本: >=5.0.3(15)
- Stage模型: 仅支持Stage模型
- 元服务支持: 从5.0.3(15)开始支持

### 常见编译问题

**问题1: 导入模块失败**
```
Cannot find module '@kit.MapKit'
```
**解决方法**: 确认项目API版本>=5.0.3(15),并在ohpm.json中配置依赖

**问题2: 类型错误**
```
Type 'TileOverlayParams' is not assignable to type 'TileOverlayOptions'
```
**解决方法**: 从6.0.0(20)版本开始使用TileOverlayOptions类型

**问题3: 缓存路径权限错误**
```
Failed to create disk cache at path
```
**解决方法**: 使用应用沙箱路径,如'/data/storage/el2/database'

## 常见问题与解决方法

### Q1: 瓦片不显示
**原因**: 瓦片URL格式错误或网络不可访问
**解决方法**:
- 检查URL是否包含{x}、{y}、{z}占位符
- 检查网络连接状态
- 开启磁盘缓存作为降级方案

### Q2: 本地瓦片加载失败
**原因**: tileProvider方法实现有误或瓦片文件不存在
**解决方法**:
- 确认tileProvider返回Promise<ArrayBuffer>
- 检查瓦片文件路径是否正确
- 确认瓦片文件格式为有效图片格式

### Q3: 缓存占用空间过大
**原因**: diskCacheSize设置过大或缓存未清理
**解决方法**:
- 减小diskCacheSize值
- 定期调用clearDiskCache清理缓存
- 在组件销毁时清理缓存

### Q4: 高层级瓦片加载缓慢
**原因**: 未配置高层级复用低层级瓦片规则
**解决方法**:
- 配置tileDataReuse参数
- 根据实际瓦片层级范围设置复用规则

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "tileOverlayId": "string",
  "transparency": 0.5,
  "fadeIn": true,
  "diskCacheEnabled": true,
  "diskCacheSize": 20480,
  "apiUsed": [
    "mapCommon.TileOverlayOptions",
    "map.MapComponentController.addTileOverlay",
    "map.TileOverlay"
  ]
}
```

## 参考文档

- [瓦片图层开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-tile)
- [TileOverlay API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-tileoverlay)
- [TileOverlayOptions API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [MapComponentController API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)

## 完整示例代码

- [在线瓦片图层示例](assets/tile_overlay_online.ets)
- [本地瓦片图层示例](assets/tile_overlay_local.ets)
- [瓦片缓存示例](assets/tile_overlay_cache.ets)
- [高层级复用示例](assets/tile_overlay_reuse.ets)

## 测试用例

### 正向测试用例
- [添加在线瓦片图层](tests/test_online_tile.ts): 测试在线URL方式添加瓦片图层
- [添加本地瓦片图层](tests/test_local_tile.ts): 测试tileProvider方式添加瓦片图层
- [配置缓存](tests/test_cache.ts): 测试磁盘缓存功能

### 边界测试用例
- [透明度边界值](tests/test_transparency_boundary.ts): 测试透明度取值范围[0,1]
- [瓦片数量限制](tests/test_tile_count_limit.ts): 测试最多10个瓦片图层
- [缓存大小边界](tests/test_cache_size_boundary.ts): 测试缓存大小配置

### 异常测试用例
- [无效URL](tests/test_invalid_url.ts): 测试不含占位符的URL
- [tileProvider异常](tests/test_provider_error.ts): 测试tileProvider返回异常
- [缓存路径无权限](tests/test_cache_path_error.ts): 测试无权限的缓存路径