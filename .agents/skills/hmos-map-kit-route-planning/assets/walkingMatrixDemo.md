# 步行批量算路 (Walking Matrix)

批量计算多个起点到多个终点之间的步行路线距离和时间。

## 接口调用

```typescript
import { navi } from '@kit.MapKit';

const params: navi.MatrixParams = {
  origins: [
    { latitude: 31.974222, longitude: 118.773606 },
    { latitude: 31.96863, longitude: 118.77158 }
  ],
  destinations: [
    { latitude: 32.069329, longitude: 118.76475 }
  ],
  language: 'zh_CN'
};

const rsp = await navi.getWalkingMatrix(params);

if (rsp.rows && rsp.rows.length > 0) {
  rsp.rows.forEach((row, i) => {
    row.cells.forEach((cell, j) => {
      const distance = cell.distance;
      const duration = cell.duration;
    });
  });
}
```
