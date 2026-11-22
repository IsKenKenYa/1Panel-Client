# 周边搜索 (Nearby Search)

在指定位置周边搜索地点。

## 接口调用

```typescript
import { site } from '@kit.MapKit';

const req: site.NearbySearchParams = {
  query: "餐厅",
  location: { latitude: 39.9042, longitude: 116.4074 },
  pageIndex: 1,
  pageSize: 10
};

const rsp = await site.nearbySearch(req);

if (rsp.sites && rsp.sites.length > 0) {
  const totalCount = rsp.totalCount;
  
  rsp.sites.forEach((item: site.Site, index: number) => {
    const name = item.name;
    const formatAddress = item.formatAddress;
    const distance = item.distance;
    const latitude = item.location?.latitude;
    const longitude = item.location?.longitude;
  });
}
```
