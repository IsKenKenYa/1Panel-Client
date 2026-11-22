# NetworkBoost_NetworkScene
---
# NetworkBoost_NetworkScene
#### 概述
网络场景状态变更回调信息。
**起始版本：** 5.1.0(18)
**相关模块：**  [NetworkBoost](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)
#### 汇总
#### 成员变量
| 名称 | 描述 |
| --- | --- |
| [NetworkBoost_PathType](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)[pathType](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-network_scene) | 表明相应的数据路径上的网络场景信息。 |
| [NetworkBoost_Scene](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)[scene](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-network_scene) | 网络场景类型。 |
| [NetworkBoost_RecommendedAction](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)[recommendedAction](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-network_scene) | 建议的数传策略。 |
| [NetworkBoost_WeakSignalPrediction](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-weak_signal_prediction)[weakSignalPrediction](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-network_scene) | 弱信号预测相关信息。 |
#### 结构体成员变量说明
#### pathType
```
NetworkBoost_PathType NetworkBoost_NetworkScene::pathType
```
**描述**
表明相应的数据路径上的网络场景信息。
#### recommendedAction
```
NetworkBoost_RecommendedAction NetworkBoost_NetworkScene::recommendedAction
```
**描述**
建议的数传策略。
#### scene
```
NetworkBoost_Scene NetworkBoost_NetworkScene::scene
```
**描述**
网络场景类型。
#### weakSignalPrediction
```
NetworkBoost_WeakSignalPrediction NetworkBoost_NetworkScene::weakSignalPrediction
```
**描述**
弱信号预测相关信息。