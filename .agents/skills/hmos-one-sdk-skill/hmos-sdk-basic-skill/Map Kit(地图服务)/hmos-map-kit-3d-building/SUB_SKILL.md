---
name: hmos-map-kit-3d-building
description: 在地图上绘制自定义3D建筑模型，支持设置建筑形状、高度、颜色、纹理、选中楼层及升起动画，API版本≥5.0.0(12)，建筑高度≤30000米，坐标点≥3个顺时针排列，适用于楼盘展示、城市建筑可视化、导航定位、旅游导览场景
---

# 3D建筑绘制技能

## 功能描述

本技能提供在HarmonyOS地图上绘制3D建筑模型的完整实现方案。通过BuildingOverlayParams配置建筑参数，使用MapComponentController的addBuildingOverlay方法添加建筑，支持自定义建筑的：

- **形状**：通过坐标点集合定义建筑底面轮廓（至少3个点，顺时针排列）
- **高度**：设置建筑总高度和选中楼层高度（最大30000米）
- **颜色**：配置顶部、侧面、选中楼层的颜色（ARGB格式）
- **纹理**：为建筑侧面和选中楼层添加纹理贴图
- **动画**：设置选中楼层从底部升起的动画时长
- **显示控制**：设置建筑开始显示的地图缩放层级（2-20级）

建筑仅在缩放级别达到showLevel时显示3D效果，支持动态更新属性和移除操作。

## 使用场景

### 触发词
- "绘制3D建筑"
- "添加建筑模型"
- "显示楼盘三维效果"
- "地图上添加建筑物"
- "创建立体建筑"

### 能做
- 在地图上绘制单个或多个3D建筑模型
- 自定义建筑的几何形状、颜色和纹理
- 设置建筑的显示层级和动画效果
- 动态更新建筑的可见性、楼层高度等属性
- 移除已添加的建筑模型
- 配置选中楼层的升起动画

### 绝不做
- 不处理建筑底面坐标少于3个点的情况
- 不支持逆时针排列的坐标点（会导致渲染异常）
- 不处理高度超过30000米的建筑
- 不在API版本低于5.0.0(12)的环境中使用
- 不在缩放级别低于showLevel时强制显示建筑

### 补充
- 建筑坐标点必须按顺时针方向排列形成闭合平面
- 纹理图片需存放在resources/base/media目录下，使用$r("app.media.xxx")引用
- 建筑显示需要地图缩放至指定层级（showLevel）
- 建筑侧面和选中楼层可独立控制显示/隐藏
- 动画时长最小值为100ms，小于100ms按默认值处理

## 调用规范和规则

### 输入约束
- **坐标点数量**：最少3个点，建议不超过100个点以保证渲染性能
- **坐标点排列**：必须按顺时针方向连接形成完整平面
- **纬度范围**：[-90, 90]
- **经度范围**：[-180, 180]
- **建筑高度**：1-30000米（totalHeight）
- **楼层高度**：0-totalHeight米（floorBottomHeight）
- **颜色格式**：ARGB格式（0xAARRGGBB），如0xffa4b8f7
- **缩放层级**：2-20（showLevel）
- **动画时长**：≥100ms（animationDuration）
- **纹理尺寸**：建议宽高≥3米

### 执行约束
- **API调用时机**：必须在MapComponent初始化回调成功后调用
- **地图缩放**：需将地图镜头移动到建筑区域并设置合适的tilt角度（建议70度）
- **坐标顺序**：points数组需使用reverse()方法反转（原始数据为逆时针）
- **错误处理**：使用try-catch捕获addBuildingOverlay可能的异常

### 内容约束
- **禁止内容**：
  - 禁止使用少于3个坐标点创建建筑
  - 禁止使用逆时针排列的坐标点
  - 禁止设置高度超过30000米
  - 禁止在API版本<5.0.0(12)时调用
  
- **禁止高危操作**：
  - 禁止直接使用用户输入的坐标未经校验
  - 禁止在地图未初始化时调用addBuildingOverlay
  - 禁止使用非法的颜色值（非ARGB格式）

### 降级约束
- **网络失败**：建筑绘制不依赖网络，无需降级
- **坐标点不足**：提示用户至少提供3个坐标点
- **高度超限**：提示用户高度限制为30000米，自动调整为最大值
- **API版本不兼容**：提示用户需要API版本≥5.0.0(12)
- **纹理加载失败**：降级使用默认颜色渲染，不使用纹理

## 调用流程和步骤

### 步骤1：导入模块和初始化地图

**前置校验**：
1. 确认API版本≥5.0.0(12)
2. 确认已导入@kit.MapKit模块
3. 确认已导入@kit.BasicServicesKit模块（AsyncCallback）

**参数准备**：
```typescript
import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

// 地图初始化参数
let mapOptions: mapCommon.MapOptions = {
  position: {
    target: {
      latitude: 31.984794,
      longitude: 118.765865
    },
    zoom: 18
  },
  scaleControlsEnabled: true
};

// 地图控制器和回调
private mapController?: map.MapComponentController;
private callback?: AsyncCallback<map.MapComponentController>;
```

### 步骤2：准备建筑坐标数据

**坐标点校验**：
1. 确认坐标点数量≥3个
2. 确认坐标点按顺时针方向排列（代码中使用reverse()方法转换）
3. 确认纬度在[-90, 90]范围内
4. 确认经度在[-180, 180]范围内

**示例代码**：
```typescript
// 3D建筑底面坐标集合（逆时针数据，需reverse）
let points: Array<mapCommon.LatLng> = [
  { latitude: 31.984794, longitude: 118.765865 },
  { latitude: 31.98468, longitude: 118.766076 },
  { latitude: 31.98472, longitude: 118.766116 },
  { latitude: 31.98463, longitude: 118.766292 },
  { latitude: 31.984586, longitude: 118.766251 },
  { latitude: 31.984536, longitude: 118.766344 },
  // ... 更多坐标点
  { latitude: 31.984794, longitude: 118.765865 } // 闭合点
];

// 反转为顺时针方向
points.reverse();

// 校验坐标点数量
if (points.length < 3) {
  console.error('建筑坐标点数量不足，至少需要3个点');
  return;
}
```

### 步骤3：配置建筑参数

**参数配置**：
```typescript
let buildingOverlayParams: mapCommon.BuildingOverlayParams = {
  // 建筑底面坐标（顺时针）
  points: points,
  
  // 建筑总高度（单位：米，最大30000）
  totalHeight: 51,
  
  // 选中楼层底部高度（单位：米）
  floorBottomHeight: 33,
  
  // 建筑顶部颜色（ARGB格式）
  topFaceColor: 0xffa4b8f7,
  
  // 建筑侧面颜色（ARGB格式）
  sideFaceColor: 0x44a4b8f7,
  
  // 选中楼层颜色（ARGB格式）
  floorColor: 0xff000000,
  
  // 建筑开始显示的缩放层级（2-20）
  showLevel: 14,
  
  // 选中楼层升起动画时长（单位：ms，最小100）
  animationDuration: 5000,
  
  // 建筑侧面纹理（需准备纹理图片）
  sideTexture: { 
    image: $r("app.media.side_tex"), 
    height: 3, 
    width: 3 
  },
  
  // 选中楼层纹理（需准备纹理图片）
  floorTexture: { 
    image: $r("app.media.floor_tex"), 
    height: 3, 
    width: 3 
  }
};
```

### 步骤4：移动相机并添加建筑

**执行添加**：
```typescript
// 移动相机到建筑区域
let cameraUpdate = map.newCameraPosition({
  target: {
    latitude: 31.984794,
    longitude: 118.765865
  },
  zoom: 18,
  tilt: 70 // 建议倾斜角度70度以展示3D效果
});

this.mapController?.moveCamera(cameraUpdate);

// 添加3D建筑（异步操作）
try {
  let buildingOverlay: map.BuildingOverlay = 
    await this.mapController?.addBuildingOverlay(buildingOverlayParams);
  
  console.info('3D建筑添加成功，ID:', buildingOverlay.getId());
} catch (error) {
  console.error('添加3D建筑失败:', error.code, error.message);
  
  // 错误处理
  if (error.code === 401) {
    console.error('参数校验失败，请检查坐标点和参数格式');
  } else if (error.code === 1002601001) {
    console.error('地图控制器不存在，请确认地图已初始化');
  }
}
```

### 步骤5：动态更新建筑属性

**属性更新示例**：
```typescript
// 更新楼层底部高度
buildingOverlay.setFloorBottomHeight(80);

// 控制侧面和顶部显示
buildingOverlay.setSideVisible(true);

// 控制选中楼层显示
buildingOverlay.setFloorVisible(true);

// 移除建筑
buildingOverlay.remove();
```

### 步骤6：错误处理和降级

**完整错误处理**：
```typescript
// 坐标点校验
function validatePoints(points: Array<mapCommon.LatLng>): boolean {
  if (points.length < 3) {
    console.warn('坐标点不足，至少需要3个点');
    return false;
  }
  
  for (let point of points) {
    if (point.latitude < -90 || point.latitude > 90) {
      console.warn('纬度超出范围:', point.latitude);
      return false;
    }
    if (point.longitude < -180 || point.longitude >= 180) {
      console.warn('经度超出范围:', point.longitude);
      return false;
    }
  }
  
  return true;
}

// 高度校验和降级
function validateHeight(height: number): number {
  const MAX_HEIGHT = 30000;
  if (height > MAX_HEIGHT) {
    console.warn('高度超限，调整为最大值:', MAX_HEIGHT);
    return MAX_HEIGHT;
  }
  if (height <= 0) {
    console.warn('高度无效，调整为默认值: 10');
    return 10;
  }
  return height;
}

// 降级处理：无纹理时使用默认颜色
function createBuildingParams(
  points: Array<mapCommon.LatLng>,
  options: Partial<mapCommon.BuildingOverlayParams>
): mapCommon.BuildingOverlayParams {
  const defaultParams: mapCommon.BuildingOverlayParams = {
    points: points,
    totalHeight: validateHeight(options.totalHeight || 10),
    floorBottomHeight: options.floorBottomHeight || 0,
    topFaceColor: options.topFaceColor || 0xffff0000,
    sideFaceColor: options.sideFaceColor || 0xffff0000,
    floorColor: options.floorColor || 0xffff0000,
    showLevel: options.showLevel || 15,
    animationDuration: options.animationDuration || 0
  };
  
  // 如果提供了纹理，添加纹理配置
  if (options.sideTexture) {
    defaultParams.sideTexture = options.sideTexture;
  }
  if (options.floorTexture) {
    defaultParams.floorTexture = options.floorTexture;
  }
  
  return defaultParams;
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数校验失败 | 检查points数组长度≥3，坐标范围正确，高度≤30000米，颜色为ARGB格式 |
| 1002601001 | 地图控制器不存在 | 确认MapComponent已成功初始化，在回调中获取mapController |
| INVALID_COORDINATES | 坐标点排列错误 | 使用points.reverse()将逆时针转为顺时针，或手动调整坐标顺序 |
| HEIGHT_EXCEEDED | 高度超过限制 | 将totalHeight调整为≤30000米 |
| API_VERSION_ERROR | API版本不兼容 | 确认设备API版本≥5.0.0(12)，在低版本设备上提示用户升级 |
| TEXTURE_LOAD_FAILED | 纹理加载失败 | 检查纹理图片路径是否正确，确认图片存放在resources/base/media目录 |
| SHOW_LEVEL_INVALID | 显示层级无效 | 调整showLevel在[2, 20]范围内 |

## 编译和修复问题

### 依赖声明

**oh-package.json5**：
```json
{
  "dependencies": {
    "@kit.MapKit": "^5.0.0",
    "@kit.BasicServicesKit": "^5.0.0"
  }
}
```

### 环境要求
- **HarmonyOS API版本**：≥5.0.0(12)
- **DevEco Studio版本**：≥5.0.0
- **ArkTS编译器**：支持ArkTS语法

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.MapKit'
```
**解决方法**：
- 确认oh-package.json5中已声明@kit.MapKit依赖
- 运行`ohpm install`安装依赖
- 确认DevEco Studio版本≥5.0.0

**问题2：API版本不兼容**
```
Error: BuildingOverlayParams is not available in API version < 5.0.0(12)
```
**解决方法**：
- 在module.json5中配置minAPIVersion为12
- 使用条件编译检查API版本：
```typescript
if (canIUse('SystemCapability.Map.Core')) {
  // 使用BuildingOverlayParams
} else {
  console.warn('当前设备不支持3D建筑功能');
}
```

**问题3：纹理资源引用错误**
```
Error: Cannot resolve resource $r("app.media.side_tex")
```
**解决方法**：
- 确认纹理图片存放在resources/base/media目录
- 确认图片文件名为side_tex.png（或其他支持的格式）
- 使用正确的资源引用格式：$r("app.media.文件名")

**问题4：坐标点反转后渲染异常**
```
渲染出现空洞或建筑形状不正确
```
**解决方法**：
- 原始坐标点需按逆时针提供（建筑外部轮廓）
- 使用points.reverse()转为顺时针
- 确认最后一个坐标点与第一个坐标点相同（闭合）

## 常见问题与解决方法

### Q1：建筑不显示或显示不正确
**原因**：
- 地图缩放层级未达到showLevel
- 坐标点排列方向错误（逆时针）
- 建筑高度设置过低或过高

**解决方法**：
- 将地图缩放至showLevel指定的层级（如showLevel=14时，zoom需≥14）
- 使用points.reverse()反转坐标顺序
- 检查totalHeight和floorBottomHeight设置是否合理
- 设置地图tilt角度（建议70度）以展示3D效果

### Q2：选中楼层升起动画不执行
**原因**：
- animationDuration设置过小（<100ms）
- floorBottomHeight设置过高，导致楼层超出建筑顶部
- setFloorVisible未设置为true

**解决方法**：
- 设置animationDuration≥100ms（建议5000ms）
- 确保floorBottomHeight < totalHeight
- 调用setFloorVisible(true)显示选中楼层

### Q3：纹理不显示或显示异常
**原因**：
- 纹理图片路径错误
- 纹理图片格式不支持
- 纹理宽高设置过小

**解决方法**：
- 确认图片存放在resources/base/media目录
- 使用支持的格式：jpg、jpeg、png、gif、webp、svg
- 设置纹理宽高≥3米
- 使用正确的资源引用：$r("app.media.文件名")

### Q4：建筑颜色显示不正确
**原因**：
- 颜色值格式错误（未使用ARGB格式）
- 颜色透明度设置不当

**解决方法**：
- 使用ARGB格式：0xAARRGGBB（如0xffa4b8f7）
- AA为透明度（00完全透明，ff完全不透明）
- 检查topFaceColor、sideFaceColor、floorColor设置

### Q5：添加建筑时抛出异常
**原因**：
- 地图控制器未初始化
- 参数校验失败（坐标点不足、高度超限等）
- API版本不兼容

**解决方法**：
- 在MapComponent回调成功后调用addBuildingOverlay
- 使用try-catch捕获异常并处理错误码
- 校验坐标点数量≥3、高度≤30000米
- 确认API版本≥5.0.0(12)

### Q6：建筑遮挡其他地图元素
**原因**：
- 建筑zIndex设置过高
- 多个建筑叠加顺序不当

**解决方法**：
- 调整建筑的添加顺序（后添加的建筑在上层）
- 使用setSideVisible(false)隐藏建筑侧面
- 使用remove()移除不需要的建筑

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "buildingId": "unique_building_id",
  "buildingParams": {
    "pointsCount": 31,
    "totalHeight": 51,
    "floorBottomHeight": 33,
    "showLevel": 14,
    "animationDuration": 5000
  },
  "cameraPosition": {
    "latitude": 31.984794,
    "longitude": 118.765865,
    "zoom": 18,
    "tilt": 70
  },
  "apiUsed": [
    "BuildingOverlayParams",
    "addBuildingOverlay",
    "BuildingOverlay",
    "MapComponent",
    "MapComponentController",
    "newCameraPosition",
    "moveCamera"
  ]
}
```

## 参考文档

- [API开发指南：3D建筑](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/map-3dbuilding)
- [API参考：BuildingOverlayParams](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-common)
- [API参考：BuildingOverlay](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-buildingoverlay)
- [API参考：MapComponentController](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-mapcomponentcontroller)

## 完整示例代码

- [ArkTS完整示例](assets/BuildingOverlayDemo.ets)

## 测试用例

### 正向测试用例
- [添加标准3D建筑](tests/test_standard_building.ets)：使用31个坐标点、高度51米、完整纹理配置
- [添加最小建筑](tests/test_minimal_building.ets)：使用3个坐标点、最小参数配置
- [添加多个建筑](tests/test_multiple_buildings.ets)：在地图上添加多个不同形状的建筑

### 边界测试用例
- [高度边界测试](tests/test_height_boundary.ets)：测试高度1米和30000米的建筑
- [缩放层级边界](tests/test_zoom_level.ets)：测试showLevel=2和20的情况
- [动画时长边界](tests/test_animation_duration.ets)：测试animationDuration=100ms和10000ms

### 异常测试用例
- [坐标点不足测试](tests/test_insufficient_points.ets)：测试少于3个坐标点的错误处理
- [高度超限测试](tests/test_exceeded_height.ets)：测试高度>30000米的降级处理
- [无效颜色测试](tests/test_invalid_color.ets)：测试非ARGB格式颜色的处理
- [纹理加载失败测试](tests/test_texture_failure.ets)：测试纹理路径错误时的降级方案