# 驾车路线规划 (Driving Route)

获取驾车路线规划结果。

## 接口调用

```typescript
import { navi } from '@kit.MapKit';

const params: navi.DrivingRouteParams = {
  origins: [{ latitude: 31.974221, longitude: 118.773606 }],
  destination: { latitude: 39.895336, longitude: 116.393388 },
  waypoints: [
    { latitude: 34.71452, longitude: 113.65631 },
    { latitude: 36.59913, longitude: 114.57032 },
    { latitude: 38.05674, longitude: 114.505 }
  ],
  language: 'zh_CN'
};

const rsp = await navi.getDrivingRoutes(params);

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
