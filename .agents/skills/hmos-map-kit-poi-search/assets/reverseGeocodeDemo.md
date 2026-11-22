# 逆地理编码 (Reverse Geocode)

将经纬度坐标转换为结构化地址信息。

## 接口调用

```typescript
import { site } from '@kit.MapKit';

const req: site.ReverseGeocodeParams = {
  location: { latitude: 39.9042, longitude: 116.4074 },
  language: "zh_CN",
  isExtension: true
};

const rsp = await site.reverseGeocode(req);

const addressDescription = rsp.addressDescription;

const addr = rsp.addressComponent;
const countryName = addr.countryName;
const adminLevel1 = addr.adminLevel1;
const locality = addr.locality;
const subLocality1 = addr.subLocality1;

if (rsp.pois && rsp.pois.length > 0) {
  rsp.pois.slice(0, 5).forEach((poi: site.ReverseGeocodePoi, index: number) => {
    const poiName = poi.name;
    const poiType = poi.poiType;
    const poiDistance = poi.distance;
  });
}

if (rsp.aois && rsp.aois.length > 0) {
  rsp.aois.forEach((aoi: site.Aoi) => {
    const aoiName = aoi.name;
    const aoiDistance = aoi.distance;
  });
}
```
