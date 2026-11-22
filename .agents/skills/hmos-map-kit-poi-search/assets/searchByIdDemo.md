# 地点详情搜索 (Search By ID)

通过siteId获取地点的详细信息。

## 接口调用

```typescript
import { site } from '@kit.MapKit';

const req: site.SearchByIdParams = {
  siteId: "A00123456789",
  language: "zh",
  isChildren: false
};

const rsp = await site.searchById(req);

if (rsp.site) {
  const item = rsp.site;
  const name = item.name;
  const formatAddress = item.formatAddress;
  const latitude = item.location?.latitude;
  const longitude = item.location?.longitude;
  
  if (item.addressComponent) {
    const addr = item.addressComponent;
    const countryName = addr.countryName;
    const adminLevel1 = addr.adminLevel1;
    const locality = addr.locality;
  }
  
  if (item.poi) {
    const phone = item.poi.phone;
    const rating = item.poi.rating;
    const websiteUrl = item.poi.websiteUrl;
  }
}
```
