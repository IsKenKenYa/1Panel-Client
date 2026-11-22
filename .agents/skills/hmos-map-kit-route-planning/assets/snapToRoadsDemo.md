# 轨迹纠偏 (Snap to Roads)

将GPS轨迹点吸附到道路上。

## 接口调用

```typescript
import { navi } from '@kit.MapKit';

const params: navi.SnapToRoadsParams = {
  points: [
    { latitude: 54.216608, longitude: -4.66529 }
  ]
};

const rsp = await navi.snapToRoads(params);

if (rsp.snappedPoints && rsp.snappedPoints.length > 0) {
  rsp.snappedPoints.forEach((point, index) => {
    const latitude = point.latitude;
    const longitude = point.longitude;
  });
}
```
