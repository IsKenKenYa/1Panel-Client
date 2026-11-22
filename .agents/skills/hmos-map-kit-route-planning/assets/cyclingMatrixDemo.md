# 骑行批量算路 (Cycling Matrix)

批量计算多个起点到多个终点之间的骑行路线距离和时间。

## 接口调用

```typescript
import { navi } from '@kit.MapKit';

const params: navi.MatrixParams = {
  origins: [
    { latitude: 31.974231, longitude: 118.773607 }
  ],
  destinations: [
    { latitude: 31.948245, longitude: 118.744137 }
  ],
  language: 'zh_CN'
};

const rsp = await navi.getCyclingMatrix(params);

if (rsp.rows && rsp.rows.length > 0) {
  rsp.rows.forEach((row, i) => {
    row.cells.forEach((cell, j) => {
      const distance = cell.distance;
      const duration = cell.duration;
    });
  });
}
```
