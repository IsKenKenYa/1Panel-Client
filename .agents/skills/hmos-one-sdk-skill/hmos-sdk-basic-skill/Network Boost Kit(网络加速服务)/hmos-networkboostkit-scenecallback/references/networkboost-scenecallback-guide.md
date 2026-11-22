# 网络场景识别
---
# 网络场景识别
#### 场景介绍
应用在订阅网络场景识别后，系统在网络场景实时信息或预测信息发生变化后回调给应用，回调的网络场景信息包括数据传输的链路类型、网络场景类型、数传策略建议、弱信号信息等。
#### 接口说明
具体API说明详见 [接口文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/networkboost-netquality) 。
| 接口名 | 描述 |
| --- | --- |
| on(type: 'netSceneChange', callback: Callback<Array<NetworkScene>>): void | 订阅网络场景信息状态变化。 |
| off(type: 'netSceneChange', callback?: Callback<Array<NetworkScene>>): void | 取消订阅网络场景信息状态变化。 |
#### 开发步骤
1.
导入Network Boost Kit模块。
```typescript
import { netQuality } from '@kit.NetworkBoostKit';
import { BusinessError } from '@kit.BasicServicesKit';
```
2.
通过订阅的方式监听网络场景识别信息。
```typescript
try {
  netQuality.on('netSceneChange', (list: Array<netQuality.NetworkScene>) => {
    if (list.length > 0) {
      list.forEach((sceneInfo) => {
        // 网络场景识别回调信息处理
        if (sceneInfo.scene == 'congestion') {
          // 网络拥塞分支处理
        }
        if (sceneInfo.weakSignalPrediction) {
          // 存在弱信号预测信息，对弱信号预测信息进行处理
        }
      });
    }
  });
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```
3.
当应用业务流程结束，取消订阅监听网络场景识别信息。
```typescript
try {
  netQuality.off('netSceneChange');
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```