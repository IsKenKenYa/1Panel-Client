# 正地理编码 (Geocode)

将地址文本转换为地理坐标（经纬度）。

## 接口调用

```typescript
import { site } from '@kit.MapKit';

const params: site.GeocodeParams = {
  query: "北京市朝阳区天安门广场",
  language: "zh_CN",
};

const rsp = await site.geocode(params);

if (rsp.sites && rsp.sites.length > 0) {
  const item = rsp.sites[0];
  const name = item.name;
  const formatAddress = item.formatAddress;
  const longitude = item.location?.longitude;
  const latitude = item.location?.latitude;
  
  if (item.addressComponent) {
    const addr = item.addressComponent;
    const countryName = addr.countryName;
    const countryCode = addr.countryCode;
    const adminLevel1 = addr.adminLevel1;
    const locality = addr.locality;
    const subLocality1 = addr.subLocality1;
  }
}
```
