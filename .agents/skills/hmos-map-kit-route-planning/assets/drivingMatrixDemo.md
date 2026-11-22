# 驾车批量算路 (Driving Matrix)

批量计算多个起点到多个终点之间的驾车路线距离和时间。

## 接口调用

```typescript
import { navi } from '@kit.MapKit';

const params: navi.DrivingMatrixParams = {
  origins: [
    { latitude: 31.974223, longitude: 118.773607 },
    { latitude: 32.02273, longitude: 118.78378 }
  ],
  destinations: [
    { latitude: 32.0855, longitude: 118.79261 }
  ],
  avoids: [1, 2],
  trafficMode: 2,
  language: 'zh_CN'
};

const rsp = await navi.getDrivingMatrix(params);

if (rsp.rows && rsp.rows.length > 0) {
  rsp.rows.forEach((row, i) => {
    row.cells.forEach((cell, j) => {
      const distance = cell.distance;
      const duration = cell.duration;
    });
  });
}
```
