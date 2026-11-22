# 地理编码
---
# 地理编码
#### 场景介绍
提供正地理编码、逆地理编码的能力：
-
正地理编码：根据地址获取地点的经纬度。
-
逆地理编码：获取经纬度对应的地点信息。
#### 接口说明
以下是地理编码相关接口，主要由 [site](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-site.md) 命名空间下的方法提供，更多接口及使用方法请参见 [接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-site.md) 。
| 接口名 | 描述 |
| --- | --- |
| [geocode](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-site.md)(geocodeParams:[GeocodeParams](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-site.md)): Promise<[GeocodeResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-site.md)> | 正地理编码。 |
| [geocode](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-site.md)(context:[common.Context](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-context.md), geocodeParams:[GeocodeParams](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-site.md)): Promise<[GeocodeResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-site.md)> | 正地理编码。支持上传Context上下文。 |
| [reverseGeocode](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-site.md)(reverseGeocodeParams:[ReverseGeocodeParams](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-site.md)): Promise<[ReverseGeocodeResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-site.md)> | 逆地理编码。 |
| [reverseGeocode](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-site.md)(context:[common.Context](D:/code/APIDevice/output/md_output/harmonyos-references/应用框架/Ability Kit（程序框架服务）/ArkTS API/接口依赖的元素及定义/application/js-apis-inner-application-context.md), reverseGeocodeParams:[ReverseGeocodeParams](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-site.md)): Promise<[ReverseGeocodeResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-site.md)> | 逆地理编码。支持上传Context上下文。 |
| [GeocodeParams](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-site.md) | 正地理编码的参数。 |
| [GeocodeResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-site.md) | 正地理编码的结果。 |
| [ReverseGeocodeParams](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-site.md) | 逆地理编码的参数。 |
| [ReverseGeocodeResult](D:/code/APIDevice/output/md_output/harmonyos-references/应用服务/Map Kit（地图服务）/ArkTS API/map-site.md) | 逆地理编码的结果。 |
#### 开发步骤
导入相关模块。
```typescript
import { site } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';
```
#### 正地理编码
![](https://contentcenter-vali-drcn.dbankcdn.cn/pvt_2/DeveloperAlliance_scene_100_1/de/v3/wCbU-TSwRHSiPiH7B7SviQ/note_3.0-zh-cn.png?HW-CC-KV=V1&HW-CC-Date=20260701T105235Z&HW-CC-Expire=86400&HW-CC-Sign=496069C02E86C30948A0B1A27485C91550133463A5A02695D9DEA10E296B8150)
根据地址获取地点的空间坐标，如经纬度，最多返回10条记录。
```typescript
let params: site.GeocodeParams = {
  // 地址信息
  query: 'Piazzale Dante, 41, 55049 Viareggio',
  language: 'en'
};
try {
  // 调用正地理编码接口进行地址查询
  const result = await site.geocode(params);
  console.info(`Succeeded in geocoding. result is ${JSON.stringify(result)}`);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed in geocoding. Code is ${err.code}, message is ${err.message}`);
}
```
#### 逆地理编码
```
let params: site.ReverseGeocodeParams = {
  // 位置经纬度
  location: {
    latitude: 31.984410259206815,
    longitude: 118.76625379397866
  },
  language: 'en',
  radius: 0,
  isExtension: true,
  isNearbyAoi: true
};
try {
  // 调用逆地理编码接口进行坐标地址查询
  const result = await site.reverseGeocode(params);
  console.info(`Succeeded in reversing. result is ${JSON.stringify(result)}`);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`Failed in reversing. Code is ${err.code}, message is ${err.message}`);
}
```