# 多网建议监听
---
# 多网建议监听
#### 场景介绍
系统感知到应用可能需要使用多网络加速的场景时，如弱网、网络切换等特定场景，会给出建议。应用通过监听多网络加速的建议，决策发起多网络加速的请求。
#### 接口说明
具体API说明详见 [接口文档](D:/code/APIDevice/output/md_output/harmonyos-references/系统/网络/Network Boost Kit（网络加速服务）/ArkTS API/networkboost-nethandover.md) 。
| 接口名 | 描述 |
| --- | --- |
| on(type: 'multiPathRecommendation', callback: Callback<MultiPathRecommendationInfo>): void | 订阅多网建议信息变化。 |
| off(type: 'multiPathRecommendation', callback?: Callback<MultiPathRecommendationInfo>): void | 取消订阅多网建议信息变化。 |
#### 开发步骤
1.
导入Network Boost Kit模块。
```typescript
import { netHandover } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';
```
2.
通过订阅的方式监听系统多网建议变化信息。
```typescript
try {
  netHandover.on('multiPathRecommendation', (data: netHandover.MultiPathRecommendationInfo) => {
    // 回调信息处理
    console.info("on multiPathRecommendation: " + JSON.stringify(data));
  });
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```
3.
当应用业务流程结束，取消订阅系统多网建议变化信息。
```typescript
try {
  netHandover.off('multiPathRecommendation');
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```