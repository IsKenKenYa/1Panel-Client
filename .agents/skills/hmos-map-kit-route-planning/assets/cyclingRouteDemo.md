# 骑行路线规划 (Cycling Route)

获取骑行路线规划结果。

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

const rsp = await navi.getCyclingRoutes(params);

if (rsp.routes && rsp.routes.length > 0) {
  const route = rsp.routes[0];
  const points: mapCommon.LatLng[] = [];
  for (const step of route.steps) {
    for (const road of step.roads) {
      for (const point of road.polyline) {
        points.push({
          latitude: point.latitude,
          longitude: point.longitude
        });
      }
    }
  }
```
