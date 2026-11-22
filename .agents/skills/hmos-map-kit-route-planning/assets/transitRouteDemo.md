# 公交路线规划 (Transit Route)

获取公交路线规划结果。

## 接口调用

```typescript
import { navi } from '@kit.MapKit';

const params: navi.TransitRouteParams = {
  origin: { latitude: 31.974223, longitude: 118.773609 },
  destination: { latitude: 32.02273, longitude: 118.78378 },
  preference: 1
};

const rsp = await navi.getTransitRoutes(null, params);

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
