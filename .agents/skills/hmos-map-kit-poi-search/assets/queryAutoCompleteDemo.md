# 自动补全 (Query Auto Complete)

提供输入联想自动补全功能。

## 接口调用

```typescript
import { site } from '@kit.MapKit';

const req: site.QueryAutoCompleteParams = {
  query: "餐厅",
  location: { latitude: 39.9042, longitude: 116.4074 },
  language: "zh_CN"
};

const rsp = await site.queryAutoComplete(req);

if (rsp.sites && rsp.sites.length > 0) {
  const sitesLength = rsp.sites.length;
  
  rsp.sites.forEach((item: site.Site, index: number) => {
    const name = item.name;
    const formatAddress = item.formatAddress;
    const distance = item.distance;
    const rating = item.poi?.rating;
  });
}
```
