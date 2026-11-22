# 步行路线规划 (Walking Route)

获取步行路线规划结果。

## 接口调用

```typescript
import { navi } from '@kit.MapKit';

const params: navi.RouteParams = {
  origins: [{ latitude: 31.974222, longitude: 118.773607 }],
  destination: { latitude: 31.9802, longitude: 118.76316 },
  language: 'zh_CN',
  avoids: [0],
  extension: 0
};

const rsp = await navi.getWalkingRoutes(params);

if (rsp.routes.length > 0) {
  const route = rsp.routes[0];
  let totalDistance = 0;
  let totalDuration = 0;
  route.steps.forEach((step) => {
    totalDistance += step.distance;
    totalDuration += step.duration;
  });
}
```
