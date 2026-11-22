# 关键字搜索 (Search By Text)

通过关键词搜索地点。

## 接口调用

```typescript
import { site } from '@kit.MapKit';

const req: site.SearchByTextParams = {
  query: '餐厅',
  location: { latitude: 39.9042, longitude: 116.4074 },
  radius: 5000,
  pageIndex: 1,
  pageSize: 10
};

const rsp = await site.searchByText(req);

if (rsp.sites && rsp.sites.length > 0) {
  const totalCount = rsp.totalCount;
  
  rsp.sites.forEach((item: site.Site, index: number) => {
    const name = item.name;
    const formatAddress = item.formatAddress;
    const latitude = item.location?.latitude;
    const longitude = item.location?.longitude;
    const distance = item.distance;
    const rating = item.poi?.rating;
  });
}
```
