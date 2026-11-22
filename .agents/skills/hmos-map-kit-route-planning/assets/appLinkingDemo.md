# AppLinking 调用示例

## 概述

AppLinking 允许通过拼接好的 URI 跳转到花瓣地图应用，执行查看位置详情、导航等操作。

## 调用方式

使用 `context.openLink` 接口调用 AppLinking：

```typescript
import { common } from '@kit.AbilityKit';

const TAG = 'AppLinkingDemo';

function getBundleName(context: common.UIAbilityContext): string {
  let bundleName = 'mapSkill';
  if (context.applicationInfo && context.applicationInfo.name) {
    bundleName = context.applicationInfo.name;
  }
  return bundleName;
}

async function openPetalMaps(uri: string): Promise<void> {
  const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  
  try {
    await context.openLink(uri, {
      appLinkingOnly: true
    });
    console.info(this.TAG, 'openLink succeed');
  } catch (err) {
    console.error(this.TAG, `openLink failed: code=${err.code}, message=${err.message}`);
  }
}
```

## 场景示例

### 1. 查看位置详情

```typescript
async function openPlaceDetail(latitude: number, longitude: number, placeId?: string): Promise<void> {
  const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  const bundleName = getBundleName(context);
  let uri = `https://www.petalmaps.com/place?marker=${latitude},${longitude}&utm_source=${bundleName}`;
  if (placeId) {
    uri += `&placeId=${placeId}`;
  }
  await openPetalMaps(uri);
}
```

### 2. 发起驾车导航

```typescript
async function startNavigation(startLat: number, startLng: number, endLat: number, endLng: number): Promise<void> {
  const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  const bundleName = getBundleName(context);
  const uri = `https://www.petalmaps.com/navigation?saddr=${startLat},${startLng}&daddr=${endLat},${endLng}&utm_source=${bundleName}`;
  await openPetalMaps(uri);
}
```

### 3. 发起步行导航

```typescript
async function startWalkNavigation(endLat: number, endLng: number): Promise<void> {
  const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  const bundleName = getBundleName(context);
  const uri = `https://www.petalmaps.com/navigation?daddr=${endLat},${endLng}&type=walk&utm_source=${bundleName}`;
  await openPetalMaps(uri);
}
```

### 4. 路径规划

```typescript
async function planRoute(startLat: number, startLng: number, endLat: number, endLng: number, type: string = 'drive'): Promise<void> {
  const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  const bundleName = getBundleName(context);
  const uri = `https://www.petalmaps.com/routes?saddr=${startLat},${startLng}&daddr=${endLat},${endLng}&type=${type}&utm_source=${bundleName}`;
  await openPetalMaps(uri);
}
```

### 5. 位置搜索

```typescript
async function searchPlace(keyword: string): Promise<void> {
  const context = AppStorage.get('context') as common.UIAbilityContext;
  const bundleName = getBundleName(context);
  const uri = `https://www.petalmaps.com/search?q=${encodeURIComponent(keyword)}&utm_source=${bundleName}`;
  await openPetalMaps(uri);
}
```

## 注意事项

1. `utm_source` 参数值需通过 `context.applicationInfo.name` 动态获取
2. 经纬度格式：纬度在前，经度在后
3. 国内站点使用 GCJ02 坐标系，海外站点使用 WGS84 坐标系
4. `appLinkingOnly: true` 表示只允许拉起花瓣地图，不允许在浏览器打开
5. 中文关键词需使用 `encodeURIComponent` 编码
