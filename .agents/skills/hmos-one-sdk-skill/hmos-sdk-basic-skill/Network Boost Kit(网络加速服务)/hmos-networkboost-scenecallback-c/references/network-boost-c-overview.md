# NetworkBoost
---
# NetworkBoost
#### 概述
提供网络质量与网络连接迁移相关接口。
- 网络质量模块提供网络质量实时评估、网络场景识别以及弱信号预测等能力,以便应用针对弱网等环境下实现网络自适应,包括缓存、码率、帧率、分辨率等策略的调整。应用也可以通过网络质量中的应用传输体验反馈接口,触发系统进行网络加速。
- 连接迁移模块提供网络连接迁移能力,以便在弱网环境下,系统发起多网迁移(Wi-Fi<->蜂窝,主卡<->副卡等)的过程中,给应用提供连接迁移开始和完成通知,应用根据连接迁移通知的建议进行重建,快速恢复业务,给用户带来平滑、高速、低时延的上网体验。
- 多网并发是系统提供接口可以建立多个网络通路,应用发起多网请求后,系统依据业务场景决定并发组合和实施相应的并发管控,并对并发做收益度量。使用多网并发功能的原则是应用申请(受限权限)、系统管控、最小化使用。
**起始版本:** 5.1.0(18)
#### 汇总
#### 文件
| 名称 | 描述 |
| --- | --- |
| [network_boost_handover.h](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-files-handover) | 声明用于连接迁移的API。提供基本的函数,结构体和const定义。 |
| [network_boost_quality.h](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-files-quality) | 声明用于网络质量的API。提供基本的函数,结构体和const定义。 |
| [network_boost.h](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-files-boost) | 声明用于网络加速的API。提供基本的函数,结构体和const定义。 |
#### 结构体
| 名称 | 描述 |
| --- | --- |
| struct[NetworkBoost_NetworkScene](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-network_scene) | 网络场景状态变更回调信息。 |
| struct[NetworkBoost_WeakSignalPrediction](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-weak_signal_prediction) | 弱信号预测相关信息。 |
#### 枚举
| 名称 | 描述 |
| --- | --- |
| [NetworkBoost_Scene](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview){ NB_SCENE_NORMAL = 0, NB_SCENE_CONGESTION = 1, NB_SCENE_FREQUENT_HANDOVER = 2, NB_SCENE_WEAK_SIGNAL = 3 } | 网络场景类型。 |
| [NetworkBoost_PathType](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview){ NB_PATH_CELLULAR_PRIMARY = 0, NB_PATH_CELLULAR_SECONDARY = 1, NB_PATH_WIFI_PRIMARY = 2, NB_PATH_WIFI_SECONDARY = 3 } | 数据路径类型,枚举值。 |
| [NetworkBoost_RecommendedAction](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview){NB_ACTION_DO_CACHING = 0, NB_ACTION_SUSPEND_DATA = 1, NB_ACTION_DECREASE_DATA = 2, NB_ACTION_INCREASE_DATA = 3,NB_ACTION_KEEP_DATA = 4} | 应用数传策略建议。 |
#### 函数
| 名称 | 描述 |
| --- | --- |
| int32_t[HMS_NetworkBoost_RegisterNetSceneCallback](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)([HMS_NetworkBoost_NetSceneChange](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)callback, uint32_t *callbackId) | 注册网络场景变化回调。 |
| int32_t[HMS_NetworkBoost_UnregisterNetSceneCallback](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)(uint32_t callbackId) | 取消注册网络场景变化回调。 |

#### 函数说明
#### HMS_NetworkBoost_RegisterNetSceneCallback()
```
int32_t HMS_NetworkBoost_RegisterNetSceneCallback (HMS_NetworkBoost_NetSceneChange callback, uint32_t * callbackId )
```
**描述**
注册网络场景变化回调。
**起始版本:** 5.1.0(18)
**参数:**
| 名称 | 描述 |
| --- | --- |
| callback | 网络场景变化回调函数。 |
| callbackId | 回调函数的ID,由系统分配,用于取消注册回调。 |
**返回:**
0 - 成功。
201 - 权限不足。
401 - 参数错误。
801 - 系统能力不支持。
62100001 - 内部错误。
62100002 - 系统服务操作失败。
62100003 - 注册请求达到上限。
**权限:**
ohos.permission.GET_NETWORK_INFO

#### HMS_NetworkBoost_UnregisterNetSceneCallback()
```
int32_t HMS_NetworkBoost_UnregisterNetSceneCallback (uint32_t callbackId)
```
**描述**
取消注册网络场景变化回调。
**起始版本:** 5.1.0(18)
**参数:**
| 名称 | 描述 |
| --- | --- |
| callbackId | 回调的ID,在注册回调函数时由系统分配。 |
**返回:**
0 - 成功。
201 - 权限不足。
401 - 参数错误。
801 - 系统能力不支持。
62100001 - 内部错误。
62100002 - 系统服务操作失败。
**权限:**
ohos.permission.GET_NETWORK_INFO

#### NetworkBoost_NetworkScene结构体说明
#### pathType
```
NetworkBoost_PathType NetworkBoost_NetworkScene::pathType
```
**描述**
表明相应的数据路径上的网络场景信息。

#### scene
```
NetworkBoost_Scene NetworkBoost_NetworkScene::scene
```
**描述**
网络场景类型。

#### recommendedAction
```
NetworkBoost_RecommendedAction NetworkBoost_NetworkScene::recommendedAction
```
**描述**
建议的数传策略。

#### weakSignalPrediction
```
NetworkBoost_WeakSignalPrediction NetworkBoost_NetworkScene::weakSignalPrediction
```
**描述**
弱信号预测相关信息。

#### NetworkBoost_WeakSignalPrediction结构体说明
#### isLastPredictionValid
```
bool NetworkBoost_WeakSignalPrediction::isLastPredictionValid
```
**描述**
最近一次的弱信号预测是否有效,true表示最近一次的弱信号预测依旧有效,false表示最近一次的弱信号预测失效,此时startTime和duration参数忽略。

#### startTime
```
uint32_t NetworkBoost_WeakSignalPrediction::startTime
```
**描述**
预计多长时间进入弱信号(单位:s),取值范围为0和任意正数。

#### duration
```
uint32_t NetworkBoost_WeakSignalPrediction::duration
```
**描述**
预计在弱信号区域停留时长(单位:s),取任意正数。取值0,此次预测结果无效。

#### NetworkBoost_Scene枚举说明
```
enum NetworkBoost_Scene
```
**描述**
网络场景类型。
**起始版本:** 5.1.0(18)
| 枚举值 | 描述 |
| --- | --- |
| NB_SCENE_NORMAL | 正常场景。 |
| NB_SCENE_CONGESTION | 拥塞场景。 |
| NB_SCENE_FREQUENT_HANDOVER | 小区切换频繁场景。 |
| NB_SCENE_WEAK_SIGNAL | 弱信号场景。 |

#### NetworkBoost_PathType枚举说明
```
enum NetworkBoost_PathType
```
**描述**
数据路径类型。
**起始版本:** 5.1.0(18)
| 枚举值 | 描述 |
| --- | --- |
| NB_PATH_CELLULAR_PRIMARY | 蜂窝主卡。 |
| NB_PATH_CELLULAR_SECONDARY | 蜂窝副卡。 |
| NB_PATH_WIFI_PRIMARY | 主Wi-Fi。 |
| NB_PATH_WIFI_SECONDARY | 辅Wi-Fi。 |

#### NetworkBoost_RecommendedAction枚举说明
```
enum NetworkBoost_RecommendedAction
```
**描述**
应用数传策略建议。
**起始版本:** 5.1.0(18)
| 枚举值 | 描述 |
| --- | --- |
| NB_ACTION_DO_CACHING | 做缓存动作。 |
| NB_ACTION_SUSPEND_DATA | 停止发包。 |
| NB_ACTION_DECREASE_DATA | 降低发包速率。 |
| NB_ACTION_INCREASE_DATA | 增加发包速率。 |
| NB_ACTION_KEEP_DATA | 保持当前发包速率。 |